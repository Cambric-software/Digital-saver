import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/health_analysis_service.dart';
import '../theme/app_theme.dart';

class BpScreen extends StatelessWidget {
  const BpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final parts = ble.bloodPressure.split('/');
    final sys = parts.length == 2 ? double.tryParse(parts[0]) ?? 0 : 0.0;
    final dia = parts.length == 2 ? double.tryParse(parts[1]) ?? 0 : 0.0;
    final bpCategory = ble.isConnected ? HealthAnalysisService.getBPCategory(sys, dia) : null;
    final vasAge = ble.isConnected && sys > 0 ? HealthAnalysisService.estimateVascularAge(sys, dia) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Blood Pressure', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _BPHero(sys: sys, dia: dia, category: bpCategory),
          const SizedBox(height: 16),
          _BPMetrics(sys: sys, dia: dia, vasAge: vasAge, ble: ble),
          const SizedBox(height: 16),
          _BPGauge(sys: sys),
          const SizedBox(height: 16),
          _BPCategoryGuide(currentSys: sys, currentDia: dia),
          const SizedBox(height: 16),
          _BPTips(sys: sys),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }
}

class _BPHero extends StatelessWidget {
  final double sys, dia;
  final String? category;
  const _BPHero({required this.sys, required this.dia, this.category});

  Color get _catColor {
    switch (category) {
      case 'Normal': return AppColors.success;
      case 'Elevated': return AppColors.warning;
      case 'High Stage 1': case 'High Stage 2': return AppColors.danger;
      case 'Hypertensive Crisis': return AppColors.dangerDark;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientBP,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.coloredCard(AppColors.bpBlue),
      ),
      child: Column(children: [
        const Icon(Icons.water_drop, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        const Text('Blood Pressure', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(children: [
            const Text('SYS', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text(sys > 0 ? '${sys.round()}' : '--',
              style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, height: 1)),
          ]),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(' / ', style: TextStyle(color: Colors.white54, fontSize: 36, fontWeight: FontWeight.w300)),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('DIA', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text(dia > 0 ? '${dia.round()}' : '--',
              style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, height: 1)),
          ]),
        ]),
        const Text('mmHg', style: TextStyle(color: Colors.white60, fontSize: 14)),
        if (category != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: _catColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _catColor.withOpacity(0.5)),
            ),
            child: Text(category!.name, style: TextStyle(color: _catColor == AppColors.dangerDark ? Colors.red.shade200 : Colors.white,
              fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ]),
    );
  }
}

class _BPMetrics extends StatelessWidget {
  final double sys, dia;
  final int? vasAge;
  final BleService ble;
  const _BPMetrics({required this.sys, required this.dia, this.vasAge, required this.ble});

  @override
  Widget build(BuildContext context) {
    final map = sys > 0 ? sys - dia : 0.0;
    final pp = sys > 0 ? sys - dia : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Advanced Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Metric(label: 'Pulse Pressure', value: sys > 0 ? '${pp.round()} mmHg' : '--', subtitle: 'Normal: 40–60 mmHg', color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _Metric(label: 'MAP', value: sys > 0 ? '${((sys + 2 * dia) / 3).round()} mmHg' : '--', subtitle: 'Normal: 70–100 mmHg', color: AppColors.accent)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Metric(label: 'Vascular Age', value: vasAge != null ? '$vasAge yrs' : '--', subtitle: 'vs your actual age', color: AppColors.heartRed)),
          const SizedBox(width: 12),
          Expanded(child: _Metric(label: 'HRV Influence', value: ble.hrv > 0 ? '${ble.hrv.round()} ms' : '--', subtitle: 'Higher = better vascular tone', color: AppColors.success)),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value, subtitle;
  final Color color;
  const _Metric({required this.label, required this.value, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.3)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary, height: 1.1)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.3)),
    ]),
  );
}

class _BPGauge extends StatelessWidget {
  final double sys;
  const _BPGauge({required this.sys});

  @override
  Widget build(BuildContext context) {
    final ranges = [
      (label: 'Low', max: 90.0, color: const Color(0xFF60A5FA)),
      (label: 'Normal', max: 120.0, color: AppColors.success),
      (label: 'Elevated', max: 130.0, color: AppColors.warning),
      (label: 'High', max: 160.0, color: AppColors.danger),
      (label: 'Crisis', max: 200.0, color: AppColors.dangerDark),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Systolic Gauge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(children: ranges.map((r) {
            final w = (r.max - (r == ranges.first ? 60 : ranges[ranges.indexOf(r) - 1].max)).clamp(0, 200) / 140;
            return Expanded(
              flex: ((r.max - (r == ranges.first ? 60 : ranges[ranges.indexOf(r) - 1].max)).clamp(0, 200) / 10).round(),
              child: Container(height: 12, color: r.color),
            );
          }).toList()),
        ),
        const SizedBox(height: 8),
        if (sys > 0) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('90', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const Text('120', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const Text('130', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const Text('160', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const Text('200+', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.arrow_drop_up, color: AppColors.primary, size: 20),
            Text('Your SBP: ${sys.round()} mmHg', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ],
      ]),
    );
  }
}

class _BPCategoryGuide extends StatelessWidget {
  final double currentSys, currentDia;
  const _BPCategoryGuide({required this.currentSys, required this.currentDia});

  static const categories = [
    (name: 'Normal', sys: '< 120', dia: '< 80', color: AppColors.success, advice: 'Maintain healthy lifestyle'),
    (name: 'Elevated', sys: '120–129', dia: '< 80', color: AppColors.warning, advice: 'Monitor regularly'),
    (name: 'High Stage 1', sys: '130–139', dia: '80–89', color: AppColors.danger, advice: 'Lifestyle changes needed'),
    (name: 'High Stage 2', sys: '≥ 140', dia: '≥ 90', color: Color(0xFFB91C1C), advice: 'See a doctor'),
    (name: 'Hypertensive Crisis', sys: '> 180', dia: '> 120', color: Color(0xFF7F1D1D), advice: 'Emergency care NOW'),
  ];

  bool _isActive(String name) {
    if (currentSys <= 0) return false;
    switch (name) {
      case 'Normal': return currentSys < 120 && currentDia < 80;
      case 'Elevated': return currentSys >= 120 && currentSys < 130;
      case 'High Stage 1': return (currentSys >= 130 && currentSys < 140) || (currentDia >= 80 && currentDia < 90);
      case 'High Stage 2': return currentSys >= 140 || currentDia >= 90;
      case 'Hypertensive Crisis': return currentSys > 180 || currentDia > 120;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Classification Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('AHA / ACC Guidelines', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 14),
        ...categories.map((c) {
          final active = _isActive(c.name);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? c.color.withOpacity(0.08) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: active ? Border.all(color: c.color.withOpacity(0.4)) : null,
            ),
            child: Row(children: [
              Container(width: 4, height: 36, decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: TextStyle(fontWeight: FontWeight.bold, color: active ? c.color : AppColors.textSecondary, fontSize: 13)),
                Text('SBP ${c.sys} · DBP ${c.dia} mmHg', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ])),
              if (active) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(8)),
                child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ) else Text(c.advice, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
          );
        }),
      ]),
    );
  }
}

class _BPTips extends StatelessWidget {
  final double sys;
  const _BPTips({required this.sys});

  List<String> get _tips {
    if (sys <= 0 || sys < 120) {
      return ['Great BP! Keep exercising regularly (150 min/week).', 'Maintain a low-sodium diet (< 2300 mg/day).', 'Stay hydrated with 2–3 litres of water daily.'];
    } else if (sys < 130) {
      return ['Reduce sodium intake to < 1500 mg/day.', 'Try DASH diet: fruits, vegetables, whole grains.', 'Limit alcohol to ≤ 1 drink/day.'];
    } else {
      return ['Monitor BP twice daily at same time.', 'Walk 30 minutes daily — reduces SBP by 4–9 mmHg.', 'Consult your doctor about medication options.', 'Reduce stress with mindfulness or breathing exercises.'];
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.tips_and_updates, color: AppColors.primary, size: 18),
        SizedBox(width: 8),
        Text('Blood Pressure Tips', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
      ]),
      const SizedBox(height: 12),
      ..._tips.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4))),
        ]),
      )),
    ]),
  );
}
