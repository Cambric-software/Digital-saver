import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Configuration for the Gemini AI service.
/// Uses the secure Cambric Cloudflare Worker relay by default so no keys
/// leak in client binaries, with optional direct API key override.
class GeminiConfig {
  /// Production Cloudflare Worker relay hosted by Cambric
  static String proxyUrl = 'https://digital-saver-ai.asser-k-dev.workers.dev';

  /// Optional direct key for testing or developer overrides
  static String apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String primaryModel = 'gemini-3.8-flash';
  static const String fallbackModel = 'gemini-2.5-flash';
  static const String legacyModel = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static Uri endpointFor(String modelName) {
    if (apiKey.isNotEmpty) {
      return Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey');
    }
    return Uri.parse(proxyUrl);
  }

  static Uri get endpoint => endpointFor(primaryModel);
}

/// A single conversational turn.
class ChatTurn {
  final String role; // 'user' or 'model'
  final String text;
  const ChatTurn({required this.role, required this.text});
}

/// Low-level Gemini REST client. Used only by [DigitalSaverAI].
class GeminiService {
  // Keep a rolling window so Gemini has conversation memory.
  final List<ChatTurn> _history = [];

  static const int _maxHistoryTurns = 20;

  /// The system prompt that gives Gemini its identity, medical knowledge,
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
    final hasKey = GeminiConfig.apiKey.isNotEmpty;
    final hasProxy = GeminiConfig.proxyUrl.isNotEmpty;

    if (!hasKey && !hasProxy) {
      return _noKeyFallback(userMessage);
    }

    // Build context prefix if health data is supplied.
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
      http.Response? response;

      if (!hasKey && hasProxy) {
        // Send via Cambric Cloudflare Worker relay
        try {
          response = await http
              .post(
                Uri.parse(GeminiConfig.proxyUrl),
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 15));
        } catch (e) {
          debugPrint('Relay request failed: $e');
        }
      } else {
        // Direct key fallback / candidate cycle
        final candidateModels = [
          GeminiConfig.primaryModel,
          GeminiConfig.fallbackModel,
          GeminiConfig.legacyModel,
        ];
        for (final candidate in candidateModels) {
          try {
            final res = await http
                .post(
                  GeminiConfig.endpointFor(candidate),
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                )
                .timeout(const Duration(seconds: 15));
            if (res.statusCode != 404) {
              response = res;
              break;
            }
            debugPrint('Gemini model $candidate returned 404, falling back...');
          } catch (e) {
            debugPrint('Gemini attempt failed for $candidate: $e');
          }
        }
      }

      if (response == null || response.statusCode != 200) {
        debugPrint('AI Relay error (${response?.statusCode}); activating offline wellness engine.');
        final localAns = _offlineHealthAdvisor(userMessage, userContext);
        _history.add(ChatTurn(role: 'model', text: localAns));
        return localAns;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text != null && text.isNotEmpty) {
        _history.add(ChatTurn(role: 'model', text: text));
        return text;
      }
      final localAns = _offlineHealthAdvisor(userMessage, userContext);
      _history.add(ChatTurn(role: 'model', text: localAns));
      return localAns;
    } catch (e) {
      debugPrint('Gemini exception: $e; falling back to local advisor.');
      final localAns = _offlineHealthAdvisor(userMessage, userContext);
      _history.add(ChatTurn(role: 'model', text: localAns));
      return localAns;
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

  /// Fallback when no service is configured.
  String _noKeyFallback(String question) {
    return _offlineHealthAdvisor(question, null);
  }

  String _offlineHealthAdvisor(String q, Map<String, dynamic>? ctx) {
    final lower = q.toLowerCase();
    
    String vitalsNote = '';
    if (ctx != null && ctx['health'] is Map) {
      final h = ctx['health'] as Map;
      final hr = h['heartRate']?['bpm'];
      final o2 = h['oxygen']?['percent'];
      if (hr != null || o2 != null) {
        vitalsNote = '\n\n(Latest watch readings: ' + (hr != null ? 'Heart Rate: $hr BPM ' : '') + (o2 != null ? 'SpO2: $o2%' : '') + ')';
      }
    }

    if (lower.contains('heart') || lower.contains('bpm') || lower.contains('pulse') || lower.contains('نبض') || lower.contains('قلب')) {
      return 'Normal resting heart rate for healthy adults is between 60 and 100 BPM. Lower rates (40-60) are common during sleep or in well-conditioned athletes. If your resting rate remains persistently above 100 or below 50 with dizziness, consult a physician.' + vitalsNote;
    }
    if (lower.contains('oxygen') || lower.contains('spo2') || lower.contains('o2') || lower.contains('أكسجين')) {
      return 'Healthy blood oxygen saturation (SpO2) is typically between 95% and 100%. If levels consistently drop below 92%, consider re-testing with your watch snug against your wrist, and consult a medical professional if accompanied by shortness of breath.' + vitalsNote;
    }
    if (lower.contains('sleep') || lower.contains('bed') || lower.contains('rest') || lower.contains('نوم')) {
      return 'For optimal cardiovascular recovery and memory consolidation, 7 to 9 hours of consistent sleep is recommended. Try keeping a consistent bedtime and avoiding bright blue screens 30 minutes before sleep.' + vitalsNote;
    }
    if (lower.contains('step') || lower.contains('walk') || lower.contains('activity') || lower.contains('exercise') || lower.contains('خطوات') || lower.contains('مشي')) {
      return 'Aiming for 8,000 to 10,000 daily steps significantly supports cardiovascular health and metabolic wellness. Even brisk 15-minute walks after meals help regulate glucose levels.' + vitalsNote;
    }
    if (lower.contains('water') || lower.contains('hydrat') || lower.contains('ماء') || lower.contains('شرب')) {
      return 'Staying hydrated is essential for regulating blood viscosity and heart rate. A baseline of 2.5 to 3 liters of water daily is recommended, increasing during physical activity.' + vitalsNote;
    }
    if (lower.contains('stress') || lower.contains('relax') || lower.contains('hrv') || lower.contains('توتر')) {
      return 'High heart rate variability (HRV) generally indicates good recovery and stress resilience. When feeling stressed, practicing deep 4-7-8 diaphragmatic breathing for 3 minutes can effectively lower sympathetic nervous tone.' + vitalsNote;
    }

    return 'I am currently operating in offline wellness mode to protect your privacy and ensure instant guidance without cloud lag. Feel free to ask about your vitals, heart rate, sleep, or daily activity!' + vitalsNote;
  }
}
