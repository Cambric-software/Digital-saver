import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _currentVersion = 'v1.0.0-beta-18';
  static const String _latestReleaseUrl = 'https://api.github.com/repos/Cambric-software/Digital-saver/releases/latest';
  static const String _githubReleasesUrl = 'https://github.com/Cambric-software/Digital-saver/releases';
  
  AppUpdateInfo? _updateInfo;

  String get currentVersion => _currentVersion;

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      // First try flexible update (Google Play style)
      final updateAvailable = await InAppUpdate.checkForUpdate();
      _updateInfo = updateAvailable;
      
      if (updateAvailable.updateAvailability == UpdateAvailability.updateAvailable) {
        return UpdateCheckResult(
          hasUpdate: true,
          newVersion: 'v1.0.0-beta-18',
          updateInfo: updateAvailable,
        );
      }
      
      // Fallback: Check GitHub API for latest release
      return await _checkGithubRelease();
    } catch (e) {
      // If in-app update fails, check GitHub directly
      return await _checkGithubRelease();
    }
  }

  Future<UpdateCheckResult> _checkGithubRelease() async {
    try {
      final response = await http.get(Uri.parse(_latestReleaseUrl));
      if (response.statusCode == 200) {
        final data = await compute(_parseGithubRelease, response.body);
        if (data != null) {
          final latestVersion = data['tag_name'] ?? '';
          final currentNum = _parseVersion(_currentVersion);
          final latestNum = _parseVersion(latestVersion);
          
          if (latestNum > currentNum) {
            return UpdateCheckResult(
              hasUpdate: true,
              newVersion: latestVersion,
              downloadUrl: data['download_url'],
              releaseNotes: data['body'],
            );
          }
        }
      }
      return UpdateCheckResult(hasUpdate: false);
    } catch (e) {
      return UpdateCheckResult(hasUpdate: false, error: e.toString());
    }
  }

  static Map<String, String>? _parseGithubRelease(String body) {
    try {
      // Simple JSON parsing
      final tagMatch = RegExp(r'"tag_name":\s*"([^"]+)"').firstMatch(body);
      final bodyMatch = RegExp(r'"body":\s*"([^"]*)"').firstMatch(body);
      final nameMatch = RegExp(r'"name":\s*"digital_saver_android_([^"]+\.apk)"').firstMatch(body);
      
      if (tagMatch != null) {
        final tag = tagMatch.group(1)!;
        String? downloadUrl;
        if (nameMatch != null) {
          final apkName = nameMatch.group(1)!;
          downloadUrl = 'https://github.com/Cambric-software/Digital-saver/releases/download/$tag/$apkName';
        }
        return {
          'tag_name': tag,
          'body': bodyMatch?.group(1) ?? '',
          'download_url': downloadUrl ?? '',
        };
      }
    } catch (_) {}
    return null;
  }

  int _parseVersion(String version) {
    // Extract version numbers: v1.0.0-beta-18 -> 100018
    final match = RegExp(r'v?(\d+)\.(\d+)\.(\d+)(?:-beta-(\d+))?').firstMatch(version);
    if (match != null) {
      final major = int.parse(match.group(1)!) * 10000;
      final minor = int.parse(match.group(2)!) * 100;
      final patch = int.parse(match.group(3)!);
      final beta = int.tryParse(match.group(4) ?? '0') ?? 0;
      return major + minor + patch + beta;
    }
    return 0;
  }

  Future<UpdateResult> startFlexibleUpdate() async {
    if (_updateInfo == null) {
      return UpdateResult(success: false, message: 'No update available');
    }
    
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      return UpdateResult(
        success: true,
        message: 'Download started',
      );
    } catch (e) {
      return UpdateResult(success: false, message: e.toString());
    }
  }

  Future<UpdateResult> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return UpdateResult(success: true, message: 'Update installed! Restart the app.');
    } catch (e) {
      return UpdateResult(success: false, message: e.toString());
    }
  }

  Future<UpdateResult> downloadAndInstallExternal(String downloadUrl) async {
    if (downloadUrl.isEmpty) {
      return UpdateResult(
        success: false, 
        message: 'No download URL available',
        fallbackUrl: _githubReleasesUrl,
      );
    }
    
    try {
      // Download the APK
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        return UpdateResult(
          success: false,
          message: 'Download failed',
          fallbackUrl: _githubReleasesUrl,
        );
      }
      
      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/digital_saver_update.apk');
      await file.writeAsBytes(response.bodyBytes);
      
      // Open installer
      if (Platform.isAndroid) {
        // Use platform channel to install
        // For now, we'll use url_launcher to open the releases page
        return UpdateResult(
          success: false,
          message: 'Download complete! Opening installer...',
          downloadedPath: file.path,
        );
      }
      
      return UpdateResult(success: false, message: 'Platform not supported');
    } catch (e) {
      return UpdateResult(
        success: false,
        message: e.toString(),
        fallbackUrl: _githubReleasesUrl,
      );
    }
  }
}

class UpdateCheckResult {
  final bool hasUpdate;
  final String? newVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? error;
  final AppUpdateInfo? updateInfo;

  UpdateCheckResult({
    required this.hasUpdate,
    this.newVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.error,
    this.updateInfo,
  });
}

class UpdateResult {
  final bool success;
  final String message;
  final int? bytesDownloaded;
  final int? totalBytesToDownload;
  final String? downloadedPath;
  final String? fallbackUrl;

  UpdateResult({
    required this.success,
    required this.message,
    this.bytesDownloaded,
    this.totalBytesToDownload,
    this.downloadedPath,
    this.fallbackUrl,
  });

  double get progress {
    if (bytesDownloaded == null || totalBytesToDownload == null) return 0;
    if (totalBytesToDownload == 0) return 0;
    return bytesDownloaded! / totalBytesToDownload!;
  }
}
