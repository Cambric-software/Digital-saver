import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_models.dart';
import 'cambric_auth_service_v2.dart';

/// Service to check and manage user profile completeness
class ProfileCheckService {
  static final ProfileCheckService _instance = ProfileCheckService._internal();
  factory ProfileCheckService() => _instance;
  ProfileCheckService._internal();
  
  /// Check if user's profile is complete
  Future<ProfileCheckResult> checkProfileCompleteness(AuthProvider auth) async {
    // Detailed error tracking
    final errorDetails = <String>[];
    
    try {
      if (!auth.isAuthenticated) {
        errorDetails.add('User is not authenticated');
        return ProfileCheckResult(
          isComplete: false,
          missingFields: [],
          profile: UserProfile(),
        );
      }
      
      // Store user ID in local variable to avoid race conditions
      final userId = auth.user?.id;
      if (userId == null || userId.isEmpty) {
        errorDetails.add('User ID is null or empty - user object: ${auth.user}');
        return ProfileCheckResult(
          isComplete: false,
          missingFields: [],
          profile: UserProfile(),
          error: 'User ID not found. Details: $errorDetails',
        );
      }
      
      errorDetails.add('Fetching profile for user ID: $userId');
      
      final result = await Supabase.instance.client
          .from('digital_saver_user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (result == null) {
        errorDetails.add('No profile found for user - creating new profile');
        // No profile exists - all fields are missing
        return ProfileCheckResult(
          isComplete: false,
          missingFields: ['name', 'age', 'weight', 'height', 'bloodType', 'emergencyContact', 'emergencyPhone'],
          profile: UserProfile(),
        );
      }

      errorDetails.add('Profile found, parsing data...');
      final profile = UserProfile.fromSupabase(result);
      final missingFields = profile.missingRequiredFields;
      
      errorDetails.add('Missing fields: $missingFields');

      return ProfileCheckResult(
        isComplete: missingFields.isEmpty,
        missingFields: missingFields,
        profile: profile,
      );
    } catch (e, stackTrace) {
      // Capture full error details
      final fullError = 'Error checking profile: $e\nUser state: ${auth.isAuthenticated}\nUser: ${auth.user}\nSteps: ${errorDetails.join(' -> ')}\n\nStack Trace:\n$stackTrace';
      debugPrint(fullError);
      return ProfileCheckResult(
        isComplete: false,
        missingFields: [],
        profile: UserProfile(),
        error: fullError,
      );
    }
  }
  
  /// Get the user's profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final result = await Supabase.instance.client
          .from('digital_saver_user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (result == null) return null;
      return UserProfile.fromSupabase(result);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }
  
  /// Save profile to database
  Future<bool> saveProfile(String userId, UserProfile profile) async {
    try {
      final data = profile.toSupabase();
      data['id'] = userId;
      
      await Supabase.instance.client
          .from('digital_saver_user_profiles')
          .upsert(data);
      
      return true;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }
  
  /// Update specific profile fields
  Future<bool> updateProfileFields(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await Supabase.instance.client
          .from('digital_saver_user_profiles')
          .update(updates)
          .eq('id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }
  
  /// Check if profile was ever completed (for first-time user flow)
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final result = await Supabase.instance.client
          .from('digital_saver_user_profiles')
          .select('created_at')
          .eq('id', userId)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Get missing fields count
  int getMissingFieldsCount(ProfileCheckResult result) {
    return result.missingFields.length;
  }
  
  /// Get human-readable missing field names
  List<String> getMissingFieldLabels(List<String> missingFields) {
    final labels = <String>[];
    for (final field in missingFields) {
      switch (field) {
        case 'name':
          labels.add('Full Name');
          break;
        case 'age':
          labels.add('Age');
          break;
        case 'weight':
          labels.add('Weight');
          break;
        case 'height':
          labels.add('Height');
          break;
        case 'bloodType':
          labels.add('Blood Type');
          break;
        case 'emergencyContact':
          labels.add('Emergency Contact Name');
          break;
        case 'emergencyPhone':
          labels.add('Emergency Contact Phone');
          break;
        default:
          labels.add(field);
      }
    }
    return labels;
  }
}

/// Result of profile completeness check
class ProfileCheckResult {
  final bool isComplete;
  final List<String> missingFields;
  final UserProfile profile;
  final String? error;
  
  ProfileCheckResult({
    required this.isComplete,
    required this.missingFields,
    required this.profile,
    this.error,
  });
  
  /// Get priority fields (shown first in completion screen)
  List<String> get priorityFields {
    return missingFields.where((f) => 
      ['name', 'bloodType', 'emergencyContact', 'emergencyPhone'].contains(f)
    ).toList();
  }
  
  /// Get secondary fields
  List<String> get secondaryFields {
    return missingFields.where((f) => 
      ['age', 'weight', 'height'].contains(f)
    ).toList();
  }
}
