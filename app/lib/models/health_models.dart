class HeartRateData {
  final int bpm;
  final int confidence;
  final int hrv; // RMSSD in ms
  final int sdnn;
  final int pnn50;
  final int afibProbability;
  final int status; // 0=normal, 1=warning, 2=critical
  final List<int> rrIntervals;
  final DateTime timestamp;

  HeartRateData({
    this.bpm = 0,
    this.confidence = 0,
    this.hrv = 0,
    this.sdnn = 0,
    this.pnn50 = 0,
    this.afibProbability = 0,
    this.status = 0,
    this.rrIntervals = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get statusLabel {
    if (status == 2) return 'Critical';
    if (status == 1) return 'Warning';
    return 'Normal';
  }

  bool get isAFib => afibProbability > 50;
}

class BloodPressureData {
  final int systolic;
  final int diastolic;
  final int map;
  final int pulsePressure;
  final double augmentationIndex;
  final double pulseWaveVelocity;
  final int confidence;
  final DateTime timestamp;

  BloodPressureData({
    this.systolic = 0,
    this.diastolic = 0,
    this.map = 0,
    this.pulsePressure = 0,
    this.augmentationIndex = 0,
    this.pulseWaveVelocity = 0,
    this.confidence = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get category {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 && diastolic < 90) return 'High Stage 1';
    return 'High Stage 2';
  }

  int get vascularAge {
    if (pulseWaveVelocity < 6) return 25;
    if (pulseWaveVelocity < 8) return 35;
    if (pulseWaveVelocity < 10) return 50;
    return 65;
  }
}

class OxygenData {
  final int spO2;
  final int perfusionIndex;
  final int respirationRate;
  final int confidence;
  final DateTime timestamp;

  OxygenData({
    this.spO2 = 0,
    this.perfusionIndex = 0,
    this.respirationRate = 0,
    this.confidence = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get spO2Status {
    if (spO2 >= 95) return 'Normal';
    if (spO2 >= 90) return 'Low';
    return 'Critical';
  }
}

class AccelData {
  final double x, y, z;
  final bool fallDetected;
  final bool locSuspected;
  final DateTime timestamp;

  AccelData({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.fallDetected = false,
    this.locSuspected = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ActivityData {
  final int steps;
  final double calories;
  final double distanceKm;
  final int activeMinutes;
  final List<int> hourlySteps;
  final DateTime date;

  ActivityData({
    this.steps = 0,
    this.calories = 0,
    this.distanceKm = 0,
    this.activeMinutes = 0,
    this.hourlySteps = const [],
    DateTime? date,
  }) : date = date ?? DateTime.now();

  int get stepsGoal => 10000;
  double get progress => (steps / stepsGoal).clamp(0.0, 1.0);
}

class SleepData {
  final DateTime bedtime;
  final DateTime wakeTime;
  final int deepSleepMinutes;
  final int lightSleepMinutes;
  final int remSleepMinutes;
  final int awakeMinutes;
  final int qualityScore;

  SleepData({
    DateTime? bedtime,
    DateTime? wakeTime,
    this.deepSleepMinutes = 0,
    this.lightSleepMinutes = 0,
    this.remSleepMinutes = 0,
    this.awakeMinutes = 0,
    this.qualityScore = 0,
  })  : bedtime = bedtime ?? DateTime.now().subtract(const Duration(hours: 8)),
        wakeTime = wakeTime ?? DateTime.now();

  int get totalMinutes =>
      deepSleepMinutes + lightSleepMinutes + remSleepMinutes;

  String get duration {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  String get qualityLabel {
    if (qualityScore >= 80) return 'Excellent';
    if (qualityScore >= 60) return 'Good';
    if (qualityScore >= 40) return 'Fair';
    return 'Poor';
  }
}

class HealthSnapshot {
  final HeartRateData heartRate;
  final BloodPressureData bloodPressure;
  final OxygenData oxygen;
  final ActivityData activity;
  final SleepData sleep;
  final int healthScore;

  HealthSnapshot({
    required this.heartRate,
    required this.bloodPressure,
    required this.oxygen,
    required this.activity,
    required this.sleep,
    this.healthScore = 0,
  });
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, String> toMap() =>
      {'name': name, 'phone': phone, 'relation': relation};

  factory EmergencyContact.fromMap(Map<String, String> m) => EmergencyContact(
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        relation: m['relation'] ?? '',
      );
}

class UserProfile {
  final String name;
  final int age;
  final double weightKg;
  final double heightCm;
  final String gender;
  final List<EmergencyContact> emergencyContacts;
  final String language;

  UserProfile({
    this.name = '',
    this.age = 30,
    this.weightKg = 70,
    this.heightCm = 170,
    this.gender = 'Male',
    this.emergencyContacts = const [],
    this.language = 'en',
  });

  double get bmi => heightCm > 0 && heightCm != 0 ? weightKg / ((heightCm / 100) * (heightCm / 100)) : 0;

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}
