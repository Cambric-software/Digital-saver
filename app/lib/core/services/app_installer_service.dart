/// Applies an update only after its published bytes have been verified.
///
/// The previous version was a shell around an idea that could not work. It
/// uninstalled the app before installing the replacement, which destroyed the
/// person's data; it then invoked `pm install` through `Process.run`, which a
/// normal Android app has no permission to do. On a stock phone that path
/// failed at the last step, after the app was already gone. It also had a
/// rollback API that nothing called, and a "staging" directory that was created
/// but never used for a download.
///
/// This version has one rule: executable bytes are never opened, staged or
/// handed to the operating system until they match a SHA-256 published beside
/// the release. A package with no published checksum is refused rather than
/// trusted, and a package that fails the comparison is deleted. The two honest
/// outcomes are kept distinct:
///
///  * [InstallStatus.installed] means a desktop package was verified, unpacked
///    into a new version directory and the version pointer was moved. That
///    operation really completed.
///  * [InstallStatus.handedOff] means Android received a verified package and
///    the system installer was opened. This class does not and cannot know
///    whether the person confirmed the install, so it never reports success.
///
/// Downloads are streamed into the temporary `updates` directory, which is the
/// only staging this class does. Desktop extraction is owned by
/// [UpdateInstaller], which writes a new version directory rather than
/// overwriting files that are currently running.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'install_layout.dart';
import 'release_assets.dart';

/// How far an install attempt actually got.
enum InstallStatus {
  /// A desktop package was verified, unpacked and activated.
  installed,

  /// A verified package was given to a system installer the user must confirm.
  handedOff,

  /// Nothing was changed.
  failed,
}

/// Result of an install attempt.
class InstallOutcome {
  /// A completed desktop install.
  const InstallOutcome.installed(this.message, {this.version})
      : status = InstallStatus.installed,
        needsUserAction = false;

  /// A verified package handed to a system installer.
  const InstallOutcome.handedOff(this.message, {this.version})
      : status = InstallStatus.handedOff,
        needsUserAction = true;

  /// A failure, with the reason in [message].
  const InstallOutcome.failure(this.message, {this.needsUserAction = false})
      : status = InstallStatus.failed,
        version = null;

  /// What happened.
  final InstallStatus status;

  /// Human-readable explanation, always populated.
  final String message;

  /// Version involved, when one was verified.
  final String? version;

  /// Whether the person has to finish the job themselves.
  final bool needsUserAction;

  /// Whether the operation completed without further action.
  bool get ok => status == InstallStatus.installed;

  /// Whether a verified package was handed to another installer.
  bool get handedOff => status == InstallStatus.handedOff;

  @override
  String toString() => 'InstallOutcome(${status.name}: $message)';
}

/// Fetches [asset] into a local file, or null when the download did not finish.
typedef PackageFetcher = Future<File?> Function(
  ReleaseAsset asset,
  void Function(int received, int total)? onProgress,
);

/// Opens a local package with the platform's installer.
typedef InstallerLauncher = Future<bool> Function(Uri uri);

/// Downloads, verifies and applies a release package.
class PackageInstaller {
  /// Create an installer.
  ///
  /// The three optional arguments exist so tests can supply a package, a
  /// launcher and a platform without a network, a real system dialog or a host
  /// platform. The app supplies none of them.
  PackageInstaller({
    PackageFetcher? fetch,
    InstallerLauncher? launchInstaller,
    TargetPlatform? platform,
    InstallLayout Function()? layout,
  })  : _fetch = fetch,
        _launchInstaller = launchInstaller,
        _platform = platform,
        _layout = layout;

  final PackageFetcher? _fetch;
  final InstallerLauncher? _launchInstaller;
  final TargetPlatform? _platform;
  final InstallLayout Function()? _layout;

  /// Download [asset], prove it matches [expectedChecksum], then apply it.
  ///
  /// A missing or malformed checksum is a failure before any network request:
  /// an unverifiable package is not worth downloading. A downloaded file that
  /// does not match is deleted, because keeping it only invites someone to run
  /// it later.
  Future<InstallOutcome> install({
    required String version,
    required ReleaseAsset asset,
    void Function(int received, int total)? onProgress,
  }) async {
    if (version.trim().isEmpty) {
      return const InstallOutcome.failure('No version was supplied.');
    }

    final String? expected = asset.checksum?.trim();
    if (expected == null || expected.isEmpty) {
      return const InstallOutcome.failure(
        'The release did not publish a SHA-256 for this package, so it was '
        'not downloaded. An update that cannot be verified is not installed.',
        needsUserAction: true,
      );
    }

    File? package;
    var keepPackage = false;
    try {
      package = await (_fetch ?? _download)(asset, onProgress);
      if (package == null) {
        return const InstallOutcome.failure(
          'The download did not complete, so nothing was changed.',
        );
      }

      final bool verified = await PackageVerifier.matches(package, expected);
      if (!verified) {
        // Delete before reporting, so a modified executable cannot be found
        // and opened later by someone who does not know it failed.
        await _deleteQuietly(package);
        package = null;
        return const InstallOutcome.failure(
          'The download did not match its published SHA-256, so it was '
          'deleted. Nothing has been changed.',
        );
      }

      final TargetPlatform platform = _platform ?? defaultTargetPlatform;
      if (platform == TargetPlatform.android) {
        // A file the system installer may still be reading must outlive this
        // call. The verified package stays in the temporary directory.
        keepPackage = true;
        final bool opened = await _openInstaller(Uri.file(package.path));
        if (!opened) {
          return InstallOutcome.failure(
            'Version $version was downloaded and verified, but the system '
            'installer did not open. The verified file is at ${package.path}; '
            'open it to finish. Nothing has been changed yet.',
            needsUserAction: true,
          );
        }
        return InstallOutcome.handedOff(
          'Version $version was downloaded and matched its published '
          'SHA-256. Android was asked to open the package; confirm the install '
          'in the system prompt. Digital Saver has not marked it installed.',
          version: version,
        );
      }

      if (platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS) {
        final InstallLayout layout = (_layout ?? InstallLayout.detect)();
        if (!layout.isVersioned) {
          return const InstallOutcome.failure(
            'This copy was not installed with the setup executable, so it '
            'cannot update itself. Download and run the installer again. '
            'Nothing has been changed.',
            needsUserAction: true,
          );
        }
        final result = await UpdateInstaller(layout).stage(
          package: package,
          version: version,
        );
        if (!result.ok) {
          return InstallOutcome.failure(
            result.message ?? 'The update could not be applied.',
          );
        }
        return InstallOutcome.installed(
          'Version $version was verified, unpacked and activated. Restart '
          'Digital Saver to run it.',
          version: version,
        );
      }

      return const InstallOutcome.failure(
        'This platform has no package installer path in Digital Saver. '
        'Nothing has been changed.',
        needsUserAction: true,
      );
    } catch (error) {
      return InstallOutcome.failure(
        'The update could not be applied: $error',
      );
    } finally {
      // On desktop the package has been extracted into its version directory,
      // so the download copy is disposable. On Android the installer may still
      // need the file; it is left in the temporary directory.
      if (package != null && !keepPackage) {
        await _deleteQuietly(package);
      }
    }
  }

  /// Stream [asset] into the temporary updates directory.
  Future<File?> _download(
    ReleaseAsset asset,
    void Function(int received, int total)? onProgress,
  ) async {
    if (asset.url.isEmpty) return null;

    final Uri uri = Uri.tryParse(asset.url) ?? Uri();
    if (!uri.hasScheme || uri.host.isEmpty) return null;

    final Directory base = await getTemporaryDirectory();
    final Directory staging =
        Directory('${base.path}${Platform.pathSeparator}updates');
    if (!await staging.exists()) await staging.create(recursive: true);

    final String safeName =
        asset.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final File target = File(
      '${staging.path}${Platform.pathSeparator}'
      '${safeName.isEmpty ? 'update.package' : safeName}',
    );

    final http.Client client = http.Client();
    try {
      final http.StreamedResponse response = await client
          .send(http.Request('GET', uri))
          .timeout(const Duration(minutes: 5));
      if (response.statusCode != HttpStatus.ok) {
        await _deleteQuietly(target);
        return null;
      }

      final int total =
          response.contentLength == null || response.contentLength! <= 0
              ? asset.sizeBytes
              : response.contentLength!;
      final IOSink sink = target.openWrite();
      var received = 0;
      try {
        await for (final List<int> chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      return target;
    } catch (_) {
      await _deleteQuietly(target);
      return null;
    } finally {
      client.close();
    }
  }

  Future<bool> _openInstaller(Uri uri) async {
    final InstallerLauncher? launch = _launchInstaller;
    if (launch != null) return launch(uri);
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover temporary file is untidy, not dangerous.
    }
  }
}
