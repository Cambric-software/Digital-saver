/// The calculations behind the Patterns panel.
///
/// The old analytics file returned a number for every score even when the
/// watch had measured nothing. These tests pin the opposite rule: an estimate
/// appears only when the samples can support it, and oxygen is reported
/// separately so a missing heart rate cannot hide a real oxygen reading.
library;

import 'package:digital_saver/core/services/health_analysis_service_v2.dart';
import 'package:digital_saver/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

WatchSample _sample(
  DateTime at, {
  int hr = 0,
  int spo2 = 0,
}) {
  return WatchSample(
    unix: at.toUtc().millisecondsSinceEpoch ~/ 1000,
    hr: hr,
    spo2: spo2,
  );
}

void main() {
  final DateTime dayOne = DateTime(2026, 10, 18, 9);
  final DateTime dayTwo = DateTime(2026, 10, 19, 9);

  test('an empty history reports nothing measured', () {
    final HealthPatterns patterns =
        HealthPatternsService.analyze(const <WatchSample>[]);

    expect(patterns.sampleCount, 0);
    expect(patterns.heartRateSamples, 0);
    expect(patterns.daysWithHeartRate, 0);
    expect(patterns.restingHeartRate, 0);
    expect(patterns.direction, HeartRateDirection.unknown);
    expect(patterns.changeBpm, 0);
    expect(patterns.lowestOxygen, 0);
    expect(patterns.hasAnyReading, isFalse);
    expect(patterns.hasRestingHeartRate, isFalse);
    expect(patterns.hasDirection, isFalse);
    expect(patterns.hasOxygen, isFalse);
  });

  test('samples with zero fields are skipped, not counted as readings', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      _sample(dayOne, hr: 0, spo2: 0),
      _sample(dayOne.add(const Duration(minutes: 1)), hr: 0, spo2: 0),
    ]);

    expect(patterns.sampleCount, 2);
    expect(patterns.heartRateSamples, 0);
    expect(patterns.oxygenSamples, 0);
    expect(patterns.hasAnyReading, isFalse);
    expect(patterns.restingHeartRate, 0);
  });

  test('one day of heart rate is not enough for a resting estimate', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      for (var i = 0; i < 8; i++)
        _sample(
          dayOne.add(Duration(minutes: i * 5)),
          hr: 60 + i,
          spo2: 97,
        ),
    ]);

    expect(patterns.heartRateSamples, 8);
    expect(patterns.daysWithHeartRate, 1);
    expect(patterns.hasRestingHeartRate, isFalse);
    expect(patterns.hasDirection, isFalse);
    expect(patterns.restingHeartRate, 0);
    expect(patterns.direction, HeartRateDirection.unknown);
    // Oxygen does not depend on the heart-rate minimum.
    expect(patterns.hasOxygen, isTrue);
    expect(patterns.lowestOxygen, 97);
  });

  test('the resting estimate is the mean of the lowest quarter', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      for (var i = 0; i < 4; i++)
        _sample(
          dayOne.add(Duration(minutes: i)),
          hr: <int>[50, 52, 54, 56][i],
        ),
      for (var i = 0; i < 4; i++)
        _sample(
          dayTwo.add(Duration(minutes: i)),
          hr: <int>[90, 100, 110, 120][i],
        ),
    ]);

    // Eight values -> ceil(8 / 4) = 2 lowest values -> (50 + 52) / 2.
    expect(patterns.heartRateSamples, 8);
    expect(patterns.daysWithHeartRate, 2);
    expect(patterns.restingHeartRate, 51);
    expect(patterns.hasRestingHeartRate, isTrue);
    expect(patterns.direction, HeartRateDirection.rising);
  });

  test('a later higher half is reported as rising with its change', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      _sample(dayOne, hr: 50),
      _sample(dayOne.add(const Duration(minutes: 5)), hr: 60),
      _sample(dayTwo, hr: 70),
      _sample(dayTwo.add(const Duration(minutes: 5)), hr: 80),
    ]);

    expect(patterns.direction, HeartRateDirection.rising);
    expect(patterns.direction.label, 'Rising');
    expect(patterns.changeBpm, 20);
    expect(patterns.hasDirection, isTrue);
  });

  test('a later lower half is reported as falling', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      _sample(dayOne, hr: 80),
      _sample(dayOne.add(const Duration(minutes: 5)), hr: 90),
      _sample(dayTwo, hr: 50),
      _sample(dayTwo.add(const Duration(minutes: 5)), hr: 60),
    ]);

    expect(patterns.direction, HeartRateDirection.falling);
    expect(patterns.changeBpm, -30);
  });

  test('a small difference between halves is called steady', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      _sample(dayOne, hr: 60),
      _sample(dayOne.add(const Duration(minutes: 5)), hr: 61),
      _sample(dayTwo, hr: 62),
      _sample(dayTwo.add(const Duration(minutes: 5)), hr: 63),
    ]);

    expect(patterns.direction, HeartRateDirection.steady);
    expect(
        patterns.changeBpm.abs(),
        lessThan(
          HealthPatternsService.trendThresholdBpm,
        ));
  });

  test('the lowest oxygen is the smallest measured value, not an average', () {
    final HealthPatterns patterns = HealthPatternsService.analyze(<WatchSample>[
      _sample(dayOne, hr: 60, spo2: 98),
      _sample(dayOne.add(const Duration(minutes: 5)), hr: 61, spo2: 94),
      _sample(dayTwo, hr: 62, spo2: 97),
      _sample(dayTwo.add(const Duration(minutes: 5)), hr: 63, spo2: 96),
    ]);

    expect(patterns.oxygenSamples, 4);
    expect(patterns.lowestOxygen, 94);
    expect(patterns.hasOxygen, isTrue);
  });

  test('the minimums are stateable in the code rather than implied', () {
    expect(HealthPatternsService.minimumHeartRateSamples, 4);
    expect(HealthPatternsService.minimumDays, 2);
    expect(HealthPatternsService.trendThresholdBpm, 3);
  });
}
