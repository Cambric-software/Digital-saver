import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:digital_saver/models/health_models.dart';

class EmergencyService extends ChangeNotifier {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _emergencyActive = false;
  Position? _lastLocation;
  Timer? _alertTimer;
  int _alertCount = 0;
  static const int maxAlerts = 3;
  
  List<HealthAlert> _recentAlerts = [];

  bool get emergencyActive => _emergencyActive;
  Position? get lastLocation => _lastLocation;
  List<HealthAlert> get recentAlerts => _recentAlerts;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }

  Future<void> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Future<Position> getCurrentLocation() async {
    await checkAndRequestPermissions();
    _lastLocation = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return _lastLocation!;
  }

  Future<void> triggerEmergency({
    required AlertType type,
    required AlertSeverity severity,
    required List<EmergencyContact> contacts,
    HealthAlert? existingAlert,
  }) async {
    if (_emergencyActive) return;
    
    _emergencyActive = true;
    _alertCount = 0;
    notifyListeners();

    try {
      // Get location
      Position? location;
      try {
        location = await getCurrentLocation();
      } catch (e) {
        debugPrint('Could not get location: $e');
      }
      
      final locationString = location != null 
          ? 'https://maps.google.com/?q=${location.latitude},${location.longitude}'
          : 'Location unavailable';
      
      // Build emergency message
      final message = _buildEmergencyMessage(type, severity, locationString, existingAlert);
      
      // Send SMS to all contacts
      for (final contact in contacts) {
        await _sendSms(contact.phone, message);
      }

      // Call primary contact
      if (contacts.isNotEmpty) {
        final primaryContact = contacts.firstWhere(
          (c) => c.isPrimary,
          orElse: () => contacts.first,
        );
        
        // Show notification
        await _showEmergencyNotification(type, severity);
        
        // Start auto-dial timer
        _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
          _alertCount++;
          if (_alertCount >= maxAlerts) {
            await callEmergency(primaryContact.phone);
            _emergencyActive = false;
            timer.cancel();
            notifyListeners();
          }
        });
      }

    } catch (e) {
      debugPrint('Emergency trigger error: $e');
      _emergencyActive = false;
      notifyListeners();
    }
  }

  String _buildEmergencyMessage(
    AlertType type, 
    AlertSeverity severity, 
    String location,
    HealthAlert? alert,
  ) {
    final timestamp = DateTime.now();
    final timeStr = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    String condition = '';
    switch (type) {
      case AlertType.fall:
        condition = '🚨 FALL DETECTED - Possible loss of consciousness';
        break;
      case AlertType.arrhythmia:
      case AlertType.afib:
        condition = '❤️ IRREGULAR HEARTBEAT DETECTED';
        break;
      case AlertType.tachycardia:
        condition = '❤️ FAST HEART RATE DETECTED';
        break;
      case AlertType.bradycardia:
        condition = '❤️ SLOW HEART RATE DETECTED';
        break;
      case AlertType.hypertension:
        condition = '🩸 HIGH BLOOD PRESSURE DETECTED';
        break;
      case AlertType.hypotension:
        condition = '🩸 LOW BLOOD PRESSURE DETECTED';
        break;
      case AlertType.lowOxygen:
        condition = '🫁 LOW OXYGEN LEVEL DETECTED';
        break;
      case AlertType.lowBattery:
        condition = '⚠️ WATCH BATTERY LOW';
        break;
      case AlertType.disconnected:
        condition = '⚠️ WATCH DISCONNECTED';
        break;
      case AlertType.manual:
        condition = '🚨 MANUAL EMERGENCY ALERT';
        break;
    }

    String severityText = '';
    switch (severity) {
      case AlertSeverity.emergency:
        severityText = '⚠️ IMMEDIATE ACTION REQUIRED';
        break;
      case AlertSeverity.critical:
        severityText = '⚠️ CRITICAL ALERT';
        break;
      case AlertSeverity.warning:
        severityText = '⚡ WARNING';
        break;
      case AlertSeverity.info:
        severityText = 'ℹ️ INFO';
        break;
    }

    final buffer = StringBuffer();
    buffer.writeln('🚨 DIGITAL SAVER EMERGENCY 🚨');
    buffer.writeln();
    buffer.writeln(severityText);
    buffer.writeln(condition);
    buffer.writeln();
    buffer.writeln('Time: $timeStr');
    buffer.writeln('Location: $location');
    buffer.writeln();
    
    if (alert?.value != null) {
      buffer.writeln('Value: ${alert!.value}');
    }
    
    buffer.writeln();
    buffer.writeln('Please check on the wearer immediately.');
    buffer.writeln();
    buffer.writeln('Emergency services: 123 (Egypt) / 112 (EU) / 911 (US)');
    buffer.writeln();
    buffer.writeln('Sent by Digital Saver Health App');

    return buffer.toString();
  }

  Future<void> _sendSms(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> callEmergency(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> callEmergencyServices() async {
    // Egypt emergency number
    const emergencyNumber = '123';
    await callEmergency(emergencyNumber);
  }

  Future<void> _showEmergencyNotification(AlertType type, AlertSeverity severity) async {
    String title;
    String body;
    
    switch (type) {
      case AlertType.fall:
        title = 'Fall Detected!';
        body = 'Emergency alert has been sent to your contacts.';
        break;
      case AlertType.arrhythmia:
      case AlertType.afib:
        title = 'Irregular Heartbeat!';
        body = 'Please check on the wearer immediately.';
        break;
      default:
        title = 'Emergency Alert';
        body = 'Please check on the wearer immediately.';
    }

    final androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Emergency alert notifications',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  void cancelEmergency() {
    _alertTimer?.cancel();
    _notifications.cancel(0);
    _emergencyActive = false;
    _alertCount = 0;
    notifyListeners();
  }

  void addRecentAlert(HealthAlert alert) {
    _recentAlerts.insert(0, alert);
    if (_recentAlerts.length > 20) {
      _recentAlerts.removeLast();
    }
    notifyListeners();
  }

  void clearRecentAlerts() {
    _recentAlerts.clear();
    notifyListeners();
  }
}
