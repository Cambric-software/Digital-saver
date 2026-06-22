import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/models/health_models.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Demo sleep data
    final sleepData = _generateDemoSleep();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.navSleep, style: AppTheme.headlineMedium),
          const SizedBox(height: 24),
          
          // Sleep Score Circle
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.nights_stay_rounded, color: AppTheme.primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Text(t.sleepScore, style: AppTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 20),
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 12,
                  percent: sleepData.sleepScore / 100,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${sleepData.sleepScore}',
                        style: AppTheme.headlineLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getSleepScoreColor(sleepData.sleepScore),
                        ),
                      ),
                      Text(
                        _getSleepQualityText(sleepData.quality),
                        style: AppTheme.bodySmall.copyWith(
                          color: _getSleepScoreColor(sleepData.sleepScore),
                        ),
                      ),
                    ],
                  ),
                  progressColor: _getSleepScoreColor(sleepData.sleepScore),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1000,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Total Sleep Time
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.bed_rounded,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.totalSleep, style: AppTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        sleepData.totalSleepString,
                        style: AppTheme.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.healthyGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.healthyGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'On Target',
                        style: TextStyle(
                          color: AppTheme.healthyGreen,
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
          
          // Sleep Stages
          _buildSectionTitle('Sleep Stages'),
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
                // Visual sleep stages bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        _buildSleepStageSegment(
                          flex: 15,
                          color: AppTheme.deepSleepColor,
                          label: 'Deep',
                        ),
                        _buildSleepStageSegment(
                          flex: 45,
                          color: AppTheme.lightSleepColor,
                          label: 'Light',
                        ),
                        _buildSleepStageSegment(
                          flex: 25,
                          color: AppTheme.remSleepColor,
                          label: 'REM',
                        ),
                        _buildSleepStageSegment(
                          flex: 15,
                          color: Colors.grey,
                          label: 'Awake',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Sleep stage details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSleepStageDetail(
                      label: t.deepSleep,
                      value: '1h 45m',
                      color: AppTheme.deepSleepColor,
                      icon: Icons.nightlight_round,
                    ),
                    _buildSleepStageDetail(
                      label: t.lightSleep,
                      value: '4h 30m',
                      color: AppTheme.lightSleepColor,
                      icon: Icons.nights_stay_outlined,
                    ),
                    _buildSleepStageDetail(
                      label: t.remSleep,
                      value: '1h 30m',
                      color: AppTheme.remSleepColor,
                      icon: Icons.remove_red_eye_outlined,
                    ),
                    _buildSleepStageDetail(
                      label: t.awake,
                      value: '38m',
                      color: Colors.grey,
                      icon: Icons.visibility_off_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sleep Insights
          _buildSectionTitle('Sleep Insights'),
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
                _buildInsightRow(
                  icon: Icons.access_time_rounded,
                  title: 'Sleep Duration',
                  value: '7h 23m',
                  status: 'Good',
                  color: AppTheme.healthyGreen,
                ),
                const Divider(height: 24),
                _buildInsightRow(
                  icon: Icons.schedule_rounded,
                  title: 'Time Asleep',
                  value: '7h 23m',
                  status: '92%',
                  color: AppTheme.primaryColor,
                ),
                const Divider(height: 24),
                _buildInsightRow(
                  icon: Icons.bedtime_rounded,
                  title: 'Bedtime',
                  value: '10:45 PM',
                  status: 'On Time',
                  color: AppTheme.infoBlue,
                ),
                const Divider(height: 24),
                _buildInsightRow(
                  icon: Icons.wb_sunny_rounded,
                  title: 'Wake Time',
                  value: '6:08 AM',
                  status: 'On Time',
                  color: AppTheme.warningOrange,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sleep Tips
          _buildSectionTitle('Sleep Tips'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildTipRow(
                  icon: Icons.phone_android_rounded,
                  tip: 'Avoid screens 1 hour before bed',
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.local_cafe_rounded,
                  tip: 'Limit caffeine after 2 PM',
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.thermostat_rounded,
                  tip: 'Keep bedroom cool (65-68°F)',
                ),
              ],
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

  Widget _buildSleepStageSegment({
    required int flex,
    required Color color,
    required String label,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          color: color,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSleepStageDetail({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String title,
    required String value,
    required String status,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.bodyMedium),
              Text(value, style: AppTheme.titleMedium),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String tip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(tip, style: AppTheme.bodyMedium),
        ),
      ],
    );
  }

  Color _getSleepScoreColor(int score) {
    if (score >= 85) return AppTheme.healthyGreen;
    if (score >= 70) return AppTheme.primaryColor;
    if (score >= 50) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

  String _getSleepQualityText(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.excellent:
        return 'Excellent';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.veryPoor:
        return 'Very Poor';
      default:
        return '';
    }
  }

  SleepData _generateDemoSleep() => SleepData(
    totalSleep: const Duration(hours: 7, minutes: 23),
    deepSleep: const Duration(hours: 1, minutes: 45),
    lightSleep: const Duration(hours: 4, minutes: 30),
    remSleep: const Duration(hours: 1, minutes: 30),
    awakeTime: const Duration(minutes: 38),
    sleepScore: 82,
    segments: [],
    quality: SleepQuality.good,
  );
}

// Extended colors for sleep stages
extension SleepColors on AppTheme {
  static const Color deepSleepColor = Color(0xFF4A148C);
  static const Color lightSleepColor = Color(0xFF2196F3);
  static const Color remSleepColor = Color(0xFFFF9800);
}
