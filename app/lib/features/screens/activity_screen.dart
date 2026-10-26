/// Steps, distance, calories and fall detection.
///
/// Rebuilt on the shared components. Three things are fixed here:
///
/// * Distance was shown as `steps x 0.762 / 1000` and active minutes as
///   `steps / 1200`. Both were arithmetic standing in for fields the watch
///   actually reports - `distanceKm` and `activeMinutes` are right there in the
///   model, unused. A step-to-distance constant is a guess that is wrong for
///   most people by a wide margin, since stride length varies with height, and
///   it was being presented as a measurement.
///
/// * The fall banner contained a corrupted emoji that rendered as mojibake.
///
/// * The screen carried its own Scaffold and AppBar inside a shell that
///   already supplies both.
///
/// The hourly chart previously hid every bar after the current hour by passing
/// 0 rather than leaving the space empty. A bar that has not happened yet and a
/// bar that recorded no steps look identical, which misreads the day.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ble_service.dart';
import 'package:cambric_design/cambric_design.dart';

/// The daily step goal. A configurable target would be better; this is the
/// commonly used adult default and it is stated rather than implied.
const int kDailyStepGoal = 10000;
const int kDailyCalorieGoal = 600;
const int kDailyActiveMinuteGoal = 60;

/// Steps, distance and calories for today.
class ActivityScreen extends StatelessWidget {
  /// Create the screen.
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final activity = ble.activity;
    // A disconnected watch has reported nothing. Treating that as zero steps
    // would show a day of inactivity that never happened.
    final live = ble.isConnected && activity.steps > 0;
    final accent = AppColors.of(AppColors.stepAmber, AppColors.darkStep, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.directions_walk_rounded,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text('Steps', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  if (live)
                    DsStatusPill(
                      label: '${(activity.steps / kDailyStepGoal * 100).round()}% of goal',
                      color: accent,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    live ? '${activity.steps}' : '--',
                    style: Type.metric.copyWith(color: accent),
                  ),
                  const SizedBox(width: Space.xs),
                  Text(
                    'of $kDailyStepGoal',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              _GoalBar(
                value: activity.steps.toDouble(),
                goal: kDailyStepGoal.toDouble(),
                color: accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        _MetricSummary(ble: ble, live: live),
        const SizedBox(height: Space.lg),
        _HourlyChart(hourlySteps: activity.hourlySteps, live: live),
        const SizedBox(height: Space.lg),
        _GoalSummary(ble: ble, live: live),
        const SizedBox(height: Space.lg),
        const _FallStatus(),
      ],
    );
  }
}

/// A labelled progress bar that cannot overflow.
class _GoalBar extends StatelessWidget {
  const _GoalBar({
    required this.value,
    required this.goal,
    required this.color,
    this.showLabel = true,
  });

  final double value;
  final double goal;
  final Color color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showLabel) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${value.round()} of ${goal.round()}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (value >= goal)
                Icon(Icons.check_circle_rounded, size: 16, color: color),
            ],
          ),
          const SizedBox(height: Space.xs),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Distance, calories and active minutes.
///
/// Every figure is reported by the watch. None is derived from the step count.
class _MetricSummary extends StatelessWidget {
  const _MetricSummary({required this.ble, required this.live});

  final BleService ble;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final activity = ble.activity;
    final theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Today so far', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.md),
          DsGrid(
            minTileWidth: 130,
            children: <Widget>[
              DsMetricTile(
                label: 'Distance',
                value: live && activity.distanceKm > 0
                    ? activity.distanceKm.toStringAsFixed(2)
                    : '--',
                unit: live && activity.distanceKm > 0 ? 'km' : null,
                accent: theme.colorScheme.primary,
                icon: Icons.straighten_rounded,
              ),
              DsMetricTile(
                label: 'Calories',
                value: live && activity.calories > 0
                    ? '${activity.calories.round()}'
                    : '--',
                unit: live && activity.calories > 0 ? 'kcal' : null,
                accent: AppColors.of(
                  AppColors.heartRed,
                  AppColors.darkHeart,
                  context,
                ),
                icon: Icons.local_fire_department_rounded,
              ),
              DsMetricTile(
                label: 'Active minutes',
                value: live && activity.activeMinutes > 0
                    ? '${activity.activeMinutes}'
                    : '--',
                unit: live && activity.activeMinutes > 0 ? 'min' : null,
                accent: AppColors.of(
                  AppColors.success,
                  AppColors.darkSuccess,
                  context,
                ),
                icon: Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Steps by hour of the day.
class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.hourlySteps, required this.live});

  final List<int> hourlySteps;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.of(AppColors.stepAmber, AppColors.darkStep, context);

    if (!live) {
      return DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Steps by hour', style: theme.textTheme.titleSmall),
            const SizedBox(height: Space.md),
            const DsEmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'No hourly data yet',
              message: 'The watch reports steps as the day goes on.',
            ),
          ],
        ),
      );
    }

    final now = DateTime.now().hour;
    final values = List<int>.generate(
      24,
      (int i) => i < hourlySteps.length ? hourlySteps[i] : 0,
    );

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Steps by hour', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            'Darker bars are hours that have happened. Hours still to come are '
            'left empty rather than shown as zero, because no steps recorded yet '
            'is not the same as no steps taken.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                barGroups: <BarChartGroupData>[
                  for (int i = 0; i < 24; i++)
                    BarChartGroupData(
                      x: i,
                      // A future hour gets no rod at all. Passing a rod with a
                      // value of zero would draw a stub, and a stub is
                      // indistinguishable from an hour that genuinely recorded
                      // no steps.
                      barRods: i <= now
                          ? <BarChartRodData>[
                              BarChartRodData(
                                toY: values[i].toDouble(),
                                color: i == now
                                    ? accent
                                    : accent.withValues(alpha: 0.35),
                                width: 8,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ]
                          : const <BarChartRodData>[],
                    ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final hour = value.toInt();
                        if (hour % 6 != 0) return const SizedBox.shrink();
                        const labels = <int, String>{
                          0: '12a',
                          6: '6a',
                          12: '12p',
                          18: '6p',
                        };
                        return Text(
                          labels[hour] ?? '',
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress against each daily goal.
class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.ble, required this.live});

  final BleService ble;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final activity = ble.activity;
    final theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Daily goals', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            'Common adult targets. They are not derived from your age, weight '
            'or fitness, so treat them as a starting point rather than a target '
            'someone has set for you.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.lg),
          _GoalRow(
            label: 'Steps',
            value: live ? activity.steps.toDouble() : 0,
            goal: kDailyStepGoal.toDouble(),
            unit: 'steps',
            color: AppColors.of(AppColors.stepAmber, AppColors.darkStep, context),
          ),
          const SizedBox(height: Space.lg),
          _GoalRow(
            label: 'Calories',
            value: live ? activity.calories : 0,
            goal: kDailyCalorieGoal.toDouble(),
            unit: 'kcal',
            color: AppColors.of(AppColors.heartRed, AppColors.darkHeart, context),
          ),
          const SizedBox(height: Space.lg),
          _GoalRow(
            label: 'Active minutes',
            value: live ? activity.activeMinutes.toDouble() : 0,
            goal: kDailyActiveMinuteGoal.toDouble(),
            unit: 'min',
            color: AppColors.of(AppColors.success, AppColors.darkSuccess, context),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Space.sm),
            Flexible(
              child: Text(
                '${value.round()} / ${goal.round()} $unit',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        _GoalBar(
          value: value,
          goal: goal,
          color: color,
          showLabel: false,
        ),
      ],
    );
  }
}

/// Whether a fall has been detected.
///
/// A wrist accelerometer will fire on dropping the phone, tripping, or a firm
/// knock against a doorframe. So the wording asks rather than declares, and it
/// tells the person to check on themselves first - the commonest and most
/// dangerous failure with this kind of alert is treating it as certain.
class _FallStatus extends StatelessWidget {
  const _FallStatus();

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final accel = ble.accel;
    final detected = ble.isConnected && accel.fallDetected;
    final theme = Theme.of(context);

    final color = detected
        ? AppColors.of(AppColors.danger, AppColors.darkDanger, context)
        : AppColors.of(AppColors.success, AppColors.darkSuccess, context);

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            detected ? Icons.warning_rounded : Icons.shield_outlined,
            color: color,
            size: 24,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  detected ? 'Possible fall detected' : 'Fall detection active',
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  detected
                      ? 'The watch felt a sharp impact. Check on yourself '
                          'first - this triggers when you drop the watch or '
                          'knock it against something as easily as a real fall.'
                          ' If you are hurt, contact someone or emergency '
                          'services.'
                      : 'Monitoring with the 6-axis accelerometer (MPU6050). '
                          'Nothing detected.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}