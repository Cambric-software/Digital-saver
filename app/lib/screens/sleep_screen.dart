/// Overnight heart rate, and an estimated sleep window.
///
/// This screen previously presented sleep stages, a stage distribution donut, a
/// stage bar and a quality score out of 100. None of it was measured. The watch
/// reports no sleep data at all - there is no sleep field anywhere in the BLE
/// service - and the stages were inferred from heart rate alone:
///
///     if (s.hr == 0 || s.hr < 55) deepMin++;
///     else if (s.hr < 65) remMin++;
///     else lightMin++;
///
/// That mapping is not a simplification of sleep staging, it is wrong. Deep
/// sleep has low, steady heart rate; REM is characterised by *variable* heart
/// rate and often a faster one, not a middling one. There is no threshold on
/// heart rate that separates deep from REM, and presenting one as though there
/// were would show a person a physiologically backwards picture of their night.
/// The quality score built on top of those stages was arithmetic from invented
/// inputs, so it inherited the problem.
///
/// Worse, when no real samples existed the screen fell back to
/// `generateTypicalSleepData()` - fixed invented values - and demo mode defaulted
/// to *on*. So the default experience of opening this screen was a plausible
/// night's sleep that had never happened.
///
/// What is left here is what the watch actually knows:
///
///   * an overnight window inferred from a sustained period of low heart rate,
///     described as an estimate because that is what it is;
///   * the heart rate recorded across that window, which is real.
///
/// There are no stages and no score, because there is nothing to put in them.
/// Sleep staging needs either a mattress sensor, a wrist actigraphy validated
/// against polysomnography, or the wearer's own report. Adding them back should
/// wait until one of those exists.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_store.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import '../utils/health_interpretation.dart';
import 'package:cambric_design/cambric_design.dart';

/// A low-heart-rate period overnight.
class _RestPeriod {
  const _RestPeriod({
    required this.start,
    required this.end,
    required this.averageBpm,
    required this.lowestBpm,
    required this.sampleCount,
    required this.missingSamples,
  });

  final DateTime start;
  final DateTime end;
  final int averageBpm;
  final int lowestBpm;
  final int sampleCount;

  /// Samples with no heart rate in them, which are counted but not averaged.
  ///
  /// Averaging as though they were zero would drag the mean down and make the
  /// night look deeper than it was.
  final int missingSamples;

  Duration get length => end.difference(start);
}

/// Overnight heart rate and an estimated rest window.
class SleepScreen extends StatefulWidget {
  /// Create the screen.
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  _RestPeriod? _period;
  bool _loading = true;
  bool _demoEnabled = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Defaults to off. Showing invented data as a person's own night by default
      // is not a demonstration, it is misleading.
      final demo = prefs.getBool('demo_mode') ?? false;
      final samples = await LocalStore.loadAll();

      if (!mounted) return;
      setState(() {
        _demoEnabled = demo;
        _period = _findRestPeriod(samples);
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      // Without this the screen sat on its spinner forever when the stored
      // history could not be opened, which looks like a slow load rather than a
      // failure. The capture harness found it: every other history screen has a
      // catch, and this one did not.
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$error';
      });
    }
  }

  /// Finds the longest run of low heart rate overnight.
  ///
  /// This is a heart-rate observation, not sleep staging, and it is labelled as
  /// such wherever it is shown. The thresholds are deliberately conservative:
  /// calling a quiet evening "rest" is harmless, whereas labelling a restless
  /// hour as sleep would not be.
  _RestPeriod? _findRestPeriod(List<WatchSample> samples) {
    if (samples.isEmpty) return null;

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(hours: 20));
    final recent = samples
        .where((WatchSample s) => s.at.isAfter(windowStart))
        .toList()
      ..sort((WatchSample a, WatchSample b) => a.unix.compareTo(b.unix));

    // Overnight only: 20:00 to midday.
    final overnight = recent
        .where((WatchSample s) => s.at.hour >= 20 || s.at.hour < 12)
        .toList();
    if (overnight.length < 3) return null;

    _RestPeriod? best;
    DateTime? runStart;
    var sum = 0;
    var low = 0;
    var counted = 0;
    var missing = 0;

    void closeRun(DateTime at) {
      if (runStart == null) return;
      if (counted >= 3) {
        final candidate = _RestPeriod(
          start: runStart!,
          end: at,
          averageBpm: (sum / counted).round(),
          lowestBpm: low,
          sampleCount: counted,
          missingSamples: missing,
        );
        // `best` is captured by the closure below, so Dart cannot promote it from
        // nullable. The null check in the same condition already guarantees it
        // is set by the time the right-hand side runs.
        if (best == null || candidate.length > best!.length) {
          best = candidate;
        }
      }
      runStart = null;
      sum = 0;
      low = 0;
      counted = 0;
      missing = 0;
    }

    for (final sample in overnight) {
      // A resting heart rate. 75 rather than 60 so an evening spent reading is
      // not captured as a rest period.
      final resting = sample.hr == 0 || sample.hr < 75;

      if (resting) {
        runStart ??= sample.at;
        if (sample.hr > 0) {
          sum += sample.hr;
          counted++;
          low = low == 0 ? sample.hr : (sample.hr < low ? sample.hr : low);
        } else {
          missing++;
        }
      } else {
        closeRun(sample.at);
      }
    }
    closeRun(overnight.last.at);

    return best;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final period = _period;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_loadError != null)
          _UnreadableHistory(error: _loadError!)
        else if (period == null)
          const _NothingRecorded()
        else ...<Widget>[
          _WindowCard(period: period),
          const SizedBox(height: Space.lg),
          _OvernightCard(period: period),
          const SizedBox(height: Space.lg),
          const _AboutStaging(),
        ],
        if (_demoEnabled) ...<Widget>[
          const SizedBox(height: Space.lg),
          const _DemoNotice(),
        ],
      ],
    );
  }
}

/// The estimated overnight window.
class _WindowCard extends StatelessWidget {
  const _WindowCard({required this.period});

  final _RestPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.of(
      AppColors.sleepPurple,
      AppColors.darkSleep,
      context,
    );

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bedtime_rounded, color: accent, size: 20),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'Overnight low activity',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              DsStatusPill(
                label: 'Estimated',
                color: theme.colorScheme.outline,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(_formatDuration(period.length), style: Type.metric.copyWith(color: accent)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            '${_formatTime(period.start)} to ${_formatTime(period.end)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          Text(
            'This is the longest stretch overnight when your heart rate stayed '
            'low. It is a window, not a measurement of sleep.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Heart rate across that window.
class _OvernightCard extends StatelessWidget {
  const _OvernightCard({required this.period});

  final _RestPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = interpretHeartRate(period.averageBpm);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Heart rate overnight', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.lg),
          DsGrid(
            minTileWidth: 120,
            children: <Widget>[
              _Stat(
                label: 'Average',
                value: '${period.averageBpm}',
                unit: 'BPM',
              ),
              _Stat(
                label: 'Lowest',
                value: '${period.lowestBpm}',
                unit: 'BPM',
              ),
              _Stat(
                label: 'Readings',
                value: '${period.sampleCount}',
                unit: period.sampleCount == 1 ? 'sample' : 'samples',
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (period.missingSamples > 0) ...<Widget>[
            Text(
              '${period.missingSamples} further ${period.missingSamples == 1 ? 'reading' : 'readings'} '
              'in this window had no heart rate recorded and were left out of '
              'the average rather than counted as zero.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Space.sm),
          ],
          Row(
            children: <Widget>[
              DsStatusPill(
                label: status.label,
                color: healthStatusColor(status, context),
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DsLabel(label),
        const SizedBox(height: Space.xxs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(value, style: Type.metricSmall),
            const SizedBox(width: Space.xxs),
            Text(unit, style: theme.textTheme.labelMedium),
          ],
        ),
      ],
    );
  }
}

/// Says plainly that stages are not available, and why.
class _AboutStaging extends StatelessWidget {
  const _AboutStaging();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DsCard(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'Sleep stages are not available',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            'This watch does not measure sleep stages. Deep, light and REM '
            'sleep cannot be told apart from heart rate, so no stages are '
            'shown here rather than guessed at.\n\n'
            'Stages need a mattress sensor, or wrist movement measured and '
            'validated against a sleep study. Until one of those is available, '
            'a stage breakdown would be invented rather than measured.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// No recordings at all.
class _NothingRecorded extends StatelessWidget {
  const _NothingRecorded();

  @override
  Widget build(BuildContext context) {
    return const DsCard(
      child: DsEmptyState(
        icon: Icons.bedtime_outlined,
        title: 'No overnight data yet',
        message: 'Wear the watch overnight with it in contact with your skin. '
            'Readings taken between 8pm and midday are used to find a low '
            'activity window.',
      ),
    );
  }
}

/// The stored history could not be opened.
class _UnreadableHistory extends StatelessWidget {
  const _UnreadableHistory({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: DsEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Stored history could not be read',
        message: 'The overnight samples saved on this phone could not be '
            'opened ($error). Nothing is estimated or invented in their place.',
      ),
    );
  }
}

/// Makes it unambiguous that simulated figures are present.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = AppColors.of(AppColors.warning, AppColors.darkWarning, context);

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.science_outlined, size: 18, color: warning),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'Demo mode is on, so some figures on other screens are '
              'simulated rather than measured.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

String _formatTime(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'am' : 'pm'}';
}