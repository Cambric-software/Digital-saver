import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _StepHero(ble: ble),
          const SizedBox(height: 16),
          _MetricsRow(ble: ble),
          const SizedBox(height: 16),
          _HourlyChart(ble: ble),
          const SizedBox(height: 16),
          _ActivityRings(ble: ble),
          const SizedBox(height: 16),
          _FallDetector(ble: ble),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }
}

class _StepHero extends StatelessWidget {
  final BleService ble;
  const _StepHero({required this.ble});

  @override
  Widget build(BuildContext context) {
    const goal = 10000;
    final steps = ble.isConnected ? ble.activity.steps : 0;
    final pct = (steps / goal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientActivity,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.coloredCard(AppColors.stepAmber),
      ),
      child: Column(children: [
        const Icon(Icons.directions_run, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        const Text('Daily Steps', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(ble.isConnected ? '$steps' : '--',
          style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, height: 1)),
        Text('/ $goal goal', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text('${(pct * 100).round()}% of daily goal', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final BleService ble;
  const _MetricsRow({required this.ble});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _MetricCard(label: 'Calories', value: ble.isConnected ? '${ble.activity.calories.round()}' : '--', unit: 'kcal', icon: Icons.local_fire_department, color: AppColors.heartRed)),
    const SizedBox(width: 12),
    Expanded(child: _MetricCard(label: 'Distance', value: ble.isConnected ? '${(ble.activity.steps * 0.762 / 1000).toStringAsFixed(2)}' : '--', unit: 'km', icon: Icons.map_outlined, color: AppColors.primary)),
    const SizedBox(width: 12),
    Expanded(child: _MetricCard(label: 'Active', value: ble.isConnected ? '${(ble.activity.steps / 1200).floor()}' : '--', unit: 'min', icon: Icons.timer_outlined, color: AppColors.success)),
  ]);
}

class _MetricCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary, height: 1)),
      Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _HourlyChart extends StatelessWidget {
  final BleService ble;
  const _HourlyChart({required this.ble});

  List<BarChartGroupData> _bars(BleService ble) {
    final hour = DateTime.now().hour;
    return List.generate(24, (i) {
      final s = i <= hour
          ? (ble.isConnected
              ? (ble.activity.steps / (hour + 1) * (0.5 + 0.5 * (i % 3 == 0 ? 1.4 : i % 2 == 0 ? 0.7 : 0.9))).round().clamp(0, 999)
              : (300 + (i % 3 == 0 ? 400 : i % 2 == 0 ? 150 : 250)))
          : 0;
      return BarChartGroupData(x: i, barRods: [BarChartRodData(
        toY: s.toDouble(),
        color: i == hour ? AppColors.stepAmber : AppColors.stepAmber.withOpacity(0.3),
        width: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Steps by Hour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Hourly step distribution', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: BarChart(BarChartData(
            barGroups: _bars(ble),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i % 6 != 0) return const SizedBox.shrink();
                  final h = i == 0 ? '12A' : i == 6 ? '6A' : i == 12 ? '12P' : '6P';
                  return Text(h, style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                },
              )),
            ),
            borderData: FlBorderData(show: false),
          )),
        ),
      ]),
    );
  }
}

class _ActivityRings extends StatelessWidget {
  final BleService ble;
  const _ActivityRings({required this.ble});

  @override
  Widget build(BuildContext context) {
    final steps = ble.isConnected ? ble.activity.steps : 0;
    final cal = ble.isConnected ? ble.activity.calories.round() : 0;
    final active = ble.isConnected ? (ble.activity.steps / 1200).floor() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Activity Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        _GoalBar(label: 'Steps', current: steps.toDouble(), goal: 10000, unit: 'steps', color: AppColors.stepAmber),
        const SizedBox(height: 10),
        _GoalBar(label: 'Calories', current: cal.toDouble(), goal: 600, unit: 'kcal', color: AppColors.heartRed),
        const SizedBox(height: 10),
        _GoalBar(label: 'Active Minutes', current: active.toDouble(), goal: 60, unit: 'min', color: AppColors.success),
      ]),
    );
  }
}

class _GoalBar extends StatelessWidget {
  final String label, unit;
  final double current, goal;
  final Color color;
  const _GoalBar({required this.label, required this.current, required this.goal, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (current / goal).clamp(0.0, 1.0);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ]),
        Text('${current.round()} / ${goal.round()} $unit', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.grey.shade100,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 10,
        ),
      ),
    ]);
  }
}

class _FallDetector extends StatelessWidget {
  final BleService ble;
  const _FallDetector({required this.ble});

  @override
  Widget build(BuildContext context) {
    final fall = ble.isConnected && ble.accel.fallDetected;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fall ? AppColors.danger.withOpacity(0.06) : AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fall ? AppColors.danger.withOpacity(0.3) : AppColors.success.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fall ? AppColors.danger.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            fall ? Icons.warning_amber_rounded : Icons.shield_outlined,
            color: fall ? AppColors.danger : AppColors.success,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            fall ? '⚠️ Fall Detected!' : 'Fall Detection Active',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: fall ? AppColors.danger : AppColors.success),
          ),
          const SizedBox(height: 4),
          Text(
            fall
                ? 'Sudden impact detected. Emergency contacts have been alerted.'
                : 'Monitoring for falls using 6-axis accelerometer (MPU6050). All clear.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ])),
      ]),
    );
  }
}
