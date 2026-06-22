import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:digital_saver/models/health_data.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  late Database _db;
  
  Locale _locale = const Locale('en');
  List<EmergencyContact> _emergencyContacts = [];
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  int _heartRateThreshold = 100;
  int _systolicThreshold = 140;

  Locale get locale => _locale;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  int get heartRateThreshold => _heartRateThreshold;
  int get systolicThreshold => _systolicThreshold;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved preferences
    final localeCode = _prefs.getString('locale') ?? 'en';
    _locale = Locale(localeCode);
    _isDarkMode = _prefs.getBool('darkMode') ?? false;
    _notificationsEnabled = _prefs.getBool('notifications') ?? true;
    _heartRateThreshold = _prefs.getInt('hrThreshold') ?? 100;
    _systolicThreshold = _prefs.getInt('systolicThreshold') ?? 140;

    // Load emergency contacts
    final contactsJson = _prefs.getString('emergencyContacts');
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      _emergencyContacts = decoded
          .map((e) => EmergencyContact.fromJson(e))
          .toList();
    }

    // Initialize database
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digital_saver.db');
    
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE health_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            heart_rate INTEGER,
            sp_o2 INTEGER,
            systolic INTEGER,
            diastolic INTEGER,
            confidence REAL,
            status INTEGER,
            timestamp TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            alert_type INTEGER,
            severity INTEGER,
            latitude REAL,
            longitude REAL,
            timestamp TEXT
          )
        ''');
      },
    );

    notifyListeners();
  }

  // Locale management
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  // Theme management
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('darkMode', value);
    notifyListeners();
  }

  // Notification settings
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notifications', value);
    notifyListeners();
  }

  // Threshold settings
  Future<void> setHeartRateThreshold(int value) async {
    _heartRateThreshold = value;
    await _prefs.setInt('hrThreshold', value);
    notifyListeners();
  }

  Future<void> setSystolicThreshold(int value) async {
    _systolicThreshold = value;
    await _prefs.setInt('systolicThreshold', value);
    notifyListeners();
  }

  // Emergency contacts management
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _emergencyContacts.add(contact);
    await _saveContacts();
    notifyListeners();
  }

  Future<void> updateEmergencyContact(int index, EmergencyContact contact) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      _emergencyContacts[index] = contact;
      await _saveContacts();
      notifyListeners();
    }
  }

  Future<void> removeEmergencyContact(int index) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      _emergencyContacts.removeAt(index);
      await _saveContacts();
      notifyListeners();
    }
  }

  Future<void> _saveContacts() async {
    final encoded = jsonEncode(_emergencyContacts.map((c) => c.toJson()).toList());
    await _prefs.setString('emergencyContacts', encoded);
  }

  // Health data storage
  Future<void> saveHealthRecord(HealthData data) async {
    await _db.insert('health_records', {
      'heart_rate': data.heartRate,
      'sp_o2': data.spO2,
      'systolic': data.systolic,
      'diastolic': data.diastolic,
      'confidence': data.confidence,
      'status': data.status.index,
      'timestamp': data.timestamp.toIso8601String(),
    });
  }

  Future<List<HealthData>> getHealthHistory({int limit = 100}) async {
    final records = await _db.query(
      'health_records',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return records.map((r) => HealthData(
      heartRate: r['heart_rate'] as int,
      spO2: r['sp_o2'] as int?,
      systolic: r['systolic'] as int?,
      diastolic: r['diastolic'] as int?,
      confidence: r['confidence'] as double?,
      timestamp: DateTime.parse(r['timestamp'] as String),
      status: HealthStatus.values[r['status'] as int],
    )).toList();
  }

  Future<void> saveAlert(AlertData alert) async {
    await _db.insert('alerts', {
      'alert_type': alert.type.index + 1,
      'severity': alert.severity.index + 1,
      'latitude': alert.latitude,
      'longitude': alert.longitude,
      'timestamp': alert.timestamp.toIso8601String(),
    });
  }

  Future<List<AlertData>> getAlertHistory({int limit = 50}) async {
    final records = await _db.query(
      'alerts',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return records.map((r) => AlertData(
      type: AlertType.values[(r['alert_type'] as int) - 1],
      severity: AlertSeverity.values[(r['severity'] as int) - 1],
      timestamp: DateTime.parse(r['timestamp'] as String),
      latitude: r['latitude'] as double?,
      longitude: r['longitude'] as double?,
    )).toList();
  }
}
