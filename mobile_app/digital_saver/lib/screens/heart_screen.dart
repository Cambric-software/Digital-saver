import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/services/health_analysis_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/models/health_models.dart';
import 'package:digital_saver/widgets/info_card.dart';

class HeartScreen extends StatelessWidget {
  const HeartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final healthAnalysis = context.watch<HealthAnalysisService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get latest HR data
    final latestHR = healthAnalysis.heartRateHistory.isNotEmpty 
        ? healthAnalysis.heartRateHistory.last 
        : _generateDemoHR();
    
    // Perform arrhythmia analysis
    final arrhythmiaResult = healthAnalysis.detectArrhythmia(latestHR.rrIntervals);
    
    // Get HR history for chart
    final hrHistory = healthAnalysis.heartRateHistory
        .take(30)
        .map((e) => e.currentBPM.toDouble())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.navHeart, style: AppTheme.headlineMedium),
          const SizedBox(height: 24),
          
          // Main Heart Rate Display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.dangerRed.withOpacity(0.1),
                  AppTheme.dangerRed.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.dangerRed.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.dangerRed,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.heartRate,
                      style: AppTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SfRadialGauge(
                  enableLoadingAnimation: true,
                  animationDuration: 1500,
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 40,
                      maximum: 200,
                      startAngle: 180,
                      endAngle: 0,
                      showLabels: false,
                      showTicks: false,
                      axisLineStyle: AxisLineStyle(
                        thickness: 20,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        cornerStyle: CornerStyle.bothCurve,
                      ),
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 40,
                          endValue: 200,
                          color: Colors.transparent,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        RangePointer(
                          value: latestHR.currentBPM.toDouble(),
                          width: 20,
                          cornerStyle: CornerStyle.bothCurve,
                          gradient: const SweepGradient(
                            colors: [
                              AppTheme.dangerRed,
                              AppTheme.dangerRed,
                            ],
                          ),
                          enableAnimation: true,
                          animationType: AnimationType.easeOutBack,
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
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.dangerRed,
                                ),
                              ),
                              Text(
                                t.bpm,
                                style: AppTheme.titleMedium.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          angle: 90,
                          positionFactor: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard(
                label: t.min,
                value: '${latestHR.minBPM}',
                icon: Icons.arrow_downward_rounded,
                color: AppTheme.infoBlue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                label: t.avg,
                value: '${latestHR.averageBPM}',
                icon: Icons.trending_flat_rounded,
                color: AppTheme.healthyGreen,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                label: t.max,
                value: '${latestHR.maxBPM}',
                icon: Icons.arrow_upward_rounded,
                color: AppTheme.warningOrange,
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // HRV Section
          _buildSectionTitle(t.hrv),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHRVMetric(t.rmssd, '${latestHR.hrv.toStringAsFixed(1)}', t.ms),
                    _buildHRVMetric(t.sdnn, '${latestHR.sdnn.toStringAsFixed(1)}', t.ms),
                    _buildHRVMetric(t.pnn50, '${(latestHR.hrv / 2).toStringAsFixed(1)}', '%'),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HRV Status: ${latestHR.hrvDescription}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
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
          
          // AFib Analysis
          _buildSectionTitle(t.afib),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.afibProbability, style: AppTheme.titleMedium),
                        Text(
                          '${latestHR.afibProbability.toStringAsFixed(1)}%',
                          style: AppTheme.headlineMedium.copyWith(
                            color: _getAFibColor(latestHR.afibProbability),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getAFibColor(latestHR.afibProbability).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAFibIcon(latestHR.afibProbability),
                            color: _getAFibColor(latestHR.afibProbability),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getAFibStatus(latestHR.afibProbability),
                            style: TextStyle(
                              color: _getAFibColor(latestHR.afibProbability),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: latestHR.afibProbability / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(
                      _getAFibColor(latestHR.afibProbability),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getAFibAdvice(latestHR.afibProbability),
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Heart Rate Trend Chart
          _buildSectionTitle('Heart Rate Trend'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: hrHistory.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
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
                              value.toInt().toString(),
                              style: AppTheme.bodySmall,
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 40,
                      maxY: 140,
                      lineBarsData: [
                        LineChartBarData(
                          spots: hrHistory.asMap().entries.map((e) => 
                            FlSpot(e.key.toDouble(), e.value)
                          ).toList(),
                          isCurved: true,
                          color: AppTheme.dangerRed,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.dangerRed.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(t.noData, style: AppTheme.bodyMedium),
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Arrhythmia Detection
          if (arrhythmiaResult.hasArrhythmia)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: AppTheme.dangerRed),
                      const SizedBox(width: 12),
                      Text(
                        t.arrhythmia,
                        style: AppTheme.titleLarge.copyWith(color: AppTheme.dangerRed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type: ${arrhythmiaResult.type?.name ?? "Unknown"}',
                    style: AppTheme.bodyMedium,
                  ),
                  Text(
                    'Confidence: ${arrhythmiaResult.confidence.toStringAsFixed(1)}%',
                    style: AppTheme.bodyMedium,
                  ),
                  Text(
                    'Risk Level: ${arrhythmiaResult.riskLevel.name}',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ...arrhythmiaResult.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppTheme.dangerRed),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec, style: AppTheme.bodySmall)),
                      ],
                    ),
                  )),
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildHRVMetric(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(unit, style: AppTheme.bodySmall),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.labelSmall),
      ],
    );
  }

  Color _getAFibColor(double probability) {
    if (probability < 20) return AppTheme.healthyGreen;
    if (probability < 50) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

  IconData _getAFibIcon(double probability) {
    if (probability < 20) return Icons.check_circle_rounded;
    if (probability < 50) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  String _getAFibStatus(double probability) {
    if (probability < 20) return 'Low Risk';
    if (probability < 50) return 'Moderate';
    return 'High Risk';
  }

  String _getAFibAdvice(double probability) {
    if (probability < 20) return 'Your heart rhythm appears regular and healthy.';
    if (probability < 50) return 'Some irregularity detected. Continue monitoring.';
    return 'Significant irregularity detected. Please consult a doctor.';
  }

  HeartRateData _generateDemoHR() => HeartRateData(
    currentBPM: 72,
    averageBPM: 70,
    minBPM: 58,
    maxBPM: 95,
    hrv: 45,
    sdnn: 32,
    rrIntervals: List.generate(60, (i) => 800 + (i % 10) * 10),
    status: HeartRateStatus.normal,
    confidence: 85,
    hrvAnalysis: [],
    afibProbability: 8,
  );
}
