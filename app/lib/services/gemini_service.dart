import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Configuration for the Gemini API key.
/// Set your key in the environment variable GEMINI_API_KEY
/// or override [GeminiConfig.apiKey] before first use.
class GeminiConfig {
  /// Replace this with your actual key from https://aistudio.google.com/
  /// or inject it at runtime:  GeminiConfig.apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  static String apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String model = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static Uri get endpoint =>
      Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');
}

/// A single conversational turn.
class ChatTurn {
  final String role; // 'user' or 'model'
  final String text;
  const ChatTurn({required this.role, required this.text});
}

/// Low-level Gemini REST client.  Used only by [DigitalSaverAI].
class GeminiService {
  // Keep a rolling window so Gemini has conversation memory.
  final List<ChatTurn> _history = [];

  static const int _maxHistoryTurns = 20;

  /// The large system prompt that gives Gemini its identity, medical knowledge,
  /// Veyro-specific knowledge, and troubleshooting context.
  static const String systemPrompt = '''
You are Digital Saver AI — a smart, friendly, and deeply knowledgeable health assistant built into the Digital Saver app by Cambric, created by a young Egyptian developer.

IDENTITY
- You are embedded in the Digital Saver app which pairs with the Veyro smartwatch (ESP32-based, open-source hardware).
- You are concise but thorough. You never panic the user. You always remind them you are a wellness assistant, not a doctor.
- You speak clearly, warmly, and confidently. You use simple language unless the user clearly wants technical depth.

VEYRO WATCH KNOWLEDGE
- Veyro is an ESP32-WROOM-32 based smartwatch (firmware 4.1.0, by Cambric).
- Sensors: MAX30102 (heart rate + rough SpO2), MPU6050 (accelerometer, step count, fall detection), SSD1306 OLED 128×64.
- The watch connects via Bluetooth Low Energy (BLE). It uses a 6-digit PIN shown on the OLED to pair.
- The watch records one CSV sample per minute when the user is wearing it (HR>30 or steps>0).
- Data is stored locally on the watch (LittleFS, 60-day rolling log) and synced to the phone locally. No cloud, no internet.
- Blood pressure: the firmware explicitly outputs 0/0 — BP is NOT measured. Always say it is not available.
- SpO2: experimental optical estimate only, not clinically validated.
- Heart rate: real optical PPG from MAX30102, processed on-device. Reasonably reliable for wellness tracking.
- Steps: counted via MPU6050 accelerometer crossing 1.2g threshold. Can over-count on bumpy rides.
- Fall detection: threshold-based free-fall + spike. Many false positives during sports.
- Battery: GPIO34 with a 2×100kΩ divider. If divider not wired, reports 0%.
- Mode button (GPIO17): cycles OLED screens. SOS button (GPIO32): 2-second hold marks a fall event.
- 8 OLED screens: clock, vitals estimate, activity, motion, battery, storage, connection, device.
- The watch PIN changes every reboot unless stored in Preferences. The app stores it in secure storage after first pair.

COMMON VEYRO TROUBLESHOOTING
- Watch not found in scan: ensure Bluetooth is on, watch is powered, within 10 m. Try "Scan Again". On Android grant Bluetooth+Location permissions.
- Wrong PIN: the PIN is displayed on the OLED screen. It changes on reboot. Read it fresh after each reboot.
- No heart rate: place finger or wrist firmly on sensor. Movement ruins the PPG signal. Ensure the MAX30102 is wired to I2C SDA=21, SCL=22, 3.3V.
- SpO2 showing 85%: often means poor sensor contact or cold fingers, not actual low oxygen.
- Steps reset to 0 after reboot: fixed in firmware 4.1.0+ with Preferences persistence.
- Battery shows 0%: the voltage divider (2×100kΩ) may not be wired. Read the GPIO34 section in manual.md.
- OLED blank: check I2C wiring and address (0x3C). If OLED flag is 0 in boot line, firmware will not advertise BLE service.
- App says "Incomplete Veyro BLE service": the watch paused advertising or you are connecting to the wrong device.
- History sync stuck: ensure pairing completed first. Try disconnecting and reconnecting.
- Falls alarm false positive: MPU6050 sensitivity. Vibration and bumpy rides trigger it. Disable by not shaking the watch.

MEDICAL KNOWLEDGE DATABASE
You have solid foundational medical knowledge for wellness interpretation. Always clarify you are not a doctor.

HEART RATE
- Normal resting HR: 60–100 BPM. Athletes: 40–60.
- Bradycardia: <60 BPM at rest (can be normal for athletes).
- Tachycardia: >100 BPM at rest. Persistent >120 warrants medical attention.
- Maximum HR formula: 220 – age.
- HRV (RMSSD): >60 ms excellent, 40–60 good, 25–40 moderate, <25 low. Low HRV = high stress or poor recovery.
- AFib: irregular beat pattern, no consistent RR spacing. Needs ECG to confirm.

BLOOD PRESSURE (for user education — Veyro does not measure BP)
- Normal: <120/80 mmHg.
- Elevated: 120–129 / <80.
- High Stage 1: 130–139 / 80–89.
- High Stage 2: ≥140 / ≥90.
- Hypertensive crisis: >180 / >120. Medical emergency.
- Lifestyle: reduce sodium, exercise, lose weight, reduce alcohol, manage stress.

BLOOD OXYGEN (SpO2)
- Normal: 95–100%. Below 90% is clinically low (hypoxemia).
- Below 94%: monitor closely, consider medical review if persistent.
- Below 85%: potentially serious, seek medical attention.
- Factors: poor circulation, altitude, lung/heart conditions, sensor placement.
- The Veyro SpO2 is an optical estimate and should not replace a pulse oximeter.

SLEEP
- Adults need 7–9 hours. Teenagers: 8–10 hours.
- Deep sleep (N3): 15–25% of total sleep. Physical restoration.
- REM: 20–25%. Memory consolidation, emotional regulation.
- Tips: consistent schedule, no screens 1 hour before bed, dark/cool room, avoid caffeine after 2 PM.

ACTIVITY
- WHO recommends 150 min/week moderate activity or 75 min vigorous.
- 10,000 steps/day is a common wellness goal (~8 km for average stride).
- Calories: roughly 40–60 kcal per 1,000 steps depending on weight and pace.

NUTRITION & HYDRATION (general)
- 2–2.5L water/day. More if active or in heat.
- Balanced diet: vegetables, lean protein, whole grains, healthy fats.
- Reduce ultra-processed food and added sugar.

STRESS
- Chronic stress raises cortisol, lowering HRV and increasing HR.
- Techniques: deep breathing (box breathing, 4-7-8), meditation, walking, sleep.

EMERGENCY GUIDANCE (always encourage calling emergency services)
- Egypt ambulance: 123. Police: 122. Fire: 180.
- If someone is unconscious and not breathing: call 123, start CPR (30 compressions, 2 breaths).
- Chest pain + left arm pain + sweating = potential heart attack. Call emergency immediately.
- SpO2 < 88% with difficulty breathing = seek emergency care.
- Fall + head injury + confusion = do not move the person, call 123.

RULES
1. Never diagnose. Always remind the user to consult a doctor for medical decisions.
2. When the user's data is shared with you, interpret it with context (age, conditions, medications).
3. Be honest: if BP is 0/0, say Veyro does not measure BP. Never make up sensor data.
4. Keep responses brief unless the user asks for detail.
5. If you do not know something, say so — do not guess.
6. If a symptom sounds serious, tell the user clearly but calmly to see a doctor or call emergency.
7. You are a wellness tool. You are not a replacement for professional medical care.
''';

  /// Send a message and get a response. Returns null on error (caller handles).
  Future<String?> send(String userMessage, {Map<String, dynamic>? userContext}) async {
    if (GeminiConfig.apiKey.isEmpty) {
      return _noKeyFallback(userMessage);
    }

    // Build the context prefix if health data is supplied.
    String contextPrefix = '';
    if (userContext != null) {
      contextPrefix = _buildContextPrefix(userContext);
    }

    final fullMessage = contextPrefix.isNotEmpty
        ? '$contextPrefix\n\nUser question: $userMessage'
        : userMessage;

    _history.add(ChatTurn(role: 'user', text: fullMessage));

    // Keep history window bounded.
    while (_history.length > _maxHistoryTurns * 2) {
      _history.removeAt(0);
    }

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}],
      },
      'contents': _history
          .map((t) => {
                'role': t.role,
                'parts': [{'text': t.text}],
              })
          .toList(),
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.9,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    });

    try {
      final response = await http
          .post(
            GeminiConfig.endpoint,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          _history.add(ChatTurn(role: 'model', text: text));
          return text;
        }
        return 'I received a response but could not read it. Please try again.';
      } else if (response.statusCode == 400) {
        debugPrint('Gemini 400: ${response.body}');
        return 'There was a problem with the request. Check your API key or message format.';
      } else if (response.statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      } else {
        debugPrint('Gemini error ${response.statusCode}: ${response.body}');
        return 'Sorry, I could not reach the AI service right now (${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('Gemini exception: $e');
      return 'Could not connect to the AI service. Check your internet connection.';
    }
  }

  /// Clears conversation history (e.g. when user starts fresh).
  void clearHistory() => _history.clear();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _buildContextPrefix(Map<String, dynamic> ctx) {
    final parts = <String>[];

    final user = ctx['user'] as Map<String, dynamic>?;
    if (user != null) {
      final name = user['name'] as String? ?? '';
      final age = user['age'];
      final gender = user['gender'] as String? ?? '';
      final bmi = user['bmi'];
      final conditions = (user['medicalConditions'] as List?)?.join(', ') ?? '';
      final meds = (user['medications'] as List?)?.join(', ') ?? '';
      parts.add('[USER PROFILE] Name: $name | Age: $age | Gender: $gender | BMI: $bmi | Conditions: ${conditions.isEmpty ? "none reported" : conditions} | Medications: ${meds.isEmpty ? "none reported" : meds}');
    }

    final health = ctx['health'] as Map<String, dynamic>?;
    if (health != null) {
      final hr = health['heartRate'] as Map<String, dynamic>?;
      final bp = health['bloodPressure'] as Map<String, dynamic>?;
      final o2 = health['oxygen'] as Map<String, dynamic>?;
      final act = health['activity'] as Map<String, dynamic>?;
      final slp = health['sleep'] as Map<String, dynamic>?;

      if (hr != null) parts.add('[HEART RATE] ${hr['bpm']} BPM | HRV: ${hr['hrv']} ms | Status: ${hr['status']} | AFib flag: ${hr['afib']}');
      if (bp != null) {
        final sys = bp['systolic'] as int? ?? 0;
        if (sys > 0) {
          parts.add('[BLOOD PRESSURE] ${bp['systolic']}/${bp['diastolic']} mmHg | Category: ${bp['category']}');
        } else {
          parts.add('[BLOOD PRESSURE] Not measured by Veyro hardware.');
        }
      }
      if (o2 != null) parts.add('[OXYGEN] SpO2: ${o2['spO2']}% | Status: ${o2['status']} (optical estimate only)');
      if (act != null) parts.add('[ACTIVITY] Steps: ${act['steps']} | Calories: ${act['calories']} | Goal: ${act['goalProgress']}');
      if (slp != null) parts.add('[SLEEP] Quality: ${slp['quality']}/100 | Hours: ${slp['hours']} | Deep: ${slp['deepSleep']}h');
    }

    final watch = ctx['watch'] as Map<String, dynamic>?;
    if (watch != null) {
      parts.add('[WATCH] Connected: ${watch['connected']} | Battery: ${watch['battery'] ?? "unknown"} | Firmware: ${watch['firmware'] ?? "unknown"}');
    }

    return parts.join('\n');
  }

  /// Fallback when no API key is configured — gives a helpful message.
  String _noKeyFallback(String question) {
    return '''⚠️ Gemini API key not configured.

To enable AI responses:
1. Get a free key from https://aistudio.google.com/
2. Add it to your app with:
   flutter run --dart-define=GEMINI_API_KEY=your_key_here
   or set GeminiConfig.apiKey in code.

Your question was: "$question"

In the meantime I can tell you: ${_localFallback(question)}''';
  }

  String _localFallback(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('heart') || lower.contains('bpm')) {
      return 'Normal resting heart rate is 60–100 BPM. Below 60 can be normal for athletes.';
    }
    if (lower.contains('oxygen') || lower.contains('spo2')) {
      return 'Normal SpO2 is 95–100%. Below 90% is concerning — consult a doctor.';
    }
    if (lower.contains('sleep')) {
      return 'Adults need 7–9 hours. Consistency matters more than duration.';
    }
    if (lower.contains('blood pressure') || lower.contains('bp')) {
      return 'Normal BP is below 120/80 mmHg. Note: Veyro does not measure BP.';
    }
    if (lower.contains('step') || lower.contains('walk')) {
      return '10,000 steps/day is a common wellness target (~8 km).';
    }
    return 'Please configure your Gemini API key for full AI responses.';
  }
}
