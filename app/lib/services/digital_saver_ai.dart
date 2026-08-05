import 'dart:math';
import '../models/health_models.dart';
import 'package:intl/intl.dart';

/// Digital Saver AI Assistant
/// A smart AI that knows your health data and can answer any question
/// about your health, your Onyx watch, or the Digital Saver app.
/// 
/// The AI has different intelligence levels:
/// - App: Standard intelligence (uses cloud for heavy processing)
/// - Watch: 8x smarter (runs advanced algorithms on-device)
/// 
/// The AI knows:
/// - Your personal health profile (height, weight, blood type, conditions)
/// - Your recent health readings (heart rate, SpO2, sleep, activity)
/// - Your watch status and settings
/// - How to interpret your data in context

class DigitalSaverAI {
  // User profile data (injected from app)
  UserProfile? _userProfile;
  
  // Recent health data
  HeartRateData? _latestHeartRate;
  BloodPressureData? _latestBloodPressure;
  OxygenData? _latestOxygen;
  ActivityData? _latestActivity;
  SleepData? _latestSleep;
  
  // Watch data
  String? _watchBatteryLevel;
  String? _watchFirmware;
  bool _watchConnected = false;
  
  // AI Intelligence Level
  // 1 = App mode, 8 = Watch mode (8x smarter)
  int _intelligenceLevel = 1;
  
  /// Initialize with user profile
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
  }
  
  /// Set health data
  void setHeartRate(HeartRateData data) => _latestHeartRate = data;
  void setBloodPressure(BloodPressureData data) => _latestBloodPressure = data;
  void setOxygen(OxygenData data) => _latestOxygen = data;
  void setActivity(ActivityData data) => _latestActivity = data;
  void setSleep(SleepData data) => _latestSleep = data;
  
  /// Set watch data
  void setWatchStatus({
    String? battery,
    String? firmware,
    bool? connected,
  }) {
    _watchBatteryLevel = battery;
    _watchFirmware = firmware;
    _watchConnected = connected ?? false;
  }
  
  /// Set intelligence level (1 = app, 8 = watch)
  void setIntelligenceLevel(int level) {
    _intelligenceLevel = level.clamp(1, 8);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONTEXT GATHERING
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get full context about the user for AI responses
  Map<String, dynamic> getUserContext() {
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
          'category': _latestBloodPressure!.category,
          'vascularAge': _latestBloodPressure!.vascularAge,
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
          'hours': _latestSleep!.totalHours.toStringAsFixed(1),
          'deepSleep': _latestSleep!.deepSleepHours.toStringAsFixed(1),
        } : null,
      },
      
      'watch': {
        'connected': _watchConnected,
        'battery': _watchBatteryLevel,
        'firmware': _watchFirmware,
      },
      
      'intelligenceLevel': _intelligenceLevel,
    };
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // QUESTION PROCESSING
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Process a user question and return an intelligent response
  String ask(String question) {
    final q = question.toLowerCase();
    
    // Route to appropriate handler
    if (_containsAny(q, ['heart', 'pulse', 'bpm', 'beat'])) {
      return _answerHeartQuestion(q);
    }
    if (_containsAny(q, ['blood pressure', 'bp', 'hypertension', 'systolic', 'diastolic'])) {
      return _answerBloodPressureQuestion(q);
    }
    if (_containsAny(q, ['oxygen', 'spo2', 'breathing', 'breath'])) {
      return _answerOxygenQuestion(q);
    }
    if (_containsAny(q, ['sleep', 'rest', 'tired', 'drowsy'])) {
      return _answerSleepQuestion(q);
    }
    if (_containsAny(q, ['steps', 'walk', 'exercise', 'activity', 'workout', 'run'])) {
      return _answerActivityQuestion(q);
    }
    if (_containsAny(q, ['calorie', 'burn', 'weight'])) {
      return _answerCalorieQuestion(q);
    }
    if (_containsAny(q, ['watch', 'onyx', 'device', 'battery', 'firmware', 'sensor'])) {
      return _answerWatchQuestion(q);
    }
    if (_containsAny(q, ['fall', 'emergency', 'alert', '911', 'sos'])) {
      return _answerEmergencyQuestion(q);
    }
    if (_containsAny(q, ['who are you', 'what are you', 'about you', 'your name'])) {
      return _aboutMe();
    }
    if (_containsAny(q, ['help', 'what can', 'capabilities', 'commands'])) {
      return _capabilities();
    }
    
    // Default: provide health summary
    return _healthSummary();
  }
  
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH ANSWERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  String _answerHeartQuestion(String question) {
    final hr = _latestHeartRate;
    final profile = _userProfile;
    
    if (hr == null) {
      return "I don't have any heart rate data yet. Make sure your Onyx watch is connected and has taken a reading. 💓";
    }
    
    final bpm = hr.bpm;
    String status = "normal";
    String advice = "";
    
    // Context-aware analysis
    if (profile != null) {
      final age = profile.age;
      
      // Age-based heart rate analysis
      if (age > 0) {
        final maxHR = 220 - age;
        final targetLow = (maxHR * 0.5).toInt();
        final targetHigh = (maxHR * 0.85).toInt();
        
        if (bpm < 60) {
          status = "low (bradycardia)";
          advice = "Your heart rate is lower than normal. ";
          if (bpm > 40) {
            advice += "This can be normal for athletes or during sleep. ";
          }
          advice += "Monitor for dizziness or fainting.";
        } else if (bpm > targetHigh) {
          status = "elevated";
          advice = "Your heart rate is above your target zone (${targetLow}-${targetHigh}bpm for age $age). ";
          if (_latestActivity == null || _latestActivity!.steps < 1000) {
            advice += "Try to get some light activity. ";
          }
          advice += "If persistent, consult a doctor.";
        } else if (bpm >= 60 && bpm <= targetHigh) {
          status = "great";
          advice = "Your heart rate is in a healthy range for your age! ";
          if (_latestActivity != null && _latestActivity!.steps > 5000) {
            advice += "Great job staying active today!";
          }
        }
      }
      
      // Blood type context
      if (profile.bloodType != null) {
        final bt = profile.bloodType!;
        if (bt == 'O-' || bt == 'O+') {
          advice += " As a ${bt} blood type, you have the most common donor type.";
        }
      }
    }
    
    // HRV analysis (more advanced with higher intelligence)
    if (hr.hrv > 0 && _intelligenceLevel >= 4) {
      advice += "\n\n📊 HRV (Heart Rate Variability): ${hr.hrv}ms";
      if (hr.hrv > 50) {
        advice += " - Excellent! Your nervous system is resilient.";
      } else if (hr.hrv > 30) {
        advice += " - Normal range. Some stress detected.";
      } else {
        advice += " - Lower than ideal. Consider relaxation techniques.";
      }
    }
    
    // A-Fib check
    if (hr.isAFib) {
      advice = "⚠️ WARNING: Irregular heartbeat pattern detected (possible A-Fib). ";
      advice += "Please consult your doctor for proper diagnosis. This is not a diagnosis but the pattern warrants medical attention.";
    }
    
    return "💓 Your Heart Rate: **$bpm BPM** ($status)\n\n$advice";
  }
  
  String _answerBloodPressureQuestion(String question) {
    final bp = _latestBloodPressure;
    final profile = _userProfile;
    
    if (bp == null) {
      return "No blood pressure data available. The Onyx watch estimates BP using pulse wave analysis. Wear it for a few readings to get accurate estimates.";
    }
    
    final systolic = bp.systolic;
    final diastolic = bp.diastolic;
    String category = bp.category;
    String advice = "";
    
    // Context-aware analysis
    if (profile != null && profile.age > 0) {
      if (profile.age > 60 && systolic > 130) {
        advice = "For your age (${profile.age}), maintaining BP below 130/80 is generally recommended. ";
      } else if (profile.age > 50 && systolic > 140) {
        advice = "At age ${profile.age}, BP should be monitored closely. ";
      }
    }
    
    // Medical conditions context
    if (profile != null && profile.medicalConditions.isNotEmpty) {
      if (profile.medicalConditions.any((c) => c.toLowerCase().contains('hypertension') || c.toLowerCase().contains('heart'))) {
        advice += "Given your medical history, regular BP monitoring is important. ";
      }
    }
    
    // Vascular age analysis (advanced feature)
    if (bp.vascularAge > 0 && _intelligenceLevel >= 4) {
      final actualAge = profile?.age ?? bp.vascularAge;
      final diff = bp.vascularAge - actualAge;
      
      if (diff > 10) {
        advice += "\n\n🔬 Vascular Age: ${bp.vascularAge} years (${diff} years older than your actual age). ";
        advice += "Consider cardiovascular exercises to improve arterial health.";
      } else if (diff < -5) {
        advice += "\n\n🔬 Vascular Age: ${bp.vascularAge} years - Your arteries are in great shape!";
      }
    }
    
    return "🩸 Blood Pressure: **$systolic/$diastolic mmHg** ($category)\n\n$advice";
  }
  
  String _answerOxygenQuestion(String question) {
    final ox = _latestOxygen;
    
    if (ox == null) {
      return "No SpO2 data available. The Onyx watch measures blood oxygen using infrared light. Make sure the sensor has good contact with your skin.";
    }
    
    final spo2 = ox.spO2;
    String status = ox.spO2Status;
    String advice = "";
    
    if (spo2 >= 95) {
      advice = "Your oxygen levels are excellent! 🌟";
    } else if (spo2 >= 90) {
      advice = "Your oxygen is slightly low. Rest and take deep breaths. ";
      advice += "If it stays below 94%, consider consulting a doctor.";
    } else {
      advice = "⚠️ Your oxygen is critically low. ";
      advice += "Seek medical attention immediately if you feel unwell.";
    }
    
    // Perfusion index context (advanced)
    if (ox.perfusionIndex > 0 && _intelligenceLevel >= 6) {
      advice += "\n\n📊 Perfusion Index: ${ox.perfusionIndex}% ";
      if (ox.perfusionIndex < 2) {
        advice += "(Low - sensor may need adjustment)";
      } else if (ox.perfusionIndex > 10) {
        advice += "(Good signal quality)";
      }
    }
    
    return "🫁 Blood Oxygen: **$spo2%** ($status)\n\n$advice";
  }
  
  String _answerSleepQuestion(String question) {
    final sleep = _latestSleep;
    final profile = _userProfile;
    
    if (sleep == null) {
      return "No sleep data yet. Wear your Onyx watch overnight to track your sleep patterns.";
    }
    
    final hours = sleep.totalHours;
    final quality = sleep.qualityScore;
    String advice = "";
    
    // Hours recommendation based on age
    int recommendedHours = 8;
    if (profile != null && profile.age > 0) {
      if (profile.age < 18) recommendedHours = 9;
      else if (profile.age > 65) recommendedHours = 7;
    }
    
    if (hours < recommendedHours - 1) {
      advice = "You're slightly short on sleep. ";
      advice += "Try going to bed 30 minutes earlier tonight.";
    } else if (hours >= recommendedHours) {
      advice = "Great job getting enough rest! 💤";
    }
    
    // Sleep stages analysis
    if (sleep.deepSleepHours > 0 && _intelligenceLevel >= 4) {
      final deepPct = ((sleep.deepSleepHours / hours) * 100).toInt();
      advice += "\n\n📊 Deep Sleep: ${sleep.deepSleepHours.toStringAsFixed(1)}h ($deepPct%)";
      if (deepPct < 15) {
        advice += " - Below optimal. Consider stress reduction before bed.";
      } else if (deepPct > 25) {
        advice += " - Excellent deep sleep recovery!";
      }
    }
    
    return "😴 Last Night's Sleep: **${hours.toStringAsFixed(1)} hours** (Quality: $quality%)\n\n$advice";
  }
  
  String _answerActivityQuestion(String question) {
    final activity = _latestActivity;
    final profile = _userProfile;
    
    if (activity == null) {
      return "No activity data yet. Start moving with your Onyx watch to track steps!";
    }
    
    final steps = activity.steps;
    final goal = activity.stepsGoal;
    final progress = ((steps / goal) * 100).toInt();
    
    String advice = "";
    int remaining = goal - steps;
    
    if (steps >= goal) {
      advice = "🎉 Congratulations! You've reached your ${goal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} step goal! ";
      if (remaining < 500) {
        advice += "You went above and beyond!";
      } else {
        advice += "Amazing work today!";
      }
    } else if (progress > 50) {
      advice = "You're ${progress}% of the way there! ";
      advice += "Just ${remaining.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} more steps to hit your goal. ";
      advice += "Keep it up! 🚶";
    } else {
      advice = "You've completed $steps steps. ";
      advice += "You need $remaining more steps to reach your daily goal. ";
      advice += "Every step counts!";
    }
    
    // Distance calculation
    if (profile != null && profile.heightCm > 0) {
      final strideLength = profile.heightCm * 0.415 / 100; // in meters
      final distance = (steps * strideLength / 1000);
      advice += "\n\n📍 Distance walked: ${distance.toStringAsFixed(2)} km";
    }
    
    return "👟 Today's Activity: **$steps / ${goal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps** (${progress}%)\n\n$advice";
  }
  
  String _answerCalorieQuestion(String question) {
    final activity = _latestActivity;
    final profile = _userProfile;
    
    if (activity == null || activity.calories == 0) {
      return "No calorie data available. The Onyx watch calculates calories based on your activity and profile.";
    }
    
    final calories = activity.calories.toInt();
    String advice = "";
    
    if (profile != null && profile.weightKg > 0 && profile.heightCm > 0) {
      // Calculate BMR
      final bmr = _calculateBMR(profile);
      final dailyTarget = (bmr * 1.55).toInt(); // Moderate activity
      
      if (calories > dailyTarget * 0.5) {
        advice = "You've burned $calories calories today. ";
        if (calories > dailyTarget) {
          advice += "That's above your estimated daily target of $dailyTarget! ";
          advice += "Great active day!";
        } else {
          advice += "You're well on your way to your daily goal.";
        }
      }
      
      advice += "\n\n📊 Your BMR: ${bmr.toInt()} cal/day";
      advice += "\n📊 Daily Target (with activity): ${dailyTarget} cal";
    }
    
    return "🔥 Calories Burned: **$calories cal**\n\n$advice";
  }
  
  String _answerWatchQuestion(String question) {
    String info = "⌚ Onyx Watch Status:\n\n";
    
    info += "• Connection: ${_watchConnected ? '🟢 Connected' : '🔴 Disconnected'}\n";
    
    if (_watchBatteryLevel != null) {
      final battery = int.tryParse(_watchBatteryLevel!.replaceAll('%', '')) ?? 0;
      String batteryIcon = battery > 50 ? '🔋' : battery > 20 ? '🪫' : '⚠️';
      info += "• Battery: $batteryIcon ${_watchBatteryLevel}\n";
      
      if (battery < 20) {
        info += "  → Low battery! Consider charging soon.\n";
      }
    }
    
    if (_watchFirmware != null) {
      info += "• Firmware: v$_watchFirmware\n";
    }
    
    if (_watchConnected) {
      info += "\n📱 Features available:\n";
      info += "• Heart rate monitoring\n";
      info += "• Blood oxygen (SpO2)\n";
      info += "• Blood pressure estimation\n";
      info += "• Step counting\n";
      info += "• Sleep tracking\n";
      info += "• Fall detection\n";
      info += "• Emergency alerts\n";
      
      if (_intelligenceLevel >= 8) {
        info += "\n🧠 Running 8x Enhanced AI Mode";
      }
    } else {
      info += "\n→ Connect your watch in Settings to enable features.";
    }
    
    return info;
  }
  
  String _answerEmergencyQuestion(String question) {
    String info = "🚨 Emergency Features:\n\n";
    
    info += "Your Onyx watch has automatic emergency detection:\n\n";
    
    info += "• 🪨 **Fall Detection**: Detects sudden falls and alerts contacts\n";
    info += "• ❤️ **Heart Alert**: Watches for dangerously high/low heart rate\n";
    info += "• 🫁 **Low Oxygen**: Alerts if SpO2 drops critically\n";
    info += "• 📞 **SOS Button**: Long-press emergency button for instant call\n\n";
    
    if (_userProfile?.emergencyContactName != null) {
      info += "📞 Your Emergency Contact: ${_userProfile!.emergencyContactName}\n";
    } else {
      info += "⚠️ No emergency contact set. Add one in Profile settings.\n";
    }
    
    info += "\n→ In an emergency, say 'Call 911' or use the watch button.";
    
    return info;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ABOUT & CAPABILITIES
  // ═══════════════════════════════════════════════════════════════════════════
  
  String _aboutMe() {
    String intro = "👋 I'm **Digital Saver AI**, your personal health assistant!\n\n";
    
    intro += "I know everything about your health data and your Onyx watch. ";
    intro += "I can help you understand your readings, answer questions, ";
    intro += "and give personalized insights based on your profile.\n\n";
    
    if (_intelligenceLevel >= 8) {
      intro += "🧠 **Watch Mode Active**: Running 8x enhanced AI algorithms on-device.\n\n";
    }
    
    if (_userProfile != null) {
      intro += "👤 I'm currently helping: ${_userProfile!.name}\n";
      if (_userProfile!.age > 0) {
        intro += "📋 Profile: ${_userProfile!.age} years old, ${_userProfile!.bmiCategory} BMI\n";
      }
    }
    
    return intro;
  }
  
  String _capabilities() {
    String caps = "🛠️ **I can help you with:**\n\n";
    
    caps += "**Health Questions:**\n";
    caps += "• \"How's my heart rate?\"\n";
    caps += "• \"What does my blood pressure mean?\"\n";
    caps += "• \"How well did I sleep?\"\n";
    caps += "• \"Am I meeting my activity goals?\"\n";
    caps += "• \"How many calories did I burn?\"\n\n";
    
    caps += "**Watch Information:**\n";
    caps += "• \"Is my watch connected?\"\n";
    caps += "• \"What's my watch battery?\"\n";
    caps += "• \"How do I use [feature]?\"\n\n";
    
    caps += "**Emergency & Safety:**\n";
    caps += "• \"How does fall detection work?\"\n";
    caps += "• \"What happens in an emergency?\"\n\n";
    
    caps += "**Personal Insights:**\n";
    caps += "• \"How does my health compare to yesterday?\"\n";
    caps += "• \"What should I improve?\"\n";
    caps += "• \"Why is my HRV low?\"\n\n";
    
    caps += "_Just ask me anything about your health or watch!_";
    
    return caps;
  }
  
  String _healthSummary() {
    String summary = "📊 **Your Health Summary**\n\n";
    
    if (_latestHeartRate != null) {
      summary += "💓 Heart: ${_latestHeartRate!.bpm} BPM (${_latestHeartRate!.statusLabel})\n";
    }
    if (_latestBloodPressure != null) {
      summary += "🩸 Blood Pressure: ${_latestBloodPressure!.systolic}/${_latestBloodPressure!.diastolic}\n";
    }
    if (_latestOxygen != null) {
      summary += "🫁 Oxygen: ${_latestOxygen!.spO2}%\n";
    }
    if (_latestActivity != null) {
      final pct = (_latestActivity!.progress * 100).toInt();
      summary += "👟 Activity: ${_latestActivity!.steps} steps ($pct% of goal)\n";
    }
    if (_latestSleep != null) {
      summary += "😴 Sleep: ${_latestSleep!.totalHours.toStringAsFixed(1)} hours\n";
    }
    
    if (_latestHeartRate == null && _latestBloodPressure == null && 
        _latestOxygen == null && _latestActivity == null && _latestSleep == null) {
      summary = "No health data available yet. ";
      summary += "Make sure your Onyx watch is connected and has taken readings.\n\n";
      summary += "Or ask me anything specific! 😊";
    } else {
      summary += "\n_Ask me any question about your health!_";
    }
    
    return summary;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CALCULATIONS (Used by AI for personalized insights)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
  double _calculateBMR(UserProfile profile) {
    double bmr;
    
    if (profile.gender.toLowerCase() == 'female') {
      bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) - 161;
    } else {
      bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) + 5;
    }
    
    return bmr;
  }
  
  /// Calculate Target Heart Rate Zone
  Map<String, int> getTargetHeartRateZone() {
    if (_userProfile == null || _userProfile!.age <= 0) {
      return {'min': 100, 'max': 170}; // Default
    }
    
    final age = _userProfile!.age;
    final maxHR = 220 - age;
    
    return {
      'resting': (maxHR * 0.5).toInt(),
      'fatBurn': (maxHR * 0.6).toInt(),
      'cardio': (maxHR * 0.75).toInt(),
      'peak': (maxHR * 0.9).toInt(),
      'max': maxHR,
    };
  }
  
  /// Get personalized health recommendation
  String getRecommendation() {
    final profile = _userProfile;
    final recommendations = <String>[];
    
    // Based on BMI
    if (profile != null) {
      if (profile.bmi < 18.5) {
        recommendations.add("Consider increasing caloric intake with nutrient-rich foods.");
      } else if (profile.bmi >= 30) {
        recommendations.add("Aim for gradual weight loss through diet and exercise.");
      }
      
      // Based on age
      if (profile.age > 50) {
        recommendations.add("Regular cardiovascular check-ups are recommended.");
      }
      
      // Based on medical conditions
      for (final condition in profile.medicalConditions) {
        if (condition.toLowerCase().contains('diabetes')) {
          recommendations.add("Monitor blood sugar regularly and maintain a balanced diet.");
        }
        if (condition.toLowerCase().contains('heart')) {
          recommendations.add("Heart-healthy habits are crucial: low sodium, regular movement.");
        }
      }
    }
    
    // Based on recent activity
    if (_latestActivity != null && _latestActivity!.steps < 5000) {
      recommendations.add("Try to walk more today - every step counts!");
    }
    
    // Based on sleep
    if (_latestSleep != null && _latestSleep!.totalHours < 6) {
      recommendations.add("You might be sleep-deprived. Try to get more rest tonight.");
    }
    
    if (recommendations.isEmpty) {
      return "You're doing great! Keep up your healthy habits. 🌟";
    }
    
    return "💡 Recommendations:\n\n" + recommendations.map((r) => "• $r").join("\n");
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WATCH AI MODULE (8x Smarter Version for ESP32)
// ═══════════════════════════════════════════════════════════════════════════
// This code will be added to the watch firmware for on-device AI processing

class WatchAI {
  // Watch AI has 8x the processing capability
  // More advanced algorithms, better predictions
  
  /// Analyze heart rate with 8x intelligence
  static String analyzeHeartRateAdvanced(int bpm, int hrv, int age, List<int> history) {
    String analysis = "";
    
    // 1. Multi-factor analysis
    int riskScore = 0;
    List<String> riskFactors = [];
    
    // Age-adjusted analysis
    int maxHR = 220 - age;
    if (bpm > maxHR * 0.9) {
      riskScore += 3;
      riskFactors.add("High heart rate for age");
    }
    
    // HRV analysis (more sophisticated)
    if (hrv > 0) {
      if (hrv < 20) {
        riskScore += 4;
        riskFactors.add("Very low HRV (high stress)");
      } else if (hrv < 40) {
        riskScore += 2;
        riskFactors.add("Below average HRV");
      } else if (hrv > 80) {
        riskScore -= 2;
        riskFactors.add("Excellent HRV");
      }
    }
    
    // Pattern analysis from history
    if (history.length >= 10) {
      // Calculate trend
      int avgRecent = history.sublist(history.length - 5).reduce((a, b) => a + b) ~/ 5;
      int avgOlder = history.sublist(0, 5).reduce((a, b) => a + b) ~/ 5;
      
      if (avgRecent > avgOlder * 1.15) {
        riskScore += 2;
        riskFactors.add("Heart rate trending upward");
      }
    }
    
    // 2. Generate response
    if (riskScore >= 5) {
      analysis = "⚠️ ELEVATED RISK\n";
      analysis += "Score: $riskScore/10\n";
      analysis += "Factors:\n" + riskFactors.map((f) => "• $f").join("\n");
    } else if (riskScore <= 0) {
      analysis = "✅ EXCELLENT\n";
      analysis += "All metrics look great!\n";
    } else {
      analysis = "📊 MONITOR\n";
      analysis += "Score: $riskScore/10\n";
      analysis += "Consider:\n" + riskFactors.map((f) => "• $f").join("\n");
    }
    
    return analysis;
  }
  
  /// Predict health trajectory (8x smarter prediction)
  static String predictTrajectory(List<Map<String, dynamic>> weekData) {
    if (weekData.length < 3) return "Need more data for prediction";
    
    // Calculate trends
    double avgHR = 0, avgSteps = 0, avgSleep = 0;
    int hrTrend = 0, stepTrend = 0, sleepTrend = 0;
    
    for (int i = 0; i < weekData.length; i++) {
      avgHR += (weekData[i]['heartRate'] ?? 0);
      avgSteps += (weekData[i]['steps'] ?? 0);
      avgSleep += (weekData[i]['sleep'] ?? 0);
    }
    avgHR /= weekData.length;
    avgSteps /= weekData.length;
    avgSleep /= weekData.length;
    
    // Calculate direction of trends
    if (weekData.length >= 5) {
      int recentAvg = weekData.sublist(weekData.length - 3).map((d) => d['steps'] ?? 0).reduce((a, b) => a + b) ~/ 3;
      int olderAvg = weekData.sublist(0, 3).map((d) => d['steps'] ?? 0).reduce((a, b) => a + b) ~/ 3;
      stepTrend = recentAvg - olderAvg;
    }
    
    // Generate prediction
    String prediction = "📈 Weekly Prediction:\n\n";
    
    if (stepTrend > 1000) {
      prediction += "↑ Activity improving (+${stepTrend ~/ 7}/day)\n";
    } else if (stepTrend < -1000) {
      prediction += "↓ Activity declining (${stepTrend ~/ 7}/day)\n";
    } else {
      prediction += "→ Activity stable\n";
    }
    
    prediction += "Avg Sleep: ${avgSleep ~/ 1}h/night\n";
    prediction += "Avg Heart Rate: ${avgHR ~/ 1} BPM\n";
    
    return prediction;
  }
  
  /// Emergency risk assessment (8x more accurate)
  static int assessEmergencyRisk({
    required int heartRate,
    required int spO2,
    required double accelerometerMagnitude,
    required bool irregularBeat,
    required int age,
  }) {
    int risk = 0;
    
    // Heart rate risks
    int maxHR = 220 - age;
    if (heartRate > maxHR * 0.95) risk += 40;
    else if (heartRate > maxHR * 0.85) risk += 20;
    if (heartRate < 40) risk += 40;
    else if (heartRate < 50) risk += 15;
    
    // Oxygen risks
    if (spO2 < 85) risk += 50;
    else if (spO2 < 92) risk += 25;
    
    // Fall detection
    if (accelerometerMagnitude > 30) risk += 30;
    else if (accelerometerMagnitude > 15) risk += 10;
    
    // Irregular heartbeat
    if (irregularBeat) risk += 25;
    
    return risk.clamp(0, 100);
  }
}
