import 'dart:math';
import '../models/health_models.dart';

class HealthAnalysisService {
  static int computeHealthScore({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    required ActivityData activity,
    required SleepData sleep,
  }) {
    double score = 100;

    // Heart rate (25 pts)
    if (hr.bpm > 0) {
      if (hr.bpm >= 60 && hr.bpm <= 100) {
        score += 0;
      } else if (hr.bpm < 50 || hr.bpm > 110) {
        score -= 20;
      } else {
        score -= 10;
      }
      if (hr.afibProbability > 60) score -= 20;
    }

    // Blood pressure (25 pts)
    if (bp.systolic > 0) {
      if (bp.systolic < 120 && bp.diastolic < 80) {
        score += 0;
      } else if (bp.systolic >= 140 || bp.diastolic >= 90) {
        score -= 25;
      } else if (bp.systolic >= 130) {
        score -= 12;
      } else {
        score -= 5;
      }
    }

    // SpO2 (25 pts)
    if (o2.spO2 > 0) {
      if (o2.spO2 >= 95) {
        score += 0;
      } else if (o2.spO2 >= 90) {
        score -= 15;
      } else {
        score -= 25;
      }
    }

    // Activity (12.5 pts)
    final stepProgress = (activity.steps / 10000).clamp(0.0, 1.0);
    score -= (1 - stepProgress) * 12.5;

    // Sleep (12.5 pts)
    if (sleep.totalMinutes < 300) score -= 12.5;
    else if (sleep.totalMinutes < 420) score -= 6;

    return score.round().clamp(0, 100);
  }

  static String heartRateZone(int bpm) {
    if (bpm < 50) return 'Very Low';
    if (bpm < 60) return 'Low';
    if (bpm < 100) return 'Normal';
    if (bpm < 130) return 'Moderate';
    if (bpm < 160) return 'Hard';
    return 'Maximum';
  }

  static double stressIndex(HeartRateData hr) {
    if (hr.hrv == 0) return 0;
    // Higher HRV = lower stress
    final stressRaw = 100 - (hr.hrv.clamp(10, 100) - 10) / 90 * 100;
    return stressRaw.clamp(0, 100);
  }

  static List<String> healthAlerts({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
  }) {
    final alerts = <String>[];
    if (hr.bpm > 0 && (hr.bpm < 50 || hr.bpm > 120)) {
      alerts.add('Abnormal heart rate: ${hr.bpm} BPM');
    }
    if (hr.afibProbability > 60) {
      alerts.add('Possible AFib detected (${hr.afibProbability}% probability)');
    }
    if (bp.systolic >= 140 || bp.diastolic >= 90) {
      alerts.add('High blood pressure: ${bp.systolic}/${bp.diastolic} mmHg');
    }
    if (o2.spO2 > 0 && o2.spO2 < 90) {
      alerts.add('Low blood oxygen: ${o2.spO2}%');
    }
    return alerts;
  }

  static List<Map<String, dynamic>> bpCategoryInfo() => [
    {'label': 'Normal', 'systolic': '<120', 'diastolic': '<80', 'color': 0xFF22C55E},
    {'label': 'Elevated', 'systolic': '120-129', 'diastolic': '<80', 'color': 0xFFF59E0B},
    {'label': 'High Stage 1', 'systolic': '130-139', 'diastolic': '80-89', 'color': 0xFFF97316},
    {'label': 'High Stage 2', 'systolic': '≥140', 'diastolic': '≥90', 'color': 0xFFEF4444},
    {'label': 'Hypertensive Crisis', 'systolic': '>180', 'diastolic': '>120', 'color': 0xFF991B1B},
  ];

  static SleepData generateTypicalSleepData() {
    final now = DateTime.now();
    return SleepData(
      bedtime: now.subtract(const Duration(hours: 8, minutes: 15)),
      wakeTime: now,
      deepSleepMinutes: 105,
      lightSleepMinutes: 220,
      remSleepMinutes: 115,
      awakeMinutes: 20,
      qualityScore: 78,
    );
  }
}
