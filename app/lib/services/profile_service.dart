import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_models.dart';

/// Service for managing user profiles and health data
class ProfileService {
  final _client = Supabase.instance.client;
  
  /// Update the current user's health profile
  Future<bool> updateHealthProfile({
    String? displayName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? bloodType,
    String? phone,
    DateTime? dateOfBirth,
    List<String>? medicalConditions,
    List<String>? allergies,
    List<String>? medications,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (displayName != null) updates['display_name'] = displayName;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (heightCm != null) updates['height_cm'] = heightCm;
      if (weightKg != null) updates['weight_kg'] = weightKg;
      if (bloodType != null) updates['blood_type'] = bloodType;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
      if (medicalConditions != null) updates['medical_conditions'] = medicalConditions;
      if (allergies != null) updates['allergies'] = allergies;
      if (medications != null) updates['medications'] = medications;
      if (emergencyContactName != null) updates['emergency_contact_name'] = emergencyContactName;
      if (emergencyContactPhone != null) updates['emergency_contact_phone'] = emergencyContactPhone;
      
      final response = await _client
          .from('digital_saver_user_profiles')
          .update(updates)
          .eq('id', user.id)
          .select();
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  /// Get the current user's profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      final response = await _client
          .from('digital_saver_user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (response == null) return null;
      return UserProfile.fromSupabase(response);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }
  
  /// Check what required profile fields are missing
  Future<List<String>> getMissingProfileFields() async {
    final profile = await getUserProfile();
    if (profile == null) return ['name', 'age', 'height', 'weight', 'bloodType', 'emergencyContact'];
    
    return profile.missingRequiredFields;
  }
  
  /// Get a human-readable list of missing fields for display
  String getMissingFieldsDisplay(List<String> missing) {
    final displayNames = <String, String>{
      'name': 'Full Name',
      'age': 'Age',
      'height': 'Height',
      'weight': 'Weight',
      'bloodType': 'Blood Type',
      'emergencyContact': 'Emergency Contact Name',
      'emergencyPhone': 'Emergency Contact Phone',
    };
    
    return missing.map((f) => displayNames[f] ?? f).join(', ');
  }
  
  /// Calculate BMI from height and weight
  static double calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  /// Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'female') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
  }
  
  /// Calculate daily calorie needs based on activity level
  static double calculateDailyCalories({
    required double bmr,
    String activityLevel = 'moderate', // sedentary, light, moderate, active, very_active
  }) {
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    
    final multiplier = multipliers[activityLevel] ?? 1.55;
    return bmr * multiplier;
  }
  
  /// Calculate target heart rate zones
  static Map<String, int> calculateHeartRateZones(int age) {
    final maxHR = 220 - age;
    return {
      'resting': (maxHR * 0.5).toInt(),
      'fat_burn': (maxHR * 0.6).toInt(),
      'cardio': (maxHR * 0.75).toInt(),
      'peak': (maxHR * 0.9).toInt(),
      'max': maxHR,
    };
  }
  
  /// Estimate calories burned from steps
  static double estimateCaloriesFromSteps({
    required int steps,
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    // stride length estimation
    final strideLength = heightCm * 0.415 / 100; // meters
    final distanceKm = (steps * strideLength) / 1000;
    
    // Calories per km based on weight (approximation)
    final caloriesPerKm = weightKg * 0.5;
    
    return distanceKm * caloriesPerKm;
  }
  
  /// Get health insights based on profile and recent data
  Future<String> generateHealthInsights(UserProfile profile) async {
    final insights = <String>[];
    
    // BMI analysis
    final bmi = profile.bmi;
    if (bmi > 0) {
      if (bmi < 18.5) {
        insights.add('Your BMI is ${bmi.toStringAsFixed(1)} (underweight). Consider a nutrient-rich diet.');
      } else if (bmi >= 30) {
        insights.add('Your BMI is ${bmi.toStringAsFixed(1)} (obese). Consult a healthcare provider for a weight management plan.');
      } else if (bmi >= 25) {
        insights.add('Your BMI is ${bmi.toStringAsFixed(1)} (overweight). Light exercise could help.');
      } else {
        insights.add('Your BMI of ${bmi.toStringAsFixed(1)} is in the healthy range. Keep it up!');
      }
    }
    
    // Age-based recommendations
    if (profile.age > 0) {
      if (profile.age > 60) {
        insights.add('Regular cardiovascular check-ups are recommended for your age group.');
      }
      if (profile.age > 50) {
        insights.add('Consider bone density screening if not done recently.');
      }
    }
    
    // Medical conditions
    if (profile.medicalConditions.isNotEmpty) {
      for (final condition in profile.medicalConditions) {
        final condLower = condition.toLowerCase();
        if (condLower.contains('diabetes')) {
          insights.add('Monitor blood sugar regularly and maintain a balanced, low-sugar diet.');
        }
        if (condLower.contains('hypertension') || condLower.contains('heart')) {
          insights.add('Heart-healthy habits: low sodium diet, regular light exercise.');
        }
        if (condLower.contains('asthma')) {
          insights.add('Keep rescue inhaler accessible. Avoid known triggers.');
        }
      }
    }
    
    // Blood type
    if (profile.bloodType != null) {
      if (profile.bloodType == 'O-') {
        insights.add('As O-negative, you are a universal donor. Consider blood donation if eligible.');
      }
      if (profile.bloodType == 'AB+') {
        insights.add('As AB-positive, you are a universal recipient. Consider being a plasma donor.');
      }
    }
    
    // Emergency contact
    if (profile.emergencyContactName == null || profile.emergencyContactName!.isEmpty) {
      insights.add('⚠️ Add an emergency contact for safety alerts.');
    }
    
    return insights.join('\n\n');
  }
}
