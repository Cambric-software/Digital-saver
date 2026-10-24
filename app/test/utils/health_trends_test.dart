/// Pure calculations behind the trends view.
///
/// These are the parts that decide what counts as "in the window", how an
/// average is formed and how a long run of one-minute samples becomes a
/// readable line. They are tested without a widget so a change in the maths is
/// caught separately from a change in the layout.
library;

import 'package:digital_saver/features/screens/health_trends_screen.dart';
import 'package:digital_saver/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

WatchSample _sample(
  DateTime at, {
  int hr = 0,
  int spo2 = 0,
  int hrv = 0,
}) {
  return WatchSample(
    unix: at.toUtc().millisecondsSinceEpoch ~/ 1000,
    hr: hr,
    spo2: spo2,
    hrv: hrv,
  );
}

void main() {
  final DateTime now = DateTime(2026, 10, 20, 12);

  test('samplesWithin keeps only the selected window, oldest first', () {
    final List<WatchSample> samples = <WatchSample>[
      _sample(now.subtract(const Duration(hours: 2)), hr: 70),
      _sample(now.subtract(const Duration(days: 2)), hr: 72),
      _sample(now.subtract(const Duration(days: 10)), hr: 74),
    ];

    expect(samplesWithin(samples, TrendPeriod.day, now: now).length, 1);
    expect(samplesWithin(samples, TrendPeriod.week, now: now).length, 2);
    expect(samplesWithin(samples, TrendPeriod.retained, now: now).length, 3);

    final List<WatchSample> ordered = samplesWithin(
      samples,
      TrendPeriod.retained,
      now: now,
    );
    expect(ordered.first.unix, lessThan(ordered.last.unix));
  });

  test('a sample with no reading is not averaged as zero', () {
    final List<WatchSample> samples = <WatchSample>[
      _sample(now, hr: 60, spo2: 0),
      _sample(now, hr: 0, spo2: 97),
      _sample(now, hr: 80, spo2: 99),
    ];

    final TrendSummary summary = summarizeSamples(samples);

    expect(summary.sampleCount, 3);
    expect(summary.heartRateCount, 2);
    expect(summary.averageBpm, 70);
    expect(summary.minimumBpm, 60);
    expect(summary.maximumBpm, 80);
    expect(summary.oxygenCount, 2);
    expect(summary.averageSpO2, 98);
    expect(summary.hasHeartRate, isTrue);
  });

  test('empty history has no averages and no readings', () {
    final TrendSummary summary = summarizeSamples(const <WatchSample>[]);

    expect(summary.sampleCount, 0);
    expect(summary.hasHeartRate, isFalse);
    expect(summary.hasOxygen, isFalse);
    expect(summary.averageBpm, 0);
    expect(summary.averageSpO2, 0);
  });

  test('trendPoints skips samples that measured nothing', () {
    final List<WatchSample> samples = <WatchSample>[
      _sample(now, hr: 0),
      _sample(now.add(const Duration(minutes: 1)), hr: 0),
    ];

    expect(
      trendPoints(
        samples,
        read: (WatchSample sample) => sample.hr,
        origin: now,
      ),
      isEmpty,
    );
  });

  test('trendPoints averages buckets and keeps the time order', () {
    final List<WatchSample> samples = <WatchSample>[
      for (var i = 0; i < 10; i++)
        _sample(
          now.add(Duration(minutes: i)),
          hr: 60 + i * 2,
        ),
    ];

    final List<TrendPoint> points = trendPoints(
      samples,
      read: (WatchSample sample) => sample.hr,
      origin: now,
      maxPoints: 5,
    );

    expect(points.length, 5);
    expect(
      points.map((TrendPoint point) => point.value).toList(),
      <int>[61, 65, 69, 73, 77],
    );
    for (var i = 1; i < points.length; i++) {
      expect(points[i].minute, greaterThan(points[i - 1].minute));
    }
  });

  test('trendPoints keeps every sample when the limit is not reached', () {
    final List<WatchSample> samples = <WatchSample>[
      _sample(now, hr: 66),
      _sample(now.add(const Duration(minutes: 1)), hr: 68),
    ];

    final List<TrendPoint> points = trendPoints(
      samples,
      read: (WatchSample sample) => sample.hr,
      origin: now,
      maxPoints: 120,
    );

    expect(points.length, 2);
    expect(points.first.minute, 0);
    expect(points.last.value, 68);
  });

  test('dailyTrends groups by local day, newest day first', () {
    final List<WatchSample> samples = <WatchSample>[
      _sample(DateTime(2026, 10, 18, 9), hr: 60, spo2: 96),
      _sample(DateTime(2026, 10, 18, 10), hr: 70, spo2: 98),
      _sample(DateTime(2026, 10, 19, 9), hr: 80, spo2: 97),
    ];

    final List<DailyTrend> days = dailyTrends(samples);

    expect(days.length, 2);
    expect(days.first.day, DateTime(2026, 10, 19));
    expect(days.first.sampleCount, 1);
    expect(days.first.averageBpm, 80);
    expect(days.last.sampleCount, 2);
    expect(days.last.averageBpm, 65);
    expect(days.last.averageSpO2, 97);
  });
}
