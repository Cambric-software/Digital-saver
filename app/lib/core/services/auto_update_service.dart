/// Watches the published releases and, when asked, applies one safely.
///
/// The old file had three problems that all pointed the same way: it claimed
/// more than it had done. It pointed "download" at invented filenames that
/// 404'd, downloaded an APK and then called `pm install` as though a normal
/// app could install silently, and reported "App Updated!" whether or not the
/// system had accepted anything.
///
/// This version separates checking from applying. The release feed is decoded
/// as JSON, the package for the current platform is selected from the assets
/// GitHub actually published, and its SHA-256 is read from the asset `digest`
/// or its `.sha256` sidecar. Applying is delegated to [PackageInstaller], which
/// refuses a package without a published hash, deletes one that does not match,
/// and distinguishes a completed desktop install from an Android hand-off that
/// the person still has to confirm.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_installer_service.dart';
import 'app_version.dart';
import 'release_assets.dart';

export 'app_version.dart';

/// A release, plus the package this platform would use if it can be verified.
class UpdateInfo {
  /// Create a release description.
  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseDate,
    required this.isNewer,
    this.asset,
  });

  /// Version from the release tag, without a leading `v`.
  final String version;

  /// Direct package URL when one was published, otherwise the releases page.
  final String downloadUrl;

  /// Release notes as published.
  final String releaseNotes;

  /// Publication time.
  final DateTime releaseDate;

  /// Whether this release is newer than the running build.
  final bool isNewer;

  /// The matching package, or null when no asset fits this platform.
  final ReleaseAsset? asset;

  /// Whether a package exists and carries a published SHA-256.
  bool get canVerify => asset?.hasChecksum ?? false;
}

/// Checks for releases and applies a verified package on request.
class AutoUpdateService extends ChangeNotifier {
  /// Whether the network check runs at all.
  static const bool networkUpdateChecksEnabled = true;

  /// Create the service.
  ///
  /// [installer] exists so a test can drive the install states without a
  /// network or a real platform dialog.
  AutoUpdateService({PackageInstaller? installer})
      : _installer = installer ?? PackageInstaller() {
    _initNotifications();
  }

  final PackageInstaller _installer;

  UpdateInfo? _latestUpdate;
  bool _isChecking = false;
  bool _updateAvailable = false;
  String? _error;
  DateTime? _lastChecked;

  bool _isAutoUpdating = false;
  double _downloadProgress = 0.0;
  String? _autoUpdateMessage;
  String? _autoUpdateError;
  bool _manualInstallNeeded = false;

  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  /// The release read by the last successful check, if any.
  UpdateInfo? get latestUpdate => _latestUpdate;

  /// Whether a check is in progress.
  bool get isChecking => _isChecking;

  /// Whether the last check found a newer release.
  bool get updateAvailable => _updateAvailable;

  /// Why the last check failed, if it did.
  String? get error => _error;

  /// When the last successful check finished.
  DateTime? get lastChecked => _lastChecked;

  /// Whether a verified package is being downloaded or applied.
  bool get isAutoUpdating => _isAutoUpdating;

  /// Download progress from 0 to 1, or 0 when nothing is downloading.
  double get downloadProgress => _downloadProgress;

  /// What the last install attempt actually did, in its own words.
  String? get autoUpdateMessage => _autoUpdateMessage;

  /// Why the last install attempt failed, if it did.
  String? get autoUpdateError => _autoUpdateError;

  /// Whether the UI should offer the releases page because automatic install
  /// could not finish here.
  bool get needsManualInstall => _updateAvailable && _manualInstallNeeded;

  Future<void> _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin?.initialize(initSettings);
  }

  /// Read the newest release and remember the package for this platform.
  Future<void> checkForUpdates() async {
    if (!networkUpdateChecksEnabled || _isChecking) return;

    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final http.Response response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/'
          '${AppVersion.repository}/releases/latest',
        ),
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _error = 'The release feed answered ${response.statusCode}.';
        return;
      }

      final Object? decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _error = 'The release feed was not a JSON object.';
        return;
      }

      final String latestVersion =
          decoded['tag_name']?.toString().replaceFirst('v', '') ?? '0.0.0';
      final String releaseNotes =
          decoded['body']?.toString() ?? 'No release notes were published.';
      final DateTime releaseDate =
          DateTime.tryParse(decoded['published_at']?.toString() ?? '') ??
              DateTime.now();

      final bool isNewer =
          _compareVersions(latestVersion, AppVersion.current) > 0;

      final List<dynamic>? rawAssets =
          decoded['assets'] is List ? decoded['assets'] as List<dynamic> : null;
      final ReleaseAsset? asset = await _selectAsset(rawAssets);

      _latestUpdate = UpdateInfo(
        version: latestVersion,
        downloadUrl: asset?.url ?? AppVersion.releasesPage,
        releaseNotes: releaseNotes,
        releaseDate: releaseDate,
        isNewer: isNewer,
        asset: asset,
      );
      _updateAvailable = isNewer;
      _lastChecked = DateTime.now();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_update_check',
        _lastChecked!.toIso8601String(),
      );

      // Automatic application only happens where it can genuinely complete:
      // a versioned desktop install with a verifiable package. Android is
      // offered the verified package through the system installer instead.
      if (isNewer &&
          _latestUpdate!.canVerify &&
          AppVersion.supportsAutoUpdate) {
        unawaited(installUpdate());
      }
    } catch (error) {
      _error = 'The update check failed: $error';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Download, verify and apply the package for the release that was found.
  ///
  /// Returns the installer's outcome, or null when there is nothing to install
  /// or an install is already running. The service never invents success: the
  /// message comes from [PackageInstaller] and says whether a desktop install
  /// completed or whether Android was merely handed a verified file.
  Future<InstallOutcome?> installUpdate() async {
    if (_isAutoUpdating) return null;

    final UpdateInfo? latest = _latestUpdate;
    if (latest == null) return null;

    final ReleaseAsset? asset = latest.asset;
    if (asset == null) {
      _autoUpdateError = 'no_package';
      _autoUpdateMessage =
          'The release did not publish a package for this platform, so '
          'nothing was downloaded.';
      _manualInstallNeeded = true;
      notifyListeners();
      return null;
    }

    if (!asset.hasChecksum) {
      _autoUpdateError = 'no_checksum';
      _autoUpdateMessage =
          'The release did not publish a SHA-256 for ${asset.name}, so it was '
          'not downloaded. An update that cannot be verified is not applied.';
      _manualInstallNeeded = true;
      notifyListeners();
      return null;
    }

    _isAutoUpdating = true;
    _downloadProgress = 0;
    _autoUpdateMessage = null;
    _autoUpdateError = null;
    _manualInstallNeeded = false;
    notifyListeners();

    try {
      final InstallOutcome outcome = await _installer.install(
        version: latest.version,
        asset: asset,
        onProgress: (int received, int total) {
          if (total <= 0) return;
          final double progress = (received / total).clamp(0.0, 1.0);
          if ((progress - _downloadProgress).abs() < 0.01) return;
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      _autoUpdateMessage = outcome.message;

      switch (outcome.status) {
        case InstallStatus.installed:
          _downloadProgress = 1;
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_auto_update_version',
            outcome.version ?? latest.version,
          );
          await _showUpdateNotification(
            title: 'Update verified and activated',
            body: 'Restart Digital Saver to run version '
                '${outcome.version ?? latest.version}.',
          );
        case InstallStatus.handedOff:
          // The system installer is open; only the person can complete it.
          _downloadProgress = 1;
        case InstallStatus.failed:
          _autoUpdateError = 'install_failed';
          _manualInstallNeeded = outcome.needsUserAction;
      }

      return outcome;
    } catch (error) {
      _autoUpdateError = 'install_failed';
      _autoUpdateMessage = 'The update could not be applied: $error';
      _manualInstallNeeded = true;
      return null;
    } finally {
      _isAutoUpdating = false;
      notifyListeners();
    }
  }

  /// Open the package directly when known, otherwise the releases page.
  Future<void> openDownloadPage() async {
    final String url = _latestUpdate?.downloadUrl ?? AppVersion.releasesPage;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Read the SHA-256 from a GitHub `digest` value (`sha256:<hex>`).
  ///
  /// Public so the accepted form is pinned by a test rather than inferred.
  static String? parseDigest(Object? raw) {
    if (raw is! String) return null;
    final String value = raw.trim().toLowerCase();
    const String prefix = 'sha256:';
    final String candidate =
        value.startsWith(prefix) ? value.substring(prefix.length) : value;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(candidate)) return null;
    return candidate;
  }

  /// Pick the matching asset and attach a checksum from the release payload.
  ///
  /// GitHub publishes the digest inline on newer releases and as a `.sha256`
  /// sidecar on older ones. Both are read here; if neither exists the asset is
  /// returned without a checksum and will be refused at install time.
  Future<ReleaseAsset?> _selectAsset(List<dynamic>? rawAssets) async {
    if (rawAssets == null) return null;

    final List<ReleaseAsset> parsed = ReleaseAsset.parseAll(rawAssets);
    final ReleaseAsset? selected = ReleaseAsset.forCurrentPlatform(parsed);
    if (selected == null || selected.url.isEmpty) return null;

    String? checksum;
    String? sidecarUrl;
    for (final dynamic entry in rawAssets) {
      if (entry is! Map) continue;
      final String name = (entry['name'] ?? '').toString();
      if (name == selected.name) {
        checksum = parseDigest(entry['digest']);
      } else if (name == '${selected.name}.sha256') {
        sidecarUrl = (entry['browser_download_url'] ?? '').toString();
      }
    }

    if (checksum == null && sidecarUrl != null && sidecarUrl.isNotEmpty) {
      checksum = await _readSidecar(sidecarUrl);
    }

    return ReleaseAsset(
      name: selected.name,
      url: selected.url,
      sizeBytes: selected.sizeBytes,
      checksum: checksum,
    );
  }

  Future<String?> _readSidecar(String url) async {
    try {
      final http.Response response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return ReleaseAsset.parseChecksum(response.body);
    } catch (_) {
      return null;
    }
  }

  /// Compare dotted versions, treating a pre-release as older than the stable
  /// build with the same numbers.
  static int _compareVersions(String a, String b) {
    final List<String> aParts = a.split('-');
    final List<String> bParts = b.split('-');
    final List<int> aNumbers = _numbers(aParts.first);
    final List<int> bNumbers = _numbers(bParts.first);

    for (var i = 0; i < 3; i++) {
      final int left = i < aNumbers.length ? aNumbers[i] : 0;
      final int right = i < bNumbers.length ? bNumbers[i] : 0;
      if (left != right) return left.compareTo(right);
    }

    final bool aPre = aParts.length > 1;
    final bool bPre = bParts.length > 1;
    if (aPre == bPre) return a.compareTo(b);
    return aPre ? -1 : 1;
  }

  static List<int> _numbers(String version) =>
      version.split('.').map((String part) => int.tryParse(part) ?? 0).toList();

  Future<void> _showUpdateNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin?.show(0, title, body, details);
  }

  /// Load the stored time of the last check.
  Future<void> loadLastChecked() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastCheckedStr = prefs.getString('last_update_check');
    if (lastCheckedStr != null) {
      _lastChecked = DateTime.tryParse(lastCheckedStr);
    }
  }

  /// Whether enough time has passed to prompt again.
  bool shouldPromptUpdate() {
    final DateTime? last = _lastChecked;
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= 24;
  }

  /// Dismiss the prompt for a week.
  Future<void> dismissUpdate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'update_dismissed_until',
      DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    );
  }

  /// Dismissal is not wired into the shell yet; a prompt is still shown.
  bool get isUpdateDismissed => false;
}
