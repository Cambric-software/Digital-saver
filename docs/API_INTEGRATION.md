# Digital Saver - Complete API Integration Documentation

> **Document Version:** 1.0.0  
> **Last Updated:** July 2026  
> **Backend:** Supabase  
> **Project:** Digital Saver Health Monitoring System  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## Table of Contents

1. [API Overview](#1-api-overview)
2. [Authentication](#2-authentication)
3. [User Profile API](#3-user-profile-api)
4. [Health Data API](#4-health-data-api)
5. [Device API](#5-device-api)
6. [Emergency Contacts API](#6-emergency-contacts-api)
7. [Goals API](#7-goals-api)
8. [Alerts API](#8-alerts-api)
9. [BLE Communication](#9-ble-communication)
10. [Error Handling](#10-error-handling)
11. [Rate Limiting](#11-rate-limiting)

---

## 1. API Overview

### Base Configuration

| Property | Value |
|----------|-------|
| **Supabase URL** | `https://dafgzzkerytjuvxzymnq.supabase.co` |
| **REST Endpoint** | `https://dafgzzkerytjuvxzymnq.supabase.co/rest/v1` |
| **Auth Endpoint** | `https://dafgzzkerytjuvxzymnq.supabase.co/auth/v1` |
| **Storage Endpoint** | `https://dafgzzkerytjuvxzymnq.supabase.co/storage/v1` |

### API Headers

```dart
// Standard headers
Map<String, String> headers = {
  'Content-Type': 'application/json',
  'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhZmd6emtlcnl0anV2eHp5bW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MTE1MDUsImV4cCI6MjA5OTI4NzUwNX0.bZdxqNuy1ZyHMGzBieq7BzUd6IUEhfHEZxL-YTka3DQ',
  'Authorization': 'Bearer ${session.accessToken}',
};
```

### Supabase Client Setup

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://dafgzzkerytjuvxzymnq.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhZmd6emtlcnl0anV2eHp5bW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MTE1MDUsImV4cCI6MjA5OTI4NzUwNX0.bZdxqNuy1ZyHMGzBieq7BzUd6IUEhfHEZxL-YTka3DQ';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: !kReleaseMode,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

---

## 2. Authentication

### Auth Service Configuration

```dart
// cambric_auth_service_v2.dart
class CambricAuth {
  static const String _supabaseUrl = 'https://dafgzzkerytjuvxzymnq.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  static SupabaseClient get client {
    _client ??= SupabaseClient(_supabaseUrl, _supabaseAnonKey);
    return _client!;
  }
}
```

### Sign Up

```dart
Future<AuthResponse> signUp({
  required String email,
  required String password,
  String? displayName,
}) async {
  final response = await SupabaseConfig.client.auth.signUp(
    email: email,
    password: password,
    data: displayName != null ? {'display_name': displayName} : null,
  );
  return response;
}
```

### Sign In

```dart
Future<AuthResponse> signIn({
  required String email,
  required String password,
}) async {
  final response = await SupabaseConfig.client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  return response;
}
```

### Sign In with Google OAuth

```dart
Future<void> signInWithGoogle() async {
  await SupabaseConfig.client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'https://cambric-software.github.io/Digital-saver/',
  );
}
```

### Sign Out

```dart
Future<void> signOut() async {
  await SupabaseConfig.client.auth.signOut();
}
```

### Get Current User

```dart
User? getCurrentUser() {
  return SupabaseConfig.client.auth.currentUser;
}
```

### Get Current Session

```dart
Session? getCurrentSession() {
  return SupabaseConfig.client.auth.currentSession;
}
```

### Auth State Listener

```dart
Stream<AuthState> authStateChanges() {
  return SupabaseConfig.client.auth.onAuthStateChange;
}
```

### Password Reset

```dart
Future<void> resetPassword(String email) async {
  await SupabaseConfig.client.auth.resetPasswordForEmail(
    email,
    redirectTo: 'https://cambric-software.github.io/Digital-saver/',
  );
}
```

### Update User

```dart
Future<User> updateUser({
  String? displayName,
  String? avatarUrl,
}) async {
  final updates = UserAttributes();
  
  if (displayName != null) {
    updates.data = {'display_name': displayName};
  }
  
  final response = await SupabaseConfig.client.auth.updateUser(updates);
  return response.user!;
}
```

---

## 3. User Profile API

### Get User Profile

```dart
Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  final response = await SupabaseConfig.client
      .from('digital_saver_user_profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
  return response;
}
```

### Create User Profile

```dart
Future<void> createUserProfile({
  required String userId,
  required String email,
  String? displayName,
}) async {
  await SupabaseConfig.client
      .from('digital_saver_user_profiles')
      .insert({
        'id': userId,
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'created_at': DateTime.now().toIso8601String(),
        'last_sync_at': DateTime.now().toIso8601String(),
      });
}
```

### Update User Profile

```dart
Future<void> updateUserProfile({
  required String userId,
  String? displayName,
  String? phone,
  double? weightKg,
  double? heightCm,
  String? gender,
  DateTime? dateOfBirth,
  String? bloodType,
}) async {
  final updates = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  if (displayName != null) updates['display_name'] = displayName;
  if (phone != null) updates['phone'] = phone;
  if (weightKg != null) updates['weight_kg'] = weightKg;
  if (heightCm != null) updates['height_cm'] = heightCm;
  if (gender != null) updates['gender'] = gender;
  if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
  if (bloodType != null) updates['blood_type'] = bloodType;
  
  await SupabaseConfig.client
      .from('digital_saver_user_profiles')
      .update(updates)
      .eq('id', userId);
}
```

### Update Emergency Contact

```dart
Future<void> updateEmergencyContact({
  required String userId,
  String? contactName,
  String? contactPhone,
}) async {
  await SupabaseConfig.client
      .from('digital_saver_user_profiles')
      .update({
        'emergency_contact_name': contactName,
        'emergency_contact_phone': contactPhone,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', userId);
}
```

### Delete User Profile

```dart
Future<void> deleteUserProfile(String userId) async {
  await SupabaseConfig.client
      .from('digital_saver_user_profiles')
      .delete()
      .eq('id', userId);
}
```

---

## 4. Health Data API

### Insert Health Log

```dart
Future<String> insertHealthLog({
  required String userId,
  required String dataType,
  int? heartRate,
  int? systolicBp,
  int? diastolicBp,
  double? spo2,
  int? steps,
  double? calories,
  int? sleepMinutes,
  double? hrvRmssd,
  double? hrvSdnn,
  bool? afibDetected,
  Map<String, dynamic>? metadata,
}) async {
  final data = <String, dynamic>{
    'user_id': userId,
    'data_type': dataType,
    'recorded_at': DateTime.now().toIso8601String(),
    'source': 'device',
    'quality_score': 100,
  };
  
  if (heartRate != null) data['heart_rate'] = heartRate;
  if (systolicBp != null) data['systolic_bp'] = systolicBp;
  if (diastolicBp != null) data['diastolic_bp'] = diastolicBp;
  if (spo2 != null) data['spo2'] = spo2;
  if (steps != null) data['steps'] = steps;
  if (calories != null) data['calories_burned'] = calories;
  if (sleepMinutes != null) data['sleep_minutes'] = sleepMinutes;
  if (hrvRmssd != null) data['hrv_rmssd'] = hrvRmssd;
  if (hrvSdnn != null) data['hrv_sdnn'] = hrvSdnn;
  if (afibDetected != null) data['afib_detected'] = afibDetected;
  if (metadata != null) data['metadata'] = metadata;
  
  final response = await SupabaseConfig.client
      .from('digital_saver_health_logs')
      .insert(data)
      .select('id')
      .single();
  
  return response['id'];
}
```

### Get Health Logs

```dart
Future<List<Map<String, dynamic>>> getHealthLogs({
  required String userId,
  String? dataType,
  DateTime? startDate,
  DateTime? endDate,
  int? limit,
}) async {
  var query = SupabaseConfig.client
      .from('digital_saver_health_logs')
      .select()
      .eq('user_id', userId)
      .order('recorded_at', ascending: false);
  
  if (dataType != null) {
    query = query.eq('data_type', dataType);
  }
  
  if (startDate != null) {
    query = query.gte('recorded_at', startDate.toIso8601String());
  }
  
  if (endDate != null) {
    query = query.lte('recorded_at', endDate.toIso8601String());
  }
  
  if (limit != null) {
    query = query.limit(limit);
  }
  
  return await query;
}
```

### Get Latest Health Log

```dart
Future<Map<String, dynamic>?> getLatestHealthLog(String userId) async {
  return await SupabaseConfig.client
      .from('digital_saver_health_logs')
      .select()
      .eq('user_id', userId)
      .order('recorded_at', ascending: false)
      .limit(1)
      .maybeSingle();
}
```

### Get Daily Aggregates

```dart
Future<List<Map<String, dynamic>>> getDailyAggregates({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  return await SupabaseConfig.client
      .from('digital_saver_daily_aggregates')
      .select()
      .eq('user_id', userId)
      .gte('date', startDate.toIso8601String().split('T')[0])
      .lte('date', endDate.toIso8601String().split('T')[0])
      .order('date', ascending: false);
}
```

### Batch Insert Health Logs

```dart
Future<void> batchInsertHealthLogs(List<Map<String, dynamic>> logs) async {
  await SupabaseConfig.client
      .from('digital_saver_health_logs')
      .insert(logs);
}
```

### Delete Old Health Logs

```dart
Future<int> deleteOldHealthLogs({
  required String userId,
  required DateTime cutoffDate,
}) async {
  final response = await SupabaseConfig.client
      .from('digital_saver_health_logs')
      .delete()
      .eq('user_id', userId)
      .lt('recorded_at', cutoffDate.toIso8601String());
  
  return response.length;
}
```

---

## 5. Device API

### Register Device

```dart
Future<String> registerDevice({
  required String userId,
  required String deviceName,
  required String deviceType,
  String? manufacturer,
  String? model,
  String? serialNumber,
  String? firmwareVersion,
}) async {
  final data = <String, dynamic>{
    'user_id': userId,
    'device_name': deviceName,
    'device_type': deviceType,
    'is_active': true,
    'created_at': DateTime.now().toIso8601String(),
  };
  
  if (manufacturer != null) data['manufacturer'] = manufacturer;
  if (model != null) data['model'] = model;
  if (serialNumber != null) data['serial_number'] = serialNumber;
  if (firmwareVersion != null) data['firmware_version'] = firmwareVersion;
  
  final response = await SupabaseConfig.client
      .from('digital_saver_devices')
      .insert(data)
      .select('id')
      .single();
  
  return response['id'];
}
```

### Get User Devices

```dart
Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
  return await SupabaseConfig.client
      .from('digital_saver_devices')
      .select()
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', ascending: false);
}
```

### Update Device Battery

```dart
Future<void> updateDeviceBattery({
  required String deviceId,
  required int batteryLevel,
}) async {
  await SupabaseConfig.client
      .from('digital_saver_devices')
      .update({
        'battery_level': batteryLevel,
        'last_sync_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', deviceId);
}
```

### Delete Device

```dart
Future<void> deleteDevice(String deviceId) async {
  await SupabaseConfig.client
      .from('digital_saver_devices')
      .update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', deviceId);
}
```

---

## 6. Emergency Contacts API

### Add Emergency Contact

```dart
Future<String> addEmergencyContact({
  required String userId,
  required String name,
  required String phone,
  String? email,
  String? relationship,
  int priority = 1,
  bool isPrimary = false,
}) async {
  final data = <String, dynamic>{
    'user_id': userId,
    'name': name,
    'phone': phone,
    'priority': priority,
    'is_primary': isPrimary,
    'notify_in_emergency': true,
    'created_at': DateTime.now().toIso8601String(),
  };
  
  if (email != null) data['email'] = email;
  if (relationship != null) data['relationship'] = relationship;
  
  final response = await SupabaseConfig.client
      .from('digital_saver_emergency_contacts')
      .insert(data)
      .select('id')
      .single();
  
  return response['id'];
}
```

### Get Emergency Contacts

```dart
Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
  return await SupabaseConfig.client
      .from('digital_saver_emergency_contacts')
      .select()
      .eq('user_id', userId)
      .eq('notify_in_emergency', true)
      .order('priority', ascending: true);
}
```

### Update Emergency Contact

```dart
Future<void> updateEmergencyContact({
  required String contactId,
  String? name,
  String? phone,
  String? email,
  String? relationship,
  int? priority,
  bool? isPrimary,
}) async {
  final updates = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  if (name != null) updates['name'] = name;
  if (phone != null) updates['phone'] = phone;
  if (email != null) updates['email'] = email;
  if (relationship != null) updates['relationship'] = relationship;
  if (priority != null) updates['priority'] = priority;
  if (isPrimary != null) updates['is_primary'] = isPrimary;
  
  await SupabaseConfig.client
      .from('digital_saver_emergency_contacts')
      .update(updates)
      .eq('id', contactId);
}
```

### Delete Emergency Contact

```dart
Future<void> deleteEmergencyContact(String contactId) async {
  await SupabaseConfig.client
      .from('digital_saver_emergency_contacts')
      .delete()
      .eq('id', contactId);
}
```

---

## 7. Goals API

### Create Health Goal

```dart
Future<String> createHealthGoal({
  required String userId,
  required String goalType,
  required double targetValue,
  String? unit,
  DateTime? targetDate,
  String? notes,
}) async {
  final response = await SupabaseConfig.client
      .from('digital_saver_health_goals')
      .insert({
        'user_id': userId,
        'goal_type': goalType,
        'target_value': targetValue,
        'unit': unit,
        'target_date': targetDate?.toIso8601String().split('T')[0],
        'status': 'active',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      })
      .select('id')
      .single();
  
  return response['id'];
}
```

### Get User Goals

```dart
Future<List<Map<String, dynamic>>> getUserGoals({
  required String userId,
  String? status,
}) async {
  var query = SupabaseConfig.client
      .from('digital_saver_health_goals')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  
  if (status != null) {
    query = query.eq('status', status);
  }
  
  return await query;
}
```

### Update Goal Progress

```dart
Future<void> updateGoalProgress({
  required String goalId,
  required double currentValue,
}) async {
  final response = await SupabaseConfig.client
      .from('digital_saver_health_goals')
      .select('target_value')
      .eq('id', goalId)
      .single();
  
  final targetValue = response['target_value'] as double;
  final progressPercentage = (currentValue / targetValue * 100).clamp(0.0, 100.0);
  final status = progressPercentage >= 100 ? 'completed' : 'active';
  
  await SupabaseConfig.client
      .from('digital_saver_health_goals')
      .update({
        'current_value': currentValue,
        'progress_percentage': progressPercentage,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', goalId);
}
```

### Delete Goal

```dart
Future<void> deleteGoal(String goalId) async {
  await SupabaseConfig.client
      .from('digital_saver_health_goals')
      .delete()
      .eq('id', goalId);
}
```

---

## 8. Alerts API

### Get User Alerts

```dart
Future<List<Map<String, dynamic>>> getUserAlerts({
  required String userId,
  bool? unreadOnly,
  int? limit,
}) async {
  var query = SupabaseConfig.client
      .from('digital_saver_health_alerts')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  
  if (unreadOnly == true) {
    query = query.eq('is_read', false);
  }
  
  if (limit != null) {
    query = query.limit(limit);
  }
  
  return await query;
}
```

### Create Alert

```dart
Future<String> createAlert({
  required String userId,
  required String alertType,
  required String severity,
  required String title,
  String? message,
  double? valueAtAlert,
  double? thresholdValue,
}) async {
  final response = await SupabaseConfig.client
      .from('digital_saver_health_alerts')
      .insert({
        'user_id': userId,
        'alert_type': alertType,
        'severity': severity,
        'title': title,
        'message': message,
        'value_at_alert': valueAtAlert,
        'threshold_value': thresholdValue,
        'created_at': DateTime.now().toIso8601String(),
      })
      .select('id')
      .single();
  
  return response['id'];
}
```

### Mark Alert as Read

```dart
Future<void> markAlertAsRead(String alertId) async {
  await SupabaseConfig.client
      .from('digital_saver_health_alerts')
      .update({'is_read': true})
      .eq('id', alertId);
}
```

### Acknowledge Alert

```dart
Future<void> acknowledgeAlert(String alertId) async {
  await SupabaseConfig.client
      .from('digital_saver_health_alerts')
      .update({
        'is_acknowledged': true,
        'acknowledged_at': DateTime.now().toIso8601String(),
      })
      .eq('id', alertId);
}
```

---

## 9. BLE Communication

### BLE Service Configuration

```dart
class BleConfig {
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String deviceNamePrefix = 'Digital Saver';
  
  static const Duration scanTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}
```

### BLE Data Format

```json
{
  "hr": 72,
  "spo2": 98,
  "bps": 118,
  "bpd": 76,
  "hrv": 45.2,
  "steps": 6234,
  "cal": 312.5,
  "temp": 36.7,
  "irreg": 0,
  "fall": 0,
  "ax": 0.01,
  "ay": 0.02,
  "az": 0.98
}
```

### Parse BLE Data

```dart
class BleDataParser {
  static HealthData parse(String jsonString) {
    final data = json.decode(jsonString);
    
    return HealthData(
      heartRate: data['hr'] ?? 0,
      spO2: data['spo2']?.toDouble() ?? 0.0,
      systolicBp: data['bps'] ?? 0,
      diastolicBp: data['bpd'] ?? 0,
      hrvRmssd: data['hrv']?.toDouble() ?? 0.0,
      steps: data['steps'] ?? 0,
      calories: data['cal']?.toDouble() ?? 0.0,
      temperature: data['temp']?.toDouble() ?? 0.0,
      irregularBeat: (data['irreg'] ?? 0) == 1,
      fallDetected: (data['fall'] ?? 0) == 1,
      accelX: data['ax']?.toDouble() ?? 0.0,
      accelY: data['ay']?.toDouble() ?? 0.0,
      accelZ: data['az']?.toDouble() ?? 0.0,
    );
  }
}
```

---

## 10. Error Handling

### Error Types

```dart
enum AppError {
  networkError,
  authError,
  databaseError,
  bleError,
  validationError,
  unknownError,
}
```

### Error Handling Pattern

```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  
  Result.success(this.data) : error = null, isSuccess = true;
  Result.failure(this.error) : data = null, isSuccess = false;
}

Future<Result<Map<String, dynamic>>> fetchWithErrorHandling(
  Future<Map<String, dynamic>> Function() fetch,
) async {
  try {
    final data = await fetch();
    return Result.success(data);
  } on AuthException catch (e) {
    return Result.failure('Authentication failed: ${e.message}');
  } on NetworkException {
    return Result.failure('Network error. Please check your connection.');
  } on DatabaseException catch (e) {
    return Result.failure('Database error: ${e.message}');
  } catch (e) {
    return Result.failure('An unexpected error occurred');
  }
}
```

---

## 11. Rate Limiting

### Rate Limit Headers

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Max requests per period |
| `X-RateLimit-Remaining` | Remaining requests |
| `X-RateLimit-Reset` | Unix timestamp when limit resets |

### Best Practices

```dart
class RateLimitedClient {
  int _requestsThisMinute = 0;
  DateTime _minuteStart = DateTime.now();
  
  Future<T> request<T>(Future<T> Function() request) async {
    // Reset counter if minute has passed
    if (DateTime.now().difference(_minuteStart).inSeconds >= 60) {
      _requestsThisMinute = 0;
      _minuteStart = DateTime.now();
    }
    
    // Check rate limit
    if (_requestsThisMinute >= 60) {
      throw RateLimitException('Too many requests. Please wait.');
    }
    
    _requestsThisMinute++;
    return await request();
  }
}
```

---

**Document Version:** 1.0.0  
**Last Updated:** July 2026  
**Author:** Cambric Engineering Team  
**Copyright © 2026 Cambric. All Rights Reserved.**
