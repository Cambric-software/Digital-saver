/// Pure calculations behind the milestones view.
///
/// Streaks and counts are the only thing that decides whether a milestone is
/// reached, so they are tested directly rather than through a widget. The
/// cases that matter are the ones the old hard-coded badges could not express:
/// gaps, duplicates, a run that ended two days ago, and an empty history.
library;

import 'package:digital_saver/features/screens/achievements_screen.dart';
import 'package:digital_saver/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

WatchSample _sample(
  DateTime at, {
  int hr = 0,
  int spo2 = 0,
  int hrv = 0,
  int steps = 0,
}) {
  return WatchSample(
    unix: at.toUtc().millisecondsSinceEpoch ~/ 1000,
    hr: hr,
    spo2: spo2,
    hrv: hrv,
    steps: steps,
  );
}

Milestone _byId(List<Milestone> milestones, String id) =>
    milestones.firstWhere((Milestone milestone) => milestone.id == id);

void main() {
  test('recordingDays deduplicates and sorts calendar days', () {
    final List<WatchSample> samples = <WatchSample>[
      _sample(DateTime(2026, 10, 3, 9)),
      _sample(DateTime(2026, 10, 1, 8)),
      _sample(DateTime(2026, 10, 3, 21)),
    ];

    final List<DateTime> days = recordingDays(samples);

    expect(days, <DateTime>[
      DateTime.utc(2026, 10, 1),
      DateTime.utc(2026, 10, 3),
    ]);
  });

  test('the longest streak spans a run and ignores gaps', () {
    final List<DateTime> days = <DateTime>[
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 2),
      DateTime(2026, 10, 4),
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 6),
    ];

    expect(longestDayStreak(days), 3);
  });

  test('a streak ending yesterday still counts today', () {
    final List<DateTime> days = <DateTime>[
      DateTime(2026, 10, 17),
      DateTime(2026, 10, 18),
      DateTime(2026, 10, 19),
    ];

    expect(
      currentDayStreak(days, asOf: DateTime(2026, 10, 20, 8)),
      3,
    );
    expect(
      currentDayStreak(days, asOf: DateTime(2026, 10, 21, 8)),
      0,
    );
  });

  test('an empty history has no streak', () {
    expect(longestDayStreak(const <DateTime>[]), 0);
    expect(currentDayStreak(const <DateTime>[]), 0);
  });

  test('no stored samples earns nothing', () {
    final List<Milestone> milestones = milestonesFor(const <WatchSample>[]);

    expect(milestones.length, 10);
    expect(
      milestones.where((Milestone milestone) => milestone.earned),
      isEmpty,
    );
    expect(_byId(milestones, 'first_reading').progress, 0);
    expect(_byId(milestones, 'seven_days').fraction, 0);
  });

  test('milestones are counted from the samples that exist', () {
    final List<WatchSample> samples = <WatchSample>[
      for (var day = 0; day < 7; day++)
        for (var minute = 0; minute < 15; minute++)
          _sample(
            DateTime(2026, 10, 1 + day, 6, minute),
            hr: 60,
            spo2: 97,
            hrv: 40,
            steps: day == 0 && minute == 0 ? 12000 : 100,
          ),
    ];

    final List<Milestone> milestones = milestonesFor(samples);

    expect(samples.length, 105);
    expect(recordingDays(samples).length, 7);
    expect(longestDayStreak(recordingDays(samples)), 7);

    expect(_byId(milestones, 'first_reading').earned, isTrue);
    expect(_byId(milestones, 'hundred_readings').earned, isTrue);
    expect(_byId(milestones, 'seven_days').earned, isTrue);
    expect(_byId(milestones, 'thirty_days').earned, isFalse);
    expect(_byId(milestones, 'three_day_streak').earned, isTrue);
    expect(_byId(milestones, 'seven_day_streak').earned, isTrue);
    expect(_byId(milestones, 'early_reading').earned, isTrue);
    expect(_byId(milestones, 'oxygen_reading').earned, isTrue);
    expect(_byId(milestones, 'step_ten_thousand').earned, isTrue);
    expect(_byId(milestones, 'hrv_reading').earned, isTrue);
  });

  test('progress never shows more than the target', () {
    final List<WatchSample> samples = <WatchSample>[
      for (var minute = 0; minute < 130; minute++)
        _sample(DateTime(2026, 10, 1, 9, minute), hr: 60),
    ];

    final Milestone reading = _byId(milestonesFor(samples), 'hundred_readings');

    expect(reading.progress, 130);
    expect(reading.shownProgress, 100);
    expect(reading.fraction, 1.0);
    expect(reading.earned, isTrue);
  });
}
