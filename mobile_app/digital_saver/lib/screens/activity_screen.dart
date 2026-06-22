import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/models/health_models.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Demo activity data
    final activityData = _generateDemoActivity();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.navActivity, style: AppTheme.headlineMedium),
          const SizedBox(height: 24),
          
          // Activity Score
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.healthyGreen.withOpacity(0.1),
                  AppTheme.healthyGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.healthyGreen.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run_rounded, color: AppTheme.healthyGreen, size: 32),
                    const SizedBox(width: 12),
                    Text('Activity Score', style: AppTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircularProgressIndicator(
                        value: activityData.activityScore / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(AppTheme.healthyGreen),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${activityData.activityScore.toInt()}',
                          style: AppTheme.headlineLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.healthyGreen,
                          ),
                        ),
                        Text('Score', style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _getActivityColor(activityData.activityScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getActivityIcon(activityData.currentActivity),
                        color: _getActivityColor(activityData.activityScore),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getActivityText(activityData.currentActivity),
                        style: TextStyle(
                          color: _getActivityColor(activityData.activityScore),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Daily Goals Progress
          _buildSectionTitle('Daily Goals'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildGoalProgress(
                  icon: Icons.directions_walk_rounded,
                  title: t.steps,
                  current: activityData.steps,
                  goal: 10000,
                  unit: t.steps_unit,
                  color: AppTheme.healthyGreen,
                ),
                const SizedBox(height: 16),
                _buildGoalProgress(
                  icon: Icons.local_fire_department_rounded,
                  title: t.calories,
                  current: activityData.caloriesBurned,
                  goal: 500,
                  unit: t.kcal,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(height: 16),
                _buildGoalProgress(
                  icon: Icons.timer_rounded,
                  title: t.activeMinutes,
                  current: activityData.activeMinutes,
                  goal: 60,
                  unit: t.minutes,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Activity Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.straighten_rounded,
                  value: '${activityData.distanceKm.toStringAsFixed(2)}',
                  label: t.distance,
                  color: AppTheme.infoBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite_rounded,
                  value: '${activityData.restingHeartRate}',
                  label: t.restingHR,
                  color: AppTheme.dangerRed,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Hourly Activity Chart
          _buildSectionTitle('Hourly Activity'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value / 1000).toStringAsFixed(0)}k',
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final hours = ['6a', '8a', '10a', '12p', '2p', '4p', '6p'];
                        if (value.toInt() < hours.length) {
                          return Text(hours[value.toInt()], style: AppTheme.bodySmall);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateHourlyData(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Weekly Overview
          _buildSectionTitle('This Week'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _generateWeeklyData(),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.titleLarge);
  }

  Widget _buildGoalProgress({
    required IconData icon,
    required String title,
    required int current,
    required int goal,
    required String unit,
    required Color color,
  }) {
    final progress = (current / goal).clamp(0.0, 1.0);
    
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(title, style: AppTheme.titleMedium),
            const Spacer(),
            Text(
              '$current / $goal $unit',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateHourlyData() {
    final data = [1200, 3400, 2100, 8900, 5600, 4200, 3100];
    return data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.toDouble(),
            color: _getBarColor(e.value),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();
  }

  Color _getBarColor(int value) {
    if (value < 2000) return Colors.grey;
    if (value < 5000) return AppTheme.healthyGreen.withOpacity(0.5);
    return AppTheme.healthyGreen;
  }

  List<Widget> _generateWeeklyData() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final values = [7500, 12000, 8900, 5400, 10200, 8200, 3200];
    
    return days.asMap().entries.map((e) {
      final progress = values[e.key] / 10000;
      return Column(
        children: [
          Container(
            width: 30,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 30,
                height: 80 * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: _getBarColor(values[e.key]),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(e.value, style: AppTheme.labelSmall),
        ],
      );
    }).toList();
  }

  Color _getActivityColor(double score) {
    if (score >= 80) return AppTheme.healthyGreen;
    if (score >= 50) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run_rounded;
      case ActivityType.jogging:
        return Icons.directions_run_rounded;
      case ActivityType.walking:
        return Icons.directions_walk_rounded;
      case ActivityType.sedentary:
        return Icons.airline_seat_recline_extra_rounded;
      case ActivityType.resting:
        return Icons.self_improvement_rounded;
    }
  }

  String _getActivityText(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.jogging:
        return 'Jogging';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.sedentary:
        return 'Sedentary';
      case ActivityType.resting:
        return 'Resting';
    }
  }

  ActivityData _generateDemoActivity() => ActivityData(
    steps: 8542,
    distanceKm: 6.2,
    caloriesBurned: 423,
    activeMinutes: 45,
    restingHeartRate: 58,
    currentActivity: ActivityType.walking,
    activityScore: 85,
    segments: [],
  );
}
