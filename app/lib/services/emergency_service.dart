import 'package:url_launcher/url_launcher.dart';
import '../models/health_models.dart';

class EmergencyService {
  static Future<void> callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '911');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
