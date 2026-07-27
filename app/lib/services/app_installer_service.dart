import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppInstallerService {
  static const String _packageName = 'com.digitalsaver.digital_saver';
  
  /// Check if app is installed
  static Future<bool> isAppInstalled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await Process.run(
        'pm',
        ['list', 'packages', _packageName],
      );
      return result.exitCode == 0 && 
             (result.stdout as String).contains(_packageName);
    } catch (e) {
      debugPrint('Error checking app installation: $e');
      return false;
    }
  }
  
  /// Uninstall the existing app
  static Future<bool> uninstallApp() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Request uninstall
      final result = await Process.run(
        'pm',
        ['uninstall', _packageName],
      );
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error uninstalling app: $e');
      return false;
    }
  }
  
  /// Download APK file
  static Future<String?> downloadApk(String url, {Function(double)? onProgress}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download APK: ${response.statusCode}');
      }
      
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
  
  /// Install APK file
  static Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Make the APK readable
      await Process.run('chmod', ['644', filePath]);
      
      // Install the APK
      final result = await Process.run(
        'pm',
        ['install', '-r', '-t', filePath],
      );
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }
  
  /// Smart install - checks for existing app, uninstalls if needed, then installs
  static Future<InstallResult> smartInstall(String downloadUrl) async {
    // Check if app is already installed
    final isInstalled = await isAppInstalled();
    
    if (isInstalled) {
      // Uninstall existing app first
      final uninstallSuccess = await uninstallApp();
      if (!uninstallSuccess) {
        return InstallResult(
          success: false,
          message: 'Failed to uninstall existing app. Please uninstall manually.',
          appWasInstalled: true,
        );
      }
    }
    
    // Download the new APK
    final apkPath = await downloadApk(downloadUrl);
    if (apkPath == null) {
      return InstallResult(
        success: false,
        message: 'Failed to download update.',
        appWasInstalled: isInstalled,
      );
    }
    
    // Install the new APK
    final installSuccess = await installApk(apkPath);
    if (!installSuccess) {
      return InstallResult(
        success: false,
        message: 'Failed to install update.',
        appWasInstalled: isInstalled,
      );
    }
    
    return InstallResult(
      success: true,
      message: isInstalled 
          ? 'App updated successfully!' 
          : 'App installed successfully!',
      appWasInstalled: isInstalled,
    );
  }
}

class InstallResult {
  final bool success;
  final String message;
  final bool appWasInstalled;
  
  InstallResult({
    required this.success,
    required this.message,
    required this.appWasInstalled,
  });
}
