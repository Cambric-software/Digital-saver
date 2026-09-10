import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_analysis_service.dart';
import '../services/local_store.dart';
import '../models/health_models.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  SleepData? _realSleep;
  bool _hasRealData = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSleepFromHistory();
  }

  Future<void> _loadSleepFromHistory() async {
    final samples = await LocalStore.loadAll();
    if (!mounted) return;

    if (samples.isEmpty) {
      setState(() { _loading = false; });
      return;
    }

    // Look for samples from yesterday night and this morning to derive
    // bedtime → wake-time window from the last night's HR data.
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // Collect last 24 hours of samples.
    final recent = samples
        .where((s) => s.at.isAfter(yesterday))
        .toList()
      ..sort((a, b) => a.unix.compareTo(b.unix));

    if (recent.isEmpty) {
      setState(() { _loading = false; });
      return;
    }

    // Derive sleep window: contiguous low-HR (< 70 bpm) block at night hours.
    // A simple heuristic: find a ≥ 3-hour block where hr < 70 or hr == 0
    // between 20:00 and 12:00 the next day.
    DateTime? bedtime;
    DateTime? wakeTime;
    int deepMin = 0, lightMin = 0, remMin = 0, awakeMin = 0;
    int totalSamples = 0;
    double hrSum = 0;

    for (final s in recent) {
      final h = s.at.hour;
      final isSleepHour = h >= 20 || h < 12;
      if (!isSleepHour) continue;

      final lowHr = s.hr == 0 || (s.hr > 0 && s.hr < 75);
      if (lowHr) {
        bedtime ??= s.at;
        wakeTime = s.at;
        totalSamples++;
        if (s.hr > 0) hrSum += s.hr;

        // Very rough stage classification from HR
        if (s.hr == 0 || s.hr < 55) {
          deepMin++;
        } else if (s.hr < 65) {
          remMin++;
        } else {
          lightMin++;
        }
      } else if (bedtime != null) {
        // Gap — count as awake
        awakeMin++;
      }
    }

    if (bedtime == null || wakeTime == null || totalSamples < 3) {
      // Not enough data — fall through to generated typical data
      setState(() { _loading = false; });
      return;
    }

    final totalMinutes = deepMin + lightMin + remMin;
    final avgHr = totalSamples > 0 ? (hrSum / totalSamples).round() : 60;
    final qualityScore = _computeSleepQuality(totalMinutes, deepMin, remMin, awakeMin);

    setState(() {
      _realSleep = SleepData(
        bedtime: bedtime!,
        wakeTime: wakeTime!,
        deepSleepMinutes: deepMin,
        lightSleepMinutes: lightMin,
        remSleepMinutes: remMin,
        awakeMinutes: awakeMin,
        qualityScore: qualityScore,
      );
      _hasRealData = true;
      _loading = false;
    });
  }

  int _computeSleepQuality(int total, int deep, int rem, int awake) {
    int score = 100;
    final hours = total / 60.0;
    if (hours < 5) score -= 40;
    else if (hours < 6) score -= 20;
    else if (hours < 7) score -= 10;
    else if (hours > 10) score -= 10;
    final deepRatio = total > 0 ? deep / total : 0;
    if (deepRatio < 0.10) score -= 20;
    else if (deepRatio > 0.30) score += 5;
    if (awake > 30) score -= 10;
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sleep = _realSleep ?? HealthAnalysisService.generateTypicalSleepData();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Sleep', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e3a5f),
        elevation: 0,
        actions: [
          if (!_hasRealData)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('Demo data', style: TextStyle(fontSize: 11)),
                backgroundColor: Color(0xFFFFF3E0),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSleepFromHistory,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (!_hasRealData)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'No watch sleep data found yet. Wear your Veyro overnight and sync. Showing example data.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    )),
                  ]),
                ),
              _SleepHero(sleep: sleep),
              const SizedBox(height: 16),
              _SleepStages(sleep: sleep),
              const SizedBox(height: 16),
              _SleepDonut(sleep: sleep),
              const SizedBox(height: 16),
              _SleepTips(score: sleep.qualityScore),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepHero extends StatelessWidget {
  final SleepData sleep;
  const _SleepHero({required this.sleep});

  Color get _color {
    if (sleep.qualityScore >= 80) return const Color(0xFF22C55E);
    if (sleep.qualityScore >= 60) return const Color(0xFF2563eb);
    if (sleep.qualityScore >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e3a5f), Color(0xFF7c3aed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.bedtime, color: Colors.white, size: 36),
          const SizedBox(height: 16),
          Text(
            sleep.duration,
            style: const TextStyle(
              color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold, height: 1,
            ),
          ),
          const Text('total sleep', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Quality: ', style: TextStyle(color: Colors.white70)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${sleep.qualityLabel} (${sleep.qualityScore}/100)',
                  style: TextStyle(color: _color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TimeInfo(label: 'Bedtime', time: _formatTime(sleep.bedtime)),
              Container(width: 1, height: 30, color: Colors.white24),
              _TimeInfo(label: 'Wake up', time: _formatTime(sleep.wakeTime)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _TimeInfo extends StatelessWidget {
  final String label, time;
  const _TimeInfo({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _SleepStages extends StatelessWidget {
  final SleepData sleep;
  const _SleepStages({required this.sleep});

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
          const Text('Sleep Stages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          _StageBar(label: 'Deep Sleep', minutes: sleep.deepSleepMinutes, color: const Color(0xFF1e3a5f), total: sleep.totalMinutes),
          const SizedBox(height: 10),
          _StageBar(label: 'REM Sleep', minutes: sleep.remSleepMinutes, color: const Color(0xFF7c3aed), total: sleep.totalMinutes),
          const SizedBox(height: 10),
          _StageBar(label: 'Light Sleep', minutes: sleep.lightSleepMinutes, color: const Color(0xFF2563eb), total: sleep.totalMinutes),
          const SizedBox(height: 10),
          _StageBar(label: 'Awake', minutes: sleep.awakeMinutes, color: Colors.grey.shade400, total: sleep.totalMinutes + sleep.awakeMinutes),
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  final String label;
  final int minutes, total;
  final Color color;
  const _StageBar({required this.label, required this.minutes, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final frac = total > 0 ? (minutes / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 13)),
              ],
            ),
            Text('${h > 0 ? '${h}h ' : ''}${m}m', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: frac,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _SleepDonut extends StatelessWidget {
  final SleepData sleep;
  const _SleepDonut({required this.sleep});

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
        children: [
          const Text('Stage Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(value: sleep.deepSleepMinutes.toDouble(), color: const Color(0xFF1e3a5f), title: 'Deep', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: sleep.remSleepMinutes.toDouble(), color: const Color(0xFF7c3aed), title: 'REM', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: sleep.lightSleepMinutes.toDouble(), color: const Color(0xFF2563eb), title: 'Light', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: sleep.awakeMinutes.toDouble(), color: Colors.grey.shade300, title: '', radius: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepTips extends StatelessWidget {
  final int score;
  const _SleepTips({required this.score});

  List<String> get tips {
    if (score >= 80) {
      return ['Great sleep! Keep your consistent schedule.', 'Your deep sleep ratio is healthy.'];
    } else if (score >= 60) {
      return ['Try sleeping 30 min earlier for better deep sleep.', 'Avoid screens 1 hour before bed.'];
    } else {
      return ['Your sleep quality needs improvement.', 'Maintain a consistent sleep/wake schedule.', 'Reduce caffeine after 2 PM.'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Color(0xFF7c3aed), size: 20),
              SizedBox(width: 8),
              Text('Sleep Tips', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7c3aed), fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF7c3aed), fontWeight: FontWeight.bold)),
                Expanded(child: Text(t, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
