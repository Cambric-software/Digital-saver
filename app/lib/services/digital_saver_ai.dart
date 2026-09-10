import 'package:flutter/foundation.dart';
import '../models/health_models.dart';
import 'gemini_service.dart';

/// Digital Saver AI — now powered by Gemini 1.5 Flash.
///
/// This class owns the [GeminiService] instance, injects the user's live health
/// data as context into every request, and exposes a simple async [ask] method
/// to the UI.  It also keeps a [chatHistory] list so the AI screen can render
/// the conversation without re-querying.
///
/// If no Gemini API key is configured the service falls back to a local
/// keyword-based response so the app still works offline.
class DigitalSaverAI extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();

  // ── Health data injected from the app ──────────────────────────────────────
  UserProfile? _userProfile;
  HeartRateData? _latestHeartRate;
  BloodPressureData? _latestBloodPressure;
  OxygenData? _latestOxygen;
  ActivityData? _latestActivity;
  SleepData? _latestSleep;
  String? _watchBattery;
  String? _watchFirmware;
  bool _watchConnected = false;

  // ── Chat state ─────────────────────────────────────────────────────────────
  final List<AiMessage> chatHistory = [];
  bool _isThinking = false;

  bool get isThinking => _isThinking;

  // ── Setters called by the UI / BleService ──────────────────────────────────
  void setUserProfile(UserProfile p) { _userProfile = p; notifyListeners(); }
  void setHeartRate(HeartRateData d) { _latestHeartRate = d; }
  void setBloodPressure(BloodPressureData d) { _latestBloodPressure = d; }
  void setOxygen(OxygenData d) { _latestOxygen = d; }
  void setActivity(ActivityData d) { _latestActivity = d; }
  void setSleep(SleepData d) { _latestSleep = d; }
  void setWatchStatus({String? battery, String? firmware, bool? connected}) {
    _watchBattery = battery;
    _watchFirmware = firmware;
    _watchConnected = connected ?? false;
  }

  // ── Core ask method ────────────────────────────────────────────────────────

  /// Ask a question.  The response is appended to [chatHistory] and the method
  /// returns the response text (or an error string — never throws).
  Future<String> ask(String question) async {
    if (question.trim().isEmpty) return '';

    chatHistory.add(AiMessage(role: MessageRole.user, text: question));
    _isThinking = true;
    notifyListeners();

    final ctx = _buildContext();
    String response;

    try {
      final geminiResponse = await _gemini.send(question, userContext: ctx);
      response = geminiResponse ?? 'No response received. Please try again.';
    } catch (e) {
      response = 'Something went wrong: $e';
    }

    chatHistory.add(AiMessage(role: MessageRole.assistant, text: response));
    _isThinking = false;
    notifyListeners();
    return response;
  }

  /// Clear the conversation and reset Gemini's memory.
  void clearConversation() {
    chatHistory.clear();
    _gemini.clearHistory();
    notifyListeners();
  }

  // ── Context builder ────────────────────────────────────────────────────────

  Map<String, dynamic> _buildContext() {
    final profile = _userProfile;
    return {
      'user': profile != null ? {
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender,
        'height': profile.heightCm,
        'weight': profile.weightKg,
        'bloodType': profile.bloodType,
        'bmi': profile.bmi.toStringAsFixed(1),
        'bmiCategory': profile.bmiCategory,
        'medicalConditions': profile.medicalConditions,
        'allergies': profile.allergies,
        'medications': profile.medications,
      } : null,
      'health': {
        'heartRate': _latestHeartRate != null ? {
          'bpm': _latestHeartRate!.bpm,
          'status': _latestHeartRate!.statusLabel,
          'hrv': _latestHeartRate!.hrv,
          'afib': _latestHeartRate!.isAFib,
        } : null,
        'bloodPressure': _latestBloodPressure != null ? {
          'systolic': _latestBloodPressure!.systolic,
          'diastolic': _latestBloodPressure!.diastolic,
          'category': _latestBloodPressure!.systolic > 0
              ? _latestBloodPressure!.category
              : 'not measured by Veyro',
        } : null,
        'oxygen': _latestOxygen != null ? {
          'spO2': _latestOxygen!.spO2,
          'status': _latestOxygen!.spO2Status,
        } : null,
        'activity': _latestActivity != null ? {
          'steps': _latestActivity!.steps,
          'calories': _latestActivity!.calories.toInt(),
          'goalProgress': '${(_latestActivity!.progress * 100).toInt()}%',
        } : null,
        'sleep': _latestSleep != null ? {
          'quality': _latestSleep!.qualityScore,
          'hours': (_latestSleep!.totalMinutes / 60).toStringAsFixed(1),
          'deepSleep': (_latestSleep!.deepSleepMinutes / 60).toStringAsFixed(1),
        } : null,
      },
      'watch': {
        'connected': _watchConnected,
        'battery': _watchBattery,
        'firmware': _watchFirmware,
      },
    };
  }

  // ── Quick greeting ─────────────────────────────────────────────────────────

  /// Returns a context-aware greeting for when the screen first opens.
  String greeting() {
    final name = _userProfile?.name ?? '';
    final greeting = name.isNotEmpty ? 'Hi $name! ' : 'Hi! ';
    if (_watchConnected) {
      return '${greeting}I\'m Digital Saver AI, powered by Gemini. Your watch is connected. Ask me anything about your health, your watch, or how to improve your wellbeing.';
    }
    return '${greeting}I\'m Digital Saver AI, powered by Gemini. Ask me anything — health tips, how to use your Veyro watch, troubleshooting, or just a health question.';
  }
}

// ── Message models ─────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class AiMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  AiMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}

// ── Legacy WatchAI stub (kept so no other file breaks) ─────────────────────

class WatchAI {
  static String analyzeHeartRateAdvanced(int bpm, int hrv, int age, List<int> history) {
    // Replaced by Gemini. This stub satisfies any remaining references.
    return 'Use DigitalSaverAI.ask() for advanced analysis.';
  }

  static String predictTrajectory(List<Map<String, dynamic>> weekData) {
    return 'Use DigitalSaverAI.ask() for trajectory prediction.';
  }

  static int assessEmergencyRisk({
    required int heartRate, required int spO2,
    required double accelerometerMagnitude, required bool irregularBeat, required int age,
  }) {
    int risk = 0;
    final maxHR = 220 - age;
    if (heartRate > maxHR * 0.95) risk += 40;
    else if (heartRate > maxHR * 0.85) risk += 20;
    if (heartRate < 40) risk += 40;
    else if (heartRate < 50) risk += 15;
    if (spO2 < 85) risk += 50;
    else if (spO2 < 92) risk += 25;
    if (accelerometerMagnitude > 30) risk += 30;
    else if (accelerometerMagnitude > 15) risk += 10;
    if (irregularBeat) risk += 25;
    return risk.clamp(0, 100);
  }
}
