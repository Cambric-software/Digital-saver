/// Digital Saver update capabilities and where releases actually live.
///
/// `downloadUrl` previously built URLs from filenames that have never existed
/// on any release - `digital_saver_windows_setup.exe`,
/// `digital_saver_linux_installer.run`, `digital_saver_android_v1.0.1-beta.apk`
/// - all pinned to v1.0.1-beta. Every one of those links 404s, so the app's
/// "download the update" path led nowhere.
///
/// The honest design: a specific package URL can only come from the release
/// assets GitHub actually published, which is what `ReleaseService` returns.
/// Until a check has run, the only correct thing to offer is the releases page
/// itself, which cannot go stale.
library;

import 'dart:io' show Platform;

import 'install_layout.dart';

/// Version reported by the running build.
///
/// Bump this together with `pubspec.yaml` and the git tag. A test verifies
/// they agree, so drift fails the build instead of silently mis-reporting the
/// version to the update checker.
class AppVersion {
  const AppVersion._();

  /// The released version.
  static const String current = '1.0.3';

  /// Build number, matching the `+N` suffix in pubspec.
  static const String buildNumber = '3';

  /// Marketing name.
  static const String displayName = 'Digital Saver';

  /// Publisher.
  static const String publisher = 'Cambric Software';

  /// Releases repository.
  static const String repository = 'Cambric-software/Digital-saver';

  /// Whether this build is a pre-release.
  static bool get isPreRelease => true;

  /// Human-readable build, e.g. `1.0.3-beta`.
  static String get display => '$current-beta';

  /// Release tag for this build.
  static String get tag => 'v$display';

  /// Where releases are listed.
  ///
  /// This is a stable, real URL. Asset links are resolved from the release
  /// rather than guessed here.
  static String get releasesPage =>
      'https://github.com/$repository/releases/latest';

  /// Whether this platform can install an update without help.
  ///
  /// Android cannot: the system installer requires a tap from the person, and
  /// the old `pm install` path had no shell permission, so it never worked on a
  /// stock device. Desktop can, but only when the app was installed with the
  /// setup executable and therefore has the versioned layout that makes a
  /// self-update safe.
  static bool get supportsAutoUpdate {
    if (Platform.isAndroid) return false;
    return InstallLayout.detect().isVersioned;
  }

  /// Why auto-install is unavailable, for display in the UI.
  static String get autoUpdateUnavailableReason {
    if (Platform.isAndroid) {
      return 'Android updates are installed by the system. Download the APK '
          'and open it - your data is preserved.';
    }
    return 'This copy was not installed with the setup executable, so it '
        'cannot update itself. Download and run the installer again.';
  }
}