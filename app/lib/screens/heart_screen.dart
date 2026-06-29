import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ble_service.dart';
import '../services/health_analysis_service.dart';

class HeartScreen extends StatelessWidget {
  const HeartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        final hr = ble.heartRate;
        final stress = HealthAnalysisService.stressIndex(hr);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          appBar: AppBar(
            title: const Text('Heart Rate', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1e3a5f),
            elevation: 0,
          ),
          body: ble.isConnected
              ? _ConnectedView(ble: ble, stress: stress)
              : const _NotConnectedView(),
        );
      },
    );
  }
}

class _ConnectedView extends StatelessWidget {
  final BleService ble;
  final double stress;
  const _ConnectedView({required this.ble, required this.stress});

  @override
  Widget build(BuildContext context) {
    final hr = ble.heartRate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _BpmHero(bpm: hr.bpm, status: hr.status),
          const SizedBox(height: 16),
          _HrvGrid(hr: hr),
          const SizedBox(height: 16),
          _AFibCard(probability: hr.afibProbability),
          const SizedBox(height: 16),
          _StressCard(stress: stress),
          const SizedBox(height: 16),
          if (hr.rrIntervals.isNotEmpty) _RRChart(intervals: hr.rrIntervals),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _BpmHero extends StatelessWidget {
  final int bpm;
  final int status;
  const _BpmHero({required this.bpm, required this.status});

  Color get _color {
    if (status == 2) return const Color(0xFFEF4444);
    if (status == 1) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFEF4444).withOpacity(0.9), const Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            bpm > 0 ? '$bpm' : '--',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const Text('BPM', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              HealthAnalysisService.heartRateZone(bpm),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HrvGrid extends StatelessWidget {
  final hr;
  const _HrvGrid({required this.hr});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _StatCard(label: 'HRV (RMSSD)', value: '${hr.hrv}', unit: 'ms', color: const Color(0xFF7c3aed)),
        _StatCard(label: 'SDNN', value: '${hr.sdnn}', unit: 'ms', color: const Color(0xFF2563eb)),
        _StatCard(label: 'pNN50', value: '${hr.pnn50}', unit: '%', color: const Color(0xFF22C55E)),
      ],
    );
  }
}

class _AFibCard extends StatelessWidget {
  final int probability;
  const _AFibCard({required this.probability});

  @override
  Widget build(BuildContext context) {
    final isRisk = probability > 50;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isRisk ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRisk
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFF22C55E).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: isRisk ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AFib Detection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRisk ? const Color(0xFF991B1B) : const Color(0xFF15803D),
                  ),
                ),
                Text(
                  isRisk
                      ? 'Irregular rhythm detected ($probability% probability)'
                      : 'Normal sinus rhythm ($probability% risk)',
                  style: TextStyle(
                    color: isRisk ? const Color(0xFF991B1B) : const Color(0xFF15803D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StressCard extends StatelessWidget {
  final double stress;
  const _StressCard({required this.stress});

  String get label {
    if (stress < 30) return 'Relaxed';
    if (stress < 60) return 'Moderate';
    return 'High Stress';
  }

  Color get color {
    if (stress < 30) return const Color(0xFF22C55E);
    if (stress < 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stress Index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            '${stress.round()} / 100 — based on HRV analysis',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RRChart extends StatelessWidget {
  final List<int> intervals;
  const _RRChart({required this.intervals});

  @override
  Widget build(BuildContext context) {
    final spots = intervals
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

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
          const Text('RR Intervals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(unit, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }
}

class _NotConnectedView extends StatelessWidget {
  const _NotConnectedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Connect your watch to view heart data',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
