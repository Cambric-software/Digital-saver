import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_models.dart';

class StorageService {
  static const _keyProfile = 'user_profile';
  static const _keyContacts = 'emergency_contacts';
  static const _keyLanguage = 'language';

  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyProfile);
    if (json == null) return UserProfile();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile(
        name: m['name'] ?? '',
        age: m['age'] ?? 30,
        weightKg: (m['weightKg'] ?? 70).toDouble(),
        heightCm: (m['heightCm'] ?? 170).toDouble(),
        gender: m['gender'] ?? 'Male',
        language: m['language'] ?? 'en',
      );
    } catch (_) {
      return UserProfile();
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyProfile,
      jsonEncode({
        'name': profile.name,
        'age': profile.age,
        'weightKg': profile.weightKg,
        'heightCm': profile.heightCm,
        'gender': profile.gender,
        'language': profile.language,
      }),
    );
  }

  static Future<List<EmergencyContact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyContacts);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => EmergencyContact.fromMap(Map<String, String>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyContacts,
      jsonEncode(contacts.map((c) => c.toMap()).toList()),
    );
  }

  static Future<String> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
  }
}
