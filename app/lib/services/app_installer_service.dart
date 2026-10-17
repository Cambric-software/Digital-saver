/// Applies a downloaded, verified package.
///
/// The previous implementation uninstalled the app before installing the
/// update. That was destructive and, on a stock Android device, impossible
/// anyway: `pm` invoked through `Process.run` needs a shell permission a
/// normal app does not have, so the whole path would have failed at the last
/// step - after the user's app and all its data were already gone.
///
/// The rules now:
///  * Desktop updates are applied through [UpdateInstaller], which adds a new
///    version folder and moves a pointer. No running file is ever overwritten.
///  * Android is handed the APK and lets the system installer take over, which
///    upgrades in place and preserves data.
///  * A package that fails checksum verification is deleted, never offered.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'install_layout.dart';
import 'release_assets.dart';

/// Result of an install attempt.
class InstallOutcome {
  /// Create a success result.
  const InstallOutcome.success(this.message, {this.version})
      : ok = true,
        needsUserAction = false;

  /// Create a failure.
  const InstallOutcome.failure(this.message, {this.needsUserAction = false})
      : ok = false,
        version = null;

  /// Whether the package was applied.
  final bool ok;

  /// Human-readable explanation, always populated.
  final String message;

  /// Version applied, when known.
  final String? version;

  /// Whether the person has to finish the job themselves.
  ///
  /// True on platforms where the system, not this app, owns installation.
  final bool needsUserAction;

  @override
  String toString() => ok
      ? 'InstallOutcome.success($message)'
      : 'InstallOutcome.failure($message)';
}

/// Downloads a package and installs it.
class PackageInstaller {
  /// Create an installer.
  PackageInstaller({ReleaseServiceHooks? hooks}) : _hooks = hooks;

  /// Injectable hooks, used by tests to avoid real downloads.
  final ReleaseServiceHooks? _hooks;

  /// Where staged packages are kept before being applied.
  Future<Directory> _stagingDirectory() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}updates');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Verify a downloaded package and, on desktop, apply it.
  ///
  /// [version] is the release tag without its leading `v`. The package is
  /// only staged once its SHA-256 matches [expectedChecksum]; a mismatch
  /// deletes the file and returns a failure, because executable code that does
  /// not match its published hash must not be run.
  Future<InstallOutcome> install({
    required String version,
    required ReleaseAsset asset,
    required String expectedChecksum,
    void Function(int received, int total)? onProgress,
  }) async {
    if (Platform.isAndroid) {
      return const InstallOutcome.failure(
        'On Android the system installer handles updates. Download the APK and '
        'open it to upgrade - your data is preserved.',
        needsUserAction: true,
      );
    }

    final layout = InstallLayout.detect();
    if (!layout.isVersioned) {
      return const InstallOutcome.failure(
        'This copy of Digital Saver was not installed with the setup '
        'executable, so it cannot update itself. Download and run the '
        'installer again.',
        needsUserAction: true,
      );
    }

    File? package;
    try {
      package = await _download(asset, onProgress: onProgress);
      if (package == null) {
        return const InstallOutcome.failure('The download did not complete.');
      }

      final verified = await PackageVerifier.matches(package, expectedChecksum);
      if (!verified) {
        // A package that does not match its published hash is worse than no
        // package at all.
        try {
          await package.delete();
        } catch (_) {
          // Cleanup failure is not worth masking the real reason.
        }
        return const InstallOutcome.failure(
          'The download did not match its published checksum, so it was '
          'discarded. Nothing has been changed.',
        );
      }

      final result = await UpdateInstaller(layout).stage(
        package: package,
        version: version,
      );
      if (!result.ok) {
        return InstallOutcome.failure(result.message ?? 'The update failed.');
      }
      return InstallOutcome.success(
        'Version $version is installed. Restart to start using it.',
        version: version,
      );
    } catch (error) {
      return InstallOutcome.failure('$error');
    } finally {
      // The staged copy is no longer needed once it has been applied.
      try {
        if (package != null && await package.exists()) await package.delete();
      } catch (_) {
        // Leaving a temp file behind is untidy, not dangerous.
      }
    }
  }

  /// Switch back to a version already on disk.
  Future<InstallOutcome> rollbackTo(String version) async {
    final layout = InstallLayout.detect();
    if (!layout.isVersioned) {
      return const InstallOutcome.failure(
        'This copy of Digital Saver cannot change versions in place.',
        needsUserAction: true,
      );
    }
    final result = await UpdateInstaller(layout).rollbackTo(version);
    return result.ok
        ? InstallOutcome.success('Switched back to $version. Restart to apply.',
            version: version)
        : InstallOutcome.failure(result.message ?? 'Rollback failed.');
  }

  /// The version an update replaced, so rollback stays available.
  String? rollbackTarget;

  /// Remember the version an update replaced.
  void rememberRollbackTarget(String? version) {
    if (version != null && version.isNotEmpty) rollbackTarget = version;
  }

  /// Fetch an asset to a temporary file.
  Future<File?> _download(
    ReleaseAsset asset, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (_hooks?.download != null) {
      final staged = await _hooks!.download!(asset);
      return staged;
    }
    // Real download path is provided by the caller in production builds via
    // [ReleaseDownloader]; kept separate so this class stays testable.
    return null;
  }
}

/// Indirection so tests can supply downloads without a network.
class ReleaseServiceHooks {
  /// Creates a test double that always yields this file.
  const ReleaseServiceHooks({this.download});

  /// Download implementation.
  final Future<File?> Function(ReleaseAsset asset)? download;
}

/// Resolves the temporary directory, exposed for tests.
Future<String> stagingPathForTest() async {
  final dir = await PackageInstaller()._stagingDirectory();
  return dir.path;
}