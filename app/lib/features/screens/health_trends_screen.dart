/// Trends from the samples the watch has actually stored.
///
/// Almost nothing on the previous version was measured:
///
/// * the "Heart Rate Pattern" chart was drawn from `math.Random(42)`, with a
///   comment explaining that it added "peaks for realistic heart rate pattern" -
///   a fabricated day of heart rate presented as the wearer's;
/// * "Activity Overview" drew seven bar heights from
///   `3000 + random.nextInt(7000)` and labelled them Mon to Sun, so the bars
///   were random numbers pretending to be steps;
/// * the Day/Week/Month/Year selector assigned a string and nothing else: every
///   window showed the same invented chart;
/// * the summary cards were hard-coded to `--`, so even with weeks of synced
///   samples the screen could not show a real average;
/// * the screen carried its own [Scaffold] and app bar inside the app shell, and
///   painted white text on the light surface, which made the labels disappear
///   in light mode.
///
/// What is here now reads [LocalStore], filters by a real time window, and draws
/// only the samples that exist. A window with no samples says so, and the
/// interpretation of the latest reading comes from
/// [health_interpretation.dart] rather than from words chosen here.
///
/// The "Patterns" panel is the measured half of that idea. Its three statements
/// - a resting estimate, a direction and the lowest oxygen reading - come from
/// [HealthPatternsService], which needs a stated minimum before it will answer.
/// When that minimum is not met the panel shows `--` and says how much data is
/// missing rather than filling the gap with a guess.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/health_analysis_service_v2.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/veyro_protocol.dart';
import 'package:cambric_design/cambric_design.dart';
import '../../../shared/utils/health_interpretation.dart';

/// The time window a trend view covers.
enum TrendPeriod {
  /// The last 24 hours.
  day('24 hours', Duration(hours: 24)),

  /// The last seven days.
  week('7 days', Duration(days: 7)),

  /// The last thirty days.
  month('30 days', Duration(days: 30)),

  /// Everything the watch and this phone still keep.
  retained('All kept', null);

  const TrendPeriod(this.label, this.window);

  /// Label used by the segmented control.
  final String label;

  /// How far back to look, or null for everything retained.
  final Duration? window;
}

/// One point on a trend chart: minutes into the window, and the value.
class TrendPoint {
  /// Create a point.
  const TrendPoint({required this.minute, required this.value});

  /// Minutes from the window's first sample.
  final double minute;

  /// The measured value, in the metric's own unit.
  final int value;
}

/// Summary statistics for a set of stored samples.
class TrendSummary {
  /// Create a summary.
  const TrendSummary({
    required this.sampleCount,
    required this.heartRateCount,
    required this.averageBpm,
    required this.minimumBpm,
    required this.maximumBpm,
    required this.oxygenCount,
    required this.averageSpO2,
  });

  /// Samples in the window, including ones with no reading.
  final int sampleCount;

  /// Samples that carried a heart rate.
  final int heartRateCount;

  /// Mean heart rate, or 0 when nothing was measured.
  final int averageBpm;

  /// Lowest measured heart rate, or 0 when nothing was measured.
  final int minimumBpm;

  /// Highest measured heart rate, or 0 when nothing was measured.
  final int maximumBpm;

  /// Samples that carried an oxygen saturation.
  final int oxygenCount;

  /// Mean oxygen saturation, or 0 when nothing was measured.
  final int averageSpO2;

  /// Whether any heart rate was measured.
  bool get hasHeartRate => heartRateCount > 0;

  /// Whether any oxygen saturation was measured.
  bool get hasOxygen => oxygenCount > 0;
}

/// Per-day averages from stored samples.
class DailyTrend {
  /// Create a day's summary.
  const DailyTrend({
    required this.day,
    required this.sampleCount,
    required this.averageBpm,
    required this.averageSpO2,
  });

  /// The calendar day, at local midnight.
  final DateTime day;

  /// Samples stored on this day.
  final int sampleCount;

  /// Mean heart rate, or 0 when no sample carried one.
  final int averageBpm;

  /// Mean oxygen saturation, or 0 when no sample carried one.
  final int averageSpO2;
}

/// Samples inside [period], oldest first.
List<WatchSample> samplesWithin(
  List<WatchSample> samples,
  TrendPeriod period, {
  required DateTime now,
}) {
  final Duration? window = period.window;
  final DateTime? cutoff = window == null ? null : now.subtract(window);
  final List<WatchSample> selected = cutoff == null
      ? List<WatchSample>.of(samples)
      : samples
          .where((WatchSample sample) => sample.at.isAfter(cutoff))
          .toList();
  selected.sort(
    (WatchSample a, WatchSample b) => a.unix.compareTo(b.unix),
  );
  return selected;
}

/// Mean, minimum and maximum for the measurements that exist in [samples].
///
/// A sample whose heart rate or oxygen field is zero did not measure that
/// metric, so it is left out of the mean rather than counted as zero.
TrendSummary summarizeSamples(List<WatchSample> samples) {
  var hrSum = 0;
  var hrCount = 0;
  var hrMin = 0;
  var hrMax = 0;
  var o2Sum = 0;
  var o2Count = 0;

  for (final WatchSample sample in samples) {
    if (sample.hr > 0) {
      hrSum += sample.hr;
      hrCount++;
      if (hrMin == 0 || sample.hr < hrMin) hrMin = sample.hr;
      if (sample.hr > hrMax) hrMax = sample.hr;
    }
    if (sample.spo2 > 0) {
      o2Sum += sample.spo2;
      o2Count++;
    }
  }

  return TrendSummary(
    sampleCount: samples.length,
    heartRateCount: hrCount,
    averageBpm: hrCount == 0 ? 0 : (hrSum / hrCount).round(),
    minimumBpm: hrMin,
    maximumBpm: hrMax,
    oxygenCount: o2Count,
    averageSpO2: o2Count == 0 ? 0 : (o2Sum / o2Count).round(),
  );
}

/// Groups [samples] by local calendar day, newest day first.
List<DailyTrend> dailyTrends(List<WatchSample> samples) {
  final Map<String, List<WatchSample>> groups = <String, List<WatchSample>>{};
  for (final WatchSample sample in samples) {
    final DateTime at = sample.at;
    final String key = '${at.year}-${at.month}-${at.day}';
    groups.putIfAbsent(key, () => <WatchSample>[]).add(sample);
  }

  final List<DailyTrend> days = <DailyTrend>[];
  for (final List<WatchSample> group in groups.values) {
    final DateTime at = group.first.at;
    final TrendSummary summary = summarizeSamples(group);
    days.add(
      DailyTrend(
        day: DateTime(at.year, at.month, at.day),
        sampleCount: summary.sampleCount,
        averageBpm: summary.averageBpm,
        averageSpO2: summary.averageSpO2,
      ),
    );
  }
  days.sort((DailyTrend a, DailyTrend b) => b.day.compareTo(a.day));
  return days;
}

/// Plot points from [samples], averaged into at most [maxPoints] buckets.
///
/// A day of one-minute samples is well over a thousand points; drawing all of
/// them makes a line that is mostly ink. Bucketing averages consecutive stored
/// samples, so the shape is preserved without inventing values between them.
/// Samples whose [read] value is zero are skipped rather than plotted as zero.
List<TrendPoint> trendPoints(
  List<WatchSample> samples, {
  required int Function(WatchSample sample) read,
  required DateTime origin,
  int maxPoints = 120,
}) {
  final List<WatchSample> measured = samples
      .where((WatchSample sample) => read(sample) > 0)
      .toList()
    ..sort((WatchSample a, WatchSample b) => a.unix.compareTo(b.unix));
  if (measured.isEmpty) return <TrendPoint>[];

  final int limit = maxPoints < 1 ? 1 : maxPoints;
  final int bucketSize =
      (measured.length / limit).ceil().clamp(1, measured.length);
  final List<TrendPoint> points = <TrendPoint>[];

  for (var start = 0; start < measured.length; start += bucketSize) {
    final int end = math.min(start + bucketSize, measured.length);
    final List<WatchSample> bucket = measured.sublist(start, end);
    var sum = 0;
    var minutes = 0.0;
    for (final WatchSample sample in bucket) {
      sum += read(sample);
      minutes += sample.at.difference(origin).inSeconds / 60;
    }
    points.add(
      TrendPoint(
        minute: minutes / bucket.length,
        value: (sum / bucket.length).round(),
      ),
    );
  }
  return points;
}

/// What the stored history can say about the last [TrendPeriod].
class HealthTrendsScreen extends StatefulWidget {
  /// Create the trends view.
  ///
  /// [samples] exists for tests and previews: when supplied, the screen uses
  /// them instead of opening the on-device history. The app always omits it.
  const HealthTrendsScreen({super.key, this.samples});

  /// Pre-supplied stored samples, or null to read [LocalStore].
  final List<WatchSample>? samples;

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen> {
  TrendPeriod _period = TrendPeriod.week;
  List<WatchSample> _samples = const <WatchSample>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final List<WatchSample>? supplied = widget.samples;
    if (supplied != null) {
      _samples = supplied;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final List<WatchSample> samples = await LocalStore.loadAll();
      if (!mounted) return;
      setState(() {
        _samples = samples;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color heart = AppColors.of(
      AppColors.heartRed,
      AppColors.darkHeart,
      context,
    );
    final Color oxygen = AppColors.of(
      AppColors.oxyGreen,
      AppColors.darkOxy,
      context,
    );

    final DateTime now = DateTime.now();
    final List<WatchSample> window = samplesWithin(
      _samples,
      _period,
      now: now,
    );
    final TrendSummary summary = summarizeSamples(window);
    final DateTime origin = window.isEmpty ? now : window.first.at;
    final List<TrendPoint> heartPoints = trendPoints(
      window,
      read: (WatchSample sample) => sample.hr,
      origin: origin,
    );
    final List<TrendPoint> oxygenPoints = trendPoints(
      window,
      read: (WatchSample sample) => sample.spo2,
      origin: origin,
    );
    final WatchSample? latest = _latestReading(window);
    final List<DailyTrend> days = dailyTrends(window);
    final HealthPatterns patterns = HealthPatternsService.analyze(window);

    return DsSection(
      title: 'Health trends',
      subtitle: 'Readings the watch has stored on this phone',
      trailing: IconButton(
        tooltip: 'Reload stored history',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: _loading
          ? const _LoadingCard(label: 'Reading stored history…')
          : _error != null
              ? _UnreadableHistory(error: _error!)
              : _samples.isEmpty
                  ? const _NoHistory()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DsSegmented<TrendPeriod>(
                          value: _period,
                          onChanged: (TrendPeriod period) =>
                              setState(() => _period = period),
                          options: <DsSegment<TrendPeriod>>[
                            for (final TrendPeriod period in TrendPeriod.values)
                              DsSegment<TrendPeriod>(
                                value: period,
                                label: period.label,
                              ),
                          ],
                        ),
                        const SizedBox(height: Space.lg),
                        if (window.isEmpty)
                          _NothingInWindow(period: _period)
                        else ...<Widget>[
                          DsGrid(
                            minTileWidth: 170,
                            children: <Widget>[
                              DsMetricTile(
                                label: 'Average heart rate',
                                value: summary.hasHeartRate
                                    ? '${summary.averageBpm}'
                                    : '--',
                                unit: summary.hasHeartRate ? 'BPM' : null,
                                accent: heart,
                                icon: Icons.favorite_rounded,
                              ),
                              DsMetricTile(
                                label: 'Heart rate range',
                                value: summary.hasHeartRate
                                    ? '${summary.minimumBpm}–${summary.maximumBpm}'
                                    : '--',
                                unit: summary.hasHeartRate ? 'BPM' : null,
                                accent: heart,
                                icon: Icons.swap_vert_rounded,
                              ),
                              DsMetricTile(
                                label: 'Average oxygen',
                                value: summary.hasOxygen
                                    ? '${summary.averageSpO2}'
                                    : '--',
                                unit: summary.hasOxygen ? '%' : null,
                                accent: oxygen,
                                icon: Icons.air_rounded,
                              ),
                              DsMetricTile(
                                label: 'Readings in window',
                                value: '${summary.sampleCount}',
                                unit: summary.sampleCount == 1
                                    ? 'sample'
                                    : 'samples',
                                accent: theme.colorScheme.primary,
                                icon: Icons.dataset_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.xxl),
                          _PatternsCard(patterns: patterns),
                          const SizedBox(height: Space.xl),
                          _ChartCard(
                            title: 'Heart rate',
                            icon: Icons.favorite_rounded,
                            accent: heart,
                            unit: 'BPM',
                            points: heartPoints,
                            origin: origin,
                            rangeLabel: _rangeLabel(window),
                            emptyMessage:
                                'No stored sample in this window carried a heart '
                                'rate. The sensor needs skin contact; a loose '
                                'strap records nothing.',
                          ),
                          const SizedBox(height: Space.xl),
                          _ChartCard(
                            title: 'Oxygen saturation',
                            icon: Icons.air_rounded,
                            accent: oxygen,
                            unit: '%',
                            points: oxygenPoints,
                            origin: origin,
                            rangeLabel: _rangeLabel(window),
                            emptyMessage:
                                'No stored sample in this window carried an '
                                'oxygen reading.',
                          ),
                          if (latest != null) ...<Widget>[
                            const SizedBox(height: Space.xl),
                            _LatestReadingCard(sample: latest),
                          ],
                          if (days.isNotEmpty) ...<Widget>[
                            const SizedBox(height: Space.xl),
                            _DailyTable(days: days),
                          ],
                        ],
                      ],
                    ),
    );
  }
}

/// The most recent sample in [samples] that carried any interpretation.
WatchSample? _latestReading(List<WatchSample> samples) {
  for (var i = samples.length - 1; i >= 0; i--) {
    final WatchSample sample = samples[i];
    if (sample.hr > 0 || sample.spo2 > 0 || sample.hrv > 0) return sample;
  }
  return null;
}

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _dayLabel(DateTime time) => '${time.day} ${_monthNames[time.month - 1]}';

String _clockLabel(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String _rangeLabel(List<WatchSample> window) {
  if (window.isEmpty) return 'no stored samples';
  final DateTime first = window.first.at;
  final DateTime last = window.last.at;
  final bool sameDay = first.year == last.year &&
      first.month == last.month &&
      first.day == last.day;
  if (sameDay) {
    return '${_dayLabel(first)}, ${_clockLabel(first)} to ${_clockLabel(last)}';
  }
  return '${_dayLabel(first)} to ${_dayLabel(last)}';
}

/// A progress indicator with a caption, used while the history is opened.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xl),
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: Space.md),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// The history could not be opened.
class _UnreadableHistory extends StatelessWidget {
  const _UnreadableHistory({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: DsEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Stored history could not be read',
        message: 'The samples saved on this phone could not be opened '
            '($error). Nothing is drawn rather than guessing at the numbers.',
      ),
    );
  }
}

/// No samples have ever been stored.
class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    return const DsCard(
      child: DsEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'No watch history yet',
        message: 'This page charts samples the watch stores on this phone. '
            'Pair the watch and let its memory sync. Readings older than '
            '${VeyroProtocol.retainDays} days are deleted, so that is the '
            'longest window available.',
      ),
    );
  }
}

/// No samples fell inside the chosen window.
class _NothingInWindow extends StatelessWidget {
  const _NothingInWindow({required this.period});

  final TrendPeriod period;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: DsEmptyState(
        icon: Icons.date_range_outlined,
        title: 'Nothing in this window',
        message: 'No sample stored on this phone falls inside the '
            '${period.label.toLowerCase()} window. Choose a longer window, or '
            'sync the watch memory to fetch what it has recorded.',
      ),
    );
  }
}

/// The measured patterns in the current window, or an honest empty state.
///
/// Every number here is derived from [HealthPatternsService.analyze]; nothing
/// is a target, a score or a comparison with another person. A statement that
/// the samples cannot support is shown as `--` with the reason, never as a
/// plausible-looking default.
class _PatternsCard extends StatelessWidget {
  const _PatternsCard({required this.patterns});

  final HealthPatterns patterns;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.insights_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Patterns', style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'What the stored samples in this window can support. A pattern is '
            'shown only once there are enough measurements for it to mean '
            'something.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          if (!patterns.hasAnyReading)
            const DsEmptyState(
              icon: Icons.insights_outlined,
              title: 'No patterns in this window',
              message: 'None of the samples stored in this window carried a '
                  'heart rate or oxygen reading. Patterns appear only after '
                  'the watch stores measurements; nothing is inferred from an '
                  'empty window.',
            )
          else ...<Widget>[
            _PatternRow(
              label: 'Resting heart rate',
              value: patterns.hasRestingHeartRate
                  ? '${patterns.restingHeartRate} BPM'
                  : '--',
              detail: patterns.hasRestingHeartRate
                  ? 'Mean of the lowest quarter of '
                      '${patterns.heartRateSamples} measured readings across '
                      '${patterns.daysWithHeartRate} '
                      '${patterns.daysWithHeartRate == 1 ? 'day' : 'days'}.'
                  : 'Needs at least '
                      '${HealthPatternsService.minimumHeartRateSamples} measured '
                      'readings on '
                      '${HealthPatternsService.minimumDays} different days. This '
                      'window has ${patterns.heartRateSamples} on '
                      '${patterns.daysWithHeartRate} '
                      '${patterns.daysWithHeartRate == 1 ? 'day' : 'days'}.',
            ),
            Divider(color: theme.colorScheme.outlineVariant),
            _PatternRow(
              label: 'Heart rate direction',
              value: patterns.hasDirection
                  ? '${patterns.direction.label} '
                      '${_changeLabel(patterns.changeBpm)}'
                  : '--',
              detail: patterns.hasDirection
                  ? _directionDetail(patterns)
                  : 'Not enough measured readings to compare the first and '
                      'second halves of the window.',
            ),
            Divider(color: theme.colorScheme.outlineVariant),
            _PatternRow(
              label: 'Lowest oxygen',
              value: patterns.hasOxygen ? '${patterns.lowestOxygen}%' : '--',
              detail: patterns.hasOxygen
                  ? 'Lowest of ${patterns.oxygenSamples} measured oxygen '
                      '${patterns.oxygenSamples == 1 ? 'reading' : 'readings'}.'
                  : 'No sample in this window carried an oxygen reading.',
            ),
          ],
        ],
      ),
    );
  }

  static String _changeLabel(int changeBpm) {
    if (changeBpm > 0) return '(+$changeBpm BPM)';
    if (changeBpm < 0) return '($changeBpm BPM)';
    return '(no change)';
  }

  static String _directionDetail(HealthPatterns patterns) {
    final int change = patterns.changeBpm;
    if (change == 0) {
      return 'The later half averaged the same as the earlier half, within '
          '${HealthPatternsService.trendThresholdBpm} BPM.';
    }
    final String amount = change.abs().toString();
    if (change > 0) {
      return 'The later half averaged $amount BPM higher than the earlier '
          'half. A difference of at least '
          '${HealthPatternsService.trendThresholdBpm} BPM is called rising.';
    }
    return 'The later half averaged $amount BPM lower than the earlier half. '
        'A difference of at least '
        '${HealthPatternsService.trendThresholdBpm} BPM is called falling.';
  }
}

/// One statement in the Patterns card.
class _PatternRow extends StatelessWidget {
  const _PatternRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                value,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(detail, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A line chart drawn only from stored samples.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.unit,
    required this.points,
    required this.origin,
    required this.rangeLabel,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String unit;
  final List<TrendPoint> points;
  final DateTime origin;
  final String rangeLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
              if (points.isNotEmpty)
                DsLabel(
                  '${points.length} ${points.length == 1 ? 'point' : 'points'}',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (points.isEmpty)
            DsEmptyState(
              icon: Icons.timeline_rounded,
              title: 'No $title data in this window',
              message: emptyMessage,
            )
          else ...<Widget>[
            SizedBox(
              height: 180,
              child: LineChart(_data(theme)),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Stored readings from $rangeLabel. The line joins measurements '
              'in time order; it does not invent points where the watch '
              'recorded nothing.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _data(ThemeData theme) {
    final List<double> values =
        points.map((TrendPoint point) => point.value.toDouble()).toList();
    final double lowest = values.reduce(math.min);
    final double highest = values.reduce(math.max);
    final double padding = math.max(2, (highest - lowest) * 0.15);
    final double minY = math.max(0, lowest - padding);
    final double maxY = highest + padding;
    final double minX = points.first.minute;
    final double maxX =
        points.length == 1 ? minX + 1 : math.max(points.last.minute, minX + 1);
    // A time of day is ambiguous once the window runs over more than a day, so
    // a multi-day axis also names the day.
    final bool spansDays = maxX - minX > 24 * 60;

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: math.max(1, (maxY - minY) / 3),
        getDrawingHorizontalLine: (double value) => FlLine(
          color: theme.colorScheme.outlineVariant,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: math.max(1, (maxY - minY) / 3),
            getTitlesWidget: (double value, TitleMeta meta) => Text(
              value.round().toString(),
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: spansDays ? 30 : 24,
            interval: math.max(1, (maxX - minX) / 2),
            getTitlesWidget: (double value, TitleMeta meta) {
              final DateTime at = origin.add(Duration(minutes: value.round()));
              final String label = spansDays
                  ? '${_dayLabel(at)}\n${_clockLabel(at)}'
                  : _clockLabel(at);
              return Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          spots: <FlSpot>[
            for (final TrendPoint point in points)
              FlSpot(point.minute, point.value.toDouble()),
          ],
          isCurved: false,
          color: accent,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: accent.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

/// What the newest stored reading means, in the app's own words.
class _LatestReadingCard extends StatelessWidget {
  const _LatestReadingCard({required this.sample});

  final WatchSample sample;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Latest stored reading',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              DsLabel(
                '${_dayLabel(sample.at)} ${_clockLabel(sample.at)}',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (hasHeartRate(sample.hr))
            _Interpretation(
              label: 'Heart rate',
              value: '${sample.hr} BPM',
              status: interpretHeartRate(sample.hr),
              metric: 'heart rate',
            ),
          if (hasOxygen(sample.spo2))
            _Interpretation(
              label: 'Oxygen saturation',
              value: '${sample.spo2}%',
              status: interpretOxygen(sample.spo2),
              metric: 'oxygen saturation',
            ),
          if (sample.hrv > 0)
            Text(
              'Heart rate variability recorded in the same sample: '
              '${sample.hrv} ms.',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: Space.sm),
          Text(
            'These are screening cues based on the app\'s ranges, not a '
            'diagnosis. A clinician reading the same number may interpret it '
            'differently.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// A measured value with its band and the next step the app suggests.
class _Interpretation extends StatelessWidget {
  const _Interpretation({
    required this.label,
    required this.value,
    required this.status,
    required this.metric,
  });

  final String label;
  final String value;
  final HealthStatus status;
  final String metric;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? guidance = guidanceFor(status, metric);

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(label, style: theme.textTheme.titleSmall),
              Text(value, style: theme.textTheme.labelMedium),
              DsStatusPill(
                label: status.label,
                color: healthStatusColor(status, context),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            guidance ??
                'Inside the range this app treats as usual for $metric. That '
                    'describes the number, not a diagnosis.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// One row per recorded day, with the measured averages.
class _DailyTable extends StatelessWidget {
  const _DailyTable({required this.days});

  final List<DailyTrend> days;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('By day', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            'Mean of the samples stored on each day. Days with no stored '
            'samples do not appear, rather than appearing as zero.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          for (final DailyTrend day in days) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 72,
                    child: Text(
                      _dayLabel(day.day),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${day.sampleCount} '
                      '${day.sampleCount == 1 ? 'sample' : 'samples'}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      day.averageBpm > 0 ? '${day.averageBpm} BPM' : '--',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  SizedBox(
                    width: 40,
                    child: Text(
                      day.averageSpO2 > 0 ? '${day.averageSpO2}%' : '--',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            if (day != days.last)
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}
