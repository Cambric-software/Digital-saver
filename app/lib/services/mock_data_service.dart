import 'dart:math';
import '../models/health_models.dart';

/// Mock Data Generator for testing without watch
/// Generates realistic health data for development and testing
class MockDataService {
  static final Random _random = Random();
  
  // User profile for personalized calculations
  static int _age = 30;
  static int _weightKg = 70;
  static int _heightCm = 170;
  static String _gender = 'male';
  
  static void setUserProfile({
    int? age,
    int? weightKg,
    int? heightCm,
    String? gender,
  }) {
    _age = age ?? _age;
    _weightKg = weightKg ?? _weightKg;
    _heightCm = heightCm ?? _heightCm;
    _gender = gender ?? _gender;
  }
  
  /// Generate random heart rate data
  static HeartRateData generateHeartRate() {
    // Base heart rate varies by time of day
    final hour = DateTime.now().hour;
    int baseHR = 70;
    
    if (hour >= 6 && hour < 9) baseHR = 65; // Morning
    if (hour >= 9 && hour < 18) baseHR = 75; // Work hours
    if (hour >= 18 && hour < 22) baseHR = 80; // Evening
    if (hour >= 22 || hour < 6) baseHR = 60; // Night
    
    // Add some randomness
    final bpm = baseHR + _random.nextInt(20) - 10;
    final hrv = 40 + _random.nextInt(40);
    final afibProbability = _random.nextInt(100) < 5 ? _random.nextInt(50) + 50 : _random.nextInt(20);
    
    return HeartRateData(
      bpm: bpm.clamp(50, 120),
      confidence: 85 + _random.nextInt(15),
      hrv: hrv,
      sdnn: 20 + _random.nextInt(30),
      pnn50: _random.nextInt(30),
      afibProbability: afibProbability,
      status: afibProbability > 50 ? 1 : 0,
      rrIntervals: List.generate(10, (_) => 600 + _random.nextInt(400)),
    );
  }
  
  /// Generate random blood pressure data
  static BloodPressureData generateBloodPressure() {
    final systolic = 110 + _random.nextInt(30);
    final diastolic = 70 + _random.nextInt(20);
    
    return BloodPressureData(
      systolic: systolic,
      diastolic: diastolic,
      map: diastolic + (systolic - diastolic) ~/ 3,
      pulsePressure: systolic - diastolic,
      augmentationIndex: 0.2 + _random.nextDouble() * 0.3,
      pulseWaveVelocity: 5 + _random.nextDouble() * 5,
      confidence: 70 + _random.nextInt(25),
    );
  }
  
  /// Generate random oxygen data
  static OxygenData generateOxygen() {
    final spo2 = 95 + _random.nextInt(5);
    
    return OxygenData(
      spO2: spo2,
      perfusionIndex: 3 + _random.nextInt(10),
      respirationRate: 14 + _random.nextInt(6),
      confidence: 80 + _random.nextInt(18),
    );
  }
  
  /// Generate random activity data
  static ActivityData generateActivity() {
    final steps = 3000 + _random.nextInt(8000);
    final calories = _calculateCalories(steps);
    
    return ActivityData(
      steps: steps,
      calories: calories,
      distanceKm: _calculateDistance(steps),
      activeMinutes: steps ~/ 100,
      hourlySteps: List.generate(24, (i) {
        if (i < 6) return 0; // Night
        if (i >= 9 && i < 12) return 500 + _random.nextInt(1000); // Morning
        if (i >= 14 && i < 17) return 300 + _random.nextInt(700); // Afternoon
        if (i >= 18 && i < 21) return 400 + _random.nextInt(800); // Evening
        return 100 + _random.nextInt(300);
      }),
    );
  }
  
  /// Generate random sleep data
  static SleepData generateSleep() {
    final totalMinutes = 360 + _random.nextInt(120); // 6-8 hours
    final deepSleepMinutes = (totalMinutes * 0.2).toInt();
    final remSleepMinutes = (totalMinutes * 0.25).toInt();
    
    return SleepData(
      totalMinutes: totalMinutes,
      deepSleepMinutes: deepSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      lightSleepMinutes: totalMinutes - deepSleepMinutes - remSleepMinutes,
      awakenings: _random.nextInt(4),
      sleepStartHour: 22 + _random.nextInt(3),
      sleepStartMinute: _random.nextInt(60),
      wakeUpHour: 6 + _random.nextInt(2),
      wakeUpMinute: _random.nextInt(60),
      qualityScore: 60 + _random.nextInt(40),
    );
  }
  
  /// Generate temperature data
  static TemperatureData generateTemperature() {
    return TemperatureData(
      temperature: 36.4 + _random.nextDouble() * 0.8,
      confidence: 75 + _random.nextInt(20),
    );
  }
  
  /// Generate all mock data at once
  static Map<String, dynamic> generateAllData() {
    return {
      'heartRate': generateHeartRate(),
      'bloodPressure': generateBloodPressure(),
      'oxygen': generateOxygen(),
      'activity': generateActivity(),
      'sleep': generateSleep(),
      'temperature': generateTemperature(),
      'timestamp': DateTime.now(),
    };
  }
  
  /// Calculate calories from steps
  static double _calculateCalories(int steps) {
    // Using height for stride length
    final strideLength = _heightCm * 0.414 / 100; // meters
    final distanceKm = steps * strideLength / 1000;
    return distanceKm * _weightKg * 0.5;
  }
  
  /// Calculate distance from steps
  static double _calculateDistance(int steps) {
    final strideLength = _heightCm * 0.414 / 100; // meters
    return steps * strideLength / 1000;
  }
  
  /// Calculate BMI
  static double calculateBMI() {
    if (_heightCm <= 0) return 0;
    final heightM = _heightCm / 100;
    return _weightKg / (heightM * heightM);
  }
  
  /// Calculate BMR using Mifflin-St Jeor
  static double calculateBMR() {
    if (_gender.toLowerCase() == 'female') {
      return (10 * _weightKg) + (6.25 * _heightCm) - (5 * _age) - 161;
    } else {
      return (10 * _weightKg) + (6.25 * _heightCm) - (5 * _age) + 5;
    }
  }
  
  /// Calculate daily calorie needs
  static double calculateDailyCalories({String activityLevel = 'moderate'}) {
    final bmr = calculateBMR();
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    return bmr * (multipliers[activityLevel] ?? 1.55);
  }
  
  /// Get target heart rate zones
  static Map<String, int> getHeartRateZones() {
    final maxHR = 220 - _age;
    return {
      'resting': (maxHR * 0.5).toInt(),
      'fatBurn': (maxHR * 0.6).toInt(),
      'cardio': (maxHR * 0.75).toInt(),
      'peak': (maxHR * 0.9).toInt(),
      'max': maxHR,
    };
  }
  
  /// Generate health trend data for charts
  static List<Map<String, dynamic>> generateWeeklyTrends() {
    return List.generate(7, (dayIndex) {
      final date = DateTime.now().subtract(Duration(days: 6 - dayIndex));
      return {
        'date': date,
        'heartRate': 65 + _random.nextInt(25),
        'steps': 5000 + _random.nextInt(7000),
        'sleepHours': 6.0 + _random.nextDouble() * 2.5,
        'calories': 1800 + _random.nextInt(600),
        'spO2': 95 + _random.nextInt(4),
      };
    });
  }
  
  /// Generate AI health insight based on data
  static String generateHealthInsight() {
    final insights = <String>[];
    
    // BMI analysis
    final bmi = calculateBMI();
    if (bmi > 0) {
      if (bmi < 18.5) {
        insights.add('Your BMI is ${bmi.toStringAsFixed(1)} (underweight). Consider a nutrient-rich diet.');
      } else if (bmi >= 30) {
        insights.add('Your BMI is ${bmi.toStringAsFixed(1)} (obese). Consult a healthcare provider.');
      } else if (bmi >= 25) {
        insights.add('Your BMI is ${bmi.toStringAsFixed(1)} (overweight). Light exercise could help.');
      } else {
        insights.add('Your BMI of ${bmi.toStringAsFixed(1)} is in the healthy range. Keep it up!');
      }
    }
    
    // Age-based recommendations
    if (_age > 50) {
      insights.add('Regular cardiovascular check-ups are recommended for your age group.');
    }
    
    // Activity analysis
    insights.add('You\'ve been moderately active this week. Try adding 20 minutes of walking.');
    
    // Sleep analysis
    insights.add('Your sleep quality has been good. Maintain a consistent bedtime routine.');
    
    return insights.join('\n\n');
  }
}
