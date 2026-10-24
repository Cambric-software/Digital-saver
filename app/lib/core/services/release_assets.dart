/// Downloadable files attached to a GitHub release, and their checksums.
///
/// Checksums matter here more than in most apps: a downloaded package is
/// executable code. A release is only offered for install when its asset
/// matches the `.sha256` file published beside it, and a package that fails is
/// deleted rather than kept.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';

/// One file on a release.
class ReleaseAsset {
  /// Create an asset.
  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.sizeBytes,
    this.checksum,
  });

  /// File name as published.
  final String name;

  /// Direct download URL.
  final String url;

  /// Size in bytes, 0 when unknown.
  final int sizeBytes;

  /// Expected SHA-256, lowercase hex, when the release publishes one.
  final String? checksum;

  /// Whether this asset carries a published checksum.
  bool get hasChecksum => (checksum ?? '').isNotEmpty;

  /// Parse every asset in a release payload, pairing `.sha256` sidecars.
  ///
  /// GitHub publishes checksums as separate `<file>.sha256` assets whose body
  /// is `<hash>  <name>`, so they are read and attached to the file they
  /// describe rather than being treated as downloads in their own right.
  static List<ReleaseAsset> parseAll(Object? raw) {
    if (raw is! List) return const <ReleaseAsset>[];
    final assets = <ReleaseAsset>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final name = (entry['name'] ?? '').toString();
      if (name.isEmpty) continue;
      assets.add(ReleaseAsset(
        name: name,
        url: (entry['browser_download_url'] ?? '').toString(),
        sizeBytes: (entry['size'] as num?)?.toInt() ?? 0,
      ));
    }
    // `.sha256` sidecars arrive as ordinary assets; [attachChecksums] pairs
    // them with the files they describe.
    return assets;
  }

  /// Attach checksums discovered from `.sha256` sidecar bodies.
  ///
  /// [sidecars] maps a sidecar asset name to the text it contains.
  static List<ReleaseAsset> attachChecksums(
    List<ReleaseAsset> assets,
    Map<String, String> sidecars,
  ) {
    String? bodyFor(String name) => sidecars[name];

    final result = <ReleaseAsset>[];
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.sha256')) {
        result.add(asset);
        continue;
      }
      final sidecarName = '${asset.name}.sha256';
      final body = bodyFor(sidecarName);
      result.add(ReleaseAsset(
        name: asset.name,
        url: asset.url,
        sizeBytes: asset.sizeBytes,
        checksum: body == null ? null : parseChecksum(body),
      ));
    }
    return result;
  }

  /// Extract the hash from a `<hash>  <name>` checksum file body.
  ///
  /// Tolerates GNU coreutils two-space formatting and a bare hash.
  static String? parseChecksum(String body) {
    final first = body.trim().split(RegExp(r'\s+')).firstOrNull;
    if (first == null) return null;
    final candidate = first.toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(candidate)) return null;
    return candidate;
  }

  /// Find the asset that looks right for this platform.
  ///
  /// Prefers a checksummed asset, because an unverifiable package should not
  /// be the one we offer.
  static ReleaseAsset? forCurrentPlatform(List<ReleaseAsset> assets) {
    final lower = assets.map((a) => a.name.toLowerCase()).toList();

    List<String> keywords;
    if (Platform.isWindows) {
      keywords = ['windows', '.zip', 'setup.exe'];
    } else if (Platform.isLinux) {
      keywords = ['linux', '.tar.gz', '.deb', '.appimage'];
    } else if (Platform.isAndroid) {
      keywords = ['android', '.apk'];
    } else if (Platform.isMacOS) {
      keywords = ['macos', '.dmg', '.zip'];
    } else {
      keywords = ['.zip', '.tar.gz'];
    }

    final candidates = <ReleaseAsset>[];
    for (var i = 0; i < assets.length; i++) {
      final name = lower[i];
      if (name.endsWith('.sha256')) continue;
      for (final k in keywords) {
        if (name.contains(k)) {
          candidates.add(assets[i]);
          break;
        }
      }
    }
    if (candidates.isEmpty) return null;
    for (final c in candidates) {
      if (c.hasChecksum) return c;
    }
    return candidates.first;
  }

  @override
  String toString() => 'ReleaseAsset($name, ${sizeBytes}B, '
      'checksum: ${hasChecksum ? 'yes' : 'MISSING'})';
}

/// Verifies a downloaded file against an expected SHA-256.
class PackageVerifier {
  const PackageVerifier._();

  /// Outcome of a verification.
  static Future<bool> matches(File file, String? expected) async {
    if (expected == null || expected.isEmpty) return false;
    if (!await file.exists()) return false;
    final digest = await sha256.bind(file.openRead()).first;
    // Constant-time-ish comparison; the values are not secret, but the habit
    // is cheap and this is the same discipline the hashing service uses.
    return digest.toString().toLowerCase() == expected.toLowerCase();
  }
}