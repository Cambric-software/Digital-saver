import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/services/ble_advanced_service.dart';
import 'package:digital_saver/services/health_analysis_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/models/health_models.dart';
import 'package:digital_saver/widgets/health_metric_card.dart';
import 'package:digital_saver/widgets/emergency_button.dart';
import 'package:digital_saver/widgets/trend_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bleService = context.watch<BleAdvancedService>();
    final healthAnalysis = context.watch<HealthAnalysisService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get latest data from history or generate demo data
    final latestHR = healthAnalysis.heartRateHistory.isNotEmpty 
        ? healthAnalysis.heartRateHistory.last 
        : _generateDemoHR();
    final latestBP = healthAnalysis.bpHistory.isNotEmpty 
        ? healthAnalysis.bpHistory.last 
        : _generateDemoBP();
    final latestO2 = healthAnalysis.oxygenHistory.isNotEmpty 
        ? healthAnalysis.oxygenHistory.last 
        : _generateDemoO2();
    
    // Calculate health score
    final healthScore = healthAnalysis.calculateComprehensiveScore(
      heartRate: latestHR,
      bloodPressure: latestBP,
      oxygen: latestO2,
      activity: ActivityData(
        steps: 0, distanceKm: 0, caloriesBurned: 0, activeMinutes: 0,
        restingHeartRate: 60, currentActivity: ActivityType.resting,
        activityScore: 75, segments: [],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.appName,
                    style: AppTheme.headlineMedium,
                  ),
                  Text(
                    t.tagline,
                    style: AppTheme.bodyMedium.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Health Score Circle
          Center(
            child: CircularPercentIndicator(
              radius: 80,
              lineWidth: 12,
              percent: healthScore.overallScore / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${healthScore.overallScore}',
                    style: AppTheme.headlineLarge.copyWith(
                      color: _getScoreColor(healthScore.overallScore),
                    ),
                  ),
                  Text(
                    t.healthScore,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
              progressColor: _getScoreColor(healthScore.overallScore),
              backgroundColor: isDark 
                  ? Colors.grey[800]! 
                  : Colors.grey[200]!,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1000,
            ),
          ),
          
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(healthScore.overallScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getGradeText(healthScore.grade),
                style: TextStyle(
                  color: _getScoreColor(healthScore.overallScore),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Health Metrics Grid
          Row(
            children: [
              Expanded(
                child: HealthMetricCard(
                  title: t.heartRate,
                  value: '${latestHR.currentBPM}',
                  unit: t.bpm,
                  icon: Icons.favorite_rounded,
                  color: AppTheme.dangerRed,
                  status: latestHR.status,
                  trend: healthAnalysis.heartRateTrend,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HealthMetricCard(
                  title: t.bloodPressure,
                  value: '${latestBP.systolic}/${latestBP.diastolic}',
                  unit: t.mmhg,
                  icon: Icons.water_drop_rounded,
                  color: AppTheme.infoBlue,
                  status: latestBP.category == BpCategory.normal 
                      ? HeartRateStatus.normal 
                      : HeartRateStatus.warning,
                  trend: healthAnalysis.bpTrend,
                  onTap: () {},
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: HealthMetricCard(
                  title: t.oxygen,
                  value: '${latestO2.spO2}',
                  unit: t.percent,
                  icon: Icons.air_rounded,
                  color: AppTheme.healthyGreen,
                  status: latestO2.status == OxygenStatus.normal 
                      ? HeartRateStatus.normal 
                      : HeartRateStatus.warning,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HealthMetricCard(
                  title: t.hrv,
                  value: latestHR.hrv.toStringAsFixed(0),
                  unit: t.ms,
                  icon: Icons.show_chart_rounded,
                  color: AppTheme.primaryColor,
                  status: HeartRateStatus.normal,
                  onTap: () {},
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Emergency Button
          EmergencyButton(
            onPressed: () => _showEmergencyDialog(context),
          ),
          
          const SizedBox(height: 24),
          
          // Heart Rate Gauge
          _buildSection(
            title: t.heartRate,
            child: SizedBox(
              height: 180,
              child: SfRadialGauge(
                enableLoadingAnimation: true,
                animationDuration: 2000,
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 40,
                    maximum: 200,
                    startAngle: 150,
                    endAngle: 30,
                    showLabels: true,
                    showTicks: true,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.15,
                      thicknessUnit: GaugeSizeUnit.factor,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 40,
                        endValue: 60,
                        color: AppTheme.infoBlue.withOpacity(0.3),
                      ),
                      GaugeRange(
                        startValue: 60,
                        endValue: 100,
                        color: AppTheme.healthyGreen.withOpacity(0.3),
                      ),
                      GaugeRange(
                        startValue: 100,
                        endValue: 150,
                        color: AppTheme.warningOrange.withOpacity(0.3),
                      ),
                      GaugeRange(
                        startValue: 150,
                        endValue: 200,
                        color: AppTheme.dangerRed.withOpacity(0.3),
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: latestHR.currentBPM.toDouble(),
                        enableAnimation: true,
                        animationType: AnimationType.easeOutBack,
                        needleColor: AppTheme.primaryColor,
                        knobStyle: const KnobStyle(
                          knobRadius: 0.08,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${latestHR.currentBPM}',
                              style: AppTheme.headlineLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              t.bpm,
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          _buildSection(
            title: 'Quick Stats',
            child: Row(
              children: [
                _buildQuickStat(
                  icon: Icons.directions_walk_rounded,
                  value: '8,542',
                  label: t.steps,
                  color: AppTheme.healthyGreen,
                ),
                _buildQuickStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '423',
                  label: t.calories,
                  color: AppTheme.warningOrange,
                ),
                _buildQuickStat(
                  icon: Icons.nights_stay_rounded,
                  value: '7h 23m',
                  label: t.sleep,
                  color: AppTheme.primaryColor,
                ),
                _buildQuickStat(
                  icon: Icons.self_improvement_rounded,
                  value: 'Low',
                  label: t.stress,
                  color: AppTheme.infoBlue,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recommendations
          if (healthScore.recommendations.isNotEmpty)
            _buildSection(
              title: t.recommendations,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: healthScore.recommendations
                      .take(3)
                      .map((rec) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 20,
                                  color: AppTheme.warningOrange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: AppTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Medical Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.medicalDisclaimer,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.titleLarge),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppTheme.healthyGreen;
    if (score >= 70) return AppTheme.primaryColor;
    if (score >= 50) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

  String _getGradeText(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.excellent:
        return 'Excellent';
      case HealthGrade.good:
        return 'Good';
      case HealthGrade.fair:
        return 'Fair';
      case HealthGrade.poor:
        return 'Poor';
      case HealthGrade.critical:
        return 'Critical';
    }
  }

  void _showEmergencyDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.dangerRed),
            const SizedBox(width: 12),
            Text(t.emergencyAlert),
          ],
        ),
        content: Text(t.areYouOkay),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger emergency
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(t.sendAlert),
          ),
        ],
      ),
    );
  }

  // Demo data generators
  HeartRateData _generateDemoHR() => HeartRateData(
    currentBPM: 72,
    averageBPM: 70,
    minBPM: 58,
    maxBPM: 95,
    hrv: 45,
    sdnn: 32,
    rrIntervals: [],
    status: HeartRateStatus.normal,
    confidence: 85,
    hrvAnalysis: [],
    afibProbability: 5,
  );

  BloodPressureData _generateDemoBP() => BloodPressureData(
    systolic: 118,
    diastolic: 76,
    meanArterialPressure: 90,
    pulsePressure: 42,
    augmentationIndex: 25,
    pulseWaveVelocity: 7.5,
    pulseWave: [],
    category: BpCategory.normal,
    confidence: 80,
  );

  OxygenData _generateDemoO2() => OxygenData(
    spO2: 98,
    perfusionIndex: 5,
    respirationRate: 16,
    lowOxygenAlert: false,
    spo2History: [],
    status: OxygenStatus.normal,
  );
}
