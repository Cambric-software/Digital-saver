import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/services/health_analysis_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/models/health_models.dart';

class BloodPressureScreen extends StatelessWidget {
  const BloodPressureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final healthAnalysis = context.watch<HealthAnalysisService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get latest BP data
    final latestBP = healthAnalysis.bpHistory.isNotEmpty 
        ? healthAnalysis.bpHistory.last 
        : _generateDemoBP();
    
    // Perform BP analysis
    final bpAnalysis = healthAnalysis.analyzeBloodPressure(healthAnalysis.bpHistory);
    
    // Get BP history for chart
    final bpHistory = healthAnalysis.bpHistory.take(30).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.navBP, style: AppTheme.headlineMedium),
          const SizedBox(height: 24),
          
          // Main BP Display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.infoBlue.withOpacity(0.1),
                  AppTheme.infoBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.infoBlue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop_rounded, color: AppTheme.infoBlue, size: 32),
                    const SizedBox(width: 12),
                    Text(t.bloodPressure, style: AppTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBPGauge(
                      value: latestBP.systolic.toDouble(),
                      label: 'SYS',
                      color: _getBPGaugeColor(latestBP.category, true),
                      min: 70,
                      max: 200,
                    ),
                    const SizedBox(width: 32),
                    Text(
                      '/',
                      style: AppTheme.headlineLarge.copyWith(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 32),
                    _buildBPGauge(
                      value: latestBP.diastolic.toDouble(),
                      label: 'DIA',
                      color: _getBPGaugeColor(latestBP.category, false),
                      min: 40,
                      max: 130,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _getBPCategoryColor(latestBP.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getBPCategoryText(latestBP.category),
                    style: TextStyle(
                      color: _getBPCategoryColor(latestBP.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // MAP and Pulse Pressure
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'MAP',
                  value: '${latestBP.meanArterialPressure}',
                  unit: t.mmhg,
                  icon: Icons.speed_rounded,
                  color: AppTheme.primaryColor,
                  subtitle: 'Mean Arterial Pressure',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'PP',
                  value: latestBP.pulsePressure.toStringAsFixed(0),
                  unit: t.mmhg,
                  icon: Icons.favorite_border_rounded,
                  color: AppTheme.secondaryColor,
                  subtitle: 'Pulse Pressure',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Advanced Metrics
          _buildSectionTitle('Vascular Health'),
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
                  children: [
                    Expanded(
                      child: _buildVascularMetric(
                        t.vascularAge,
                        '${bpAnalysis.vascularAge}',
                        'years',
                        AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildVascularMetric(
                        t.arterialStiffness,
                        bpAnalysis.arterialStiffness.toStringAsFixed(1),
                        '',
                        _getStiffnessColor(bpAnalysis.arterialStiffness),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.infoBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vascular age estimates artery health based on pulse wave analysis.',
                          style: AppTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // BP Trend Chart
          _buildSectionTitle('${t.trend} Analysis'),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: bpHistory.isNotEmpty
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
                      minY: 60,
                      maxY: 160,
                      lineBarsData: [
                        // Systolic line
                        LineChartBarData(
                          spots: bpHistory.asMap().entries.map((e) => 
                            FlSpot(e.key.toDouble(), e.value.systolic.toDouble())
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
                        // Diastolic line
                        LineChartBarData(
                          spots: bpHistory.asMap().entries.map((e) => 
                            FlSpot(e.key.toDouble(), e.value.diastolic.toDouble())
                          ).toList(),
                          isCurved: true,
                          color: AppTheme.infoBlue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : Center(child: Text(t.noData, style: AppTheme.bodyMedium)),
          ),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Systolic', AppTheme.dangerRed),
              const SizedBox(width: 24),
              _buildLegend('Diastolic', AppTheme.infoBlue),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // BP Categories Guide
          _buildSectionTitle('BP Categories Guide'),
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
                _buildBPCategoryRow('Normal', '<120', 'and', '<80', AppTheme.healthyGreen),
                const Divider(height: 24),
                _buildBPCategoryRow('Elevated', '120-129', 'and', '<80', AppTheme.infoBlue),
                const Divider(height: 24),
                _buildBPCategoryRow('Stage 1 HTN', '130-139', 'or', '80-89', AppTheme.warningOrange),
                const Divider(height: 24),
                _buildBPCategoryRow('Stage 2 HTN', '≥140', 'or', '≥90', AppTheme.dangerRed),
                const Divider(height: 24),
                _buildBPCategoryRow('Crisis', '>180', 'or', '>120', Colors.purple),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recommendations
          if (bpAnalysis.recommendations.isNotEmpty)
            _buildSectionTitle(t.recommendations),
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
                children: bpAnalysis.recommendations
                    .take(4)
                    .map((rec) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates_rounded,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(rec, style: AppTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBPGauge({
    required double value,
    required String label,
    required Color color,
    required double min,
    required double max,
  }) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          height: 100,
          child: SfRadialGauge(
            enableLoadingAnimation: true,
            axes: <RadialAxis>[
              RadialAxis(
                minimum: min,
                maximum: max,
                showLabels: false,
                showTicks: false,
                startAngle: 135,
                endAngle: 45,
                axisLineStyle: AxisLineStyle(
                  thickness: 8,
                  color: Colors.grey.withOpacity(0.2),
                  cornerStyle: CornerStyle.bothCurve,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: value,
                    width: 8,
                    cornerStyle: CornerStyle.bothCurve,
                    gradient: SweepGradient(
                      colors: [color.withOpacity(0.5), color],
                    ),
                    enableAnimation: true,
                    animationType: AnimationType.easeOutBack,
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(
                      value.toInt().toString(),
                      style: AppTheme.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: AppTheme.bodySmall),
            ],
          ),
          Text(title, style: AppTheme.labelSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: AppTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildVascularMetric(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: AppTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (unit.isNotEmpty) Text(unit, style: AppTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.titleLarge);
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }

  Widget _buildBPCategoryRow(String category, String sys, String connector, String dia, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(category, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(sys, style: AppTheme.bodySmall, textAlign: TextAlign.center),
        ),
        Text(connector, style: AppTheme.bodySmall),
        Expanded(
          child: Text(dia, style: AppTheme.bodySmall, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Color _getBPGaugeColor(BpCategory category, bool isSystolic) {
    switch (category) {
      case BpCategory.normal:
        return AppTheme.healthyGreen;
      case BpCategory.elevated:
        return AppTheme.infoBlue;
      case BpCategory.hypertension1:
        return AppTheme.warningOrange;
      case BpCategory.hypertension2:
        return AppTheme.dangerRed;
      case BpCategory.crisis:
        return Colors.purple;
      case BpCategory.hypotension:
        return Colors.teal;
    }
  }

  Color _getBPCategoryColor(BpCategory category) {
    switch (category) {
      case BpCategory.normal:
        return AppTheme.healthyGreen;
      case BpCategory.elevated:
        return AppTheme.infoBlue;
      case BpCategory.hypertension1:
        return AppTheme.warningOrange;
      case BpCategory.hypertension2:
        return AppTheme.dangerRed;
      case BpCategory.crisis:
        return Colors.purple;
      case BpCategory.hypotension:
        return Colors.teal;
    }
  }

  String _getBPCategoryText(BpCategory category) {
    switch (category) {
      case BpCategory.normal:
        return 'Normal';
      case BpCategory.elevated:
        return 'Elevated';
      case BpCategory.hypertension1:
        return 'Stage 1 Hypertension';
      case BpCategory.hypertension2:
        return 'Stage 2 Hypertension';
      case BpCategory.crisis:
        return 'Hypertensive Crisis!';
      case BpCategory.hypotension:
        return 'Low Blood Pressure';
    }
  }

  Color _getStiffnessColor(double stiffness) {
    if (stiffness < 25) return AppTheme.healthyGreen;
    if (stiffness < 35) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

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
}
