/// The app's theme choice, plus the one automatic rule the person can switch on.
///
/// Before this file had a partner, [ThemeService] only remembered one of six
/// palette names. The app could choose light or dark, but never changed by
/// itself, even though a whole unused service existed to guess the time of day
/// and then invent the weather.
///
/// "Dim after dark" is the honest version of that idea. It is off by default,
/// stored under one key in [StorageService], and when on it asks
/// [DynamicThemeService] whether the local clock is between 20:00 and 07:00.
/// If it is, the dark theme is used. No weather is fetched or made up, and the
/// switch does nothing at all until the person turns it on.
///
/// While the switch is on, one timer wakes at the next 07:00 or 20:00 so an app
/// left open changes with the clock instead of waiting for an unrelated rebuild.
/// The timer is cancelled when the switch is turned off and on [dispose].
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';
import 'dynamic_theme_service.dart';
import 'storage_service.dart';

enum AppThemeMode { light, dark, blue, purple, green, gradient }

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
    _ready =
        loadStoredPreference ? _restoreDimAfterDark() : Future<void>.value();
  }

  final DynamicThemeService _dynamicTheme;
  late final Future<void> _ready;

  AppThemeMode _themeMode = AppThemeMode.light;
  bool _dimAfterDark = StorageService.defaultDimAfterDark;
  Timer? _boundaryTimer;
  bool _disposed = false;

  /// Completes when the stored switch has been read.
  Future<void> get ready => _ready;

  AppThemeMode get themeModeType => _themeMode;

  /// Whether the person asked the app to use the dark theme after dark.
  bool get dimAfterDark => _dimAfterDark;

  /// What the local clock currently asks for.
  LightChoice get lightChoice => _dynamicTheme.currentChoice;

  /// Whether the dark theme is being applied because of the clock.
  bool get isDimmed => _dimAfterDark && lightChoice == LightChoice.dim;

  ThemeMode get themeMode {
    // The clock may only dim. It never overrides a person's chosen palette with
    // anything other than the dark theme, and only while the switch is on.
    if (isDimmed) return ThemeMode.dark;
    switch (_themeMode) {
      case AppThemeMode.light:
      case AppThemeMode.blue:
      case AppThemeMode.purple:
      case AppThemeMode.green:
      case AppThemeMode.gradient:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  void setTheme(AppThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
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

  Future<void> _restoreDimAfterDark() async {
    try {
      final bool stored = await StorageService.dimAfterDark();
      if (_disposed || stored == _dimAfterDark) return;
      _dimAfterDark = stored;
      _scheduleBoundary();
      notifyListeners();
    } catch (_) {
      // An unreadable preference means "use the default". It must not stop the
      // app from rendering its first frame.
    }
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

  ThemeData getLightTheme() => AppTheme.light;

  ThemeData getDarkTheme() => AppTheme.dark;

  String getThemeName() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.blue:
        return 'Blue';
      case AppThemeMode.purple:
        return 'Purple';
      case AppThemeMode.green:
        return 'Green';
      case AppThemeMode.gradient:
        return 'Gradient';
    }
  }

  IconData getThemeIcon() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Icons.wb_sunny;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.blue:
        return Icons.water;
      case AppThemeMode.purple:
        return Icons.auto_awesome;
      case AppThemeMode.green:
        return Icons.eco;
      case AppThemeMode.gradient:
        return Icons.gradient;
    }
  }

  List<Map<String, dynamic>> getAvailableThemes() {
    return [
      {
        'mode': AppThemeMode.gradient,
        'name': 'Gradient Blue',
        'icon': Icons.gradient,
        'color': const Color(0xFF2563EB),
        'watchTheme': 0
      },
      {
        'mode': AppThemeMode.blue,
        'name': 'Ocean Blue',
        'icon': Icons.water,
        'color': const Color(0xFF0EA5E9),
        'watchTheme': 1
      },
      {
        'mode': AppThemeMode.purple,
        'name': 'Royal Purple',
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF7C3AED),
        'watchTheme': 2
      },
      {
        'mode': AppThemeMode.green,
        'name': 'Nature Green',
        'icon': Icons.eco,
        'color': const Color(0xFF22C55E),
        'watchTheme': 0
      },
      {
        'mode': AppThemeMode.light,
        'name': 'Clean White',
        'icon': Icons.wb_sunny,
        'color': Colors.blueGrey,
        'watchTheme': 1
      },
      {
        'mode': AppThemeMode.dark,
        'name': 'Night Dark',
        'icon': Icons.dark_mode,
        'color': const Color(0xFF64748B),
        'watchTheme': 3
      },
    ];
  }

  // Get watch theme ID for current theme
  int getWatchThemeId() {
    final themes = getAvailableThemes();
    final index = AppThemeMode.values.indexOf(_themeMode);
    if (index >= 0 && index < themes.length) {
      return themes[index]['watchTheme'] as int;
    }
    return 0; // Default theme
  }

  // Get watch theme name
  String getWatchThemeName() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Inverted (Black on White)';
      case AppThemeMode.dark:
        return 'Night (Red Display)';
      case AppThemeMode.blue:
        return 'Inverted (Black on White)';
      case AppThemeMode.purple:
        return 'High Contrast';
      case AppThemeMode.green:
        return 'Default (White on Black)';
      case AppThemeMode.gradient:
        return 'Default (White on Black)';
    }
  }
}
