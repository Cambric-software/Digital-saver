import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppThemeMode { light, dark, blue, purple, green, gradient }

class ThemeService extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.light;
  
  AppThemeMode get themeModeType => _themeMode;
  
  ThemeMode get themeMode {
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
      {'mode': AppThemeMode.gradient, 'name': 'Gradient Blue', 'icon': Icons.gradient, 'color': const Color(0xFF2563EB), 'watchTheme': 0},
      {'mode': AppThemeMode.blue, 'name': 'Ocean Blue', 'icon': Icons.water, 'color': const Color(0xFF0EA5E9), 'watchTheme': 1},
      {'mode': AppThemeMode.purple, 'name': 'Royal Purple', 'icon': Icons.auto_awesome, 'color': const Color(0xFF7C3AED), 'watchTheme': 2},
      {'mode': AppThemeMode.green, 'name': 'Nature Green', 'icon': Icons.eco, 'color': const Color(0xFF22C55E), 'watchTheme': 0},
      {'mode': AppThemeMode.light, 'name': 'Clean White', 'icon': Icons.wb_sunny, 'color': Colors.blueGrey, 'watchTheme': 1},
      {'mode': AppThemeMode.dark, 'name': 'Night Dark', 'icon': Icons.dark_mode, 'color': const Color(0xFF64748B), 'watchTheme': 3},
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
