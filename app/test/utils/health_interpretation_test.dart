import 'package:digital_saver/models/health_models.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:digital_saver/utils/health_interpretation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every screen that shows a reading asks this module what it means. If it is
/// wrong, the same number reads as fine on one screen and alarming on another,
/// so these tests pin the behaviour rather than the implementation.
void main() {
  group('a zero reading is absent, not a measurement', () {
    test('the helpers reject zero', () {
      expect(hasHeartRate(0), isFalse);
      expect(hasOxygen(0), isFalse);
      expect(hasBloodPressure(BloodPressureData()), isFalse);
    });

    test('a zero reading is never classified as normal', () {
      // The dangerous case: showing 0 BPM as "in the usual range" invites
      // someone to believe the watch measured them when it did not.
      expect(interpretHeartRate(0), HealthStatus.unknown);
      expect(interpretOxygen(0), HealthStatus.unknown);
      expect(interpretAfib(0), HealthStatus.unknown);
    });

    test('blood pressure displays as dashes, not as 0/0', () {
      expect(formatBloodPressure(BloodPressureData()), '--');
    });

    test('a half-present blood pressure reading is still absent', () {
      // One sensor with no value is not a measurement.
      expect(
        hasBloodPressure(BloodPressureData(systolic: 120, diastolic: 0)),
        isFalse,
      );
    });
  });

  group('heart rate', () {
    test('a typical resting rate is unremarkable', () {
      expect(interpretHeartRate(62), HealthStatus.normal);
      expect(interpretHeartRate(70), HealthStatus.normal);
    });

    test('a very low or very high rate is critical', () {
      expect(interpretHeartRate(35), HealthStatus.critical);
      expect(interpretHeartRate(190), HealthStatus.critical);
    });

    test('mild elevation is distinguished from serious elevation', () {
      expect(interpretHeartRate(105), HealthStatus.elevated);
      expect(interpretHeartRate(165), HealthStatus.high);
    });

    test('a personal baseline is respected over the population band', () {
      // 52 is inside the population resting band, so unremarkable. But for
      // someone whose baseline is 68, it is a fall, and a fall matters.
      expect(interpretHeartRate(52), HealthStatus.normal);
      expect(
        interpretHeartRateAgainstBaseline(52, restingBpm: 68),
        HealthStatus.elevated,
      );
    });

    test('a rise from baseline is caught even when the number looks normal', () {
      // 75 is an ordinary-looking heart rate. Against a baseline of 55 it is a
      // 36% rise, which a population check would miss entirely.
      expect(interpretHeartRate(75), HealthStatus.normal);
      expect(
        interpretHeartRateAgainstBaseline(75, restingBpm: 55),
        HealthStatus.elevated,
      );
    });

    test('a baseline of zero falls back to the population check', () {
      expect(
        interpretHeartRateAgainstBaseline(70, restingBpm: 0),
        interpretHeartRate(70),
      );
    });

    test('a critical reading is never softened by a healthy baseline', () {
      expect(
        interpretHeartRateAgainstBaseline(190, restingBpm: 65),
        HealthStatus.critical,
      );
    });
  });

  group('blood pressure', () {
    BloodPressureData bp(int systolic, int diastolic) =>
        BloodPressureData(systolic: systolic, diastolic: diastolic);

    test('a typical reading is unremarkable', () {
      expect(interpretBloodPressure(bp(118, 76)), HealthStatus.normal);
    });

    test('the bands step up rather than jumping straight to critical', () {
      expect(interpretBloodPressure(bp(132, 80)), HealthStatus.elevated);
      expect(interpretBloodPressure(bp(145, 92)), HealthStatus.high);
      expect(interpretBloodPressure(bp(185, 122)), HealthStatus.critical);
    });

    test('either number alone can be critical', () {
      // Isolated systolic or diastolic crisis is still crisis.
      expect(interpretBloodPressure(bp(182, 70)), HealthStatus.critical);
      expect(interpretBloodPressure(bp(110, 125)), HealthStatus.critical);
    });

    test('formats as systolic over diastolic', () {
      expect(formatBloodPressure(bp(118, 76)), '118/76');
    });
  });

  group('oxygen', () {
    test('normal saturation is unremarkable', () {
      expect(interpretOxygen(98), HealthStatus.normal);
    });

    test('the bands step up', () {
      expect(interpretOxygen(95), HealthStatus.elevated);
      expect(interpretOxygen(93), HealthStatus.high);
      expect(interpretOxygen(88), HealthStatus.critical);
    });

    test('the boundary is inclusive at the safe end', () {
      // 94 and 95 straddle the line; both must be handled deliberately.
      expect(interpretOxygen(95), isNot(HealthStatus.normal));
      expect(interpretOxygen(96), HealthStatus.normal);
    });
  });

  group('atrial fibrillation probability', () {
    test('a low probability is unremarkable', () {
      expect(interpretAfib(10), HealthStatus.normal);
    });

    test('a raised probability is flagged for checking', () {
      expect(interpretAfib(30), HealthStatus.elevated);
      expect(interpretAfib(70), HealthStatus.high);
    });
  });

  group('recovery', () {
    test('an absent reading is never described as low', () {
      // Zero HRV means no data. Reporting it as "recovery may be low" would
      // invent a concern out of a missing value.
      expect(isRecoveryLow(hrv: 0, restingHrv: 40), isFalse);
    });

    test('a known baseline is used in preference to a fixed cutoff', () {
      expect(isRecoveryLow(hrv: 25, restingHrv: 40), isTrue);
      expect(isRecoveryLow(hrv: 38, restingHrv: 40), isFalse);
    });

    test('without a baseline, a clearly low reading is still flagged', () {
      expect(isRecoveryLow(hrv: 12, restingHrv: 0), isTrue);
      expect(isRecoveryLow(hrv: 45, restingHrv: 0), isFalse);
    });
  });

  group('guidance wording', () {
    test('an unremarkable reading gets no advice', () {
      expect(guidanceFor(HealthStatus.normal, 'heart rate'), isNull);
      expect(guidanceFor(HealthStatus.unknown, 'heart rate'), isNull);
    });

    test('advice never uses diagnostic language', () {
      // The app is not placed to tell someone what is wrong with them.
      for (final status in <HealthStatus>[
        HealthStatus.elevated,
        HealthStatus.high,
        HealthStatus.critical,
      ]) {
        final text = guidanceFor(status, 'heart rate')!.toLowerCase();
        for (final forbidden in <String>[
          'you have',
          'diagnos',
          'healthy',
          'abnormal',
        ]) {
          expect(
            text.contains(forbidden),
            isFalse,
            reason: '$status guidance must not say "$forbidden"',
          );
        }
      }
    });

    test('a critical reading tells the person to act', () {
      final text = guidanceFor(HealthStatus.critical, 'heart rate')!;
      expect(
        text.contains('clinician') || text.contains('emergency'),
        isTrue,
        reason: 'a critical reading must say what to do',
      );
    });
  });

  group('status presentation', () {
    test('every status is distinguishable without relying on colour', () {
      // Colour alone excludes anyone with a colour vision deficiency, and in a
      // health context that is not acceptable.
      final labels = HealthStatus.values.map((s) => s.label).toSet();
      final icons = HealthStatus.values.map((s) => s.icon).toSet();
      expect(labels.length, HealthStatus.values.length);
      expect(icons.length, HealthStatus.values.length);
    });
  });
}