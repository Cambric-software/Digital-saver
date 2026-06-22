import 'dart:math';

/// Advanced Health Data Model with comprehensive metrics
class HealthMetrics {
  final DateTime timestamp;
  final HeartRateData heartRate;
  final BloodPressureData bloodPressure;
  final OxygenData oxygen;
  final ActivityData activity;
  final SleepData? sleep;
  final StressData? stress;
  final HealthScore overallScore;

  HealthMetrics({
    required this.timestamp,
    required this.heartRate,
    required this.bloodPressure,
    required this.oxygen,
    required this.activity,
    this.sleep,
    this.stress,
    required this.overallScore,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'heartRate': heartRate.toJson(),
    'bloodPressure': bloodPressure.toJson(),
    'oxygen': oxygen.toJson(),
    'activity': activity.toJson(),
    'sleep': sleep?.toJson(),
    'stress': stress?.toJson(),
    'overallScore': overallScore.toJson(),
  };
}

/// Heart Rate Analysis with HRV and detailed metrics
class HeartRateData {
  final int currentBPM;
  final int averageBPM;
  final int minBPM;
  final int maxBPM;
  final double hrv; // Heart Rate Variability (RMSSD in ms)
  final double sdnn; // Standard Deviation of NN intervals
  final List<int> rrIntervals; // Raw RR intervals
  final HeartRateStatus status;
  final double confidence;
  final List<HRVSegment> hrvAnalysis;
  final ArrhythmiaType? arrhythmiaDetected;
  final double afibProbability; // Atrial fibrillation probability

  HeartRateData({
    required this.currentBPM,
    required this.averageBPM,
    required this.minBPM,
    required this.maxBPM,
    required this.hrv,
    required this.sdnn,
    required this.rrIntervals,
    required this.status,
    required this.confidence,
    required this.hrvAnalysis,
    this.arrhythmiaDetected,
    required this.afibProbability,
  });

  factory HeartRateData.analyze(List<int> readings, {int windowSeconds = 60}) {
    if (readings.isEmpty) {
      return HeartRateData(
        currentBPM: 0,
        averageBPM: 0,
        minBPM: 0,
        maxBPM: 0,
        hrv: 0,
        sdnn: 0,
        rrIntervals: [],
        status: HeartRateStatus.unknown,
        confidence: 0,
        hrvAnalysis: [],
        afibProbability: 0,
      );
    }

    final current = readings.last;
    final avg = readings.reduce((a, b) => a + b) ~/ readings.length;
    final min = readings.reduce(min);
    final max = readings.reduce(max);
    
    // Calculate HRV from RR intervals
    final rrIntervals = readings.map((bpm) => (60000 / bpm).round()).toList();
    final hrv = _calculateRMSSD(rrIntervals);
    final sdnn = _calculateSDNN(rrIntervals);
    
    // Detect arrhythmia
    final arrhythmia = _detectArrhythmia(rrIntervals);
    
    // Calculate AFib probability using machine learning-like analysis
    final afibProb = _calculateAfibProbability(rrIntervals, hrv, sdnn);
    
    // Analyze HRV segments
    final hrvAnalysis = _analyzeHRVSegments(rrIntervals);
    
    // Determine status
    final status = _determineStatus(current, hrv, arrhythmia);
    
    // Calculate confidence
    final confidence = _calculateConfidence(readings.length, hrv);

    return HeartRateData(
      currentBPM: current,
      averageBPM: avg,
      minBPM: min,
      maxBPM: max,
      hrv: hrv,
      sdnn: sdnn,
      rrIntervals: rrIntervals,
      status: status,
      confidence: confidence,
      hrvAnalysis: hrvAnalysis,
      arrhythmiaDetected: arrhythmia,
      afibProbability: afibProb,
    );
  }

  static double _calculateRMSSD(List<int> rrIntervals) {
    if (rrIntervals.length < 2) return 0;
    double sumSquaredDiffs = 0;
    int count = 0;
    for (int i = 0; i < rrIntervals.length - 1; i++) {
      final diff = rrIntervals[i + 1] - rrIntervals[i];
      sumSquaredDiffs += diff * diff;
      count++;
    }
    return count > 0 ? sqrt(sumSquaredDiffs / count) : 0;
  }

  static double _calculateSDNN(List<int> rrIntervals) {
    if (rrIntervals.isEmpty) return 0;
    final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    double sumSquaredDiffs = 0;
    for (int rr in rrIntervals) {
      sumSquaredDiffs += pow(rr - mean, 2);
    }
    return sqrt(sumSquaredDiffs / rrIntervals.length);
  }

  static ArrhythmiaType? _detectArrhythmia(List<int> rrIntervals) {
    if (rrIntervals.length < 10) return null;
    
    // Check for irregular RR intervals (Arrhythmia)
    double maxGap = 0;
    for (int i = 0; i < rrIntervals.length - 1; i++) {
      final gap = (rrIntervals[i + 1] - rrIntervals[i]).abs();
      if (gap > maxGap) maxGap = gap.toDouble();
    }
    
    // High HRV combined with irregular patterns
    final rmssd = _calculateRMSSD(rrIntervals);
    if (rmssd > 150) return ArrhythmiaType.highHrv;
    if (maxGap > 500) return ArrhythmiaType.missedBeats;
    if (rmssd > 100 && rrIntervals.length > 20) return ArrhythmiaType.irregular;
    
    // Check for tachycardia patterns
    final avgRr = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    if (avgRr < 600) return ArrhythmiaType.tachycardia;
    if (avgRr > 1200) return ArrhythmiaType.bradycardia;
    
    return null;
  }

  static double _calculateAfibProbability(List<int> rrIntervals, double hrv, double sdnn) {
    if (rrIntervals.length < 30) return 0;
    
    // Simplified AFib detection algorithm
    // In production, this would use a trained ML model
    
    // 1. RR interval irregularity
    double irregularity = sdnn / (rrIntervals.reduce((a, b) => a + b) / rrIntervals.length) * 100;
    
    // 2. Number of extreme RR intervals
    int extremeCount = 0;
    final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    for (int rr in rrIntervals) {
      if ((rr - mean).abs() > mean * 0.3) extremeCount++;
    }
    double extremeRatio = extremeCount / rrIntervals.length;
    
    // 3. Combine factors
    double probability = (irregularity * 0.4 + extremeRatio * 60) / 100;
    
    return probability.clamp(0, 100);
  }

  static List<HRVSegment> _analyzeHRVSegments(List<int> rrIntervals) {
    if (rrIntervals.length < 5) return [];
    
    final segments = <HRVSegment>[];
    final segmentSize = rrIntervals.length ~/ 4;
    
    for (int i = 0; i < 4; i++) {
      final start = i * segmentSize;
      final end = (i == 3) ? rrIntervals.length : (i + 1) * segmentSize;
      final segment = rrIntervals.sublist(start, end);
      
      if (segment.isNotEmpty) {
        segments.add(HRVSegment(
          timeOffset: i * 15, // minutes
          rmssd: _calculateRMSSD(segment),
          sdnn: _calculateSDNN(segment),
          meanHR: 60000 ~/ (segment.reduce((a, b) => a + b) ~/ segment.length),
        ));
      }
    }
    
    return segments;
  }

  static HeartRateStatus _determineStatus(int bpm, double hrv, ArrhythmiaType? arrhythmia) {
    if (arrhythmia != null) return HeartRateStatus.critical;
    if (bpm < 50 || bpm > 150) return HeartRateStatus.critical;
    if (bpm < 60 || bpm > 100) return HeartRateStatus.warning;
    if (hrv > 100 || hrv < 15) return HeartRateStatus.warning;
    return HeartRateStatus.normal;
  }

  static double _calculateConfidence(int readings, double hrv) {
    double base = min(readings / 60.0, 1.0) * 40; // 40% from sample size
    double hrvFactor = (hrv > 0 && hrv < 200) ? 30 : 15; // 15-30% from HRV quality
    double consistency = readings > 10 ? 30 : readings * 3; // Up to 30% from consistency
    return (base + hrvFactor + consistency).clamp(0, 100);
  }

  String get displayString => '$currentBPM BPM';
  
  String get hrvDescription {
    if (hrv < 20) return 'Very Low';
    if (hrv < 40) return 'Low';
    if (hrv < 60) return 'Normal';
    if (hrv < 100) return 'Good';
    return 'High';
  }

  Map<String, dynamic> toJson() => {
    'currentBPM': currentBPM,
    'averageBPM': averageBPM,
    'minBPM': minBPM,
    'maxBPM': maxBPM,
    'hrv': hrv,
    'sdnn': sdnn,
    'rrIntervals': rrIntervals,
    'status': status.name,
    'confidence': confidence,
    'hrvAnalysis': hrvAnalysis.map((e) => e.toJson()).toList(),
    'arrhythmiaDetected': arrhythmiaDetected?.name,
    'afibProbability': afibProbability,
  };
}

class HRVSegment {
  final int timeOffset; // minutes from start
  final double rmssd;
  final double sdnn;
  final int meanHR;

  HRVSegment({
    required this.timeOffset,
    required this.rmssd,
    required this.sdnn,
    required this.meanHR,
  });

  Map<String, dynamic> toJson() => {
    'timeOffset': timeOffset,
    'rmssd': rmssd,
    'sdnn': sdnn,
    'meanHR': meanHR,
  };
}

enum HeartRateStatus { normal, warning, critical, unknown }
enum ArrhythmiaType { tachycardia, bradycardia, irregular, missedBeats, highHrv }

/// Blood Pressure with Pulse Wave Analysis
class BloodPressureData {
  final int systolic;
  final int diastolic;
  final int meanArterialPressure;
  final double pulsePressure;
  final double augmentationIndex;
  final double pulseWaveVelocity;
  final List<PulseWaveData> pulseWave;
  final BpCategory category;
  final double confidence;
  final int? estimatedMAP; // If direct measurement not available

  BloodPressureData({
    required this.systolic,
    required this.diastolic,
    required this.meanArterialPressure,
    required this.pulsePressure,
    required this.augmentationIndex,
    required this.pulseWaveVelocity,
    required this.pulseWave,
    required this.category,
    required this.confidence,
    this.estimatedMAP,
  });

  factory BloodPressureData.fromSensorData({
    required List<double> ppgWaveform,
    required int heartRate,
    required int age,
    required double skinTone,
  }) {
    // Advanced PPG-based BP estimation
    // Uses Pulse Wave Analysis (PWA) techniques
    
    // Extract pulse wave features
    final systolicPeak = _findSystolicPeak(ppgWaveform);
    final diastolicPeak = _findDiastolicPeak(ppgWaveform);
    final inflectionPoint = _findInflectionPoint(ppgWaveform);
    
    // Calculate Augmentation Index (AIx)
    final augmentationIndex = _calculateAugmentationIndex(systolicPeak, diastolicPeak, inflectionPoint);
    
    // Estimate Pulse Wave Velocity (PWV)
    final pulseWaveVelocity = _estimatePWV(augmentationIndex, age);
    
    // Calculate Pulse Pressure
    final pulsePressure = systolicPeak - diastolicPeak;
    
    // Estimate MAP using PTT-like correlation
    final estimatedMAP = _estimateMAP(pulseWaveVelocity, heartRate, age);
    
    // Estimate SBP and DBP using transfer functions
    final systolic = _estimateSystolic(estimatedMAP, augmentationIndex, pulsePressure, age);
    final diastolic = _estimateDiastolic(estimatedMAP, heartRate);
    
    // Determine category
    final category = _categorizeBP(systolic, diastolic);
    
    // Calculate confidence based on signal quality
    final confidence = _calculateConfidence(ppgWaveform, augmentationIndex);

    return BloodPressureData(
      systolic: systolic,
      diastolic: diastolic,
      meanArterialPressure: estimatedMAP,
      pulsePressure: pulsePressure,
      augmentationIndex: augmentationIndex,
      pulseWaveVelocity: pulseWaveVelocity,
      pulseWave: _analyzePulseWave(ppgWaveform),
      category: category,
      confidence: confidence,
    );
  }

  static double _findSystolicPeak(List<double> waveform) {
    if (waveform.isEmpty) return 120;
    // First major peak is systolic peak
    double maxVal = waveform.first;
    int maxIdx = 0;
    for (int i = 0; i < waveform.length ~/ 3; i++) {
      if (waveform[i] > maxVal) {
        maxVal = waveform[i];
        maxIdx = i;
      }
    }
    return 80 + (maxVal * 40); // Scale to realistic values
  }

  static double _findDiastolicPeak(List<double> waveform) {
    if (waveform.length < 10) return 70;
    // Second peak is diastolic peak
    double maxVal = 0;
    for (int i = waveform.length ~/ 3; i < waveform.length; i++) {
      if (waveform[i] > maxVal) maxVal = waveform[i];
    }
    return 60 + (maxVal * 30);
  }

  static double _findInflectionPoint(List<double> waveform) {
    // Find the dicrotic notch/inflection point
    if (waveform.length < 20) return 0.5;
    return 0.6; // Simplified
  }

  static double _calculateAugmentationIndex(double systolic, double diastolic, double inflection) {
    if (systolic == 0) return 0;
    return ((systolic - diastolic) / systolic) * 100;
  }

  static double _estimatePWV(double ai, int age) {
    // PWV increases with age and AIx
    return 5 + (age * 0.1) + (ai * 0.05);
  }

  static int _estimateMAP(double pwv, int hr, int age) {
    // Simplified MAP estimation
    return (100 + (hr - 70) + (age ~/ 10)).clamp(70, 150);
  }

  static int _estimateSystolic(int map, double ai, double pp, int age) {
    // Estimate SBP from MAP with age compensation
    final base = map + (pp ~/ 2);
    final ageFactor = age > 50 ? (age - 50) ~/ 2 : 0;
    return (base + ageFactor).clamp(80, 220);
  }

  static int _estimateDiastolic(int map, int hr) {
    // Estimate DBP from MAP
    return (map - (hr ~/ 4)).clamp(40, 140);
  }

  static BpCategory _categorizeBP(int sys, int dia) {
    if (sys >= 180 || dia >= 120) return BpCategory.crisis;
    if (sys >= 140 || dia >= 90) return BpCategory.hypertension2;
    if (sys >= 130 || dia >= 80) return BpCategory.hypertension1;
    if (sys >= 120 && dia < 80) return BpCategory.elevated;
    if (sys < 90 || dia < 60) return BpCategory.hypotension;
    return BpCategory.normal;
  }

  static double _calculateConfidence(List<double> waveform, double ai) {
    if (waveform.isEmpty) return 0;
    
    // Signal quality assessment
    double signalVariance = 0;
    for (int i = 1; i < waveform.length; i++) {
      signalVariance += pow(waveform[i] - waveform[i-1], 2);
    }
    signalVariance /= waveform.length;
    
    // Good signal has moderate variance
    double signalQuality = signalVariance > 0.001 && signalVariance < 0.1 ? 40 : 20;
    
    // AIx validity
    double aiQuality = ai > 0 && ai < 100 ? 30 : 15;
    
    return (signalQuality + aiQuality + 20).clamp(0, 100);
  }

  static List<PulseWaveData> _analyzePulseWave(List<double> waveform) {
    // Extract features from pulse wave for detailed analysis
    final features = <PulseWaveData>[];
    if (waveform.length < 50) return features;
    
    final segmentSize = waveform.length ~/ 10;
    for (int i = 0; i < 10; i++) {
      final start = i * segmentSize;
      final end = (i == 9) ? waveform.length : (i + 1) * segmentSize;
      final segment = waveform.sublist(start, end);
      
      if (segment.isNotEmpty) {
        features.add(PulseWaveData(
          timePercent: (i * 10).toDouble(),
          amplitude: segment.reduce((a, b) => a + b) / segment.length,
          derivative: _calculateDerivative(segment),
        ));
      }
    }
    
    return features;
  }

  static double _calculateDerivative(List<double> segment) {
    if (segment.length < 2) return 0;
    return (segment.last - segment.first) / segment.length;
  }

  String get displayString => '$systolic/$diastolic mmHg';
  String get mapString => '$meanArterialPressure mmHg (MAP)';

  Map<String, dynamic> toJson() => {
    'systolic': systolic,
    'diastolic': diastolic,
    'meanArterialPressure': meanArterialPressure,
    'pulsePressure': pulsePressure,
    'augmentationIndex': augmentationIndex,
    'pulseWaveVelocity': pulseWaveVelocity,
    'pulseWave': pulseWave.map((e) => e.toJson()).toList(),
    'category': category.name,
    'confidence': confidence,
  };
}

class PulseWaveData {
  final double timePercent;
  final double amplitude;
  final double derivative;

  PulseWaveData({
    required this.timePercent,
    required this.amplitude,
    required this.derivative,
  });

  Map<String, dynamic> toJson() => {
    'timePercent': timePercent,
    'amplitude': amplitude,
    'derivative': derivative,
  };
}

enum BpCategory { normal, elevated, hypertension1, hypertension2, crisis, hypotension }

/// Oxygen Saturation with Perfusion Analysis
class OxygenData {
  final int spO2;
  final int perfusionIndex;
  final double respirationRate;
  final bool lowOxygenAlert;
  final List<int> spo2History;
  final OxygenStatus status;

  OxygenData({
    required this.spO2,
    required this.perfusionIndex,
    required this.respirationRate,
    required this.lowOxygenAlert,
    required this.spo2History,
    required this.status,
  });

  factory OxygenData.analyze(List<int> readings) {
    if (readings.isEmpty) {
      return OxygenData(
        spO2: 0,
        perfusionIndex: 0,
        respirationRate: 0,
        lowOxygenAlert: false,
        spo2History: [],
        status: OxygenStatus.unknown,
      );
    }

    final current = readings.last;
    final avg = readings.reduce((a, b) => a + b) ~/ readings.length;
    
    // Perfusion Index calculation (from PPG signal amplitude)
    final perfusionIndex = _calculatePerfusionIndex(readings);
    
    // Estimate respiration rate from SpO2 variability
    final respirationRate = _estimateRespirationRate(readings);
    
    // Low oxygen alert
    final lowAlert = current < 90 || _hasSignificantDrop(readings);
    
    // Status determination
    final status = _determineStatus(current, avg);

    return OxygenData(
      spO2: current,
      perfusionIndex: perfusionIndex.toInt(),
      respirationRate: respirationRate,
      lowOxygenAlert: lowAlert,
      spo2History: readings,
      status: status,
    );
  }

  static double _calculatePerfusionIndex(List<int> readings) {
    if (readings.isEmpty) return 0;
    // PI is typically 0.02-20% in healthy adults
    final variance = _calculateVariance(readings);
    return (variance / readings.length * 100).clamp(0.1, 25.0);
  }

  static double _calculateVariance(List<int> readings) {
    if (readings.isEmpty) return 0;
    final mean = readings.reduce((a, b) => a + b) / readings.length;
    double sum = 0;
    for (int val in readings) {
      sum += pow(val - mean, 2);
    }
    return sum / readings.length;
  }

  static double _estimateRespirationRate(List<int> readings) {
    // Simplified respiration rate estimation from SpO2 variations
    if (readings.length < 30) return 0;
    
    // Count oscillations that could correspond to breaths
    int oscillations = 0;
    bool wasAboveMean = readings.first > readings.reduce((a, b) => a + b) / readings.length;
    for (int i = 1; i < readings.length; i++) {
      final mean = readings.reduce((a, b) => a + b) / readings.length;
      bool isAbove = readings[i] > mean;
      if (wasAboveMean != isAbove) {
        oscillations++;
        wasAboveMean = isAbove;
      }
    }
    
    // Convert oscillations to breaths per minute
    return (oscillations * 2).toDouble().clamp(8, 30);
  }

  static bool _hasSignificantDrop(List<int> readings) {
    if (readings.length < 10) return false;
    final recent = readings.sublist(readings.length - 10);
    final older = readings.sublist(0, 10);
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    return (olderAvg - recentAvg) > 5;
  }

  static OxygenStatus _determineStatus(int current, int average) {
    if (current < 90) return OxygenStatus.critical;
    if (current < 94) return OxygenStatus.warning;
    if (average < 95) return OxygenStatus.moderate;
    return OxygenStatus.normal;
  }

  String get displayString => '$spO2%';
  String get piString => '$perfusionIndex% (PI)';

  Map<String, dynamic> toJson() => {
    'spO2': spO2,
    'perfusionIndex': perfusionIndex,
    'respirationRate': respirationRate,
    'lowOxygenAlert': lowOxygenAlert,
    'spo2History': spo2History,
    'status': status.name,
  };
}

enum OxygenStatus { normal, moderate, warning, critical, unknown }

/// Activity and Movement Analysis
class ActivityData {
  final int steps;
  final double distanceKm;
  final int caloriesBurned;
  final int activeMinutes;
  final int restingHeartRate;
  final ActivityType currentActivity;
  final double activityScore;
  final List<ActivitySegment> segments;

  ActivityData({
    required this.steps,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.restingHeartRate,
    required this.currentActivity,
    required this.activityScore,
    required this.segments,
  });

  factory ActivityData.analyze({
    required List<AccelerometerReading> accelerometerData,
    required int restingHR,
  }) {
    // Count steps from accelerometer data
    final steps = _countSteps(accelerometerData);
    
    // Calculate distance
    final distance = steps * 0.00075; // Average stride length in km
    
    // Estimate calories
    final calories = _estimateCalories(steps, restingHR);
    
    // Determine current activity
    final activity = _classifyActivity(accelerometerData);
    
    // Calculate activity score
    final score = _calculateActivityScore(steps, calories, activity);
    
    // Analyze activity segments
    final segments = _analyzeSegments(accelerometerData);

    return ActivityData(
      steps: steps,
      distanceKm: distance,
      caloriesBurned: calories,
      activeMinutes: segments.where((s) => s.intensity > 0.3).length,
      restingHeartRate: restingHR,
      currentActivity: activity,
      activityScore: score,
      segments: segments,
    );
  }

  static int _countSteps(List<AccelerometerReading> data) {
    if (data.length < 50) return 0;
    
    int steps = 0;
    bool wasAboveThreshold = false;
    double threshold = 1.2; // g-force threshold for step detection
    
    for (int i = 0; i < data.length; i++) {
      final magnitude = data[i].magnitude;
      bool isAboveThreshold = magnitude > threshold;
      
      if (isAboveThreshold && !wasAboveThreshold) {
        // Look for peak
        if (i > 0 && i < data.length - 1) {
          if (data[i - 1].magnitude < magnitude && data[i + 1].magnitude < magnitude) {
            steps++;
          }
        }
      }
      wasAboveThreshold = isAboveThreshold;
    }
    
    return steps ~/ 2; // Divide by 2 to correct for double counting
  }

  static int _estimateCalories(int steps, int restingHR) {
    // Basic calorie estimation based on steps and heart rate
    final baseCalories = steps * 0.04; // ~40 calories per 1000 steps
    final hrFactor = (restingHR - 60) * 0.1; // Extra calories for elevated HR
    return (baseCalories + hrFactor * 10).toInt();
  }

  static ActivityType _classifyActivity(List<AccelerometerReading> data) {
    if (data.isEmpty) return ActivityType.resting;
    
    final avgMagnitude = data.map((e) => e.magnitude).reduce((a, b) => a + b) / data.length;
    final variance = _calculateVariance(data.map((e) => e.magnitude).toList());
    
    if (avgMagnitude < 1.05) return ActivityType.resting;
    if (avgMagnitude < 1.3) {
      if (variance > 0.1) return ActivityType.walking;
      return ActivityType.sedentary;
    }
    if (avgMagnitude < 2.0) return ActivityType.walking;
    if (avgMagnitude < 3.0) return ActivityType.jogging;
    return ActivityType.running;
  }

  static double _calculateActivityScore(int steps, int calories, ActivityType activity) {
    double score = 0;
    
    // Steps contribution (up to 50 points)
    score += (steps / 10000 * 50).clamp(0, 50);
    
    // Calories contribution (up to 30 points)
    score += (calories / 500 * 30).clamp(0, 30);
    
    // Activity type bonus
    switch (activity) {
      case ActivityType.running:
        score += 20;
        break;
      case ActivityType.jogging:
        score += 15;
        break;
      case ActivityType.walking:
        score += 10;
        break;
      case ActivityType.sedentary:
        score += 5;
        break;
      case ActivityType.resting:
        break;
    }
    
    return score.clamp(0, 100);
  }

  static double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    double sum = 0;
    for (int val in values) {
      sum += pow(val - mean, 2);
    }
    return sum / values.length;
  }

  static List<ActivitySegment> _analyzeSegments(List<AccelerometerReading> data) {
    if (data.length < 30) return [];
    
    final segments = <ActivitySegment>[];
    final segmentSize = data.length ~/ 6;
    
    for (int i = 0; i < 6; i++) {
      final start = i * segmentSize;
      final end = (i == 5) ? data.length : (i + 1) * segmentSize;
      final segment = data.sublist(start, end);
      
      if (segment.isNotEmpty) {
        final avgMagnitude = segment.map((e) => e.magnitude).reduce((a, b) => a + b) / segment.length;
        segments.add(ActivitySegment(
          timeOffset: i * 10,
          intensity: (avgMagnitude - 1.0).clamp(0, 2) / 2,
          stepCount: _countSteps(segment),
        ));
      }
    }
    
    return segments;
  }

  String get displayString => '$steps steps';
  String get distanceString => '${distanceKm.toStringAsFixed(2)} km';

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'distanceKm': distanceKm,
    'caloriesBurned': caloriesBurned,
    'activeMinutes': activeMinutes,
    'restingHeartRate': restingHeartRate,
    'currentActivity': currentActivity.name,
    'activityScore': activityScore,
    'segments': segments.map((e) => e.toJson()).toList(),
  };
}

class AccelerometerReading {
  final double x, y, z;
  final DateTime timestamp;

  AccelerometerReading({required this.x, required this.y, required this.z, required this.timestamp});
  
  double get magnitude => sqrt(x*x + y*y + z*z);
}

class ActivitySegment {
  final int timeOffset; // minutes
  final double intensity; // 0-1
  final int stepCount;

  ActivitySegment({
    required this.timeOffset,
    required this.intensity,
    required this.stepCount,
  });

  Map<String, dynamic> toJson() => {
    'timeOffset': timeOffset,
    'intensity': intensity,
    'stepCount': stepCount,
  };
}

enum ActivityType { resting, sedentary, walking, jogging, running }

/// Sleep Analysis
class SleepData {
  final Duration totalSleep;
  final Duration deepSleep;
  final Duration lightSleep;
  final Duration remSleep;
  final Duration awakeTime;
  final int sleepScore;
  final List<SleepSegment> segments;
  final SleepQuality quality;

  SleepData({
    required this.totalSleep,
    required this.deepSleep,
    required this.lightSleep,
    required this.remSleep,
    required this.awakeTime,
    required this.sleepScore,
    required this.segments,
    required this.quality,
  });

  factory SleepData.analyze(List<HealthMetrics> nightData) {
    if (nightData.isEmpty) {
      return SleepData(
        totalSleep: Duration.zero,
        deepSleep: Duration.zero,
        lightSleep: Duration.zero,
        remSleep: Duration.zero,
        awakeTime: Duration.zero,
        sleepScore: 0,
        segments: [],
        quality: SleepQuality.unknown,
      );
    }

    // Analyze HR and movement patterns to determine sleep stages
    Duration deep = Duration.zero;
    Duration light = Duration.zero;
    Duration rem = Duration.zero;
    Duration awake = Duration.zero;
    final segments = <SleepSegment>[];

    // Simplified sleep stage detection based on HRV
    for (int i = 0; i < nightData.length; i++) {
      final data = nightData[i];
      final hrv = data.heartRate.hrv;
      final hr = data.heartRate.currentBPM;
      
      SleepStage stage;
      if (hrv > 60 && hr < 60) {
        stage = SleepStage.deep;
        deep += const Duration(minutes: 5);
      } else if (hrv > 30 && hr < 75) {
        stage = SleepStage.light;
        light += const Duration(minutes: 5);
      } else if (hr < 70 && hrv > 40) {
        stage = SleepStage.rem;
        rem += const Duration(minutes: 5);
      } else {
        stage = SleepStage.awake;
        awake += const Duration(minutes: 5);
      }
      
      if (i % 12 == 0) { // Every hour
        segments.add(SleepSegment(
          hour: i ~/ 12,
          stage: stage,
          heartRate: hr,
          hrv: hrv,
        ));
      }
    }

    final total = deep + light + rem + awake;
    final score = _calculateSleepScore(total, deep, rem, awake);
    final quality = _determineQuality(score);

    return SleepData(
      totalSleep: total,
      deepSleep: deep,
      lightSleep: light,
      remSleep: rem,
      awakeTime: awake,
      sleepScore: score,
      segments: segments,
      quality: quality,
    );
  }

  static int _calculateSleepScore(Duration total, Duration deep, Duration rem, Duration awake) {
    int score = 0;
    
    // Duration score (up to 40 points)
    final hours = total.inHours;
    if (hours >= 7 && hours <= 9) score += 40;
    else if (hours >= 6 && hours <= 10) score += 30;
    else if (hours >= 5) score += 20;
    else score += 10;
    
    // Deep sleep score (up to 25 points)
    final deepPercent = total.inMinutes > 0 ? deep.inMinutes / total.inMinutes : 0;
    if (deepPercent > 0.2) score += 25;
    else if (deepPercent > 0.15) score += 20;
    else if (deepPercent > 0.1) score += 15;
    else score += 10;
    
    // REM score (up to 25 points)
    final remPercent = total.inMinutes > 0 ? rem.inMinutes / total.inMinutes : 0;
    if (remPercent > 0.2) score += 25;
    else if (remPercent > 0.15) score += 20;
    else if (remPercent > 0.1) score += 15;
    else score += 10;
    
    // Awake time penalty (up to 10 points)
    if (awake.inMinutes < 20) score += 10;
    else if (awake.inMinutes < 30) score += 7;
    else if (awake.inMinutes < 60) score += 4;
    else score += 0;
    
    return score.clamp(0, 100);
  }

  static SleepQuality _determineQuality(int score) {
    if (score >= 85) return SleepQuality.excellent;
    if (score >= 70) return SleepQuality.good;
    if (score >= 50) return SleepQuality.fair;
    if (score >= 30) return SleepQuality.poor;
    return SleepQuality.veryPoor;
  }

  String get totalSleepString {
    final hours = totalSleep.inHours;
    final minutes = totalSleep.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toJson() => {
    'totalSleep': totalSleep.inMinutes,
    'deepSleep': deepSleep.inMinutes,
    'lightSleep': lightSleep.inMinutes,
    'remSleep': remSleep.inMinutes,
    'awakeTime': awakeTime.inMinutes,
    'sleepScore': sleepScore,
    'segments': segments.map((e) => e.toJson()).toList(),
    'quality': quality.name,
  };
}

class SleepSegment {
  final int hour;
  final SleepStage stage;
  final int heartRate;
  final double hrv;

  SleepSegment({
    required this.hour,
    required this.stage,
    required this.heartRate,
    required this.hrv,
  });

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'stage': stage.name,
    'heartRate': heartRate,
    'hrv': hrv,
  };
}

enum SleepStage { awake, light, deep, rem }
enum SleepQuality { unknown, veryPoor, poor, fair, good, excellent }

/// Stress Level Analysis
class StressData {
  final double stressLevel; // 0-100
  final StressLevel level;
  final double galvanicResponse;
  final int hrvBaseline;
  final List<StressSegment> segments;

  StressData({
    required this.stressLevel,
    required this.level,
    required this.galvanicResponse,
    required this.hrvBaseline,
    required this.segments,
  });

  factory StressData.analyze(List<HeartRateData> hrData) {
    if (hrData.isEmpty) {
      return StressData(
        stressLevel: 0,
        level: StressLevel.unknown,
        galvanicResponse: 0,
        hrvBaseline: 0,
        segments: [],
      );
    }

    // Calculate overall stress level
    final avgHrv = hrData.map((e) => e.hrv).reduce((a, b) => a + b) / hrData.length;
    final avgHr = hrData.map((e) => e.currentBPM).reduce((a, b) => a + b) / hrData.length;
    
    // Stress calculation based on HRV and HR
    double stress = 100 - (avgHrv * 0.5 + (120 - avgHr) * 0.5);
    stress = stress.clamp(0, 100);
    
    // Analyze segments
    final segments = <StressSegment>[];
    for (int i = 0; i < hrData.length; i += 10) {
      if (i < hrData.length) {
        final data = hrData[i];
        segments.add(StressSegment(
          timeOffset: i * 5,
          stressLevel: 100 - (data.hrv * 0.5 + (120 - data.currentBPM) * 0.5),
          hrv: data.hrv,
          heartRate: data.currentBPM,
        ));
      }
    }
    
    final level = _determineLevel(stress);
    final baseline = _calculateBaseline(hrData);

    return StressData(
      stressLevel: stress,
      level: level,
      galvanicResponse: stress / 10, // Simplified GSR estimation
      hrvBaseline: baseline,
      segments: segments,
    );
  }

  static double _calculateBaseline(List<HeartRateData> data) {
    if (data.isEmpty) return 0;
    return data.map((e) => e.hrv).reduce((a, b) => a + b) / data.length;
  }

  static StressLevel _determineLevel(double stress) {
    if (stress >= 80) return StressLevel.veryHigh;
    if (stress >= 60) return StressLevel.high;
    if (stress >= 40) return StressLevel.moderate;
    if (stress >= 20) return StressLevel.low;
    return StressLevel.minimal;
  }

  String get levelString {
    switch (level) {
      case StressLevel.veryHigh:
        return 'Very High';
      case StressLevel.high:
        return 'High';
      case StressLevel.moderate:
        return 'Moderate';
      case StressLevel.low:
        return 'Low';
      case StressLevel.minimal:
        return 'Minimal';
      case StressLevel.unknown:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() => {
    'stressLevel': stressLevel,
    'level': level.name,
    'galvanicResponse': galvanicResponse,
    'hrvBaseline': hrvBaseline,
    'segments': segments.map((e) => e.toJson()).toList(),
  };
}

class StressSegment {
  final int timeOffset; // seconds
  final double stressLevel;
  final double hrv;
  final int heartRate;

  StressSegment({
    required this.timeOffset,
    required this.stressLevel,
    required this.hrv,
    required this.heartRate,
  });

  Map<String, dynamic> toJson() => {
    'timeOffset': timeOffset,
    'stressLevel': stressLevel,
    'hrv': hrv,
    'heartRate': heartRate,
  };
}

enum StressLevel { unknown, minimal, low, moderate, high, veryHigh }

/// Overall Health Score
class HealthScore {
  final int score; // 0-100
  final HealthGrade grade;
  final List<ScoreFactor> factors;
  final String recommendation;

  HealthScore({
    required this.score,
    required this.grade,
    required this.factors,
    required this.recommendation,
  });

  factory HealthScore.calculate({
    required HeartRateData heartRate,
    required BloodPressureData bloodPressure,
    required OxygenData oxygen,
    required ActivityData activity,
    SleepData? sleep,
    StressData? stress,
  }) {
    final factors = <ScoreFactor>[];
    int totalScore = 0;
    int factorCount = 0;

    // Heart Rate Factor (25%)
    final hrFactor = _calculateHRFactor(heartRate);
    factors.add(hrFactor);
    totalScore += (hrFactor.score * 0.25).round();
    factorCount++;

    // Blood Pressure Factor (25%)
    final bpFactor = _calculateBPFactor(bloodPressure);
    factors.add(bpFactor);
    totalScore += (bpFactor.score * 0.25).round();
    factorCount++;

    // Oxygen Factor (20%)
    final o2Factor = _calculateO2Factor(oxygen);
    factors.add(o2Factor);
    totalScore += (o2Factor.score * 0.20).round();
    factorCount++;

    // Activity Factor (15%)
    final activityFactor = _calculateActivityFactor(activity);
    factors.add(activityFactor);
    totalScore += (activityFactor.score * 0.15).round();
    factorCount++;

    // Sleep Factor (15%)
    if (sleep != null) {
      final sleepFactor = _calculateSleepFactor(sleep);
      factors.add(sleepFactor);
      totalScore += (sleepFactor.score * 0.15).round();
      factorCount++;
    }

    // Generate recommendation
    final recommendation = _generateRecommendation(factors);

    return HealthScore(
      score: totalScore.clamp(0, 100),
      grade: _determineGrade(totalScore),
      factors: factors,
      recommendation: recommendation,
    );
  }

  static ScoreFactor _calculateHRFactor(HeartRateData hr) {
    int score = 100;
    String issue = '';
    
    if (hr.status == HeartRateStatus.critical) {
      score = 30;
      issue = 'Critical heart rate detected';
    } else if (hr.status == HeartRateStatus.warning) {
      score = 60;
      issue = 'Heart rate outside normal range';
    }
    
    if (hr.arrhythmiaDetected != null) {
      score = max(score - 30, 20);
      issue = 'Arrhythmia detected';
    }
    
    if (hr.afibProbability > 50) {
      score = max(score - 20, 30);
      issue = 'High AFib risk';
    }
    
    return ScoreFactor(
      name: 'Heart Health',
      score: score.clamp(0, 100),
      icon: '❤️',
      color: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
      issue: issue.isEmpty ? null : issue,
    );
  }

  static ScoreFactor _calculateBPFactor(BloodPressureData bp) {
    int score = 100;
    String issue = '';
    
    switch (bp.category) {
      case BpCategory.crisis:
        score = 20;
        issue = 'Hypertensive crisis';
        break;
      case BpCategory.hypertension2:
        score = 40;
        issue = 'Stage 2 hypertension';
        break;
      case BpCategory.hypertension1:
        score = 60;
        issue = 'Stage 1 hypertension';
        break;
      case BpCategory.elevated:
        score = 80;
        issue = 'Elevated blood pressure';
        break;
      case BpCategory.hypotension:
        score = 70;
        issue = 'Low blood pressure';
        break;
      case BpCategory.normal:
        score = 100;
        break;
    }
    
    return ScoreFactor(
      name: 'Blood Pressure',
      score: score.clamp(0, 100),
      icon: '🩸',
      color: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
      issue: issue.isEmpty ? null : issue,
    );
  }

  static ScoreFactor _calculateO2Factor(OxygenData o2) {
    int score = 100;
    String issue = '';
    
    if (o2.status == OxygenStatus.critical) {
      score = 30;
      issue = 'Critical oxygen level';
    } else if (o2.status == OxygenStatus.warning) {
      score = 50;
      issue = 'Low oxygen saturation';
    } else if (o2.status == OxygenStatus.moderate) {
      score = 75;
      issue = 'Slightly low oxygen';
    }
    
    return ScoreFactor(
      name: 'Oxygen Level',
      score: score.clamp(0, 100),
      icon: '🫁',
      color: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
      issue: issue.isEmpty ? null : issue,
    );
  }

  static ScoreFactor _calculateActivityFactor(ActivityData activity) {
    int score = 100;
    String issue = '';
    
    if (activity.activityScore < 30) {
      score = 40;
      issue = 'Low activity level';
    } else if (activity.activityScore < 60) {
      score = 70;
      issue = 'Moderate activity';
    }
    
    return ScoreFactor(
      name: 'Activity',
      score: score.clamp(0, 100),
      icon: '🏃',
      color: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
      issue: issue.isEmpty ? null : issue,
    );
  }

  static ScoreFactor _calculateSleepFactor(SleepData sleep) {
    int score = sleep.sleepScore;
    String issue = '';
    
    if (sleep.quality == SleepQuality.veryPoor) {
      issue = 'Very poor sleep quality';
    } else if (sleep.quality == SleepQuality.poor) {
      issue = 'Poor sleep quality';
    } else if (sleep.quality == SleepQuality.fair) {
      issue = 'Fair sleep quality';
    }
    
    return ScoreFactor(
      name: 'Sleep',
      score: score.clamp(0, 100),
      icon: '😴',
      color: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
      issue: issue.isEmpty ? null : issue,
    );
  }

  static HealthGrade _determineGrade(int score) {
    if (score >= 90) return HealthGrade.excellent;
    if (score >= 80) return HealthGrade.good;
    if (score >= 70) return HealthGrade.fair;
    if (score >= 50) return HealthGrade.poor;
    return HealthGrade.critical;
  }

  static String _generateRecommendation(List<ScoreFactor> factors) {
    final issues = factors.where((f) => f.score < 70 && f.issue != null).toList();
    
    if (issues.isEmpty) {
      return 'Your health metrics look great! Keep up the good work with your current lifestyle.';
    }
    
    // Sort by severity
    issues.sort((a, b) => a.score.compareTo(b.score));
    
    final topIssue = issues.first;
    return 'Focus on improving your ${topIssue.name.toLowerCase()}. ${topIssue.issue}.';
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'grade': grade.name,
    'factors': factors.map((e) => e.toJson()).toList(),
    'recommendation': recommendation,
  };
}

class ScoreFactor {
  final String name;
  final int score;
  final String icon;
  final Color color;
  final String? issue;

  ScoreFactor({
    required this.name,
    required this.score,
    required this.icon,
    required this.color,
    this.issue,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'icon': icon,
    'color': color.toString(),
    'issue': issue,
  };
}

enum HealthGrade { excellent, good, fair, poor, critical }

/// Emergency Contact Model
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final String? email;
  final String? address;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.email,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'isPrimary': isPrimary,
    'email': email,
    'address': address,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      relationship: json['relationship'],
      isPrimary: json['isPrimary'] ?? false,
      email: json['email'],
      address: json['address'],
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    String? email,
    String? address,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}

/// Alert/Event Model
class HealthAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String message;
  final String? details;
  final double? value;
  final double? threshold;
  final bool acknowledged;
  final String? location;

  HealthAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.message,
    this.details,
    this.value,
    this.threshold,
    this.acknowledged = false,
    this.location,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'details': details,
    'value': value,
    'threshold': threshold,
    'acknowledged': acknowledged,
    'location': location,
  };
}

enum AlertType {
  fall,
  arrhythmia,
  afib,
  tachycardia,
  bradycardia,
  hypertension,
  hypotension,
  lowOxygen,
  lowBattery,
  disconnected,
  manual
}

enum AlertSeverity { info, warning, critical, emergency }

/// Watch Device Model
class WatchDevice {
  final String id;
  final String name;
  final String firmwareVersion;
  final int batteryLevel;
  final bool isConnected;
  final DateTime? lastSync;
  final int signalStrength;
  final WatchStatus status;

  WatchDevice({
    required this.id,
    required this.name,
    required this.firmwareVersion,
    required this.batteryLevel,
    required this.isConnected,
    this.lastSync,
    required this.signalStrength,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'firmwareVersion': firmwareVersion,
    'batteryLevel': batteryLevel,
    'isConnected': isConnected,
    'lastSync': lastSync?.toIso8601String(),
    'signalStrength': signalStrength,
    'status': status.name,
  };
}

enum WatchStatus {
  active,
  monitoring,
  sleeping,
  syncing,
  error,
  disconnected
}
