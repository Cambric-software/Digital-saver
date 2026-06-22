import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digital_saver/models/health_data.dart';
import 'package:digital_saver/services/storage_service.dart';

class EmergencyService extends ChangeNotifier {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  bool _emergencyActive = false;
  Position? _lastLocation;
  Timer? _alertTimer;
  int _alertCount = 0;
  static const int maxAlerts = 3;

  bool get emergencyActive => _emergencyActive;
  Position? get lastLocation => _lastLocation;

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

  Future<void> triggerEmergency(AlertData alert, List<EmergencyContact> contacts) async {
    if (_emergencyActive) return;
    
    _emergencyActive = true;
    _alertCount = 0;
    notifyListeners();

    try {
      // Get location
      final location = await getCurrentLocation();
      final locationString = 'https://maps.google.com/?q=${location.latitude},${location.longitude}';
      
      // Send SMS to all contacts
      final message = _buildEmergencyMessage(alert, locationString);
      
      for (final contact in contacts) {
        await _sendSms(contact.phone, message);
      }

      // Call primary contact
      final primaryContact = contacts.firstWhere(
        (c) => c.isPrimary,
        orElse: () => contacts.first,
      );
      
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

    } catch (e) {
      debugPrint('Emergency trigger error: $e');
      _emergencyActive = false;
      notifyListeners();
    }
  }

  String _buildEmergencyMessage(AlertData alert, String location) {
    final timestamp = DateTime.now().toString();
    
    String condition = '';
    switch (alert.type) {
      case AlertType.fall:
        condition = 'FALL DETECTED - Possible loss of consciousness';
        break;
      case AlertType.arrhythmia:
        condition = 'IRREGULAR HEARTBEAT DETECTED';
        break;
      case AlertType.hypertension:
        condition = 'HIGH BLOOD PRESSURE DETECTED';
        break;
    }

    return '''
🚨 DIGITAL SAVER EMERGENCY 🚨
$condition

Time: $timestamp
Location: $location

Please check on the wearer immediately.
If this is a medical emergency, call 123 (Egypt Emergency).
''';
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

  void cancelEmergency() {
    _alertTimer?.cancel();
    _emergencyActive = false;
    _alertCount = 0;
    notifyListeners();
  }
}
