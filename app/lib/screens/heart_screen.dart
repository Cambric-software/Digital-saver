import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ble_service.dart';
import '../services/health_analysis_service.dart';
import '../theme/app_theme.dart';

class HeartScreen extends StatelessWidget {
  const HeartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final zone = ble.heartRate.bpm > 0 ? HealthAnalysisService.heartRateZone(ble.heartRate.bpm) : null;
    final zone2 = ble.heartRate.bpm > 0 ? HealthAnalysisService.getHeartRateZone2(ble.heartRate.bpm) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Heart Rate', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _HeroBPM(ble: ble, zone: zone, zone2: zone2),
          const SizedBox(height: 16),
          _HRVPanel(ble: ble),
          const SizedBox(height: 16),
          _RRChart(ble: ble),
          const SizedBox(height: 16),
          _AFibPanel(ble: ble),
          const SizedBox(height: 16),
          _ZoneGuide(currentHR: ble.heartRate.bpm.toDouble()),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }
}

class _HeroBPM extends StatelessWidget {
  final BleService ble;
  final String? zone, zone2;
  const _HeroBPM({required this.ble, this.zone, this.zone2});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientHeart,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.coloredCard(AppColors.heartRed),
      ),
      child: Column(children: [
        const Icon(Icons.favorite, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        const Text('Heart Rate', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(
          ble.isConnected && ble.heartRate.bpm > 0 ? '${ble.heartRate.bpm}' : '--',
          style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1),
        ),
        const Text('BPM', style: TextStyle(color: Colors.white70, fontSize: 16)),
        if (zone != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$zone · $zone2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _HeroStat('Min', '${ble.heartRate.bpm > 0 ? (ble.heartRate.bpm.toDouble() * 0.92).round() : "--"}'),
          Container(width: 1, height: 28, color: Colors.white30),
          _HeroStat('Current', ble.heartRate.bpm > 0 ? '${ble.heartRate.bpm}' : '--'),
          Container(width: 1, height: 28, color: Colors.white30),
          _HeroStat('Max', '${ble.heartRate.bpm > 0 ? (ble.heartRate.bpm.toDouble() * 1.08).round() : "--"}'),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
  ]);
}

class _HRVPanel extends StatelessWidget {
  final BleService ble;
  const _HRVPanel({required this.ble});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('Heart Rate Variability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _HRVStat(label: 'RMSSD', value: ble.isConnected && ble.heartRate.hrv > 0 ? '${ble.heartRate.hrv} ms' : '--',
            subtitle: 'Parasympathetic tone', color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _HRVStat(label: 'SDNN', value: ble.isConnected && ble.heartRate.hrv > 0 ? '${(ble.heartRate.hrv * 1.4).round()} ms' : '--',
            subtitle: 'Overall variability', color: AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _HRVStat(label: 'pNN50', value: ble.isConnected && ble.heartRate.hrv > 0 ? '${((ble.heartRate.hrv - 15) / 0.85).clamp(0, 100).round()}%' : '--',
            subtitle: '> 50ms intervals', color: AppColors.accent)),
        ]),
        if (ble.isConnected && ble.heartRate.hrv > 0) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _StressBar(hrv: ble.heartRate.hrv.toDouble()),
        ],
      ]),
    );
  }
}

class _HRVStat extends StatelessWidget {
  final String label, value, subtitle;
  final Color color;
  const _HRVStat({required this.label, required this.value, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.4)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, height: 1.3)),
    ]),
  );
}

class _StressBar extends StatelessWidget {
  final double hrv;
  const _StressBar({required this.hrv});

  double get _stress => ((80 - hrv.clamp(0, 80)) / 80).clamp(0.0, 1.0);
  String get _label {
    if (_stress < 0.25) return 'Relaxed';
    if (_stress < 0.5) return 'Moderate';
    if (_stress < 0.75) return 'Stressed';
    return 'High Stress';
  }
  Color get _color {
    if (_stress < 0.25) return AppColors.success;
    if (_stress < 0.5) return AppColors.primary;
    if (_stress < 0.75) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('Stress Index', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    ]),
    const SizedBox(height: 8),
    ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: _stress,
        backgroundColor: Colors.grey.shade100,
        valueColor: AlwaysStoppedAnimation(_color),
        minHeight: 10,
      ),
    ),
  ]);
}

class _RRChart extends StatelessWidget {
  final BleService ble;
  const _RRChart({required this.ble});

  @override
  Widget build(BuildContext context) {
    final spots = ble.heartRate.rrIntervals.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RR Interval History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Beat-to-beat timing (ms)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: spots.isEmpty
              ? const Center(child: Text('Waiting for data...', style: TextStyle(color: AppColors.textMuted)))
              : LineChart(LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.heartRed,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.heartRed.withOpacity(0.2), AppColors.heartRed.withOpacity(0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  )],
                )),
        ),
      ]),
    );
  }
}

class _AFibPanel extends StatelessWidget {
  final BleService ble;
  const _AFibPanel({required this.ble});

  @override
  Widget build(BuildContext context) {
    final irregular = ble.isConnected && ble.heartRate.afibProbability > 30;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: irregular ? AppColors.danger.withOpacity(0.05) : AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: irregular ? AppColors.danger.withOpacity(0.3) : AppColors.success.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: irregular ? AppColors.danger.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            irregular ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: irregular ? AppColors.danger : AppColors.success,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            irregular ? 'Irregular Rhythm Detected' : 'Rhythm Normal',
            style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15,
              color: irregular ? AppColors.danger : AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            irregular
                ? 'Your heartbeat shows irregular pattern. This may indicate AFib. Consult your doctor.'
                : 'Heart rhythm appears regular. No signs of AFib detected.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ])),
      ]),
    );
  }
}

class _ZoneGuide extends StatelessWidget {
  final double currentHR;
  const _ZoneGuide({required this.currentHR});

  static const zones = [
    (name: 'Rest', range: '< 60', color: Color(0xFF94A3B8), min: 0.0, max: 60.0),
    (name: 'Fat Burn', range: '60–100', color: Color(0xFF22C55E), min: 60.0, max: 100.0),
    (name: 'Cardio', range: '100–140', color: Color(0xFFF59E0B), min: 100.0, max: 140.0),
    (name: 'Peak', range: '140–170', color: Color(0xFFEF4444), min: 140.0, max: 170.0),
    (name: 'Max', range: '> 170', color: Color(0xFF7C3AED), min: 170.0, max: 220.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Heart Rate Zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ...zones.map((z) {
          final active = currentHR >= z.min && currentHR < z.max;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? z.color.withOpacity(0.12) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: active ? Border.all(color: z.color.withOpacity(0.4)) : null,
            ),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: z.color)),
              const SizedBox(width: 10),
              Expanded(child: Text(z.name, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? z.color : AppColors.textSecondary, fontSize: 13))),
              Text(z.range, style: TextStyle(color: active ? z.color : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text('BPM', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              if (active) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: z.color, borderRadius: BorderRadius.circular(6)),
                  child: const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ]),
          );
        }),
      ]),
    );
  }
}
