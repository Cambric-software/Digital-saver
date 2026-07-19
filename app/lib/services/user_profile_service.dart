import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_models.dart';

// ===========================================================================
// USER PROFILE SERVICE - Syncs local and cloud profiles
// ===========================================================================

class UserProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  // Local storage keys
  static const String _keyLocalProfile = 'local_user_profile';
  static const String _keyProfileVersion = 'profile_version';
  static const String _keyLastSync = 'last_profile_sync';

  // =========================================================================
  // PROFILE OPERATIONS
  // =========================================================================

  /// Load profile - tries cloud first, falls back to local
  Future<UserProfile> loadProfile(String? userId) async {
    // Try to load from cloud if authenticated
    if (userId != null) {
      try {
        final cloudProfile = await _loadFromCloud(userId);
        if (cloudProfile != null) {
          // Merge with local and update cloud if needed
          final localProfile = await _loadFromLocal();
          final merged = _mergeProfiles(localProfile, cloudProfile);

          // Update cloud with merged data
          await _saveToCloud(merged, userId);
          await _saveToLocal(merged);
          await _updateLastSync();

          return merged;
        }
      } catch (e) {
        // Cloud load failed, use local
      }
    }

    // Load from local storage
    final localProfile = await _loadFromLocal();
    return localProfile;
  }

  /// Save profile - saves to both cloud and local
  Future<void> saveProfile(UserProfile profile, String? userId) async {
    // Always save locally first
    await _saveToLocal(profile);

    // Save to cloud if authenticated
    if (userId != null) {
      try {
        await _saveToCloud(profile, userId);
        await _updateLastSync();
      } catch (e) {
        // Cloud save failed, but local succeeded
        // Will sync next time
      }
    }
  }

  // =========================================================================
  // CLOUD OPERATIONS
  // =========================================================================

  Future<UserProfile?> _loadFromCloud(String userId) async {
    final result = await _client
        .from('digital_saver_user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (result == null) return null;

    return _cloudProfileToUserProfile(result);
  }

  Future<void> _saveToCloud(UserProfile profile, String userId) async {
    final cloudProfile = _userProfileToCloudProfile(profile, userId);

    // Check if profile exists
    final existing = await _client
        .from('digital_saver_user_profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      // Update existing
      await _client
          .from('digital_saver_user_profiles')
          .update({
            ...cloudProfile,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } else {
      // Insert new
      await _client
          .from('digital_saver_user_profiles')
          .insert(cloudProfile);
    }
  }

  // =========================================================================
  // LOCAL OPERATIONS
  // =========================================================================

  Future<UserProfile> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyLocalProfile);

    if (json == null) return UserProfile();

    try {
      final Map<String, dynamic> m = _parseJson(json);
      return UserProfile(
        name: m['name'] ?? '',
        age: m['age'] ?? 30,
        weightKg: (m['weightKg'] ?? 70).toDouble(),
        heightCm: (m['heightCm'] ?? 170).toDouble(),
        gender: m['gender'] ?? 'Male',
        language: m['language'] ?? 'en',
        emergencyContacts: _parseContacts(m['emergencyContacts']),
      );
    } catch (e) {
      return UserProfile();
    }
  }

  Future<void> _saveToLocal(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final json = _encodeJson({
      'name': profile.name,
      'age': profile.age,
      'weightKg': profile.weightKg,
      'heightCm': profile.heightCm,
      'gender': profile.gender,
      'language': profile.language,
      'emergencyContacts': profile.emergencyContacts
          .map((c) => c.toMap())
          .toList(),
    });

    await prefs.setString(_keyLocalProfile, json);
    await prefs.setInt(_keyProfileVersion, (prefs.getInt(_keyProfileVersion) ?? 0) + 1);
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  UserProfile _mergeProfiles(UserProfile local, UserProfile cloud) {
    // Cloud takes precedence for most fields
    // But keep emergency contacts from local if cloud doesn't have them

    List<EmergencyContact> mergedContacts = cloud.emergencyContacts.isNotEmpty
        ? cloud.emergencyContacts
        : local.emergencyContacts;

    return UserProfile(
      name: cloud.name.isNotEmpty ? cloud.name : local.name,
      age: cloud.age != 30 ? cloud.age : local.age,
      weightKg: cloud.weightKg != 70 ? cloud.weightKg : local.weightKg,
      heightCm: cloud.heightCm != 170 ? cloud.heightCm : local.heightCm,
      gender: cloud.gender.isNotEmpty ? cloud.gender : local.gender,
      language: cloud.language.isNotEmpty ? cloud.language : local.language,
      emergencyContacts: mergedContacts,
    );
  }

  UserProfile _cloudProfileToUserProfile(Map<String, dynamic> cloud) {
    return UserProfile(
      name: cloud['display_name'] ?? '',
      age: _calculateAge(cloud['date_of_birth']),
      weightKg: (cloud['weight_kg'] ?? 70).toDouble(),
      heightCm: (cloud['height_cm'] ?? 170).toDouble(),
      gender: cloud['gender'] ?? 'Male',
      language: cloud['preferred_language'] ?? 'en',
      emergencyContacts: [],
    );
  }

  Map<String, dynamic> _userProfileToCloudProfile(UserProfile profile, String userId) {
    return {
      'id': userId,
      'display_name': profile.name,
      'height_cm': profile.heightCm.round(),
      'weight_kg': profile.weightKg,
      'gender': profile.gender.toLowerCase(),
      'preferred_language': profile.language,
    };
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 30;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  List<EmergencyContact> _parseContacts(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];

    return data.map((c) {
      if (c is Map) {
        return EmergencyContact(
          name: c['name'] ?? '',
          phone: c['phone'] ?? '',
          relation: c['relation'] ?? '',
        );
      }
      return EmergencyContact(name: '', phone: '', relation: '');
    }).toList();
  }

  Map<String, dynamic> _parseJson(String json) {
    // Simple JSON parser for SharedPreferences
    final result = <String, dynamic>{};
    final content = json.trim();
    if (content.startsWith('{') && content.endsWith('}')) {
      final inner = content.substring(1, content.length - 1);
      _parseJsonObject(inner, result);
    }
    return result;
  }

  void _parseJsonObject(String content, Map<String, dynamic> result) {
    final pairs = _splitJsonPairs(content);
    for (var pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex > 0) {
        final key = pair.substring(0, colonIndex).trim().replaceAll('"', '');
        var value = pair.substring(colonIndex + 1).trim();
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        } else if (value == 'null') {
          value = '';
        }
        result[key] = value;
      }
    }
  }

  List<String> _splitJsonPairs(String content) {
    final pairs = <String>[];
    var current = '';
    var depth = 0;
    var inString = false;

    for (var i = 0; i < content.length; i++) {
      final c = content[i];
      if (c == '"' && (i == 0 || content[i - 1] != '\\')) {
        inString = !inString;
      }
      if (!inString) {
        if (c == '{' || c == '[') depth++;
        if (c == '}' || c == ']') depth--;
        if (c == ',' && depth == 0) {
          pairs.add(current);
          current = '';
          continue;
        }
      }
      current += c;
    }
    if (current.isNotEmpty) pairs.add(current);
    return pairs;
  }

  String _encodeJson(Map<String, dynamic> map) {
    final pairs = map.entries.map((e) {
      final value = e.value;
      if (value is String) {
        return '"${e.key}":"${value.replaceAll('"', '\\"')}"';
      } else if (value is List) {
        return '"${e.key}":[${value.map((v) => v.toString()).join(',')}]';
      } else {
        return '"${e.key}":$value';
      }
    }).join(',');
    return '{$pairs}';
  }

  Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_keyLastSync);
    return lastSync != null ? DateTime.parse(lastSync) : null;
  }

  // =========================================================================
  // PROFILE SYNC STATUS
  // =========================================================================

  Future<SyncStatus> getSyncStatus(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_keyLastSync);
    final localVersion = prefs.getInt(_keyProfileVersion) ?? 0;

    bool cloudExists = false;
    if (userId != null) {
      try {
        final result = await _client
            .from('digital_saver_user_profiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        cloudExists = result != null;
      } catch (e) {
        cloudExists = false;
      }
    }

    return SyncStatus(
      isAuthenticated: userId != null,
      cloudHasProfile: cloudExists,
      localVersion: localVersion,
      lastSyncTime: lastSync != null ? DateTime.parse(lastSync) : null,
      needsSync: userId != null && (lastSync == null || !cloudExists),
    );
  }
}

// ===========================================================================
// SYNC STATUS
// ===========================================================================

class SyncStatus {
  final bool isAuthenticated;
  final bool cloudHasProfile;
  final int localVersion;
  final DateTime? lastSyncTime;
  final bool needsSync;

  SyncStatus({
    required this.isAuthenticated,
    required this.cloudHasProfile,
    required this.localVersion,
    this.lastSyncTime,
    required this.needsSync,
  });

  String get statusText {
    if (!isAuthenticated) return 'Local only';
    if (needsSync) return 'Sync needed';
    return 'Synced';
  }
}
