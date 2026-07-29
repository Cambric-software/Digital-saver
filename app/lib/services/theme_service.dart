import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, blue, purple, green, gradient }

class ThemeService extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.gradient;
  
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

  ThemeData getLightTheme() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return _buildTheme(Colors.blueGrey, Brightness.light);
      case AppThemeMode.blue:
        return _buildTheme(const Color(0xFF2563EB), Brightness.light);
      case AppThemeMode.purple:
        return _buildTheme(const Color(0xFF7C3AED), Brightness.light);
      case AppThemeMode.green:
        return _buildTheme(const Color(0xFF22C55E), Brightness.light);
      case AppThemeMode.gradient:
      case AppThemeMode.dark:
        return _buildTheme(const Color(0xFF2563EB), Brightness.light);
    }
  }

  ThemeData getDarkTheme() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return _buildTheme(Colors.blueGrey, Brightness.dark);
      case AppThemeMode.blue:
        return _buildTheme(const Color(0xFF2563EB), Brightness.dark);
      case AppThemeMode.purple:
        return _buildTheme(const Color(0xFF7C3AED), Brightness.dark);
      case AppThemeMode.green:
        return _buildTheme(const Color(0xFF22C55E), Brightness.dark);
      case AppThemeMode.gradient:
      case AppThemeMode.dark:
        return _buildTheme(const Color(0xFF2563EB), Brightness.dark);
    }
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        surface: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E3A5F),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        indicatorColor: seedColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: seedColor),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

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
      {'mode': AppThemeMode.gradient, 'name': 'Gradient Blue', 'icon': Icons.gradient, 'color': const Color(0xFF2563EB)},
      {'mode': AppThemeMode.blue, 'name': 'Ocean Blue', 'icon': Icons.water, 'color': const Color(0xFF0EA5E9)},
      {'mode': AppThemeMode.purple, 'name': 'Royal Purple', 'icon': Icons.auto_awesome, 'color': const Color(0xFF7C3AED)},
      {'mode': AppThemeMode.green, 'name': 'Nature Green', 'icon': Icons.eco, 'color': const Color(0xFF22C55E)},
      {'mode': AppThemeMode.light, 'name': 'Clean White', 'icon': Icons.wb_sunny, 'color': Colors.blueGrey},
      {'mode': AppThemeMode.dark, 'name': 'Night Dark', 'icon': Icons.dark_mode, 'color': const Color(0xFF64748B)},
    ];
  }
}
