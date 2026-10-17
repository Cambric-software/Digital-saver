import 'package:url_launcher/url_launcher.dart';
import '../models/health_models.dart';

/// Emergency dialling.
///
/// The number is a setting, not a constant. It was hardcoded to 911, which is
/// the US emergency number and is simply not callable in the UK - the country
/// this product is built and used in. A hardcoded wrong number in an emergency
/// feature is worse than no feature, so it is now configurable and defaults to
/// the UK number, with the US available alongside.
class EmergencyService {
  /// Dialled by [callEmergency].
  ///
  /// Overridable by the person using the app via [setEmergencyNumber], and
  /// persisted by the settings screen.
  static String emergencyNumber = '999';

  /// Common emergency numbers, offered in settings.
  static const Map<String, String> knownEmergencyNumbers = <String, String>{
    'United Kingdom': '999',
    'United States / Canada': '911',
    'European Union': '112',
    'Australia': '000',
    'India': '112',
  };

  /// Set the number dialled by [callEmergency].
  ///
  /// Digits only, 3-6 characters. Anything else is rejected rather than
  /// dialled, because a malformed URI here would silently do nothing when it
  /// matters most.
  static bool setEmergencyNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3 || digits.length > 6) return false;
    emergencyNumber = digits;
    return true;
  }

  /// Dial the configured emergency number.
  static Future<bool> callEmergency() async {
    final uri = Uri(scheme: 'tel', path: emergencyNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  static Future<void> callContact(EmergencyContact contact) async {
    if (contact.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: contact.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> sendSmsAlert({
    required EmergencyContact contact,
    required String message,
  }) async {
    if (contact.phone.isEmpty) return;
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:${contact.phone}?body=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static String buildAlertMessage({
    required String userName,
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    String? reason,
  }) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return '''🚨 EMERGENCY ALERT - Digital Saver
Patient: $userName
Time: $time
${reason != null ? 'Reason: $reason\n' : ''}
Health Status:
❤️ Heart Rate: ${hr.bpm > 0 ? '${hr.bpm} BPM' : 'N/A'}
🩸 BP: ${bp.systolic > 0 ? '${bp.systolic}/${bp.diastolic} mmHg' : 'N/A'}
💨 SpO2: ${o2.spO2 > 0 ? '${o2.spO2}%' : 'N/A'}

Please check on them immediately or call emergency services.''';
  }

  static bool shouldTriggerAutoAlert({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    required AccelData accel,
  }) {
    if (accel.fallDetected) return true;
    if (accel.locSuspected) return true;
    if (hr.bpm > 0 && (hr.bpm < 40 || hr.bpm > 180)) return true;
    if (o2.spO2 > 0 && o2.spO2 < 85) return true;
    if (bp.systolic > 180 || bp.diastolic > 120) return true;
    return false;
  }

  static String autoAlertReason({
    required HeartRateData hr,
    required BloodPressureData bp,
    required OxygenData o2,
    required AccelData accel,
  }) {
    if (accel.fallDetected) return 'Fall detected';
    if (accel.locSuspected) return 'Possible loss of consciousness';
    if (hr.bpm > 0 && hr.bpm > 180) return 'Critical heart rate: ${hr.bpm} BPM';
    if (hr.bpm > 0 && hr.bpm < 40) return 'Critical low heart rate: ${hr.bpm} BPM';
    if (o2.spO2 > 0 && o2.spO2 < 85) return 'Critical SpO2: ${o2.spO2}%';
    if (bp.systolic > 180) return 'Hypertensive crisis: ${bp.systolic}/${bp.diastolic}';
    return 'Critical health event';
  }
}
