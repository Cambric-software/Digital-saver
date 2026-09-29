import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const String _prefKey = 'app_language';
  String _language = 'English';

  LocaleService() {
    _loadLanguage();
  }

  String get currentLanguage => _language;
  bool get isArabic => _language == 'العربية';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;
  Locale get currentLocale => isArabic ? const Locale('ar') : const Locale('en');

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) {
        _language = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language);
    } catch (_) {}
  }

  String tr(String key) {
    if (!isArabic) {
      return _translationsEn[key] ?? key;
    }
    return _translationsAr[key] ?? _translationsEn[key] ?? key;
  }

  static const Map<String, String> _translationsEn = {
    'home': 'Home',
    'vitals': 'Vitals',
    'ai_coach': 'AI Coach',
    'watch': 'Watch',
    'settings': 'Settings',
    'scan_ble': 'Scanning for Veyro smartwatch...',
    'pairing': 'Pairing with Veyro...',
    'version': 'Version',
    'version_unavailable': 'Version unavailable',
  };

  static const Map<String, String> _translationsAr = {
    'home': 'الرئيسية',
    'vitals': 'المؤشرات',
    'ai_coach': 'مساعد الذكاء',
    'watch': 'الساعة',
    'settings': 'الإعدادات',
    'scan_ble': 'جاري البحث عن ساعة فيرو...',
    'pairing': 'جاري الاقتران بساعة فيرو...',
    'version': 'الإصدار',
    'version_unavailable': 'الإصدار غير متاح',
  };
}
