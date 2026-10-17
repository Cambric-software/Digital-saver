/// Versioned installation layout and the update installer.
///
/// ## Why not just overwrite the files?
///
/// Windows locks a running executable and its DLLs. Any updater that replaces
/// `digital_saver.exe` or `flutter_windows.dll` in place, while the app is running,
/// produces a half-written install that cannot start and cannot be recovered by
/// the app that was supposed to fix it. The usual workaround — a helper process
/// that waits for exit — is a second binary to ship, update and keep alive.
///
/// ## The layout used instead
///
///     <root>/                      e.g. %LOCALAPPDATA%\Programs\MaxTools
///       current.txt                the active version, e.g. "0.1.0"
///       versions/
///         0.1.0/
///           digital_saver.exe
///           flutter_windows.dll
///           data/
///         0.1.1/
///           ...
///
/// An update **adds a directory** and moves a pointer. Nothing running is ever
/// touched, so there is no race and no failed half-swap to recover from.
/// Rollback is writing the pointer back.
///
/// ## Roles
///
/// * [InstallLayout.detect] recognises this layout. A flat layout (a dev build,
///   or the pre-0.1.0 zip) is reported as unversioned, and every operation
///   becomes a no-op rather than an error.
/// * [UpdateInstaller.stage] extracts a verified package into a new version
///   directory and confirms it actually contains a runnable app.
/// * [UpdateInstaller.activate] moves the pointer, which is the commit.
/// * [UpdateInstaller.rollback] moves it back.
/// * [handoff] is the safety net: an app that notices the pointer names a
///   different version hands control to that version and exits, so a launch
///   from an old shortcut can never trap the user on a stale build.
library;

import 'dart:convert';
import 'dart:io';

/// The file that records which version directory is live.
const String kVersionPointerFile = 'current.txt';

/// The directory under the install root that holds one folder per version.
const String kVersionsDirectoryName = 'versions';

/// Result of an installer operation. Never throws; the reason is in [message].
class InstallOutcome {
  /// Create a success result.
  const InstallOutcome.success(this.version, {this.previousVersion})
      : ok = true,
        message = null;

  /// Create a failure.
  const InstallOutcome.failure(this.message)
      : ok = false,
        version = null,
        previousVersion = null;

  /// Whether the operation completed.
  final bool ok;

  /// The version that is now active, when successful.
  final String? version;

  /// The version that was active before, when it changed.
  ///
  /// This is what makes rollback possible after an update, so callers can hold
  /// on to it.
  final String? previousVersion;

  /// Why it failed, when it did.
  final String? message;

  @override
  String toString() => ok
      ? 'InstallOutcome.success($version, previous: $previousVersion)'
      : 'InstallOutcome.failure($message)';
}

/// Locates the versioned install and reads/writes its pointer.
class InstallLayout {
  InstallLayout._({
    required this.root,
    required this.versionsDirectory,
    required this.executableDirectory,
    required bool versioned,
  }) : _isVersioned = versioned;

  /// The install root, the parent of `versions/`.
  final Directory root;

  /// The `versions/` directory.
  final Directory versionsDirectory;

  /// The directory containing the currently running executable.
  final Directory executableDirectory;

  /// Whether this build is running from a versioned install at all.
  bool get isVersioned => _isVersioned;
  final bool _isVersioned;

  /// The file naming the active version.
  File get pointerFile => File('${root.path}${Platform.pathSeparator}$kVersionPointerFile');

  /// The version this process is running from, taken from its folder name.
  String get runningVersion {
    final parts = executableDirectory.path.split(Platform.pathSeparator);
    return parts.isEmpty ? '' : parts.last;
  }

  /// The version named by the pointer, or null when absent or unreadable.
  String? get activeVersion {
    try {
      final file = pointerFile;
      if (!file.existsSync()) return null;
      final text = file.readAsStringSync().trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// Directory for a given version.
  Directory versionDirectory(String version) =>
      Directory('${versionsDirectory.path}${Platform.pathSeparator}$version');

  /// Directory holding the executable for a given version.
  File executableFor(String version) => File(
        '${versionDirectory(version).path}${Platform.pathSeparator}'
        '${InstallLayout.executableName}',
      );

  /// Whether a version directory holds an executable.
  bool versionLooksInstalled(String version) {
    if (!isVersioned) return false;
    try {
      return executableFor(version).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// The platform's executable name for this project.
  static String get executableName {
    if (Platform.isWindows) return 'digital_saver.exe';
    if (Platform.isLinux) return 'digital_saver';
    if (Platform.isMacOS) return 'digital_saver';
    return 'digital_saver';
  }

  /// Work out whether this process is inside a versioned install.
  ///
  /// [executablePath] defaults to the running process. Tests pass a path to
  /// exercise the logic without a real install.
  static InstallLayout detect({String? executablePath}) {
    final exePath = executablePath ?? Platform.resolvedExecutable;
    final exeDir = File(exePath).parent;
    final parts = exeDir.path.split(Platform.pathSeparator);
    // A versioned install looks like <root>/versions/<version>/digital_saver.exe,
    // so the executable's parent is the version directory and its grandparent
    // is the install root.
    final isVersioned =
        parts.length >= 2 && parts[parts.length - 2] == kVersionsDirectoryName;
    return InstallLayout._(
      root: isVersioned ? exeDir.parent.parent : exeDir.parent,
      versionsDirectory: isVersioned ? exeDir.parent : exeDir.parent,
      executableDirectory: exeDir,
      versioned: isVersioned,
    );
  }
}

/// Applies, activates, rolls back and prunes versions.
class UpdateInstaller {
  /// Create an installer for [layout].
  UpdateInstaller(this.layout);

  /// Where the layout lives.
  final InstallLayout layout;

  /// Extract a verified package into `versions/<version>` and point at it.
  ///
  /// The pointer is only moved once the new directory is known to contain a
  /// runnable executable, so a truncated download can never become the active
  /// version. Extraction shells out to `tar`, which ships with Windows 10+ and
  /// every supported Linux distribution, so this adds no dependency.
  Future<InstallOutcome> stage({
    required File package,
    required String version,
    bool activate = true,
  }) async {
    if (!layout.isVersioned) {
      return const InstallOutcome.failure(
        'This build is not running from a versioned install, so it cannot '
        'update itself. Reinstall using the setup executable.',
      );
    }
    if (version.trim().isEmpty) {
      return const InstallOutcome.failure('No version was supplied.');
    }
    if (!await package.exists()) {
      return const InstallOutcome.failure('The downloaded package is missing.');
    }

    final target = layout.versionDirectory(version);
    try {
      await layout.versionsDirectory.create(recursive: true);
      // A previous failed attempt may have left a partial directory.
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      await target.create(recursive: true);
    } catch (error) {
      return InstallOutcome.failure('Could not create the install directory: $error');
    }

    final extracted = await _extract(package: package, into: target);
    if (!extracted.ok) {
      await _deleteQuietly(target);
      return extracted;
    }

    // Prove the new directory is runnable before it can become active.
    if (!await layout.executableFor(version).exists()) {
      await _deleteQuietly(target);
      return InstallOutcome.failure(
        'The package did not contain ${InstallLayout.executableName}, so it '
        'cannot be run. Nothing was changed.',
      );
    }

    if (!activate) return InstallOutcome.success(version);
    return activateVersion(version);
  }

  /// Move the pointer to [version], returning the version it replaced.
  Future<InstallOutcome> activateVersion(String version) async {
    if (!await layout.executableFor(version).exists()) {
      return InstallOutcome.failure('Version $version is not installed.');
    }
    final previous = layout.activeVersion;
    if (previous == version) return InstallOutcome.success(version);
    try {
      // Write-then-rename, so an interrupted write cannot leave the pointer
      // naming a version that does not exist.
      final temp = File('${layout.pointerFile.path}.tmp');
      await temp.writeAsString(version, flush: true);
      await temp.rename(layout.pointerFile.path);
    } catch (error) {
      return InstallOutcome.failure('Could not activate the version: $error');
    }
    return InstallOutcome.success(version, previousVersion: previous);
  }

  /// Point back at [version] without re-extracting anything.
  Future<InstallOutcome> rollbackTo(String version) async {
    if (version == layout.activeVersion) {
      return InstallOutcome.success(version);
    }
    if (!await layout.executableFor(version).exists()) {
      return InstallOutcome.failure('Version $version is not installed.');
    }
    return activateVersion(version);
  }

  /// Versions present on disk, newest-looking first.
  Future<List<String>> installedVersions() async {
    if (!layout.isVersioned) return <String>[];
    try {
      if (!await layout.versionsDirectory.exists()) return <String>[];
      final entries = await layout.versionsDirectory.list().toList();
      final versions = <String>[];
      for (final entry in entries) {
        if (entry is! Directory) continue;
        final name = entry.path.split(Platform.pathSeparator).last;
        if (layout.executableFor(name).existsSync()) versions.add(name);
      }
      versions.sort();
      return versions;
    } catch (_) {
      return <String>[];
    }
  }

  /// Delete every version except [keep].
  ///
  /// The active version and [extraKeep] more are retained so a rollback always
  /// has somewhere to go.
  Future<int> prune({String? keep, int extraKeep = 1}) async {
    if (!layout.isVersioned) return 0;
    final versions = await installedVersions();
    final active = keep ?? layout.activeVersion;
    final survivors = <String>{};
    if (active != null) survivors.add(active);
    // Keep the most recent N others, which is what makes rollback possible.
    final others = versions.where((v) => !survivors.contains(v)).toList()..sort();
    for (final other in others.reversed.take(extraKeep)) {
      survivors.add(other);
    }
    var removed = 0;
    for (final version in versions) {
      if (survivors.contains(version)) continue;
      if (await _deleteQuietly(layout.versionDirectory(version))) removed++;
    }
    return removed;
  }

  Future<InstallOutcome> _extract({
    required File package,
    required Directory into,
  }) async {
    ProcessResult result;
    try {
      // bsdtar reads zip on both Windows and Linux and refuses to write
      // outside the destination via --strip-components-free absolute paths only
      // because we chdir with -C.
      result = await Process.run(
        'tar',
        <String>['-xf', package.path, '-C', into.path],
        workingDirectory: into.path,
      );
    } on ProcessException catch (error) {
      return InstallOutcome.failure('Could not unpack the download: ${error.message}');
    }
    if (result.exitCode != 0) {
      return InstallOutcome.failure(
        'Could not unpack the download (tar exited ${result.exitCode}).',
      );
    }
    return const InstallOutcome.success('');
  }

  Future<bool> _deleteQuietly(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        return true;
      }
    } catch (_) {
      // A leftover directory is untidy, not fatal.
    }
    return false;
  }
}

/// What should happen at startup because of the pointer.
enum HandoffAction {
  /// Nothing to do; carry on running.
  none,

  /// A different version is active, so start it and exit.
  relaunchActiveVersion,
}

/// Decides whether this process should hand over to another version.
///
/// A process launched from an old shortcut, or from a stale desktop icon,
/// finds the pointer naming a newer version. Rather than running an outdated
/// build it starts the active one and exits, which is what makes rollback and
/// half-finished updates self-healing.
Future<HandoffAction> handoff({InstallLayout? layout}) async {
  final resolved = layout ?? InstallLayout.detect();
  if (!resolved.isVersioned) return HandoffAction.none;
  final active = resolved.activeVersion;
  if (active == null || active.isEmpty) return HandoffAction.none;
  final running = resolved.runningVersion;
  if (active == running) return HandoffAction.none;

  final target = resolved.executableFor(active);
  if (!await target.exists()) return HandoffAction.none;

  try {
    await Process.start(
      target.path,
      <String>[],
      mode: ProcessStartMode.detached,
    );
    return HandoffAction.relaunchActiveVersion;
  } catch (_) {
    // If it will not start, running the version we already have beats
    // exiting and leaving the user with nothing.
    return HandoffAction.none;
  }
}

/// Relaunch the executable for [version] and exit the current process.
Future<bool> relaunchVersion(String version, {InstallLayout? layout}) async {
  final resolved = layout ?? InstallLayout.detect();
  final target = resolved.executableFor(version);
  if (!await target.exists()) return false;
  try {
    await Process.start(
      target.path,
      <String>[],
      mode: ProcessStartMode.detached,
    );
    exit(0);
  } catch (_) {
    return false;
  }
}

/// Reads a staged-update marker written before a restart.
///
/// Kept separate from the layout so a crash between activation and relaunch is
/// still visible to the next run.
Future<Map<String, dynamic>?> readPendingUpdate(Directory directory) async {
  final file = File('${directory.path}${Platform.pathSeparator}pending_update.json');
  try {
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Record that [version] is staged and about to be activated.
Future<void> writePendingUpdate(Directory directory, String version) async {
  final file = File('${directory.path}${Platform.pathSeparator}pending_update.json');
  try {
    await file.writeAsString(
      jsonEncode(<String, dynamic>{'version': version}),
      flush: true,
    );
  } catch (_) {
    // Best effort: the pointer is the real commit, this is only a breadcrumb.
  }
}

/// Clear the staged-update breadcrumb.
Future<void> clearPendingUpdate(Directory directory) async {
  final file = File('${directory.path}${Platform.pathSeparator}pending_update.json');
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Nothing depends on this succeeding.
  }
}