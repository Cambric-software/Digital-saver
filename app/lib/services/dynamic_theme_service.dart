import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum TimeOfDay { morning, afternoon, evening, night }
enum WeatherCondition { sunny, cloudy, rainy, snowy, stormy, unknown }

class DynamicThemeConfig {
  final TimeOfDay timeOfDay;
  final WeatherCondition weather;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Brightness brightness;
  final List<Color>? gradientColors;
  final IconData weatherIcon;
  final String greeting;

  DynamicThemeConfig({
    required this.timeOfDay,
    required this.weather,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.brightness,
    this.gradientColors,
    required this.weatherIcon,
    required this.greeting,
  });
}

class DynamicThemeService extends ChangeNotifier {
  TimeOfDay _currentTimeOfDay = TimeOfDay.morning;
  WeatherCondition _currentWeather = WeatherCondition.sunny;
  bool _autoMode = true;
  bool _weatherEnabled = true;
  Timer? _timeCheckTimer;
  
  // Default location for weather (can be customized)
  String _location = 'auto'; // or specific city
  
  TimeOfDay get currentTimeOfDay => _currentTimeOfDay;
  WeatherCondition get currentWeather => _currentWeather;
  bool get autoMode => _autoMode;
  bool get weatherEnabled => _weatherEnabled;

  DynamicThemeService() {
    _updateTimeOfDay();
    // Check time every minute
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateTimeOfDay();
    });
  }

  void _updateTimeOfDay() {
    final hour = DateTime.now().hour;
    TimeOfDay newTimeOfDay;
    
    if (hour >= 5 && hour < 12) {
      newTimeOfDay = TimeOfDay.morning;
    } else if (hour >= 12 && hour < 17) {
      newTimeOfDay = TimeOfDay.afternoon;
    } else if (hour >= 17 && hour < 21) {
      newTimeOfDay = TimeOfDay.evening;
    } else {
      newTimeOfDay = TimeOfDay.night;
    }
    
    if (newTimeOfDay != _currentTimeOfDay) {
      _currentTimeOfDay = newTimeOfDay;
      notifyListeners();
    }
  }

  Future<void> fetchWeather() async {
    if (!_weatherEnabled || _location == 'auto') return;
    
    try {
      // Using OpenWeatherMap free API - user would need to add their own API key
      // For now, we'll simulate weather or use IP-based location
      // This is a placeholder - in production, you'd use a real weather API
      _currentWeather = _inferWeatherFromTime();
      notifyListeners();
    } catch (e) {
      // Silently fail, use time-based weather inference
      _currentWeather = _inferWeatherFromTime();
    }
  }

  WeatherCondition _inferWeatherFromTime() {
    // Simple heuristic based on time and season
    final month = DateTime.now().month;
    final hour = DateTime.now().hour;
    
    // Winter months (Dec-Feb) might have snow
    if (month >= 12 || month <= 2) {
      return WeatherCondition.snowy;
    }
    // Rainy season (Nov-Mar)
    if (month >= 11 || month <= 3) {
      return WeatherCondition.rainy;
    }
    // Summer - sunny
    return WeatherCondition.sunny;
  }

  void setWeatherCondition(WeatherCondition condition) {
    _currentWeather = condition;
    _weatherEnabled = false; // Manual override
    notifyListeners();
  }

  void setAutoMode(bool enabled) {
    _autoMode = enabled;
    if (enabled) {
      _updateTimeOfDay();
      fetchWeather();
    }
    notifyListeners();
  }

  void enableWeather(bool enabled) {
    _weatherEnabled = enabled;
    if (enabled) {
      fetchWeather();
    }
    notifyListeners();
  }

  DynamicThemeConfig getDynamicTheme() {
    return _getThemeForConditions(_currentTimeOfDay, _currentWeather);
  }

  DynamicThemeConfig _getThemeForConditions(TimeOfDay time, WeatherCondition weather) {
    switch (time) {
      case TimeOfDay.morning:
        return _getMorningTheme(weather);
      case TimeOfDay.afternoon:
        return _getAfternoonTheme(weather);
      case TimeOfDay.evening:
        return _getEveningTheme(weather);
      case TimeOfDay.night:
        return _getNightTheme(weather);
    }
  }

  DynamicThemeConfig _getMorningTheme(WeatherCondition weather) {
    if (weather == WeatherCondition.rainy) {
      return DynamicThemeConfig(
        timeOfDay: TimeOfDay.morning,
        weather: weather,
        primaryColor: const Color(0xFF5B8DEF),
        secondaryColor: const Color(0xFF7BA3F5),
        backgroundColor: const Color(0xFFF0F4F8),
        surfaceColor: Colors.white,
        textColor: const Color(0xFF1E3A5F),
        brightness: Brightness.light,
        gradientColors: [const Color(0xFF87CEEB), const Color(0xFF5B8DEF)],
        weatherIcon: Icons.water_drop,
        greeting: 'Good Morning! ☀️',
      );
    }
    return DynamicThemeConfig(
      timeOfDay: TimeOfDay.morning,
      weather: weather,
      primaryColor: const Color(0xFFFFB347),
      secondaryColor: const Color(0xFFFF6B6B),
      backgroundColor: const Color(0xFFFFF8E7),
      surfaceColor: Colors.white,
      textColor: const Color(0xFF5D4E37),
      brightness: Brightness.light,
      gradientColors: [const Color(0xFFFFE5B4), const Color(0xFFFFDAB9)],
      weatherIcon: Icons.wb_sunny,
      greeting: 'Good Morning! ☀️',
    );
  }

  DynamicThemeConfig _getAfternoonTheme(WeatherCondition weather) {
    if (weather == WeatherCondition.rainy) {
      return DynamicThemeConfig(
        timeOfDay: TimeOfDay.afternoon,
        weather: weather,
        primaryColor: const Color(0xFF4A90D9),
        secondaryColor: const Color(0xFF6BA3E0),
        backgroundColor: const Color(0xFFE8EEF4),
        surfaceColor: Colors.white,
        textColor: const Color(0xFF2C3E50),
        brightness: Brightness.light,
        gradientColors: [const Color(0xFFB0C4DE), const Color(0xFF708090)],
        weatherIcon: Icons.cloud,
        greeting: 'Good Afternoon! 🌤️',
      );
    }
    return DynamicThemeConfig(
      timeOfDay: TimeOfDay.afternoon,
      weather: weather,
      primaryColor: const Color(0xFF4FC3F7),
      secondaryColor: const Color(0xFF29B6F6),
      backgroundColor: const Color(0xFFE3F2FD),
      surfaceColor: Colors.white,
      textColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
      gradientColors: [const Color(0xFF87CEEB), const Color(0xFF4FC3F7)],
      weatherIcon: Icons.wb_sunny,
      greeting: 'Good Afternoon! 🌞',
    );
  }

  DynamicThemeConfig _getEveningTheme(WeatherCondition weather) {
    if (weather == WeatherCondition.rainy) {
      return DynamicThemeConfig(
        timeOfDay: TimeOfDay.evening,
        weather: weather,
        primaryColor: const Color(0xFF6B5B95),
        secondaryColor: const Color(0xFF8B7BB5),
        backgroundColor: const Color(0xFF2C2C3A),
        surfaceColor: const Color(0xFF3A3A4A),
        textColor: const Color(0xFFE8E8E8),
        brightness: Brightness.dark,
        gradientColors: [const Color(0xFF2C3E50), const Color(0xFF4A4A6A)],
        weatherIcon: Icons.cloud,
        greeting: 'Good Evening! 🌙',
      );
    }
    return DynamicThemeConfig(
      timeOfDay: TimeOfDay.evening,
      weather: weather,
      primaryColor: const Color(0xFFFF7F50),
      secondaryColor: const Color(0xFFFF6347),
      backgroundColor: const Color(0xFF2D1B4E),
      surfaceColor: const Color(0xFF3D2B5E),
      textColor: const Color(0xFFF8F8FF),
      brightness: Brightness.dark,
      gradientColors: [const Color(0xFF4A148C), const Color(0xFFFF5722)],
      weatherIcon: Icons.nights_stay,
      greeting: 'Good Evening! 🌅',
    );
  }

  DynamicThemeConfig _getNightTheme(WeatherCondition weather) {
    if (weather == WeatherCondition.rainy) {
      return DynamicThemeConfig(
        timeOfDay: TimeOfDay.night,
        weather: weather,
        primaryColor: const Color(0xFF5C6BC0),
        secondaryColor: const Color(0xFF7986CB),
        backgroundColor: const Color(0xFF0D1117),
        surfaceColor: const Color(0xFF161B22),
        textColor: const Color(0xFFB0B0B0),
        brightness: Brightness.dark,
        gradientColors: [const Color(0xFF0D1117), const Color(0xFF1A1A2E)],
        weatherIcon: Icons.thunderstorm,
        greeting: 'Good Night! 🌧️',
      );
    }
    if (weather == WeatherCondition.stormy) {
      return DynamicThemeConfig(
        timeOfDay: TimeOfDay.night,
        weather: weather,
        primaryColor: const Color(0xFF7E57C2),
        secondaryColor: const Color(0xFF9575CD),
        backgroundColor: const Color(0xFF0D0D1A),
        surfaceColor: const Color(0xFF1A1A2E),
        textColor: const Color(0xFFD0D0D0),
        brightness: Brightness.dark,
        gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF2E2E4A)],
        weatherIcon: Icons.flash_on,
        greeting: 'Stormy Night! ⛈️',
      );
    }
    return DynamicThemeConfig(
      timeOfDay: TimeOfDay.night,
      weather: weather,
      primaryColor: const Color(0xFF7C4DFF),
      secondaryColor: const Color(0xFFB388FF),
      backgroundColor: const Color(0xFF0D0D1A),
      surfaceColor: const Color(0xFF1A1A2E),
      textColor: const Color(0xFFE0E0E0),
      brightness: Brightness.dark,
      gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF2D1B69)],
      weatherIcon: Icons.star,
      greeting: 'Good Night! ✨',
    );
  }

  ThemeData getThemeData() {
    final config = getDynamicTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: config.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primaryColor,
        brightness: config.brightness,
        surface: config.surfaceColor,
      ),
      scaffoldBackgroundColor: config.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: config.backgroundColor,
        foregroundColor: config.textColor,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: config.surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: config.primaryColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: config.surfaceColor,
        indicatorColor: config.primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: config.primaryColor),
        ),
      ),
    );
  }

  String getGreeting() {
    return getDynamicTheme().greeting;
  }

  @override
  void dispose() {
    _timeCheckTimer?.cancel();
    super.dispose();
  }
}
