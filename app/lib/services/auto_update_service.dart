import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Current app version - update this with each release
class AppVersion {
  static const String current = '3.1.2';
  static const String buildNumber = '12';
  
  static String get downloadUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://github.com/Cambric-software/Digital-saver/releases/download/v$current/digital_saver_android_v$current.apk';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'https://github.com/Cambric-software/Digital-saver/releases/download/v$current/digital_saver_windows_v$current.zip';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'https://github.com/Cambric-software/Digital-saver/releases/download/v$current/digital_saver_linux_v$current.tar.gz';
    }
    return 'https://cambric-software.github.io/Digital-saver/';
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime releaseDate;
  final bool isNewer;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseDate,
    required this.isNewer,
  });
}

class AutoUpdateService extends ChangeNotifier {
  UpdateInfo? _latestUpdate;
  bool _isChecking = false;
  bool _updateAvailable = false;
  String? _error;
  DateTime? _lastChecked;

  UpdateInfo? get latestUpdate => _latestUpdate;
  bool get isChecking => _isChecking;
  bool get updateAvailable => _updateAvailable;
  String? get error => _error;
  DateTime? get lastChecked => _lastChecked;

  Future<void> checkForUpdates() async {
    if (_isChecking) return;
    
    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      // Check GitHub releases API for latest version
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/Cambric-software/Digital-saver/releases/latest'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name']?.toString().replaceFirst('v', '') ?? '0.0.0';
        final releaseNotes = data['body']?.toString() ?? 'New update available!';
        final releaseDateStr = data['published_at']?.toString();
        final releaseDate = releaseDateStr != null 
            ? DateTime.tryParse(releaseDateStr) ?? DateTime.now()
            : DateTime.now();

        // Parse version numbers for comparison
        final currentParts = AppVersion.current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
        final latestParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

        bool isNewer = false;
        for (int i = 0; i < 3; i++) {
          final curr = i < currentParts.length ? currentParts[i] : 0;
          final lat = i < latestParts.length ? latestParts[i] : 0;
          if (lat > curr) {
            isNewer = true;
            break;
          } else if (lat < curr) {
            break;
          }
        }

        // Get download URL for current platform
        String downloadUrl = AppVersion.downloadUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name']?.toString().toLowerCase() ?? '';
          if (defaultTargetPlatform == TargetPlatform.android && name.contains('android')) {
            downloadUrl = asset['browser_download_url']?.toString() ?? downloadUrl;
            break;
          } else if (defaultTargetPlatform == TargetPlatform.windows && name.contains('windows')) {
            downloadUrl = asset['browser_download_url']?.toString() ?? downloadUrl;
            break;
          } else if (defaultTargetPlatform == TargetPlatform.linux && name.contains('linux')) {
            downloadUrl = asset['browser_download_url']?.toString() ?? downloadUrl;
            break;
          }
        }

        _latestUpdate = UpdateInfo(
          version: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          releaseDate: releaseDate,
          isNewer: isNewer,
        );

        _updateAvailable = isNewer;
        _lastChecked = DateTime.now();

        // Save last checked time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_update_check', _lastChecked.toIso8601String());
      } else {
        _error = 'Failed to check for updates';
      }
    } catch (e) {
      _error = 'Error checking updates: $e';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> loadLastChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckedStr = prefs.getString('last_update_check');
    if (lastCheckedStr != null) {
      _lastChecked = DateTime.tryParse(lastCheckedStr);
    }
  }

  // Check if we should show update prompt (don't ask too often)
  bool shouldPromptUpdate() {
    final lastChecked = _lastChecked;
    if (lastChecked == null) return true;
    final hoursSinceCheck = DateTime.now().difference(lastChecked).inHours;
    return hoursSinceCheck >= 24; // Only prompt once per day
  }

  // Dismiss update notification temporarily
  Future<void> dismissUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('update_dismissed_until', 
        DateTime.now().add(const Duration(days: 7)).toIso8601String());
  }

  bool get isUpdateDismissed {
    // Check if user dismissed update
    return false; // For now, always show
  }
}
