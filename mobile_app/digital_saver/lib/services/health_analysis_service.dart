import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:digital_saver/models/health_models.dart';

/// Advanced Health Analysis Service with ML-like algorithms
class HealthAnalysisService extends ChangeNotifier {
  static final HealthAnalysisService _instance = HealthAnalysisService._internal();
  factory HealthAnalysisService() => _instance;
  HealthAnalysisService._internal();

  // Historical data
  final List<HeartRateData> _heartRateHistory = [];
  final List<BloodPressureData> _bpHistory = [];
  final List<OxygenData> _oxygenHistory = [];
  final List<ActivityData> _activityHistory = [];
  final List<SleepData> _sleepHistory = [];
  final List<StressData> _stressHistory = [];
  final List<HealthAlert> _alerts = [];

  // Analysis parameters
  static const int maxHistorySize = 1000;
  static const int analysisWindowSeconds = 300; // 5 minutes

  // Getters for history
  List<HeartRateData> get heartRateHistory => List.unmodifiable(_heartRateHistory);
  List<BloodPressureData> get bpHistory => List.unmodifiable(_bpHistory);
  List<OxygenData> get oxygenHistory => List.unmodifiable(_oxygenHistory);
  List<ActivityData> get activityHistory => List.unmodifiable(_activityHistory);
  List<SleepData> get sleepHistory => List.unmodifiable(_sleepHistory);
  List<StressData> get stressHistory => List.unmodifiable(_stressHistory);
  List<HealthAlert> get alerts => List.unmodifiable(_alerts);

  // Trend analysis
  TrendAnalysis get heartRateTrend => _analyzeTrend(_heartRateHistory.map((e) => e.currentBPM).toList());
  TrendAnalysis get bpTrend => _analyzeTrend(_bpHistory.map((e) => e.systolic).toList());
  TrendAnalysis get oxygenTrend => _analyzeTrend(_oxygenHistory.map((e) => e.spO2).toList());

  /// Add new data points
  void addHeartRateData(HeartRateData data) {
    _heartRateHistory.add(data);
    _trimHistory(_heartRateHistory);
    _checkForAlerts(data);
    notifyListeners();
  }

  void addBloodPressureData(BloodPressureData data) {
    _bpHistory.add(data);
    _trimHistory(_bpHistory);
    _checkBPAlerts(data);
    notifyListeners();
  }

  void addOxygenData(OxygenData data) {
    _oxygenHistory.add(data);
    _trimHistory(_oxygenHistory);
    _checkOxygenAlerts(data);
    notifyListeners();
  }

  void addActivityData(ActivityData data) {
    _activityHistory.add(data);
    _trimHistory(_activityHistory);
    notifyListeners();
  }

  void addSleepData(SleepData data) {
    _sleepHistory.add(data);
    _trimHistory(_sleepHistory);
    notifyListeners();
  }

  void addStressData(StressData data) {
    _stressHistory.add(data);
    _trimHistory(_stressHistory);
    notifyListeners();
  }

  void _trimHistory(List list) {
    while (list.length > maxHistorySize) {
      list.removeAt(0);
    }
  }

  // ============================================
  // ARRHYTHMIA DETECTION (Advanced Algorithm)
  // ============================================
  
  /// Advanced Arrhythmia Detection using multiple signal features
  ArrhythmiaAnalysisResult detectArrhythmia(List<int> rrIntervals) {
    if (rrIntervals.length < 10) {
      return ArrhythmiaAnalysisResult(
        hasArrhythmia: false,
        type: null,
        confidence: 0,
        features: {},
        riskLevel: RiskLevel.low,
      );
    }

    // Extract features
    final features = _extractRRFeatures(rrIntervals);
    
    // Calculate various metrics
    final rmssd = features['rmssd']!;
    final sdnn = features['sdnn']!;
    final pnn50 = features['pnn50']!;
    final sd1 = features['sd1']!;
    final sd2 = features['sd2']!;
    final entropy = features['entropy']!;
    
    // Poincaré plot analysis
    final poincareRatio = sd1 > 0 ? sd2 / sd1 : 0;
    
    // Determine arrhythmia type
    ArrhythmiaType? type;
    RiskLevel risk = RiskLevel.low;
    double confidence = 0;

    // Atrial Fibrillation detection
    if (_detectAFib(rrIntervals, features)) {
      type = ArrhythmiaType.atrialFibrillation;
      confidence = _calculateAFibConfidence(features);
      risk = RiskLevel.critical;
    }
    // Premature Ventricular Contractions (PVC)
    else if (pnn50 > 30 && rmssd > 150) {
      type = ArrhythmiaType.pvc;
      confidence = 70 + (pnn50 / 3).clamp(0, 20);
      risk = RiskLevel.high;
    }
    // Premature Atrial Contractions (PAC)
    else if (pnn50 > 20 && pnn50 <= 30 && rmssd > 100) {
      type = ArrhythmiaType.pac;
      confidence = 65 + (pnn50 / 2).clamp(0, 20);
      risk = RiskLevel.moderate;
    }
    // Sinus Tachycardia
    else if (features['meanRR']! < 600) {
      type = ArrhythmiaType.tachycardia;
      confidence = 80;
      risk = RiskLevel.moderate;
    }
    // Sinus Bradycardia
    else if (features['meanRR']! > 1200) {
      type = ArrhythmiaType.bradycardia;
      confidence = 80;
      risk = RiskLevel.moderate;
    }
    // High HRV
    else if (rmssd > 100) {
      type = ArrhythmiaType.highHrv;
      confidence = 60;
      risk = RiskLevel.low;
    }

    return ArrhythmiaAnalysisResult(
      hasArrhythmia: type != null && confidence > 60,
      type: type,
      confidence: confidence,
      features: features,
      riskLevel: risk,
      poincareRatio: poincareRatio,
      recommendations: _generateRecommendations(type, risk, features),
    );
  }

  Map<String, double> _extractRRFeatures(List<int> rrIntervals) {
    final n = rrIntervals.length;
    if (n < 2) return {};

    // Basic statistics
    double sum = 0;
    for (int rr in rrIntervals) sum += rr;
    final meanRR = sum / n;

    // Standard deviation
    double sumSquaredDiff = 0;
    for (int rr in rrIntervals) {
      sumSquaredDiff += pow(rr - meanRR, 2);
    }
    final sdnn = sqrt(sumSquaredDiff / n);

    // RMSSD (Root Mean Square of Successive Differences)
    double sumSquaredDiffs = 0;
    int nnCount = 0;
    for (int i = 0; i < n - 1; i++) {
      final diff = rrIntervals[i + 1] - rrIntervals[i];
      sumSquaredDiffs += diff * diff;
      if (diff.abs() > 50) nnCount++;
    }
    final rmssd = n > 1 ? sqrt(sumSquaredDiffs / (n - 1)) : 0;

    // pNN50 (Percentage of successive RR intervals differing by more than 50ms)
    final pnn50 = n > 1 ? (nnCount / (n - 1)) * 100 : 0;

    // Poincaré plot features (SD1 and SD2)
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n - 1; i++) {
      final x = rrIntervals[i].toDouble();
      final y = rrIntervals[i + 1].toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    final sd1 = sqrt(max(0, (sumX2 / (n - 1)) - pow(sumX / (n - 1), 2) - 
                      pow((sumXY / (n - 1)) - (sumX * sumY / ((n - 1) * (n - 1))), 2) / 2));
    final sd2 = sqrt(max(0, 2 * (sumX2 / (n - 1)) - pow(sumX / (n - 1), 2)));

    // Entropy (Sample Entropy)
    final entropy = _calculateSampleEntropy(rrIntervals);

    // Coefficient of Variation
    final cv = sdnn / meanRR * 100;

    return {
      'meanRR': meanRR,
      'sdnn': sdnn,
      'rmssd': rmssd,
      'pnn50': pnn50,
      'sd1': sd1,
      'sd2': sd2,
      'entropy': entropy,
      'cv': cv,
    };
  }

  double _calculateSampleEntropy(List<int> rrIntervals) {
    // Simplified sample entropy calculation
    if (rrIntervals.length < 4) return 0;
    
    double matches = 0;
    double total = 0;
    const tolerance = 0.2;
    
    for (int i = 0; i < rrIntervals.length - 2; i++) {
      for (int j = i + 1; j < rrIntervals.length - 2; j++) {
        bool similar = true;
        for (int k = 0; k < 2; k++) {
          if ((rrIntervals[i + k] - rrIntervals[j + k]).abs() / rrIntervals[i + k] > tolerance) {
            similar = false;
            break;
          }
        }
        if (similar) matches++;
        total++;
      }
    }
    
    return total > 0 ? -log(matches / total + 0.0001) : 0;
  }

  bool _detectAFib(List<int> rrIntervals, Map<String, double> features) {
    // Multi-criteria AFib detection
    final rmssd = features['rmssd']!;
    final sdnn = features['sdnn']!;
    final entropy = features['entropy']!;
    
    // High irregularity
    bool hasHighIrregularity = rmssd > 80 && sdnn / features['meanRR']! > 0.2;
    
    // Very irregular RR intervals (coefficient of variation)
    bool hasHighVariability = features['cv']! > 25;
    
    // Low sample entropy (more random pattern)
    bool hasLowEntropy = entropy < 1.5;
    
    // No clear patterns
    int patternCount = 0;
    for (int i = 2; i < rrIntervals.length; i++) {
      if ((rrIntervals[i] - rrIntervals[i-1]).abs() < 50 &&
          (rrIntervals[i-1] - rrIntervals[i-2]).abs() < 50) {
        patternCount++;
      }
    }
    bool hasNoPattern = patternCount < rrIntervals.length * 0.3;

    return (hasHighIrregularity && hasHighVariability) || 
           (hasLowEntropy && hasNoPattern);
  }

  double _calculateAFibConfidence(Map<String, double> features) {
    double confidence = 50;
    
    if (features['cv']! > 30) confidence += 20;
    else if (features['cv']! > 20) confidence += 10;
    
    if (features['entropy']! < 1.0) confidence += 15;
    else if (features['entropy']! < 1.5) confidence += 8;
    
    if (features['rmssd']! > 150) confidence += 10;
    
    return confidence.clamp(0, 100);
  }

  List<String> _generateRecommendations(ArrhythmiaType? type, RiskLevel risk, Map<String, double> features) {
    final recommendations = <String>[];

    if (type == null) {
      recommendations.add('Your heart rhythm appears normal. Continue regular monitoring.');
      return recommendations;
    }

    switch (type) {
      case ArrhythmiaType.atrialFibrillation:
        recommendations.add('AFib detected. Consult a cardiologist within 24-48 hours.');
        recommendations.add('Monitor for symptoms: palpitations, dizziness, shortness of breath.');
        recommendations.add('Avoid caffeine and alcohol until evaluated.');
        break;
      case ArrhythmiaType.pvc:
      case ArrhythmiaType.pac:
        recommendations.add('Occasional irregular beats detected. Usually benign but worth monitoring.');
        recommendations.add('Reduce stress and limit caffeine intake.');
        recommendations.add('Consult a doctor if symptoms occur or frequency increases.');
        break;
      case ArrhythmiaType.tachycardia:
        recommendations.add('Elevated heart rate detected. Try relaxation techniques.');
        recommendations.add('Stay hydrated and avoid stimulants.');
        recommendations.add('Seek medical attention if persistent or accompanied by symptoms.');
        break;
      case ArrhythmiaType.bradycardia:
        recommendations.add('Slow heart rate detected. This may be normal for athletes.');
        recommendations.add('Monitor for dizziness, fatigue, or fainting.');
        recommendations.add('Consult a doctor if symptomatic.');
        break;
      case ArrhythmiaType.highHrv:
        recommendations.add('High heart rate variability detected. This is generally positive.');
        recommendations.add('Continue regular exercise and stress management.');
        break;
    }

    if (risk == RiskLevel.critical) {
      recommendations.add('⚠️ CRITICAL: Seek immediate medical attention.');
    } else if (risk == RiskLevel.high) {
      recommendations.add('📞 Contact your healthcare provider soon.');
    }

    return recommendations;
  }

  // ============================================
  // BLOOD PRESSURE ANALYSIS
  // ============================================
  
  /// Analyze blood pressure trends and estimate vascular age
  BloodPressureAnalysis analyzeBloodPressure(List<BloodPressureData> history) {
    if (history.isEmpty) {
      return BloodPressureAnalysis(
        averageSystolic: 0,
        averageDiastolic: 0,
        variability: 0,
        trend: Trend.up,
        vascularAge: 0,
        arterialStiffness: 0,
        recommendations: [],
      );
    }

    final recent = history.take(10).toList();
    final avgSys = recent.map((e) => e.systolic).reduce((a, b) => a + b) ~/ recent.length;
    final avgDia = recent.map((e) => e.diastolic).reduce((a, b) => a + b) ~/ recent.length;
    
    // Calculate variability
    double varSys = 0;
    for (int bp in recent.map((e) => e.systolic)) {
      varSys += pow(bp - avgSys, 2);
    }
    final variability = sqrt(varSys / recent.length);
    
    // Determine trend
    final trend = _analyzeBPTrend(history);
    
    // Estimate vascular age based on arterial stiffness
    final arterialStiffness = _estimateArterialStiffness(recent);
    final vascularAge = _estimateVascularAge(arterialStiffness, avgSys, avgDia);
    
    // Generate recommendations
    final recommendations = _generateBPRecommendations(avgSys, avgDia, trend);

    return BloodPressureAnalysis(
      averageSystolic: avgSys,
      averageDiastolic: avgDia,
      variability: variability,
      trend: trend,
      vascularAge: vascularAge,
      arterialStiffness: arterialStiffness,
      recommendations: recommendations,
    );
  }

  double _estimateArterialStiffness(List<BloodPressureData> recent) {
    if (recent.isEmpty) return 0;
    
    // Calculate based on augmentation index and pulse pressure
    double totalStiffness = 0;
    for (var bp in recent) {
      // Higher AI and PP indicate stiffer arteries
      final stiffness = (bp.augmentationIndex * 0.5) + 
                        (bp.pulsePressure * 0.05);
      totalStiffness += stiffness;
    }
    
    return totalStiffness / recent.length;
  }

  int _estimateVascularAge(double stiffness, int sys, int dia) {
    // Simplified vascular age estimation
    // Assumes chronological age is passed during initialization
    
    int estimatedAge = 40; // Base age
    
    // Adjust based on blood pressure
    if (sys > 140) estimatedAge += 10;
    else if (sys > 130) estimatedAge += 5;
    
    if (dia > 90) estimatedAge += 8;
    else if (dia > 85) estimatedAge += 4;
    
    // Adjust based on arterial stiffness
    if (stiffness > 40) estimatedAge += 10;
    else if (stiffness > 30) estimatedAge += 5;
    
    return estimatedAge.clamp(20, 100);
  }

  List<String> _generateBPRecommendations(int sys, int dia, Trend trend) {
    final recommendations = <String>[];

    if (sys >= 180 || dia >= 120) {
      recommendations.add('🚨 HYPERTENSIVE CRISIS: Seek immediate medical attention!');
      recommendations.add('Take prescribed medications immediately.');
      recommendations.add('Call emergency services if symptoms present.');
    } else if (sys >= 140 || dia >= 90) {
      recommendations.add('Stage 2 Hypertension: Consult your doctor about medication options.');
      recommendations.add('Reduce sodium intake to less than 2,300mg daily.');
      recommendations.add('Increase physical activity to at least 150 minutes per week.');
    } else if (sys >= 130 || dia >= 80) {
      recommendations.add('Stage 1 Hypertension: Lifestyle modifications recommended.');
      recommendations.add('Consider DASH diet and regular exercise.');
      recommendations.add('Monitor BP regularly and consult doctor if elevated.');
    } else if (sys >= 120 && dia < 80) {
      recommendations.add('Elevated BP: Focus on preventive measures.');
      recommendations.add('Maintain healthy weight and active lifestyle.');
    } else if (sys < 90 || dia < 60) {
      recommendations.add('Low blood pressure detected. Monitor for dizziness or fainting.');
      recommendations.add('Stay hydrated and rise slowly from sitting/lying position.');
    } else {
      recommendations.add('Blood pressure is within normal range.');
      recommendations.add('Maintain current healthy habits.');
    }

    if (trend == Trend.up) {
      recommendations.add('📈 BP trending upward. Increase monitoring frequency.');
    } else if (trend == Trend.down) {
      recommendations.add('📉 BP trending downward. Continue current regimen.');
    }

    return recommendations;
  }

  // ============================================
  // STRESS ANALYSIS
  // ============================================
  
  /// Comprehensive stress level analysis
  StressAnalysisResult analyzeStress({
    required HeartRateData heartRate,
    BloodPressureData? bloodPressure,
    OxygenData? oxygen,
    ActivityData? activity,
  }) {
    // Calculate stress score components
    final hrvScore = _calculateHrvStressScore(heartRate.hrv);
    final hrScore = _calculateHRStressScore(heartRate.currentBPM);
    final variabilityScore = _calculateVariabilityStressScore(heartRate.sdnn);
    
    // Combine scores with weights
    double overallStress = 
        (hrvScore * 0.4) + 
        (hrScore * 0.3) + 
        (variabilityScore * 0.3);
    
    // Adjust for activity state
    if (activity != null && activity.currentActivity != ActivityType.resting) {
      overallStress *= 0.7; // Reduce stress impact if active
    }
    
    // Determine stress level
    StressLevel level;
    if (overallStress >= 80) level = StressLevel.veryHigh;
    else if (overallStress >= 60) level = StressLevel.high;
    else if (overallStress >= 40) level = StressLevel.moderate;
    else if (overallStress >= 20) level = StressLevel.low;
    else level = StressLevel.minimal;
    
    // Generate insights and recommendations
    final insights = _generateStressInsights(heartRate, level);
    final recommendations = _generateStressRecommendations(level);

    return StressAnalysisResult(
      overallScore: overallStress.round(),
      level: level,
      hrvScore: hrvScore.round(),
      hrScore: hrScore.round(),
      variabilityScore: variabilityScore.round(),
      insights: insights,
      recommendations: recommendations,
    );
  }

  double _calculateHrvStressScore(double hrv) {
    // Lower HRV = higher stress
    if (hrv < 20) return 90;
    if (hrv < 30) return 75;
    if (hrv < 50) return 55;
    if (hrv < 70) return 35;
    if (hrv < 100) return 20;
    return 10;
  }

  double _calculateHRStressScore(int hr) {
    // Deviation from resting HR indicates stress
    final deviation = (hr - 65).abs(); // Assuming 65 is optimal resting
    if (deviation > 40) return 85;
    if (deviation > 25) return 65;
    if (deviation > 15) return 45;
    if (deviation > 5) return 25;
    return 10;
  }

  double _calculateVariabilityStressScore(double sdnn) {
    // Very low or very high SDNN can indicate stress
    if (sdnn < 20) return 80;
    if (sdnn < 40) return 50;
    if (sdnn < 80) return 25;
    if (sdnn < 120) return 40;
    return 60;
  }

  List<String> _generateStressInsights(HeartRateData heartRate, StressLevel level) {
    final insights = <String>[];
    
    if (heartRate.hrv < 30) {
      insights.add('Very low heart rate variability indicates elevated stress response.');
    }
    
    if (heartRate.arrhythmiaDetected != null) {
      insights.add('Heart rhythm irregularities may be stress-related.');
    }
    
    if (level == StressLevel.veryHigh || level == StressLevel.high) {
      insights.add('Your nervous system is in a heightened state of alertness.');
    }
    
    return insights;
  }

  List<String> _generateStressRecommendations(StressLevel level) {
    final recommendations = <String>[];
    
    switch (level) {
      case StressLevel.veryHigh:
      case StressLevel.high:
        recommendations.add('Practice deep breathing: 4-7-8 technique');
        recommendations.add('Consider a short walk or physical activity');
        recommendations.add('Try progressive muscle relaxation');
        recommendations.add('If persistent, consider speaking with a professional');
        break;
      case StressLevel.moderate:
        recommendations.add('Take regular breaks throughout the day');
        recommendations.add('Practice mindfulness for 10-15 minutes daily');
        recommendations.add('Ensure adequate sleep (7-9 hours)');
        break;
      case StressLevel.low:
      case StressLevel.minimal:
        recommendations.add('Continue stress management practices');
        recommendations.add('Maintain work-life balance');
        break;
      case StressLevel.unknown:
        break;
    }
    
    return recommendations;
  }

  // ============================================
  // TREND ANALYSIS
  // ============================================
  
  TrendAnalysis _analyzeTrend(List<int> values) {
    if (values.length < 5) {
      return TrendAnalysis(
        direction: Trend.stable,
        changePercent: 0,
        confidence: 0,
        prediction: values.isNotEmpty ? values.last : 0,
      );
    }

    // Simple linear regression
    final n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    // Calculate R² for confidence
    final yMean = sumY / n;
    double ssTot = 0, ssRes = 0;
    for (int i = 0; i < n; i++) {
      final predicted = intercept + slope * i;
      ssTot += pow(values[i] - yMean, 2);
      ssRes += pow(values[i] - predicted, 2);
    }
    final rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0;
    
    // Predict next value
    final prediction = intercept + slope * n;
    
    // Determine trend direction
    Trend direction;
    if (slope.abs() < 0.5) {
      direction = Trend.stable;
    } else if (slope > 0) {
      direction = Trend.up;
    } else {
      direction = Trend.down;
    }
    
    // Calculate percent change
    final changePercent = values.first > 0 
        ? ((values.last - values.first) / values.first * 100)
        : 0;

    return TrendAnalysis(
      direction: direction,
      changePercent: changePercent,
      confidence: rSquared * 100,
      prediction: prediction,
    );
  }

  Trend _analyzeBPTrend(List<BloodPressureData> history) {
    if (history.length < 3) return Trend.stable;
    
    final sysValues = history.map((e) => e.systolic).toList();
    final trend = _analyzeTrend(sysValues);
    return trend.direction;
  }

  // ============================================
  // COMPREHENSIVE HEALTH SCORE
  // ============================================
  
  /// Calculate overall health score with detailed breakdown
  ComprehensiveHealthScore calculateComprehensiveScore({
    required HeartRateData heartRate,
    required BloodPressureData bloodPressure,
    required OxygenData oxygen,
    required ActivityData activity,
    SleepData? sleep,
    StressData? stress,
  }) {
    // Calculate individual component scores
    final heartScore = _calculateHeartScore(heartRate);
    final bpScore = _calculateBPScore(bloodPressure);
    final oxygenScore = _calculateOxygenScore(oxygen);
    final activityScore = _calculateActivityScore(activity);
    final sleepScore = sleep != null ? _calculateSleepScore(sleep) : null;
    final stressScore = stress != null ? (100 - stress.stressLevel).round() : null;
    
    // Weighted average
    double totalScore = 
        (heartScore * 0.25) +
        (bpScore * 0.25) +
        (oxygenScore * 0.15) +
        (activityScore * 0.15) +
        ((sleepScore ?? 75) * 0.10) +
        ((stressScore ?? 75) * 0.10);
    
    // Determine grade
    HealthGrade grade;
    if (totalScore >= 90) grade = HealthGrade.excellent;
    else if (totalScore >= 80) grade = HealthGrade.good;
    else if (totalScore >= 70) grade = HealthGrade.fair;
    else if (totalScore >= 50) grade = HealthGrade.poor;
    else grade = HealthGrade.critical;

    // Generate overall recommendations
    final recommendations = _generateOverallRecommendations(
      heartScore: heartScore,
      bpScore: bpScore,
      oxygenScore: oxygenScore,
      activityScore: activityScore,
      sleepScore: sleepScore,
      stressScore: stressScore,
    );

    return ComprehensiveHealthScore(
      overallScore: totalScore.round(),
      grade: grade,
      heartScore: heartScore,
      bloodPressureScore: bpScore,
      oxygenScore: oxygenScore,
      activityScore: activityScore,
      sleepScore: sleepScore,
      stressScore: stressScore,
      recommendations: recommendations,
    );
  }

  int _calculateHeartScore(HeartRateData hr) {
    if (hr.status == HeartRateStatus.critical) return 20;
    if (hr.status == HeartRateStatus.warning) return 50;
    if (hr.arrhythmiaDetected != null) return 40;
    if (hr.afibProbability > 50) return 30;
    if (hr.hrv > 50 && hr.hrv < 100) return 90;
    return 80;
  }

  int _calculateBPScore(BloodPressureData bp) {
    switch (bp.category) {
      case BpCategory.normal:
        return 100;
      case BpCategory.elevated:
        return 80;
      case BpCategory.hypertension1:
        return 60;
      case BpCategory.hypertension2:
        return 40;
      case BpCategory.crisis:
        return 10;
      case BpCategory.hypotension:
        return 70;
    }
  }

  int _calculateOxygenScore(OxygenData o2) {
    switch (o2.status) {
      case OxygenStatus.normal:
        return 100;
      case OxygenStatus.moderate:
        return 75;
      case OxygenStatus.warning:
        return 50;
      case OxygenStatus.critical:
        return 20;
      case OxygenStatus.unknown:
        return 50;
    }
  }

  int _calculateActivityScore(ActivityData activity) {
    return activity.activityScore.round();
  }

  int _calculateSleepScore(SleepData sleep) {
    return sleep.sleepScore;
  }

  List<String> _generateOverallRecommendations({
    required int heartScore,
    required int bpScore,
    required int oxygenScore,
    required int activityScore,
    int? sleepScore,
    int? stressScore,
  }) {
    final recommendations = <String>[];

    if (heartScore < 50) {
      recommendations.add('❤️ Heart health needs attention. Consult a cardiologist.');
    }
    if (bpScore < 60) {
      recommendations.add('🩸 Blood pressure management is recommended.');
    }
    if (oxygenScore < 70) {
      recommendations.add('🫁 Consider checking lung health and breathing patterns.');
    }
    if (activityScore < 40) {
      recommendations.add('🏃 Increase daily physical activity.');
    }
    if (sleepScore != null && sleepScore < 60) {
      recommendations.add('😴 Improve sleep quality and duration.');
    }
    if (stressScore != null && stressScore < 40) {
      recommendations.add('🧘 Practice stress management techniques.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✨ Great job! Maintain your healthy lifestyle.');
    }

    return recommendations;
  }

  // ============================================
  // ALERT GENERATION
  // ============================================
  
  void _checkForAlerts(HeartRateData hr) {
    if (hr.status == HeartRateStatus.critical) {
      final type = hr.currentBPM > 150 
          ? AlertType.tachycardia 
          : AlertType.bradycardia;
      _addAlert(HealthAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        severity: AlertSeverity.critical,
        timestamp: DateTime.now(),
        message: '${hr.currentBPM} BPM detected',
        value: hr.currentBPM.toDouble(),
      ));
    }
    
    if (hr.arrhythmiaDetected != null) {
      _addAlert(HealthAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.arrhythmia,
        severity: AlertSeverity.critical,
        timestamp: DateTime.now(),
        message: 'Arrhythmia: ${hr.arrhythmiaDetected}',
        details: 'AFib probability: ${hr.afibProbability.toStringAsFixed(1)}%',
      ));
    }
  }

  void _checkBPAlerts(BloodPressureData bp) {
    if (bp.category == BpCategory.crisis) {
      _addAlert(HealthAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.hypertension,
        severity: AlertSeverity.emergency,
        timestamp: DateTime.now(),
        message: 'Hypertensive Crisis: ${bp.systolic}/${bp.diastolic}',
        value: bp.systolic.toDouble(),
        threshold: 180,
      ));
    }
  }

  void _checkOxygenAlerts(OxygenData o2) {
    if (o2.status == OxygenStatus.critical || o2.status == OxygenStatus.warning) {
      _addAlert(HealthAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.lowOxygen,
        severity: o2.status == OxygenStatus.critical 
            ? AlertSeverity.critical 
            : AlertSeverity.warning,
        timestamp: DateTime.now(),
        message: 'Low SpO2: ${o2.spO2}%',
        value: o2.spO2.toDouble(),
        threshold: 90,
      ));
    }
  }

  void _addAlert(HealthAlert alert) {
    _alerts.insert(0, alert);
    if (_alerts.length > 100) {
      _alerts.removeLast();
    }
    notifyListeners();
  }

  void acknowledgeAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      // Create acknowledged version
      final old = _alerts[index];
      _alerts[index] = HealthAlert(
        id: old.id,
        type: old.type,
        severity: old.severity,
        timestamp: old.timestamp,
        message: old.message,
        details: old.details,
        value: old.value,
        threshold: old.threshold,
        acknowledged: true,
        location: old.location,
      );
      notifyListeners();
    }
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }
}

// ============================================
// ANALYSIS RESULT CLASSES
// ============================================

class ArrhythmiaAnalysisResult {
  final bool hasArrhythmia;
  final ArrhythmiaType? type;
  final double confidence;
  final Map<String, double> features;
  final RiskLevel riskLevel;
  final double poincareRatio;
  final List<String> recommendations;

  ArrhythmiaAnalysisResult({
    required this.hasArrhythmia,
    this.type,
    required this.confidence,
    required this.features,
    required this.riskLevel,
    this.poincareRatio = 0,
    required this.recommendations,
  });
}

class BloodPressureAnalysis {
  final int averageSystolic;
  final int averageDiastolic;
  final double variability;
  final Trend trend;
  final int vascularAge;
  final double arterialStiffness;
  final List<String> recommendations;

  BloodPressureAnalysis({
    required this.averageSystolic,
    required this.averageDiastolic,
    required this.variability,
    required this.trend,
    required this.vascularAge,
    required this.arterialStiffness,
    required this.recommendations,
  });
}

class StressAnalysisResult {
  final int overallScore;
  final StressLevel level;
  final int hrvScore;
  final int hrScore;
  final int variabilityScore;
  final List<String> insights;
  final List<String> recommendations;

  StressAnalysisResult({
    required this.overallScore,
    required this.level,
    required this.hrvScore,
    required this.hrScore,
    required this.variabilityScore,
    required this.insights,
    required this.recommendations,
  });
}

class TrendAnalysis {
  final Trend direction;
  final double changePercent;
  final double confidence;
  final double prediction;

  TrendAnalysis({
    required this.direction,
    required this.changePercent,
    required this.confidence,
    required this.prediction,
  });
}

class ComprehensiveHealthScore {
  final int overallScore;
  final HealthGrade grade;
  final int heartScore;
  final int bloodPressureScore;
  final int oxygenScore;
  final int activityScore;
  final int? sleepScore;
  final int? stressScore;
  final List<String> recommendations;

  ComprehensiveHealthScore({
    required this.overallScore,
    required this.grade,
    required this.heartScore,
    required this.bloodPressureScore,
    required this.oxygenScore,
    required this.activityScore,
    this.sleepScore,
    this.stressScore,
    required this.recommendations,
  });
}

enum Trend { up, down, stable }
enum RiskLevel { low, moderate, high, critical }
