import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UpdateService {
  static const String _currentVersion = 'v1.0.0-beta-44';
  static const String _latestReleaseUrl = 'https://api.github.com/repos/Cambric-software/Digital-saver/releases/latest';
  static const String _githubReleasesUrl = 'https://github.com/Cambric-software/Digital-saver/releases';

  String get currentVersion => _currentVersion;

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      // Check GitHub API for latest release
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
              downloadUrl: data['android_url'], windowsDownloadUrl: data['windows_url'],
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
      final androidMatch = RegExp(r'"name":\s*"digital_saver_android_([^"]+\.apk)"').firstMatch(body);
      final windowsMatch = RegExp(r'"name":\s*"digital_saver_windows_([^"]+\.zip)"').firstMatch(body);
      
      if (tagMatch != null) {
        final tag = tagMatch.group(1) ?? '';
        String? androidUrl;
        String? windowsUrl;
        if (androidMatch != null) {
          final apkName = androidMatch.group(1) ?? '';
          if (apkName.isNotEmpty) {
            androidUrl = 'https://github.com/Cambric-software/Digital-saver/releases/download/$tag/$apkName';
          }
        }
        if (windowsMatch != null) {
          final zipName = windowsMatch.group(1) ?? '';
          if (zipName.isNotEmpty) {
            windowsUrl = 'https://github.com/Cambric-software/Digital-saver/releases/download/$tag/$zipName';
          }
        }
        return {
          'tag_name': tag,
          'body': bodyMatch?.group(1) ?? '',
          'android_url': androidUrl ?? '',
          'windows_url': windowsUrl ?? '',
        };
      }
    } catch (_) {}
    return null;
  }

  int _parseVersion(String version) {
    // Extract version numbers: v1.0.0-beta-18 -> 100018
    final match = RegExp(r'v?(\d+)\.(\d+)\.(\d+)(?:-beta-(\d+))?').firstMatch(version);
    if (match != null) {
      final majorStr = match.group(1) ?? '0';
      final minorStr = match.group(2) ?? '0';
      final patchStr = match.group(3) ?? '0';
      final major = int.tryParse(majorStr) ?? 0;
      final minor = int.tryParse(minorStr) ?? 0;
      final patch = int.tryParse(patchStr) ?? 0;
      final beta = int.tryParse(match.group(4) ?? '0') ?? 0;
      return major * 10000 + minor * 100 + patch + beta;
    }
    return 0;
  }
}

class UpdateCheckResult {
  final bool hasUpdate;
  final String? newVersion;
  final String? downloadUrl;       // Android APK URL
  final String? windowsDownloadUrl; // Windows ZIP URL
  final String? releaseNotes;
  final String? error;

  UpdateCheckResult({
    required this.hasUpdate,
    this.newVersion,
    this.downloadUrl,
    this.windowsDownloadUrl,
    this.releaseNotes,
    this.error,
  });
}
