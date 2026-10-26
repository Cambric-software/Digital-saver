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

class TemperatureData {
  final double temperature; // Body temperature in Celsius
  final int confidence;
  final DateTime timestamp;

  TemperatureData({
    this.temperature = 0,
    this.confidence = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get temperatureStatus {
    if (temperature >= 36.1 && temperature <= 37.2) return 'Normal';
    if (temperature < 36.1) return 'Low';
    if (temperature <= 38.0) return 'Elevated';
    return 'Fever';
  }

  bool get isFever => temperature > 38.0;
  bool get isHypothermia => temperature < 35.0;
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
  // Basic Info
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String gender;
  
  // Physical Stats
  final int age;
  final double weightKg;
  final double heightCm;
  
  // Medical Info
  final String? bloodType;
  final List<String> medicalConditions;
  final List<String> allergies;
  final List<String> medications;
  
  // Emergency Contact (Primary)
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  
  // Insurance
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  
  // Preferences
  final String language;
  final String timezone;
  final bool notificationEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsAlerts;
  
  // Consent
  final bool dataSharingConsent;
  final bool researchConsent;
  
  // Legacy emergency contacts for backwards compatibility
  final List<EmergencyContact> emergencyContacts;

  UserProfile({
    this.name = '',
    this.email = '',
    this.phone,
    this.dateOfBirth,
    this.gender = 'male',
    this.age = 30,
    this.weightKg = 70,
    this.heightCm = 170,
    this.bloodType,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.language = 'en',
    this.timezone = 'UTC',
    this.notificationEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsAlerts = false,
    this.dataSharingConsent = false,
    this.researchConsent = false,
    this.emergencyContacts = const [],
  });

  double get bmi => heightCm > 0 && heightCm != 0 ? weightKg / ((heightCm / 100) * (heightCm / 100)) : 0;

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
  
  /// Check which required fields are missing
  List<String> get missingRequiredFields {
    final missing = <String>[];
    
    if (name.isEmpty) missing.add('name');
    if (age == 0 || age < 1) missing.add('age');
    if (weightKg == 0) missing.add('weight');
    if (heightCm == 0) missing.add('height');
    if (bloodType == null || bloodType!.isEmpty) missing.add('bloodType');
    if (emergencyContactName == null || emergencyContactName!.isEmpty) missing.add('emergencyContact');
    if (emergencyContactPhone == null || emergencyContactPhone!.isEmpty) missing.add('emergencyPhone');
    
    return missing;
  }
  
  /// Check if profile is complete enough for emergency services
  bool get isProfileComplete => missingRequiredFields.isEmpty;
  
  /// Copy with updates
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    List<String>? medicalConditions,
    List<String>? allergies,
    List<String>? medications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    String? language,
    String? timezone,
    bool? notificationEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsAlerts,
    bool? dataSharingConsent,
    bool? researchConsent,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      dataSharingConsent: dataSharingConsent ?? this.dataSharingConsent,
      researchConsent: researchConsent ?? this.researchConsent,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
