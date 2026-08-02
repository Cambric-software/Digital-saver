import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Current app version - update this with each release
class AppVersion {
  static const String current = '3.1.8';
  static const String buildNumber = '15';
  
  // Minimum version for auto-update (3.1.8+ supports silent auto-update)
  static const String autoUpdateMinVersion = '3.1.8';
  
  static bool get supportsAutoUpdate {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final minParts = autoUpdateMinVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      final curr = i < currentParts.length ? currentParts[i] : 0;
      final min = i < minParts.length ? minParts[i] : 0;
      if (curr > min) return true;
      if (curr < min) return false;
    }
    return true; // Equal to min version
  }
  
  static String get downloadUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://github.com/Cambric-software/Digital-saver/releases/download/v3.1.8/digital_saver_android_v3.1.8.apk';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'https://github.com/Cambric-software/Digital-saver/releases/download/v3.1.8/digital_saver_windows_v3.1.8.zip';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'https://github.com/Cambric-software/Digital-saver/releases/download/v3.1.8/digital_saver_linux_v3.1.8.tar.gz';
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
  
  // Auto-update state
  bool _isAutoUpdating = false;
  double _downloadProgress = 0.0;
  String? _autoUpdateError;
  
  // Notification plugin
  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  UpdateInfo? get latestUpdate => _latestUpdate;
  bool get isChecking => _isChecking;
  bool get updateAvailable => _updateAvailable;
  String? get error => _error;
  DateTime? get lastChecked => _lastChecked;
  bool get isAutoUpdating => _isAutoUpdating;
  double get downloadProgress => _downloadProgress;
  String? get autoUpdateError => _autoUpdateError;

  AutoUpdateService() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin?.initialize(initSettings);
  }

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
        
        // Safely get assets - handle null, missing, or non-list assets
        List<dynamic>? rawAssets = data['assets'];
        if (rawAssets is List) {
          for (final asset in rawAssets) {
            if (asset is! Map) continue;
            final name = (asset['name'] as String?)?.toLowerCase() ?? '';
            if (name.isEmpty) continue;
            
            final url = (asset['browser_download_url'] as String?) ?? '';
            if (url.isEmpty) continue;
            
            if (defaultTargetPlatform == TargetPlatform.android && name.contains('android')) {
              downloadUrl = url;
              break;
            } else if (defaultTargetPlatform == TargetPlatform.windows && name.contains('windows')) {
              downloadUrl = url;
              break;
            } else if (defaultTargetPlatform == TargetPlatform.linux && name.contains('linux')) {
              downloadUrl = url;
              break;
            }
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
        final now = DateTime.now();
        _lastChecked = now;

        // Save last checked time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_update_check', now.toIso8601String());
        
        // Auto-update if conditions are met
        if (isNewer && AppVersion.supportsAutoUpdate && Platform.isAndroid) {
          _startAutoUpdate();
        }
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

  Future<void> _startAutoUpdate() async {
    if (_isAutoUpdating || _latestUpdate == null) return;
    
    _isAutoUpdating = true;
    _downloadProgress = 0.0;
    _autoUpdateError = null;
    notifyListeners();
    
    try {
      final downloadUrl = _latestUpdate!.downloadUrl;
      final version = _latestUpdate!.version;
      
      // Download APK
      final apkPath = await _downloadApkSilent(downloadUrl);
      
      if (apkPath == null) {
        _autoUpdateError = 'Failed to download update';
        _isAutoUpdating = false;
        notifyListeners();
        return;
      }
      
      // Install APK
      final installed = await _installApkSilent(apkPath);
      
      if (installed) {
        // Show success notification
        await _showUpdateNotification(
          title: 'App Updated! 🎉',
          body: 'Your app has been updated to version $version',
        );
        
        // Save that we auto-updated
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_auto_update_version', version);
      } else {
        _autoUpdateError = 'Failed to install update';
      }
    } catch (e) {
      _autoUpdateError = 'Auto-update error: $e';
    } finally {
      _isAutoUpdating = false;
      notifyListeners();
    }
  }

  Future<String?> _downloadApkSilent(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(minutes: 5),
      );
      
      if (response.statusCode != 200) return null;
      
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/digital_saver_update.apk');
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return null;
    }
  }

  Future<bool> _installApkSilent(String filePath) async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Make APK readable
      await Process.run('chmod', ['644', filePath]);
      
      // Install APK with auto-accept
      final result = await Process.run(
        'pm',
        ['install', '-r', '-t', filePath],
      ).timeout(const Duration(minutes: 3));
      
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }

  Future<void> _showUpdateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin?.show(
      0,
      title,
      body,
      details,
    );
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
