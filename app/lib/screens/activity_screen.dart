import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ble_service.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        final activity = ble.activity;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          appBar: AppBar(
            title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1e3a5f),
            elevation: 0,
          ),
          body: ble.isConnected
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _StepsHero(steps: activity.steps, goal: activity.stepsGoal),
                      const SizedBox(height: 16),
                      _ActivityGrid(activity: activity),
                      const SizedBox(height: 16),
                      _HourlyChart(hourlySteps: activity.hourlySteps),
                      const SizedBox(height: 100),
                    ],
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_run, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Connect your watch to view activity data',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _StepsHero extends StatelessWidget {
  final int steps, goal;
  const _StepsHero({required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_walk, color: Colors.white, size: 36),
          const SizedBox(height: 16),
          Text(
            '$steps',
            style: const TextStyle(
              color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, height: 1,
            ),
          ),
          const Text('steps today', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% of $goal step goal',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  final activity;
  const _ActivityGrid({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _ActivityCard(
          icon: Icons.local_fire_department,
          color: const Color(0xFFEF4444),
          label: 'Calories',
          value: '${activity.calories.round()}',
          unit: 'kcal',
        ),
        _ActivityCard(
          icon: Icons.route,
          color: const Color(0xFF22C55E),
          label: 'Distance',
          value: activity.distanceKm.toStringAsFixed(1),
          unit: 'km',
        ),
        _ActivityCard(
          icon: Icons.timer,
          color: const Color(0xFF2563eb),
          label: 'Active Time',
          value: '${activity.activeMinutes}',
          unit: 'min',
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, unit;
  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(unit, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  final List<int> hourlySteps;
  const _HourlyChart({required this.hourlySteps});

  @override
  Widget build(BuildContext context) {
    if (hourlySteps.isEmpty) return const SizedBox.shrink();
    final maxVal = hourlySteps.reduce((a, b) => a > b ? a : b).toDouble();
    final bars = hourlySteps.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.toDouble(),
            color: e.value == 0
                ? Colors.grey.shade200
                : const Color(0xFFF59E0B),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Steps by Hour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.2 : 100,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        if (val.toInt() % 6 != 0) return const SizedBox.shrink();
                        return Text('${val.toInt()}h',
                            style: TextStyle(color: Colors.grey[400], fontSize: 10));
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
