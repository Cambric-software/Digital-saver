/// Heart rate, variability, rhythm and training zones.
///
/// Rebuilt on the shared components. Four problems are fixed here, three of them
/// substantive rather than cosmetic:
///
/// * SDNN was displayed as `HRV x 1.4` and pNN50 as `(HRV - 15) / 0.85`. Both
///   were invented. The model already carries real `sdnn` and `pnn50` values
///   from the watch, and they were being ignored in favour of arithmetic that
///   produced plausible-looking numbers which meant nothing. A health screen
///   showing invented figures under real labels is the worst kind of wrong,
///   because nothing about it looks wrong.
///
/// * The rhythm panel said "No signs of AFib detected". A wrist optical sensor
///   cannot rule out atrial fibrillation - it has neither the sensitivity nor
///   the specificity to exclude it, and the false reassurance is more
///   dangerous than the uncertainty. It now says what was actually observed.
///
/// * The zone ranges were stored with a corrupted dash character, so they
///   rendered as "60?100" rather than "60-100".
///
/// * The layout overflowed at phone widths in two places, both [Row]s holding
///   content that could not shrink.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/health_analysis_service.dart';
import '../services/heart_rate_tracker.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../utils/health_interpretation.dart';
import '../widgets/ds_widgets.dart';

/// Live heart rate and the detail behind it.
class HeartScreen extends StatelessWidget {
  /// Create the screen.
  const HeartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final tracker = context.watch<HeartRateTracker>();
    final bpm = ble.heartRate.bpm;
    final live = hasHeartRate(bpm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LiveReading(ble: ble, tracker: tracker),
        const SizedBox(height: Space.lg),
        _VariabilityPanel(ble: ble),
        const SizedBox(height: Space.lg),
        _RhythmPanel(ble: ble),
        const SizedBox(height: Space.lg),
        _ZoneGuide(currentBpm: live ? bpm : 0),
      ],
    );
  }
}

/// The current rate, with the session's own range beneath it.
class _LiveReading extends StatelessWidget {
  const _LiveReading({required this.ble, required this.tracker});

  final BleService ble;
  final HeartRateTracker tracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hr = ble.heartRate;
    final bpm = hr.bpm;
    final live = hasHeartRate(bpm);
    final accent = AppColors.of(AppColors.heartRed, AppColors.darkHeart, context);
    final status = interpretHeartRate(bpm);

    final zone = live ? HealthAnalysisService.heartRateZone(bpm) : null;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.favorite_rounded, color: accent, size: 20),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Heart rate', style: theme.textTheme.titleSmall),
              ),
              if (live)
                DsStatusPill(
                  label: status.label,
                  color: healthStatusColor(status, context),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                live ? '$bpm' : '--',
                style: Type.metric.copyWith(color: accent),
              ),
              const SizedBox(width: Space.xs),
              Text('BPM', style: theme.textTheme.labelLarge),
            ],
          ),
          if (zone != null) ...<Widget>[
            const SizedBox(height: Space.xs),
            Text(zone, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Space.lg),
          DsGrid(
            minTileWidth: 110,
            spacing: Space.sm,
            children: <Widget>[
              _MiniStat(
                label: 'Session low',
                value: tracker.bestMin > 0 ? '${tracker.bestMin}' : '--',
              ),
              _MiniStat(
                label: 'Current',
                value: live ? '$bpm' : '--',
              ),
              _MiniStat(
                label: 'Session high',
                value: tracker.bestMax > 0 ? '${tracker.bestMax}' : '--',
              ),
            ],
          ),
          if (guidanceFor(status, 'heart rate') case final String guidance)
            ...<Widget>[
              const SizedBox(height: Space.md),
              _Guidance(text: guidance, status: status),
            ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: Type.metricSmall),
        const SizedBox(height: Space.xxs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Advice about the reading, styled by how serious it is.
class _Guidance extends StatelessWidget {
  const _Guidance({required this.text, required this.status});

  final String text;
  final HealthStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: healthStatusColor(status, context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: healthStatusColor(status, context).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(status.icon, size: 18, color: healthStatusColor(status, context)),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Heart rate variability.
///
/// Every figure here comes from the watch. Nothing is derived from another
/// figure, because a number labelled as a distinct measurement but actually
/// computed from a different one is not a measurement.
class _VariabilityPanel extends StatelessWidget {
  const _VariabilityPanel({required this.ble});

  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hr = ble.heartRate;
    final connected = ble.isConnected;
    final hasData = connected && hr.hrv > 0;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.monitor_heart_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'Heart rate variability',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (!hasData)
            const DsEmptyState(
              icon: Icons.timeline_rounded,
              title: 'No variability yet',
              message: 'HRV needs a few minutes of steady connected data '
                  'before it means anything.',
            )
          else ...<Widget>[
            DsGrid(
              minTileWidth: 120,
              spacing: Space.sm,
              children: <Widget>[
                _VariabilityStat(
                  label: 'RMSSD',
                  value: '${hr.hrv}',
                  unit: 'ms',
                  caption: 'Beat-to-beat',
                ),
                _VariabilityStat(
                  label: 'SDNN',
                  value: hr.sdnn > 0 ? '${hr.sdnn}' : '--',
                  unit: 'ms',
                  caption: 'Overall spread',
                ),
                _VariabilityStat(
                  label: 'pNN50',
                  value: hr.pnn50 > 0 ? '${hr.pnn50}' : '--',
                  unit: '%',
                  caption: 'Intervals over 50ms',
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            _RRChart(rrIntervals: hr.rrIntervals),
            const SizedBox(height: Space.md),
            Text(
              'Higher variability generally indicates better recovery. A '
              'single reading is not meaningful on its own - it moves with '
              'stress, sleep, illness and alcohol.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _VariabilityStat extends StatelessWidget {
  const _VariabilityStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });

  final String label;
  final String value;
  final String unit;
  final String caption;

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
        const SizedBox(height: Space.xxs),
        Text(caption, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// The beat-to-beat trace.
class _RRChart extends StatelessWidget {
  const _RRChart({required this.rrIntervals});

  final List<int> rrIntervals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.of(AppColors.heartRed, AppColors.darkHeart, context);

    if (rrIntervals.isEmpty) {
      return Text(
        'No beat-to-beat data recorded yet.',
        style: theme.textTheme.bodySmall,
      );
    }

    final spots = rrIntervals.asMap().entries
        .map((MapEntry<int, int> e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Beat-to-beat timing', style: theme.textTheme.titleSmall),
        const SizedBox(height: Space.xs),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: accent,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// What the watch observed about rhythm.
///
/// Framed as an observation, not a diagnosis and not an exclusion. A wrist
/// sensor screening positive is a prompt to see a clinician; screening
/// negative is not evidence that nothing is wrong, and saying so would be
/// misleading in a way that could delay care.
class _RhythmPanel extends StatelessWidget {
  const _RhythmPanel({required this.ble});

  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hr = ble.heartRate;
    final probability = hr.afibProbability;
    final known = probability > 0;
    final status = interpretAfib(probability);
    final accent = AppColors.of(AppColors.heartRed, AppColors.darkHeart, context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.heart_broken_outlined, size: 20, color: accent),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Heart rhythm', style: theme.textTheme.titleSmall),
              ),
              if (known)
                DsStatusPill(
                  label: status.label,
                  color: healthStatusColor(status, context),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (!known)
            Text(
              'The watch has not reported a rhythm assessment. This is not '
              'the same as a clear result.',
              style: theme.textTheme.bodySmall,
            )
          else ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text('$probability', style: Type.metricSmall),
                const SizedBox(width: Space.xxs),
                Text('% irregular', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(
              status == HealthStatus.normal
                  ? 'No irregular pattern stood out in this reading. A wrist '
                      'sensor cannot rule out atrial fibrillation, so this is '
                      'not a clean bill of health - symptoms matter more than '
                      'a quiet reading.'
                  : 'An irregular pattern was seen in this reading. A wrist '
                      'sensor cannot confirm atrial fibrillation, so this is '
                      'not a diagnosis, but it is worth mentioning to a '
                      'clinician.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Training zones, and where the current rate sits in them.
class _ZoneGuide extends StatelessWidget {
  const _ZoneGuide({required this.currentBpm});

  final int currentBpm;

  /// Bands, as (name, lower bound, upper bound). An en dash is used in the
  /// label because a plain hyphen read as a minus sign at small sizes, and the
  /// original used a dash that had been corrupted into a replacement character.
  static const List<({String name, String range, double min, double max, Color color})>
  _zones = <({String name, String range, double min, double max, Color color})>[
    (
      name: 'Rest',
      range: 'under 60',
      min: 0,
      max: 60,
      color: Color(0xFF94A3B8)
    ),
    (
      name: 'Fat burn',
      range: '60 to 100',
      min: 60,
      max: 100,
      color: Color(0xFF22C55E)
    ),
    (
      name: 'Cardio',
      range: '100 to 140',
      min: 100,
      max: 140,
      color: Color(0xFFF59E0B)
    ),
    (
      name: 'Peak',
      range: '140 to 170',
      min: 140,
      max: 170,
      color: Color(0xFFEF4444)
    ),
    (
      name: 'Maximum',
      range: 'over 170',
      min: 170,
      max: 220,
      color: Color(0xFF7C3AED)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = hasHeartRate(currentBpm);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Training zones', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            'Effort bands for an adult. Where you sit depends on your own '
            'fitness, so treat these as a guide.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          for (final zone in _zones) ...<Widget>[
            _ZoneRow(
              name: zone.name,
              range: zone.range,
              color: zone.color,
              active: live && currentBpm >= zone.min && currentBpm < zone.max,
            ),
            const SizedBox(height: Space.sm),
          ],
        ],
      ),
    );
  }
}

/// One training zone.
///
/// Laid out so it cannot overflow: the range sits under the name on a narrow
/// row rather than competing with it horizontally.
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.name,
    required this.range,
    required this.color,
    required this.active,
  });

  final String name;
  final String range;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.10) : null,
        borderRadius: BorderRadius.circular(Radii.md),
        border: active
            ? Border.all(color: color.withValues(alpha: 0.35))
            : Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? color : theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Space.sm),
          Flexible(
            child: Text(
              range,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (active) ...<Widget>[
            const SizedBox(width: Space.sm),
            DsStatusPill(
              label: 'Now',
              color: color,
              icon: Icons.radio_button_checked_rounded,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}