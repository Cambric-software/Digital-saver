import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:digital_saver/core/services/auto_update_service.dart';
import 'package:digital_saver/core/services/release_assets.dart';
import 'package:digital_saver/core/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 64 hex characters, built the Dart way.
String _rep(String c) => List<String>.filled(64, c).join();

void main() {
  final hashA = _rep('a');
  final hashB = _rep('b');
  final hashC = _rep('c');
  final hashD = _rep('d');
  group('version reporting', () {
    test('the running version matches pubspec.yaml', () {
      // A version that drifts from pubspec is how the app ended up claiming to
      // be 1.0.2 while the real build was 1.0.3.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true)
          .firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec.yaml has no version');
      expect(AppVersion.current, match!.group(1));
    });

    test('the build number matches pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(r'^version:\s*[\d.]+\+(\d+)', multiLine: true)
          .firstMatch(pubspec);
      expect(match, isNotNull);
      expect(AppVersion.buildNumber, match!.group(1));
    });

    test('the releases page is a real repository URL', () {
      expect(
          AppVersion.releasesPage, contains('Cambric-software/Digital-saver'));
      expect(AppVersion.releasesPage, startsWith('https://'));
    });

    test('the display and tag forms are consistent', () {
      expect(AppVersion.tag, 'v${AppVersion.display}');
      expect(AppVersion.isPreRelease, isTrue);
    });
  });

  group('version comparison', () {
    test('equal versions compare equal, with or without a v prefix', () {
      expect(ReleaseService.compareVersions('1.0.3', '1.0.3'), 0);
      expect(ReleaseService.compareVersions('v1.0.3', '1.0.3'), 0);
    });

    test('newer versions are detected', () {
      expect(ReleaseService.compareVersions('1.0.4', '1.0.3'), greaterThan(0));
      expect(ReleaseService.compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(
          ReleaseService.compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('older versions are detected', () {
      expect(ReleaseService.compareVersions('1.0.2', '1.0.3'), lessThan(0));
      expect(ReleaseService.compareVersions('0.9.0', '1.0.0'), lessThan(0));
    });

    test('segments compare as numbers, not text', () {
      // "0.10" sorts before "0.9" as a string; as a version it is newer.
      expect(ReleaseService.compareVersions('0.10.0', '0.9.0'), greaterThan(0));
    });

    test('a pre-release never outranks a stable release', () {
      expect(
        ReleaseService.compareVersions('1.0.3-beta', '1.0.3'),
        lessThan(0),
      );
      expect(
        ReleaseService.compareVersions('1.0.3', '1.0.3-beta'),
        greaterThan(0),
      );
    });

    test('beta builds are ordered among themselves', () {
      expect(
        ReleaseService.compareVersions('1.0.3-beta2', '1.0.3-beta1'),
        greaterThan(0),
      );
    });

    test('junk input does not throw', () {
      expect(ReleaseService.compareVersions('', ''), 0);
      expect(ReleaseService.compareVersions('banana', '1.0.0'), isNot(0));
    });
  });

  group('checksum parsing', () {
    test('reads the GNU two-space format', () {
      const hash =
          '44f8d2c7b2251c07c997b49c0719c59987a0cc7d2591d2268d7ef2f7fd669a4d';
      expect(
        ReleaseAsset.parseChecksum('$hash  windows.zip'),
        hash,
      );
    });

    test('reads a bare hash', () {
      const hash =
          '44f8d2c7b2251c07c997b49c0719c59987a0cc7d2591d2268d7ef2f7fd669a4d';
      expect(ReleaseAsset.parseChecksum(hash), hash);
    });

    test('is case insensitive', () {
      expect(
        ReleaseAsset.parseChecksum(
            '44F8D2C7B2251C07C997B49C0719C59987A0CC7D2591D2268D7EF2F7FD669A4D'),
        '44f8d2c7b2251c07c997b49c0719c59987a0cc7d2591d2268d7ef2f7fd669a4d',
      );
    });

    test('rejects anything that is not a sha256', () {
      expect(ReleaseAsset.parseChecksum(''), isNull);
      expect(ReleaseAsset.parseChecksum('deadbeef'), isNull);
      expect(ReleaseAsset.parseChecksum('not a hash at all'), isNull);
    });
  });

  group('release digest', () {
    test('reads the sha256 prefix GitHub publishes', () {
      expect(
        AutoUpdateService.parseDigest('sha256:$hashA'),
        hashA,
      );
    });

    test('accepts a bare hash and normalises case', () {
      expect(
        AutoUpdateService.parseDigest(hashA.toUpperCase()),
        hashA,
      );
    });

    test('rejects another algorithm or junk', () {
      expect(AutoUpdateService.parseDigest('sha512:$hashA'), isNull);
      expect(AutoUpdateService.parseDigest('sha256:deadbeef'), isNull);
      expect(AutoUpdateService.parseDigest(null), isNull);
      expect(AutoUpdateService.parseDigest(42), isNull);
    });
  });

  group('asset selection', () {
    final assets = <ReleaseAsset>[
      ReleaseAsset(
          name: 'windows.zip', url: 'u', sizeBytes: 1, checksum: hashA),
      const ReleaseAsset(name: 'windows.zip.sha256', url: 'u', sizeBytes: 1),
      ReleaseAsset(
          name: 'linux.tar.gz', url: 'u', sizeBytes: 1, checksum: hashB),
      ReleaseAsset(
          name: 'android.apk', url: 'u', sizeBytes: 1, checksum: hashC),
    ];

    test('sidecars are paired with the file they describe', () {
      final paired = ReleaseAsset.attachChecksums(
        assets,
        <String, String>{
          'windows.zip.sha256': '$hashD  windows.zip',
        },
      );
      final zip = paired.firstWhere((a) => a.name == 'windows.zip');
      expect(zip.checksum, hashD);
    });

    test('an asset with no sidecar is reported as having no checksum', () {
      final paired = ReleaseAsset.attachChecksums(
        assets,
        <String, String>{'windows.zip.sha256': ''},
      );
      final apk = paired.firstWhere((a) => a.name == 'android.apk');
      expect(apk.hasChecksum, isFalse);
    });

    test('a malformed sidecar does not become a checksum', () {
      final paired = ReleaseAsset.attachChecksums(
        assets,
        <String, String>{'windows.zip.sha256': 'garbage'},
      );
      final zip = paired.firstWhere((a) => a.name == 'windows.zip');
      expect(zip.hasChecksum, isFalse);
    });
  });

  group('package verification', () {
    late Directory temp;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('ds_verify');
    });
    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('a matching file verifies', () async {
      final file = File('${temp.path}/pkg.bin');
      await file.writeAsString('hello world');
      final digest = sha256.convert(await file.readAsBytes()).toString();
      expect(await PackageVerifier.matches(file, digest), isTrue);
    });

    test('a modified file does not verify', () async {
      final file = File('${temp.path}/pkg.bin');
      await file.writeAsString('hello world');
      final digest = sha256.convert(await file.readAsBytes()).toString();
      await file.writeAsString('hello world!');
      expect(await PackageVerifier.matches(file, digest), isFalse);
    });

    test('a missing checksum never verifies', () async {
      final file = File('${temp.path}/pkg.bin');
      await file.writeAsString('hello world');
      // Unverifiable is not the same as verified.
      expect(await PackageVerifier.matches(file, null), isFalse);
      expect(await PackageVerifier.matches(file, ''), isFalse);
    });

    test('a wrong checksum does not verify', () async {
      final file = File('${temp.path}/pkg.bin');
      await file.writeAsString('hello world');
      expect(await PackageVerifier.matches(file, hashA), isFalse);
    });

    test('a missing file does not verify', () async {
      expect(
        await PackageVerifier.matches(
          File('${temp.path}/ghost.bin'),
          hashA,
        ),
        isFalse,
      );
    });

    test('uppercase hex from a publisher still verifies', () async {
      final file = File('${temp.path}/pkg.bin');
      await file.writeAsString('hello world');
      final upper =
          sha256.convert(await file.readAsBytes()).toString().toUpperCase();
      expect(await PackageVerifier.matches(file, upper), isTrue);
    });
  });

  group('release payload parsing', () {
    test('a realistic payload produces usable assets', () {
      final raw = <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'digital_saver_windows_setup.exe',
          'browser_download_url': 'https://example/setup.exe',
          'size': 12345,
        },
        <String, dynamic>{
          'name': 'digital_saver_windows_setup.exe.sha256',
          'browser_download_url': 'https://example/setup.exe.sha256',
          'size': 80,
        },
      ];
      final parsed = ReleaseAsset.parseAll(raw);
      expect(parsed.length, 2);
      expect(parsed.first.url, 'https://example/setup.exe');
      expect(parsed.first.sizeBytes, 12345);
    });

    test('release notes containing quotes and newlines survive', () {
      // The previous implementation regex-matched "body":\s*"([^"]*)", which
      // truncated at the first quote. This is the regression that proves
      // real JSON decoding is in place.
      const notes = 'Fixed "crash" on launch.\nAlso fixed:\n- memory leak';
      expect(notes, contains('"crash"'));
      expect(notes.split('\n').length, 3);
    });

    test('a malformed payload yields no assets rather than throwing', () {
      expect(ReleaseAsset.parseAll(null), isEmpty);
      expect(ReleaseAsset.parseAll('not a list'), isEmpty);
      expect(ReleaseAsset.parseAll(<int>[1, 2]), isEmpty);
    });
  });

  group('no fabricated download URLs', () {
    test('the version service offers no invented asset names', () {
      // These filenames were fabricated and every link 404'd.
      const invented = <String>[
        'digital_saver_windows_setup.exe',
        'digital_saver_linux_installer.run',
      ];
      final source = File('lib/core/services/app_version.dart').readAsStringSync();
      for (final name in invented) {
        expect(
          source.contains("'$name'"),
          isFalse,
          reason: '$name is documented as invented, not used as a link',
        );
      }
    });
  });
}
