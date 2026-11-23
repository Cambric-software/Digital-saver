/// The appearance and language each person using the app has chosen.
///
/// Digital Saver is shared in a household, so the theme, accent, text size,
/// contrast and language are stored per person rather than per device.
/// Switching profiles applies that person's whole appearance in one step, and
/// the next change is written back to the profile that is active.
///
/// The one automatic rule the person can switch on is "Dim after dark". It is
/// off by default, stored under one key in [StorageService], and when on it asks
/// [DynamicThemeService] whether the local clock is between 20:00 and 07:00. If
/// it is, the dark theme is used. No weather is fetched or made up, and the
/// switch does nothing at all until the person turns it on.
///
/// While the switch is on, one timer wakes at the next 07:00 or 20:00 so an app
/// left open changes with the clock instead of waiting for an unrelated rebuild.
/// The timer is cancelled when the switch is turned off and on [dispose].
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dynamic_theme_service.dart';
import 'storage_service.dart';

/// Whether the app is drawn on light or dark surfaces.
enum AppThemeMode { light, dark }

/// The accent a person can choose for the app.
///
/// Each accent is a seed colour, not a hand-built palette. The base Cambric
/// design keeps its surfaces, borders and semantic health colours; only the
/// primary, secondary and tertiary families are re-derived from the seed. That
/// is why a theme change is visible on every screen without a second design
/// system.
enum AppAccent {
  blue('blue', Color(0xFF3B82F6)),
  teal('teal', Color(0xFF0D9488)),
  purple('purple', Color(0xFF7C3AED)),
  green('green', Color(0xFF16A34A)),
  amber('amber', Color(0xFFD97706));

  const AppAccent(this.storageKey, this.seed);

  /// Value written to storage.
  final String storageKey;

  /// Seed colour used to derive the palette.
  final Color seed;

  /// Translation key for the accent name.
  String get labelKey => 'accent_$storageKey';

  /// Look up an accent, falling back to blue for an unknown stored value.
  static AppAccent fromStorage(String? value) {
    for (final AppAccent accent in AppAccent.values) {
      if (accent.storageKey == value) return accent;
    }
    return AppAccent.blue;
  }
}

/// One person's saved appearance.
///
/// [id] is stable; [name] is what the person typed.
@immutable
class PersonProfile {
  /// Create a profile.
  const PersonProfile({
    required this.id,
    required this.name,
    this.themeMode = AppThemeMode.light,
    this.accent = AppAccent.blue,
    this.textScale = 1.0,
    this.languageCode = 'en',
    this.highContrast = false,
  });

  /// Stable identifier used as the storage key.
  final String id;

  /// Name shown in the profile switcher.
  final String name;

  /// Light or dark.
  final AppThemeMode themeMode;

  /// Accent seed.
  final AppAccent accent;

  /// Multiplier applied on top of the operating system's text scale.
  final double textScale;

  /// `en` or `ar`.
  final String languageCode;

  /// Stronger borders and contrast.
  final bool highContrast;

  /// The same profile with selected fields replaced.
  PersonProfile copyWith({
    String? name,
    AppThemeMode? themeMode,
    AppAccent? accent,
    double? textScale,
    String? languageCode,
    bool? highContrast,
  }) {
    return PersonProfile(
      id: id,
      name: name ?? this.name,
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      textScale: textScale ?? this.textScale,
      languageCode: languageCode ?? this.languageCode,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  /// Serialise for storage.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'theme': themeMode == AppThemeMode.dark ? 'dark' : 'light',
        'accent': accent.storageKey,
        'textScale': textScale,
        'language': languageCode,
        'highContrast': highContrast,
      };

  /// Read a stored profile, falling back to safe values for a damaged entry.
  static PersonProfile fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] ?? '').toString();
    final String name = (json['name'] ?? '').toString().trim();
    return PersonProfile(
      id: id.isEmpty ? 'default' : id,
      name: name.isEmpty ? 'Me' : name,
      themeMode:
          json['theme'] == 'dark' ? AppThemeMode.dark : AppThemeMode.light,
      accent: AppAccent.fromStorage(json['accent']?.toString()),
      textScale: ThemeService._clampScale(
        (json['textScale'] as num?)?.toDouble() ?? 1.0,
      ),
      languageCode: json['language'] == 'ar' ? 'ar' : 'en',
      highContrast: json['highContrast'] == true,
    );
  }

  /// Every profile starts from these values.
  static const PersonProfile defaults = PersonProfile(
    id: 'default',
    name: 'Me',
  );
}

/// The app's stored appearance and language, plus the one automatic rule.
class ThemeService extends ChangeNotifier {
  /// Create the service.
  ///
  /// [dynamicTheme] and [loadStoredPreference] exist for tests: a fake clock
  /// makes the hour deterministic, and turning off the restore keeps a unit
  /// test from depending on shared_preferences.
  ThemeService({
    DynamicThemeService? dynamicTheme,
    bool loadStoredPreference = true,
  }) : _dynamicTheme = dynamicTheme ?? DynamicThemeService() {
    _ready = loadStoredPreference ? _restore() : Future<void>.value();
  }

  static const String _profilesKey = 'digital_saver.profiles';
  static const String _activeKey = 'digital_saver.active_profile';
  static const String _legacyLanguageKey = 'app_language';

  /// Smallest text scale offered. Below this, labels start to clip.
  static const double minTextScale = 0.9;

  /// Largest text scale offered. Above this, the settings screen itself becomes
  /// unusable on a phone.
  static const double maxTextScale = 1.6;

  final DynamicThemeService _dynamicTheme;
  late final Future<void> _ready;

  List<PersonProfile> _profiles = <PersonProfile>[PersonProfile.defaults];
  String _activeProfileId = PersonProfile.defaults.id;
  bool _dimAfterDark = StorageService.defaultDimAfterDark;
  Timer? _boundaryTimer;
  bool _disposed = false;

  /// Completes when stored preferences have been read.
  Future<void> get ready => _ready;

  /// Every profile, in the order they were created.
  List<PersonProfile> get profiles => List<PersonProfile>.unmodifiable(_profiles);

  /// The id of the profile whose settings are active.
  String get activeProfileId => _activeProfileId;

  /// The profile that is currently applied.
  PersonProfile get activeProfile {
    for (final PersonProfile profile in _profiles) {
      if (profile.id == _activeProfileId) return profile;
    }
    return _profiles.isEmpty ? PersonProfile.defaults : _profiles.first;
  }

  /// Light or dark, before the clock rule is applied.
  AppThemeMode get themeModeType => activeProfile.themeMode;

  /// Whether the person asked the app to use the dark theme after dark.
  bool get dimAfterDark => _dimAfterDark;

  /// What the local clock currently asks for.
  LightChoice get lightChoice => _dynamicTheme.currentChoice;

  /// Whether the dark theme is being applied because of the clock.
  bool get isDimmed => _dimAfterDark && lightChoice == LightChoice.dim;

  /// The mode handed to [MaterialApp].
  ThemeMode get themeMode {
    // The clock may only dim. It never overrides a person's chosen palette with
    // anything other than the dark theme, and only while the switch is on.
    if (isDimmed) return ThemeMode.dark;
    return themeModeType == AppThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  /// Accent seed for the active profile.
  AppAccent get accent => activeProfile.accent;

  /// Text multiplier for the active profile.
  double get textScale => activeProfile.textScale;

  /// `en` or `ar` for the active profile.
  String get languageCode => activeProfile.languageCode;

  /// Whether the active profile reads Arabic.
  bool get isArabic => languageCode == 'ar';

  /// The language name used by older call sites and the language menu.
  String get currentLanguage => isArabic ? 'العربية' : 'English';

  /// Locale handed to [MaterialApp].
  Locale get currentLocale => Locale(languageCode);

  /// Reading direction for the active profile.
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Stronger borders and contrast for the active profile.
  bool get highContrast => activeProfile.highContrast;

  /// Change the theme and store it on the active profile.
  Future<void> setTheme(AppThemeMode mode) =>
      _updateActive((PersonProfile p) => p.copyWith(themeMode: mode));

  /// Change the accent and store it on the active profile.
  Future<void> setAccent(AppAccent value) =>
      _updateActive((PersonProfile p) => p.copyWith(accent: value));

  /// Change the text scale and store it on the active profile.
  Future<void> setTextScale(double value) {
    final double clamped = _clampScale(value);
    return _updateActive((PersonProfile p) => p.copyWith(textScale: clamped));
  }

  /// Change the language and store it on the active profile.
  Future<void> setLanguage(String code) {
    final String safe = code == 'ar' ? 'ar' : 'en';
    return _updateActive((PersonProfile p) => p.copyWith(languageCode: safe));
  }

  /// Change the contrast and store it on the active profile.
  Future<void> setHighContrast(bool value) =>
      _updateActive((PersonProfile p) => p.copyWith(highContrast: value));

  /// Switch to another profile and apply its settings.
  Future<void> selectProfile(String id) async {
    if (id == _activeProfileId) return;
    if (!_profiles.any((PersonProfile p) => p.id == id)) return;
    _activeProfileId = id;
    notifyListeners();
    await _persist();
  }

  /// Add a profile and switch to it.
  ///
  /// A new profile starts from the defaults rather than copying the current
  /// person's settings, so two people do not accidentally share a text size
  /// that only one of them needs.
  Future<PersonProfile> addProfile(String name) async {
    final String trimmed = name.trim();
    final PersonProfile created = PersonProfile(
      id: _newId(),
      name: trimmed.isEmpty ? 'Person ${_profiles.length + 1}' : trimmed,
    );
    _profiles = <PersonProfile>[..._profiles, created];
    _activeProfileId = created.id;
    notifyListeners();
    await _persist();
    return created;
  }

  /// Rename a profile. The active person sees the new name immediately.
  Future<void> renameProfile(String id, String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _profiles = _profiles
        .map((PersonProfile p) => p.id == id ? p.copyWith(name: trimmed) : p)
        .toList();
    notifyListeners();
    await _persist();
  }

  /// Delete a profile. The last profile cannot be deleted.
  Future<bool> deleteProfile(String id) async {
    if (_profiles.length <= 1) return false;
    final List<PersonProfile> next =
        _profiles.where((PersonProfile p) => p.id != id).toList();
    if (next.isEmpty) return false;
    _profiles = next;
    if (_activeProfileId == id) {
      _activeProfileId = next.first.id;
    }
    notifyListeners();
    await _persist();
    return true;
  }

  /// Returns the active profile to its defaults, keeping its name.
  Future<void> restoreDefaults() async {
    final PersonProfile reset = PersonProfile(
      id: _activeProfileId,
      name: activeProfile.name,
    );
    _profiles = _profiles
        .map((PersonProfile p) => p.id == reset.id ? reset : p)
        .toList();
    notifyListeners();
    await _persist();
  }

  /// Persist and apply the "Dim after dark" choice.
  ///
  /// The value changes only after the write succeeds, so a failed save leaves
  /// the switch and the theme in agreement rather than showing an unsaved
  /// setting.
  Future<void> setDimAfterDark(bool value) async {
    if (value == _dimAfterDark) return;
    await StorageService.setDimAfterDark(value);
    if (_disposed) return;
    _dimAfterDark = value;
    _scheduleBoundary();
    notifyListeners();
  }

  Future<void> _restore() async {
    await _restoreProfiles();
    await _restoreDimAfterDark();
    if (!_disposed) notifyListeners();
  }

  Future<void> _restoreProfiles() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_profilesKey);
      if (raw == null || raw.isEmpty) {
        // An existing install kept only the language name. Carry that choice
        // into the first profile instead of silently reverting to English.
        final String? legacy = prefs.getString(_legacyLanguageKey);
        final PersonProfile migrated = PersonProfile.defaults.copyWith(
          languageCode: legacy == 'العربية' ? 'ar' : 'en',
        );
        _profiles = <PersonProfile>[migrated];
        _activeProfileId = migrated.id;
        await _persist();
        return;
      }

      final Object? decoded = jsonDecode(raw);
      final List<PersonProfile> parsed = <PersonProfile>[];
      if (decoded is List) {
        for (final Object? entry in decoded) {
          if (entry is Map<String, dynamic>) {
            parsed.add(PersonProfile.fromJson(entry));
          } else if (entry is Map) {
            parsed.add(PersonProfile.fromJson(entry.cast<String, dynamic>()));
          }
        }
      }
      if (parsed.isEmpty) parsed.add(PersonProfile.defaults);
      _profiles = _deduplicate(parsed);
      final String? storedActive = prefs.getString(_activeKey);
      _activeProfileId = _profiles.any(
        (PersonProfile p) => p.id == storedActive,
      )
          ? storedActive!
          : _profiles.first.id;
    } catch (_) {
      // Unreadable preferences fall back to the default rather than blocking
      // startup.
      _profiles = <PersonProfile>[PersonProfile.defaults];
      _activeProfileId = PersonProfile.defaults.id;
    }
  }

  Future<void> _restoreDimAfterDark() async {
    try {
      final bool stored = await StorageService.dimAfterDark();
      if (_disposed || stored == _dimAfterDark) return;
      _dimAfterDark = stored;
      _scheduleBoundary();
    } catch (_) {
      // An unreadable preference means "use the default". It must not stop the
      // app from rendering its first frame.
    }
  }

  Future<void> _updateActive(
    PersonProfile Function(PersonProfile) update,
  ) async {
    _profiles = _profiles
        .map((PersonProfile p) => p.id == _activeProfileId ? update(p) : p)
        .toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _profilesKey,
        jsonEncode(
          _profiles.map((PersonProfile p) => p.toJson()).toList(),
        ),
      );
      await prefs.setString(_activeKey, _activeProfileId);
    } catch (_) {
      // The change still applies for this session.
    }
  }

  List<PersonProfile> _deduplicate(List<PersonProfile> input) {
    final Set<String> seen = <String>{};
    final List<PersonProfile> output = <PersonProfile>[];
    for (final PersonProfile profile in input) {
      if (seen.add(profile.id)) {
        output.add(profile);
      } else {
        output.add(profile.copyWith(name: '${profile.name} 2'));
      }
    }
    return output;
  }

  static double _clampScale(double value) =>
      value.clamp(minTextScale, maxTextScale).toDouble();

  String _newId() {
    final int stamp = DateTime.now().microsecondsSinceEpoch;
    int suffix = 0;
    while (_profiles.any((PersonProfile p) => p.id == 'p$stamp-$suffix')) {
      suffix++;
    }
    return 'p$stamp-$suffix';
  }

  /// Wake at the next clock boundary while dimming is enabled.
  ///
  /// A person who leaves the app open at 19:59 should see it dim at 20:00, and
  /// the reverse at 07:00. No timer is kept while the switch is off, because
  /// the clock has no effect then.
  void _scheduleBoundary() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
    if (_disposed || !_dimAfterDark) return;

    final DateTime now = _dynamicTheme.now;
    final Duration wait = _dynamicTheme.nextChangeAfter(now).difference(now);
    _boundaryTimer = Timer(wait.isNegative ? Duration.zero : wait, _onBoundary);
  }

  void _onBoundary() {
    _boundaryTimer = null;
    if (_disposed) return;
    // themeMode reads the clock on access, so a bare notification is enough for
    // every listener to rebuild with the new choice.
    notifyListeners();
    _scheduleBoundary();
  }

  @override
  void dispose() {
    _disposed = true;
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
    super.dispose();
  }
}
