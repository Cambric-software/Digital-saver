import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:digital_saver/models/health_models.dart';

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
  String? _userId;
  String? _userName;
  int? _userAge;
  String? _userGender;

  Locale get locale => _locale;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  int get heartRateThreshold => _heartRateThreshold;
  int get systolicThreshold => _systolicThreshold;
  String? get userId => _userId;
  String? get userName => _userName;
  int? get userAge => _userAge;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load user data
    _userId = _prefs.getString('userId') ?? const Uuid().v4();
    _userName = _prefs.getString('userName');
    _userAge = _prefs.getInt('userAge');
    _userGender = _prefs.getString('userGender');
    
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
        
        await db.execute('''
          CREATE TABLE daily_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            steps INTEGER,
            calories INTEGER,
            distance REAL,
            active_minutes INTEGER,
            sleep_hours REAL,
            avg_heart_rate INTEGER,
            avg_bp_sys INTEGER,
            avg_bp_dia INTEGER,
            health_score INTEGER
          )
        ''');
      },
    );

    // Save user ID
    await _prefs.setString('userId', _userId!);
    
    notifyListeners();
  }

  // User profile
  Future<void> updateUserProfile({
    String? name,
    int? age,
    String? gender,
  }) async {
    if (name != null) {
      _userName = name;
      await _prefs.setString('userName', name);
    }
    if (age != null) {
      _userAge = age;
      await _prefs.setInt('userAge', age);
    }
    if (gender != null) {
      _userGender = gender;
      await _prefs.setString('userGender', gender);
    }
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
  Future<void> saveHealthRecord(HealthMetrics data) async {
    await _db.insert('health_records', {
      'heart_rate': data.heartRate.currentBPM,
      'sp_o2': data.oxygen.spO2,
      'systolic': data.bloodPressure.systolic,
      'diastolic': data.bloodPressure.diastolic,
      'confidence': data.heartRate.confidence,
      'status': data.heartRate.status.index,
      'timestamp': data.timestamp.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHealthHistory({int limit = 100}) async {
    return await _db.query(
      'health_records',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<void> saveDailyStats({
    required DateTime date,
    required int steps,
    required int calories,
    required double distance,
    required int activeMinutes,
    required double sleepHours,
    required int avgHeartRate,
    required int avgBpSys,
    required int avgBpDia,
    required int healthScore,
  }) async {
    await _db.insert('daily_stats', {
      'date': date.toIso8601String().split('T')[0],
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'active_minutes': activeMinutes,
      'sleep_hours': sleepHours,
      'avg_heart_rate': avgHeartRate,
      'avg_bp_sys': avgBpSys,
      'avg_bp_dia': avgBpDia,
      'health_score': healthScore,
    });
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return await _db.query(
      'daily_stats',
      where: 'date >= ?',
      whereArgs: [weekAgo.toIso8601String().split('T')[0]],
      orderBy: 'date ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats() async {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return await _db.query(
      'daily_stats',
      where: 'date >= ?',
      whereArgs: [monthAgo.toIso8601String().split('T')[0]],
      orderBy: 'date ASC',
    );
  }

  // Export data
  Future<String> exportData() async {
    final history = await getHealthHistory();
    final weekly = await getWeeklyStats();
    
    return jsonEncode({
      'userId': _userId,
      'userName': _userName,
      'userAge': _userAge,
      'userGender': _userGender,
      'emergencyContacts': _emergencyContacts.map((c) => c.toJson()).toList(),
      'healthHistory': history,
      'weeklyStats': weekly,
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _db.delete('health_records');
    await _db.delete('alerts');
    await _db.delete('daily_stats');
    _emergencyContacts.clear();
    await _saveContacts();
    notifyListeners();
  }
}
