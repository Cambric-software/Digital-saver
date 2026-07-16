import 'dart:math';
import '../models/health_models.dart';

/// Enhanced Health Analysis Service with sophisticated algorithms
/// for accurate health monitoring and scoring
class HealthAnalysisService {
  // ===========================================================================
  // CONSTANTS & THRESHOLDS (Based on Medical Research)
  // ===========================================================================
  
  // Heart Rate Zones (American Heart Association Guidelines)
  static const Map<String, Map<String, dynamic>> heartRateZones = {
    'rest': {'min': 0, 'max': 60, 'color': 0xFF94A3B8, 'description': 'Resting/Recovery'},
    'fatBurn': {'min': 60, 'max': 100, 'color': 0xFF22C55E, 'description': 'Fat Burn Zone'},
    'cardio': {'min': 100, 'max': 140, 'color': 0xFFF59E0B, 'description': 'Cardio/Aerobic'},
    'peak': {'min': 140, 'max': 170, 'color': 0xFFEF4444, 'description': 'Peak Performance'},
    'max': {'min': 170, 'max': 220, 'color': 0xFF7C3AED, 'description': 'Maximum Effort'},
  };

  // HRV Reference Ranges (Medical Research Standards)
  static const Map<String, Map<String, int>> hrvRanges = {
    'excellent': {'min': 60, 'max': 100},
    'good': {'min': 40, 'max': 59},
    'moderate': {'min': 25, 'max': 39},
    'low': {'min': 15, 'max': 24},
    'poor': {'min': 0, 'max': 14},
  };

  // Age-adjusted heart rate calculations
  static int get maxHeartRate => 220; // Default formula
  static int getTargetHeartRateZone(int age, double intensity) {
    int maxHR = 220 - age;
    int minHR = (maxHR * (0.5 + intensity * 0.4)).round();
    int maxZoneHR = (maxHR * (0.6 + intensity * 0.35)).round();
    return (minHR + maxZoneHR) ~/ 2;
  }

  // ===========================================================================
  // ENHANCED HEALTH SCORE CALCULATION
  // ===========================================================================
  
  /// Computes a comprehensive health score (0-100) based on multiple factors
  /// Uses weighted algorithm with confidence adjustments
  static int computeHealthScore({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    required ActivityData activity,
    required SleepData sleep,
    int? userAge,
    double confidenceThreshold = 0.7,
  }) {
    if (userAge == null) userAge = 40; // Default age if not provided

    double totalScore = 100.0;
    int factorCount = 0;
    double confidenceMultiplier = 1.0;

    // Calculate confidence based on data availability
    if (hr.bpm > 0) {
      double hrConfidence = hr.confidence / 100.0;
      double hrContribution = _calculateHeartRateScore(hr, userAge);
      totalScore += _weightedContribution(hrContribution, 25.0, hrConfidence);
      factorCount++;
      confidenceMultiplier *= (0.5 + hrConfidence * 0.5);
    }

    if (bp.systolic > 0 && bp.diastolic > 0) {
      double bpConfidence = bp.confidence / 100.0;
      double bpContribution = _calculateBloodPressureScore(bp, userAge);
      totalScore += _weightedContribution(bpContribution, 25.0, bpConfidence);
      factorCount++;
      confidenceMultiplier *= (0.5 + bpConfidence * 0.5);
    }

    if (o2.spO2 > 0) {
      double o2Confidence = o2.confidence / 100.0;
      double o2Contribution = _calculateOxygenScore(o2);
      totalScore += _weightedContribution(o2Contribution, 20.0, o2Confidence);
      factorCount++;
      confidenceMultiplier *= (0.5 + o2Confidence * 0.5);
    }

    // Activity score (weighted by goal achievement)
    double activityScore = _calculateActivityScore(activity);
    totalScore += _weightedContribution(activityScore, 15.0, 0.95);

    // Sleep score
    double sleepScore = _calculateSleepScore(sleep);
    totalScore += _weightedContribution(sleepScore, 15.0, 0.85);

    // Apply HRV bonus/penalty
    if (hr.hrv > 0) {
      totalScore += _calculateHrvBonus(hr.hrv);
    }

    // Apply AFib penalty if detected
    if (hr.afibProbability > 50) {
      totalScore -= (hr.afibProbability - 50) * 0.3;
    }

    // Normalize based on factor count
    if (factorCount > 0) {
      double normalizationFactor = (5.0 / factorCount).clamp(0.8, 1.0);
      totalScore = 100.0 - ((100.0 - totalScore) * normalizationFactor);
    }

    return totalScore.round().clamp(0, 100);
  }

  static double _weightedContribution(double score, double maxPoints, double confidence) {
    double normalizedScore = (score - 50) / 50.0; // -1 to 1
    return normalizedScore * maxPoints * confidence;
  }

  static double _calculateHeartRateScore(HeartRateData hr, int age) {
    double score = 100.0;
    int maxHR = 220 - age;
    
    // Resting heart rate analysis
    if (hr.bpm >= 60 && hr.bpm <= 100) {
      // Normal range
      if (hr.bpm >= 60 && hr.bpm <= 80) {
        score = 90.0 + (80 - hr.bpm) * 0.5; // Lower is generally better
      } else {
        score = 90.0 - (hr.bpm - 80) * 0.5;
      }
    } else if (hr.bpm < 50 || hr.bpm > maxHR * 0.9) {
      // Critical
      if (hr.bpm < 50) {
        score = 40.0 - (50 - hr.bpm) * 2;
      } else {
        score = 40.0 - ((hr.bpm - maxHR * 0.9) * 0.5).clamp(0, 40);
      }
    } else {
      // Warning range
      score = 70.0;
    }

    // HRV influence on score
    if (hr.hrv > 0) {
      if (hr.hrv >= 50) {
        score += 5.0; // Good HRV bonus
      } else if (hr.hrv < 25) {
        score -= 10.0; // Poor HRV penalty
      }
    }

    return score.clamp(0, 100);
  }

  static double _calculateBloodPressureScore(BloodPressureData bp, int age) {
    double score = 100.0;
    
    // Systolic-based scoring (more nuanced)
    if (bp.systolic < 90) {
      score = 50.0; // Too low
    } else if (bp.systolic >= 90 && bp.systolic < 100) {
      score = 75.0; // Low normal
    } else if (bp.systolic >= 100 && bp.systolic < 120) {
      score = 95.0 + (120 - bp.systolic) * 0.25; // Optimal
    } else if (bp.systolic >= 120 && bp.systolic < 130) {
      score = 85.0; // Elevated
    } else if (bp.systolic >= 130 && bp.systolic < 140) {
      score = 70.0; // High Stage 1
    } else if (bp.systolic >= 140 && bp.systolic < 160) {
      score = 50.0 - (bp.systolic - 140) * 0.5; // High Stage 2
    } else if (bp.systolic >= 160 && bp.systolic < 180) {
      score = 40.0; // Hypertensive Crisis
    } else {
      score = 20.0; // Severe Hypertensive Crisis
    }

    // Diastolic adjustment
    if (bp.diastolic >= 80 && bp.diastolic < 90) {
      score -= 10.0;
    } else if (bp.diastolic >= 90) {
      score -= 20.0;
    }

    // MAP consideration
    if (bp.map > 0) {
      if (bp.map >= 70 && bp.map <= 100) {
        score += 5.0; // Good MAP range
      } else if (bp.map > 100 && bp.map <= 110) {
        score -= 5.0;
      } else if (bp.map > 110) {
        score -= 15.0;
      }
    }

    return score.clamp(0, 100);
  }

  static double _calculateOxygenScore(OxygenData o2) {
    double score = 100.0;

    if (o2.spO2 >= 95) {
      score = 100.0;
    } else if (o2.spO2 >= 93 && o2.spO2 < 95) {
      score = 85.0 + (o2.spO2 - 93) * 5.0; // 85-95
    } else if (o2.spO2 >= 90 && o2.spO2 < 93) {
      score = 60.0 + (o2.spO2 - 90) * 8.33; // 60-85
    } else if (o2.spO2 >= 85 && o2.spO2 < 90) {
      score = 40.0 + (o2.spO2 - 85) * 4.0; // 40-60 (critical zone)
    } else {
      score = 40.0 - (85 - o2.spO2) * 2.0; // Below critical
    }

    // Perfusion index influence
    if (o2.perfusionIndex > 0) {
      if (o2.perfusionIndex >= 5) {
        score += 5.0; // Good perfusion
      } else if (o2.perfusionIndex < 2) {
        score -= 10.0; // Poor perfusion signal quality
      }
    }

    return score.clamp(0, 100);
  }

  static double _calculateActivityScore(ActivityData activity) {
    double score = 100.0;
    
    // Step progress (primary metric)
    double stepProgress = (activity.steps / 10000).clamp(0.0, 1.0);
    score -= (1 - stepProgress) * 20.0;

    // Active minutes bonus
    if (activity.activeMinutes >= 30) {
      score += 5.0;
    } else if (activity.activeMinutes >= 60) {
      score += 10.0;
    }

    // Calorie burn relative to steps
    double expectedCalories = activity.steps * 0.04; // ~40 cal per 1000 steps
    if (activity.calories > expectedCalories * 0.8) {
      score += 5.0; // Good intensity
    }

    return score.clamp(0, 100);
  }

  static double _calculateSleepScore(SleepData sleep) {
    double score = 100.0;
    int totalHours = sleep.totalMinutes ~/ 60;

    // Duration scoring (optimal: 7-9 hours)
    if (totalHours >= 7 && totalHours <= 9) {
      score = 100.0;
    } else if (totalHours >= 6 && totalHours < 7) {
      score = 85.0 + (totalHours - 6) * 15.0;
    } else if (totalHours > 9 && totalHours <= 10) {
      score = 85.0 + (10 - totalHours) * 15.0;
    } else if (totalHours >= 5 && totalHours < 6) {
      score = 60.0 + (totalHours - 5) * 25.0;
    } else if (totalHours < 5) {
      score = 60.0 - (5 - totalHours) * 10.0;
    } else {
      score = 70.0; // Oversleeping
    }

    // Sleep quality distribution
    double deepSleepRatio = sleep.deepSleepMinutes / (sleep.totalMinutes + 1);
    double remSleepRatio = sleep.remSleepMinutes / (sleep.totalMinutes + 1);
    
    // Optimal: Deep 15-25%, REM 20-25%
    if (deepSleepRatio >= 0.15 && deepSleepRatio <= 0.30) {
      score += 5.0;
    } else if (deepSleepRatio < 0.10) {
      score -= 15.0; // Insufficient deep sleep
    }

    if (remSleepRatio >= 0.18 && remSleepRatio <= 0.28) {
      score += 5.0;
    } else if (remSleepRatio < 0.15) {
      score -= 10.0;
    }

    // Awake time penalty
    if (sleep.awakeMinutes > 30) {
      score -= (sleep.awakeMinutes - 30) * 0.5;
    }

    return score.clamp(0, 100);
  }

  static double _calculateHrvBonus(int hrv) {
    if (hrv >= 60) return 5.0;
    if (hrv >= 50) return 3.0;
    if (hrv >= 40) return 1.0;
    if (hrv >= 30) return 0.0;
    if (hrv >= 20) return -3.0;
    return -5.0;
  }

  // ===========================================================================
  // HEART RATE ANALYSIS
  // ===========================================================================

  static String heartRateZone(int bpm) {
    if (bpm < 50) return 'Very Low';
    if (bpm < 60) return 'Low';
    if (bpm < 100) return 'Normal';
    if (bpm < 130) return 'Moderate';
    if (bpm < 160) return 'Hard';
    return 'Maximum';
  }

  static String getHeartRateZone2(int bpm) {
    double intensity = _calculateIntensity(bpm);
    if (intensity < 0.5) return 'Light';
    if (intensity < 0.7) return 'Moderate';
    if (intensity < 0.85) return 'Vigorous';
    return 'Peak';
  }

  static double _calculateIntensity(int bpm) {
    int maxHR = 220 - 40; // Assuming age 40
    return (bpm / maxHR).clamp(0.0, 1.0);
  }

  // ===========================================================================
  // STRESS INDEX CALCULATION
  // ===========================================================================

  /// Calculates stress index based on HRV and heart rate variability
  /// Uses multiple HRV metrics for accuracy
  static double stressIndex(HeartRateData hr) {
    if (hr.hrv == 0) return 0;
    
    // Primary: RMSSD-based stress
    double baseStress = 100 - (hr.hrv.clamp(10, 100) - 10) * 1.1;
    
    // Secondary: Adjust based on pNN50 if available
    if (hr.pnn50 > 0) {
      if (hr.pnn50 > 30) {
        baseStress *= 0.85; // Relaxed
      } else if (hr.pnn50 < 10) {
        baseStress *= 1.15; // Stressed
      }
    }

    // Tertiary: SDNN influence
    if (hr.sdnn > 0) {
      if (hr.sdnn > 80) {
        baseStress *= 0.9; // Good variability
      } else if (hr.sdnn < 40) {
        baseStress *= 1.1; // Poor variability
      }
    }

    return baseStress.clamp(0, 100);
  }

  /// Returns stress level label
  static String getStressLabel(double stress) {
    if (stress < 20) return 'Very Relaxed';
    if (stress < 40) return 'Relaxed';
    if (stress < 60) return 'Moderate';
    if (stress < 80) return 'Stressed';
    return 'High Stress';
  }

  // ===========================================================================
  // HRV ANALYSIS
  // ===========================================================================

  /// Classifies HRV level based on RMSSD value
  static String classifyHrv(int hrv) {
    if (hrv >= 60) return 'Excellent';
    if (hrv >= 40) return 'Good';
    if (hrv >= 25) return 'Moderate';
    if (hrv >= 15) return 'Low';
    return 'Poor';
  }

  /// Calculates SDNN from RMSSD (approximate relationship)
  static int estimateSdnn(int rmssd) {
    return (rmssd * 1.3).round(); // Empirical relationship
  }

  /// Calculates pNN50 from RMSSD (approximate)
  static int estimatePnn50(int rmssd) {
    // pNN50 ≈ (RMSSD - 15) / 0.85, clamped
    return ((rmssd - 15) / 0.85).clamp(0, 100).round();
  }

  // ===========================================================================
  // BLOOD PRESSURE ANALYSIS
  // ===========================================================================

  /// Categorizes blood pressure based on AHA/ACC guidelines
  static String? getBPCategory(double systolic, double diastolic) {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic >= 130 && systolic < 140 || diastolic >= 80 && diastolic < 90) return 'High Stage 1';
    if (systolic >= 140 || diastolic >= 90) return 'High Stage 2';
    if (systolic > 180 || diastolic > 120) return 'Hypertensive Crisis';
    return null;
  }

  /// Estimates vascular age based on blood pressure
  static int estimateVascularAge(double systolic, double diastolic) {
    // Based on pulse wave velocity estimation
    int baseAge = 30;
    
    if (systolic < 110) return baseAge;
    
    if (systolic < 120) return baseAge + 5;
    if (systolic < 130) return baseAge + 15;
    if (systolic < 140) return baseAge + 25;
    if (systolic < 150) return baseAge + 30;
    if (systolic < 160) return baseAge + 35;
    
    return baseAge + 40; // High risk
  }

  /// Calculates Mean Arterial Pressure (MAP)
  static double calculateMAP(double systolic, double diastolic) {
    return (systolic + 2 * diastolic) / 3;
  }

  /// Calculates Pulse Pressure
  static int calculatePulsePressure(double systolic, double diastolic) {
    return (systolic - diastolic).round();
  }

  /// Estimates cardiovascular risk score
  static double calculateCVRisk({
    required double systolic,
    required double diastolic,
    required int age,
    required bool isSmoker,
    required bool hasDiabetes,
    required double cholesterolRatio,
  }) {
    double risk = 0;

    // Blood pressure contribution
    if (systolic >= 140 || diastolic >= 90) {
      risk += 30;
    } else if (systolic >= 130 || diastolic >= 85) {
      risk += 20;
    } else if (systolic >= 120 || diastolic >= 80) {
      risk += 10;
    }

    // Age contribution
    if (age >= 65) risk += 20;
    else if (age >= 55) risk += 15;
    else if (age >= 45) risk += 10;

    // Lifestyle factors
    if (isSmoker) risk += 15;
    if (hasDiabetes) risk += 15;
    if (cholesterolRatio > 5) risk += 10;
    if (cholesterolRatio > 4) risk += 5;

    return risk.clamp(0, 100);
  }

  // ===========================================================================
  // SLEEP ANALYSIS
  // ===========================================================================

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

  /// Calculates sleep efficiency
  static double calculateSleepEfficiency(SleepData sleep) {
    int totalTimeInBed = sleep.totalMinutes + sleep.awakeMinutes;
    if (totalTimeInBed == 0) return 0;
    return (sleep.totalMinutes / totalTimeInBed) * 100;
  }

  /// Estimates sleep debt in hours
  static double calculateSleepDebt({
    required int actualSleepMinutes,
    required int targetSleepMinutes = 480, // 8 hours default
    required int daysTracked = 7,
  }) {
    int totalSleepNeeded = targetSleepMinutes * daysTracked;
    int totalSleepActual = actualSleepMinutes;
    int deficit = totalSleepNeeded - totalSleepActual;
    return (deficit / 60.0).clamp(0, 100); // Hours of debt
  }

  // ===========================================================================
  // ACTIVITY ANALYSIS
  // ===========================================================================

  /// Calculates calories burned from steps
  static double calculateCaloriesFromSteps(int steps, {double? weightKg}) {
    // MET-based calculation
    double metValue = 3.5; // Walking MET
    double weight = weightKg ?? 70.0;
    double hours = steps / 1000 * 0.1; // Approximate walking time
    return metValue * weight * hours / 60;
  }

  /// Estimates distance from steps
  static double calculateDistanceKm(int steps, {double? heightCm}) {
    // Average stride length approximation
    double strideLength = (heightCm ?? 170) * 0.415 / 100; // meters
    return (steps * strideLength) / 1000;
  }

  /// Calculates active minutes goal progress
  static double calculateActiveMinutesProgress(int activeMinutes, {int target = 30}) {
    return (activeMinutes / target).clamp(0.0, 1.0);
  }

  // ===========================================================================
  // ALERTS & WARNINGS
  // ===========================================================================

  static List<String> healthAlerts({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    bool fallDetected = false,
    bool irregularHR = false,
  }) {
    final alerts = <String>[];

    // Heart rate alerts
    if (hr.bpm > 0) {
      if (hr.bpm < 40) {
        alerts.add('⚠️ CRITICAL: Very low heart rate (${hr.bpm} BPM) - Bradycardia detected. Seek immediate medical attention.');
      } else if (hr.bpm < 50) {
        alerts.add('⚡ Low heart rate: ${hr.bpm} BPM - May indicate bradycardia.');
      } else if (hr.bpm > 120) {
        alerts.add('⚡ High heart rate: ${hr.bpm} BPM - May indicate tachycardia.');
      } else if (hr.bpm > 150) {
        alerts.add('🚨 CRITICAL: Very high heart rate (${hr.bpm} BPM) - Immediate rest recommended.');
      }
    }

    // AFib alerts
    if (hr.afibProbability > 70) {
      alerts.add('🚨 CRITICAL: High AFib probability (${hr.afibProbability}%) - Irregular heartbeat pattern detected. Consult a doctor.');
    } else if (hr.afibProbability > 50) {
      alerts.add('⚠️ Possible AFib detected (${hr.afibProbability}% probability) - Monitor closely.');
    }

    if (irregularHR) {
      alerts.add('⚠️ Irregular heart rhythm detected - Possible arrhythmia.');
    }

    // Blood pressure alerts
    if (bp.systolic > 0) {
      if (bp.systolic > 180 || bp.diastolic > 120) {
        alerts.add('🚨 CRITICAL: Hypertensive Crisis (${bp.systolic}/${bp.diastolic} mmHg) - Seek emergency care immediately!');
      } else if (bp.systolic >= 140 || bp.diastolic >= 90) {
        alerts.add('⚡ High blood pressure: ${bp.systolic}/${bp.diastolic} mmHg - Consider lifestyle changes.');
      } else if (bp.systolic < 90) {
        alerts.add('⚡ Low blood pressure: ${bp.systolic}/${bp.diastolic} mmHg - May cause dizziness.');
      }
    }

    // SpO2 alerts
    if (o2.spO2 > 0) {
      if (o2.spO2 < 85) {
        alerts.add('🚨 CRITICAL: Severe hypoxemia (${o2.spO2}% SpO₂) - Seek immediate medical attention!');
      } else if (o2.spO2 < 90) {
        alerts.add('⚠️ Low blood oxygen: ${o2.spO2}% SpO₂ - Below normal range.');
      } else if (o2.spO2 < 94) {
        alerts.add('⚡ Slightly low oxygen: ${o2.spO2}% SpO₂ - Monitor closely.');
      }
    }

    // Fall detection
    if (fallDetected) {
      alerts.add('🚨 Fall detected! Please confirm you are okay. Emergency contacts have been notified.');
    }

    return alerts;
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  static List<Map<String, dynamic>> bpCategoryInfo() => [
    {'label': 'Normal', 'systolic': '<120', 'diastolic': '<80', 'color': 0xFF22C55E, 'advice': 'Maintain healthy lifestyle'},
    {'label': 'Elevated', 'systolic': '120-129', 'diastolic': '<80', 'color': 0xFFF59E0B, 'advice': 'Monitor regularly, reduce sodium'},
    {'label': 'High Stage 1', 'systolic': '130-139', 'diastolic': '80-89', 'color': 0xFFF97316, 'advice': 'Lifestyle changes needed, consult doctor'},
    {'label': 'High Stage 2', 'systolic': '≥140', 'diastolic': '≥90', 'color': 0xFFEF4444, 'advice': 'See a doctor, may need medication'},
    {'label': 'Hypertensive Crisis', 'systolic': '>180', 'diastolic': '>120', 'color': 0xFF991B1B, 'advice': 'EMERGENCY - Seek immediate care!'},
  ];

  /// Generates personalized health tips based on current readings
  static List<String> generateHealthTips({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    required ActivityData activity,
    required SleepData sleep,
  }) {
    final tips = <String>[];

    // Heart rate tips
    if (hr.bpm > 80) {
      tips.add('💓 Your resting heart rate is elevated. Try relaxation techniques like deep breathing.');
    } else if (hr.bpm < 60 && hr.bpm > 0) {
      tips.add('💓 Low resting heart rate may indicate good fitness or require medical evaluation.');
    }

    if (hr.hrv > 0 && hr.hrv < 30) {
      tips.add('🧘 Your HRV is low. Consider meditation, better sleep, and stress management.');
    }

    // Blood pressure tips
    if (bp.systolic >= 120 || bp.diastolic >= 80) {
      tips.add('🩺 Your blood pressure could be improved. Reduce sodium intake and exercise regularly.');
    }
    if (bp.systolic >= 140 || bp.diastolic >= 90) {
      tips.add('⚠️ High blood pressure detected. Please consult your healthcare provider.');
    }

    // Oxygen tips
    if (o2.spO2 > 0 && o2.spO2 < 95) {
      tips.add('🌬️ Your oxygen saturation could be better. Practice deep breathing exercises.');
    }

    // Activity tips
    if (activity.steps < 5000) {
      tips.add('🚶 You\'re below your daily step goal. Take short walks throughout the day.');
    }
    if (activity.steps >= 10000) {
      tips.add('🏆 Great job! You\'ve reached your daily step goal.');
    }

    // Sleep tips
    if (sleep.totalMinutes < 420) {
      tips.add('😴 You may be undersleeping. Aim for 7-9 hours of quality sleep.');
    }
    if (sleep.deepSleepMinutes < 60) {
      tips.add('💤 Your deep sleep could be improved. Avoid screens before bed.');
    }

    if (tips.isEmpty) {
      tips.add('✨ Your health metrics look good! Keep maintaining your healthy habits.');
    }

    return tips;
  }
}
