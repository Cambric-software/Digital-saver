/// Health data model for sensor readings
class HealthData {
  final int heartRate;
  final int? spO2;
  final int? systolic;
  final int? diastolic;
  final double? confidence;
  final DateTime timestamp;
  final HealthStatus status;

  HealthData({
    required this.heartRate,
    this.spO2,
    this.systolic,
    this.diastolic,
    this.confidence,
    required this.timestamp,
    this.status = HealthStatus.normal,
  });

  factory HealthData.fromPacket(List<int> data) {
    if (data.length < 3) throw FormatException('Invalid health data packet');
    
    return HealthData(
      heartRate: data[1],
      spO2: data.length > 2 ? data[2] : null,
      confidence: data.length > 3 ? data[3].toDouble() : null,
      timestamp: DateTime.now(),
      status: _determineStatus(data[1]),
    );
  }

  static HealthStatus _determineStatus(int hr) {
    if (hr < 50 || hr > 120) return HealthStatus.alert;
    if (hr < 60 || hr > 100) return HealthStatus.warning;
    return HealthStatus.normal;
  }

  String get bloodPressureString => systolic != null && diastolic != null 
      ? '$systolic/$diastolic' 
      : '--/--';

  Map<String, dynamic> toJson() => {
    'heartRate': heartRate,
    'spO2': spO2,
    'systolic': systolic,
    'diastolic': diastolic,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
  };
}

enum HealthStatus { normal, warning, alert }

/// Blood pressure estimation data
class BloodPressureData {
  final int systolic;
  final int diastolic;
  final int map; // Mean Arterial Pressure
  final int confidence;
  final DateTime timestamp;

  BloodPressureData({
    required this.systolic,
    required this.diastolic,
    required this.map,
    required this.confidence,
    required this.timestamp,
  });

  factory BloodPressureData.fromPacket(List<int> data) {
    if (data.length < 4) throw FormatException('Invalid BP packet');
    
    return BloodPressureData(
      systolic: data[1],
      diastolic: data[2],
      map: data[3],
      confidence: data.length > 4 ? data[4] : 70,
      timestamp: DateTime.now(),
    );
  }

  BpCategory get category {
    if (systolic < 120 && diastolic < 80) return BpCategory.normal;
    if (systolic < 130 && diastolic < 80) return BpCategory.elevated;
    if (systolic < 140 || diastolic < 90) return BpCategory.stage1;
    if (systolic < 180 || diastolic < 120) return BpCategory.stage2;
    return BpCategory.crisis;
  }

  String get displayString => '$systolic/$diastolic mmHg';
}

enum BpCategory { normal, elevated, stage1, stage2, crisis }

/// Alert data from the watch
class AlertData {
  final AlertType type;
  final AlertSeverity severity;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  AlertData({
    required this.type,
    required this.severity,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory AlertData.fromPacket(List<int> data) {
    if (data.length < 3) throw FormatException('Invalid alert packet');
    
    return AlertData(
      type: AlertType.values[data[1] - 1],
      severity: AlertSeverity.values[data[2] - 1],
      timestamp: DateTime.now(),
    );
  }

  String get message {
    switch (type) {
      case AlertType.fall:
        return 'Fall detected! Are you okay?';
      case AlertType.arrhythmia:
        return 'Irregular heartbeat detected!';
      case AlertType.hypertension:
        return 'High blood pressure detected!';
    }
  }
}

enum AlertType { fall, arrhythmia, hypertension }

enum AlertSeverity { warning, critical }

/// Emergency contact model
class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'isPrimary': isPrimary,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
      relationship: json['relationship'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}
