/// The Today screen.
///
/// Rebuilt from scratch. The previous dashboard was a 30 KB file that mixed
/// layout, formatting, colour choice, threshold logic and data fetching in one
/// place, so the same number was interpreted differently in different parts of
/// the screen and there was no way to test any of it.
///
/// What is here now:
///   * every reading gets an explicit [HealthStatus] from one place, so a value
///     cannot read as "fine" in one tile and "critical" in another;
///   * a reading of 0 means no data and is shown as such, never as a number;
///   * the layout is built from the shared components, so light and dark are
///     handled once rather than per screen;
///   * there is no connection state to guess at - the shell already shows it,
///     and this screen reacts by saying what is missing.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/health_models.dart';
import '../services/ble_service.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/ds_widgets.dart';

/// Live overview of the current day.
class DashboardScreen extends StatelessWidget {
  /// Create the dashboard.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= Breakpoints.expanded
        ? 4
        : width >= Breakpoints.medium
            ? 2
            : 1;

    return DsPage(
      title: 'Today',
      actions: <Widget>[
        IconButton(
          tooltip: ble.demoMode ? 'Showing sample data' : 'Live readings',
          onPressed: () {},
          icon: Icon(
            ble.demoMode ? Icons.science_outlined : Icons.sensors_rounded,
            color: ble.demoMode ? AppColors.warning : null,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!ble.isConnected)
            const _DisconnectedNotice()
          else
            _ConnectedBanner(batteryLevel: ble.batteryLevel),
          const SizedBox(height: Space.xl),
          DsSection(
            title: 'Vitals',
            subtitle: 'Live from your watch',
            child: _VitalsGrid(ble: ble, columns: columns),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Activity',
            subtitle: 'Today so far',
            child: _ActivityPanel(activity: ble.activity),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Recovery',
            subtitle: 'Signals worth knowing about',
            child: _RecoveryPanel(ble: ble),
          ),
        ],
      ),
    );
  }
}

/// Everything is unavailable until a watch connects.
class _DisconnectedNotice extends StatelessWidget {
  const _DisconnectedNotice();

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_disabled_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'No watch connected',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Open the Watch tab to pair, then readings will appear here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedBanner extends StatelessWidget {
  const _ConnectedBanner({required this.batteryLevel});

  final int batteryLevel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = batteryLevel > 0 && batteryLevel < 20;
    final color = low ? AppColors.warning : scheme.secondary;

    return Row(
      children: <Widget>[
        DsStatusPill(
          label: low ? 'Watch battery low' : 'Watch connected',
          icon: low ? Icons.battery_alert_rounded : Icons.bluetooth_connected_rounded,
          color: color,
        ),
        const SizedBox(width: Space.md),
        if (batteryLevel > 0)
          Text('$batteryLevel%', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({required this.ble, required this.columns});

  final BleService ble;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      DsMetricTile(
        label: 'Heart rate',
        value: ble.heartRate.bpm > 0 ? '${ble.heartRate.bpm}' : '--',
        unit: ble.heartRate.bpm > 0 ? 'BPM' : null,
        accent: _heart(context),
        status: _heartStatus(ble.heartRate),
        icon: Icons.favorite_rounded,
      ),
      DsMetricTile(
        label: 'Blood pressure',
        value: _bloodPressureValue(ble.bloodPressure),
        unit: ble.bloodPressure.systolic > 0 ? 'mmHg' : null,
        accent: _bp(context),
        status: _bloodPressureStatus(ble.bloodPressure),
        icon: Icons.bloodtype_outlined,
      ),
      DsMetricTile(
        label: 'Oxygen',
        value: ble.oxygen.spO2 > 0 ? '${ble.oxygen.spO2}' : '--',
        unit: ble.oxygen.spO2 > 0 ? '%' : null,
        accent: _oxy(context),
        status: _oxygenStatus(ble.oxygen),
        icon: Icons.air_rounded,
      ),
      DsMetricTile(
        label: 'Heart rhythm',
        value: ble.heartRate.afibProbability > 0
            ? '${ble.heartRate.afibProbability}%'
            : '--',
        accent: _heart(context),
        status: _afibStatus(ble.heartRate),
        icon: Icons.monitor_heart_outlined,
      ),
    ];

    return _Grid(columns: columns, children: tiles);
  }

  static Color _heart(BuildContext c) =>
      AppColors.of(AppColors.heartRed, AppColors.darkHeart, c);
  static Color _bp(BuildContext c) =>
      AppColors.of(AppColors.bpBlue, AppColors.darkBp, c);
  static Color _oxy(BuildContext c) =>
      AppColors.of(AppColors.oxyGreen, AppColors.darkOxy, c);
}

/// A simple responsive grid, because GridView cannot size to its content inside
/// a scrolling page.
class _Grid extends StatelessWidget {
  const _Grid({required this.children, required this.columns});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: Space.md),
            children[i],
          ],
        ],
      );
    }
    return Wrap(
      spacing: Space.md,
      runSpacing: Space.md,
      children: <Widget>[
        for (final child in children)
          SizedBox(
            width: _childWidth(context, columns),
            child: child,
          ),
      ],
    );
  }

  double _childWidth(BuildContext context, int columns) {
    final available = MediaQuery.sizeOf(context).width;
    // DsPage caps content and pads it, so the usable width is derived rather
    // than measured, which keeps this cheap inside a scrolling page.
    final usable = available < Breakpoints.compact
        ? available - Space.lg * 2
        : available - Space.xl * 2;
    final capped = usable > 1180 ? 1180.0 : usable;
    return (capped - Space.md * (columns - 1)) / columns;
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.activity});

  final ActivityData activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = activity.steps > 0;

    return DsCard(
      child: hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Progress(
                        label: 'Steps',
                        value: activity.steps,
                        goal: 10000,
                        unit: '',
                        color: AppColors.of(
                            AppColors.stepAmber, AppColors.darkStep, context),
                      ),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: _Progress(
                        label: 'Active minutes',
                        value: activity.activeMinutes,
                        goal: 60,
                        unit: '',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MiniStat(
                        label: 'Calories',
                        value: '${activity.calories.round()}',
                        unit: 'kcal',
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Distance',
                        value: activity.distanceKm.toStringAsFixed(2),
                        unit: 'km',
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const DsEmptyState(
              icon: Icons.directions_walk_rounded,
              title: 'No activity yet',
              message:
                  'Steps, distance and active minutes appear once the watch '
                  'reports them for today.',
            ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    final reached = value >= goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: Text(
                value.toString(),
                style: Type.metricSmall.copyWith(color: theme.colorScheme.onSurface),
              ),
            ),
            Text(
              ' / $goal',
              style: theme.textTheme.labelMedium,
            ),
            if (reached) ...<Widget>[
              const SizedBox(width: Space.xs),
              Icon(Icons.check_circle_rounded, size: 16, color: color),
            ],
          ],
        ),
        const SizedBox(height: Space.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              value,
              style: Type.metricSmall.copyWith(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(width: Space.xxs),
            Text(unit, style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: Space.xxs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({required this.ble});

  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final hr = ble.heartRate;
    final hasData = hr.bpm > 0;
    final hrvLow = hasData && hr.hrv > 0 && hr.hrv < 20;

    return DsCard(
      child: hasData
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _MiniStat(
                    label: 'HRV (RMSSD)',
                    value: hr.hrv > 0 ? '${hr.hrv}' : '--',
                    unit: 'ms',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Confidence',
                    value: '${hr.confidence}',
                    unit: '%',
                  ),
                ),
                if (hrvLow)
                  Expanded(
                    child: DsStatusPill(
                      label: 'Recovery may be low',
                      icon: HealthStatus.elevated.icon,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
              ],
            )
          : const DsEmptyState(
              icon: Icons.bedtime_outlined,
              title: 'Nothing to interpret yet',
              message:
                  'Recovery signals need a few minutes of connected data '
                  'before they mean anything.',
            ),
    );
  }
}

// ── Interpretation ─────────────────────────────────────────────────────
// Thresholds live here, once. They were previously duplicated across the
// dashboard and the detail screens, which is how the same reading came to
// look healthy in one place and alarming in another.
//
// These are screening cues, not diagnoses. Anything that suggests a problem
// is phrased as "worth checking", never as a conclusion.

String _bloodPressureValue(BloodPressureData bp) {
  if (bp.systolic <= 0 || bp.diastolic <= 0) return '--';
  return '${bp.systolic}/${bp.diastolic}';
}

HealthStatus _heartStatus(HeartRateData hr) {
  if (hr.bpm <= 0) return HealthStatus.unknown;
  if (hr.bpm < 40 || hr.bpm > 180) return HealthStatus.critical;
  if (hr.bpm < 50 || hr.bpm > 120) return HealthStatus.high;
  if (hr.bpm > 100) return HealthStatus.elevated;
  return HealthStatus.normal;
}

HealthStatus _bloodPressureStatus(BloodPressureData bp) {
  if (bp.systolic <= 0 || bp.diastolic <= 0) return HealthStatus.unknown;
  if (bp.systolic >= 180 || bp.diastolic >= 120) return HealthStatus.critical;
  if (bp.systolic >= 140 || bp.diastolic >= 90) return HealthStatus.high;
  if (bp.systolic >= 130 || bp.diastolic >= 85) return HealthStatus.elevated;
  return HealthStatus.normal;
}

HealthStatus _oxygenStatus(OxygenData o2) {
  if (o2.spO2 <= 0) return HealthStatus.unknown;
  if (o2.spO2 < 90) return HealthStatus.critical;
  if (o2.spO2 < 94) return HealthStatus.high;
  if (o2.spO2 < 95) return HealthStatus.elevated;
  return HealthStatus.normal;
}

HealthStatus _afibStatus(HeartRateData hr) {
  if (hr.afibProbability <= 0) return HealthStatus.unknown;
  if (hr.afibProbability >= 60) return HealthStatus.high;
  if (hr.afibProbability >= 25) return HealthStatus.elevated;
  return HealthStatus.normal;
}