/// Release discovery for Digital Saver.
///
/// Replaces a previous implementation that had four real problems:
///
/// 1. **The current version was a hardcoded string** (`v1.0.1-beta`) that had
///    already drifted from `pubspec.yaml` (1.0.3+3) and from the newest tag
///    (v1.0.3-beta). The app therefore believed it was two releases behind and
///    kept offering an update that was not one. It now reads the real version
///    from a single source of truth.
/// 2. **Release JSON was parsed with regular expressions.** The pattern
///    `"body":\s*"([^"]*)"` breaks on the first quote or escaped newline in a
///    release note, and release notes are markdown. This decodes real JSON.
/// 3. **Any failure silently produced a plausible-looking answer.** A network
///    error returned a hardcoded tag, so the app could not tell "up to date"
///    from "I could not reach GitHub".
/// 4. **No verification.** A download was accepted on an HTTP 200 alone.
///
/// Version comparison is numeric per segment, so 0.10.0 correctly beats 0.9.0,
/// and a pre-release never outranks a stable release of the same number.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_version.dart';
import 'release_assets.dart';

/// Outcome of looking for a newer release.
class ReleaseCheck {
  /// Create a check result.
  const ReleaseCheck({
    required this.currentVersion,
    required this.upToDate,
    this.latestVersion = '',
    this.notes = '',
    this.assets = const <ReleaseAsset>[],
    this.error,
  });

  /// Version this build reports.
  final String currentVersion;

  /// Whether the newest published release is not newer than this build.
  final bool upToDate;

  /// Newest published tag, empty when the check failed.
  final String latestVersion;

  /// Release notes published upstream.
  final String notes;

  /// Downloadable assets on that release.
  final List<ReleaseAsset> assets;

  /// Why the check failed, when it did.
  ///
  /// Present means nothing was learned about updates, which is deliberately
  /// different from "up to date".
  final String? error;

  /// Whether a newer release exists.
  bool get hasUpdate => !upToDate && latestVersion.isNotEmpty && error == null;

  /// One-line summary for the UI.
  String get summary {
    if (error != null) return 'Could not check for updates: $error';
    if (hasUpdate) return 'Version $latestVersion is available (you have $currentVersion).';
    return 'Digital Saver is up to date.';
  }
}

/// Finds and describes published releases.
class ReleaseService {
  /// Create a release service.
  ReleaseService({http.Client? client, this.repository = defaultRepository})
      : _client = client ?? http.Client();

  /// `owner/repo` releases are read from.
  static const String defaultRepository = 'Cambric-software/Digital-saver';

  /// Final, unauthenticated client. Closed by [dispose].
  final http.Client _client;

  /// Releases repository.
  final String repository;

  /// How long to wait before giving up.
  static const Duration timeout = Duration(seconds: 15);

  /// Look for a release newer than [currentVersion].
  ///
  /// Never throws. A failure is reported in [ReleaseCheck.error] rather than
  /// being turned into a fake "latest version".
  Future<ReleaseCheck> check({String? currentVersion}) async {
    final current = currentVersion ?? AppVersion.current;

    ReleaseCheck offline(String reason) =>
        ReleaseCheck(currentVersion: current, upToDate: false, error: reason);

    final uri = Uri.parse('https://api.github.com/repos/$repository/releases/latest');
    late final http.Response response;
    try {
      response = await _client.get(uri, headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Digital-Saver-Desktop',
      }).timeout(timeout);
    } on TimeoutException {
      return offline('the request timed out');
    } catch (error) {
      return offline('$error');
    }

    if (response.statusCode != 200) {
      // 404 means the repository has no published release at all, which is
      // genuinely "nothing to install" rather than a failure to look.
      if (response.statusCode == 404) {
        return ReleaseCheck(currentVersion: current, upToDate: true);
      }
      return offline('GitHub returned HTTP ${response.statusCode}');
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return offline('GitHub returned an unexpected payload');
      }
      json = decoded;
    } catch (_) {
      return offline('GitHub returned malformed JSON');
    }

    final tag = (json['tag_name'] ?? '').toString().trim();
    if (tag.isEmpty) {
      return offline('the release has no tag');
    }

    final newer = compareVersions(tag, current) > 0;
    return ReleaseCheck(
      currentVersion: current,
      upToDate: !newer,
      latestVersion: tag,
      notes: (json['body'] ?? '').toString(),
      assets: ReleaseAsset.parseAll(json['assets']),
    );
  }

  /// Release the HTTP client.
  void dispose() => _client.close();

  /// Compare two dotted versions.
  ///
  /// Returns a positive number when [a] is newer than [b]. A leading `v` is
  /// ignored. Numeric segments compare as numbers, so 0.10 beats 0.9. A
  /// non-numeric segment sorts before a numeric one, so a pre-release never
  /// outranks a stable release of the same number.
  static int compareVersions(String a, String b) {
    final left = _segments(a);
    final right = _segments(b);
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : null;
      final r = i < right.length ? right[i] : null;
      if (l == null) return r == 'beta' ? 1 : -1;
      if (r == null) return l == 'beta' ? -1 : 1;
      if (l == r) continue;
      final ln = int.tryParse(l.replaceAll(RegExp(r'^beta(\d+)$'), r'1$1'));
      final rn = int.tryParse(r.replaceAll(RegExp(r'^beta(\d+)$'), r'1$1'));
      if (ln != null && rn != null) return ln.compareTo(rn);
      if (ln != null) return 1;
      if (rn != null) return -1;
      if (l == 'beta') return -1;
      if (r == 'beta') return 1;
      return l.compareTo(r);
    }
    return 0;
  }

  static List<String> _segments(String version) => version
      .trim()
      .replaceFirst(RegExp('^[vV]'), '')
      .split(RegExp(r'[.\-+_]'))
      .where((s) => s.isNotEmpty)
      .toList();
}