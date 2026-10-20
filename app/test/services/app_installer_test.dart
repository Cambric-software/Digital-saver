/// Verification and hand-off rules for a downloaded update.
///
/// These tests use a local file and an injected launcher, so no network or
/// system dialog is involved. They pin the two failures that matter: a package
/// with no published hash is never downloaded, and a package whose bytes do not
/// match is deleted rather than offered. They also check that Android is
/// reported as a hand-off, never as a completed install.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:digital_saver/services/app_installer_service.dart';
import 'package:digital_saver/services/install_layout.dart' hide InstallOutcome;
import 'package:digital_saver/services/release_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseAsset _asset(String? checksum, {String name = 'digital_saver.apk'}) {
  return ReleaseAsset(
    name: name,
    url: 'https://example.test/$name',
    sizeBytes: 11,
    checksum: checksum,
  );
}

Future<String> _digestOf(File file) async =>
    sha256.convert(await file.readAsBytes()).toString();

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ds_installer');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('a package with no published checksum is never downloaded', () async {
    var fetched = false;
    final PackageInstaller installer = PackageInstaller(
      fetch: (ReleaseAsset asset, void Function(int, int)? progress) async {
        fetched = true;
        return null;
      },
      platform: TargetPlatform.android,
    );

    final InstallOutcome outcome = await installer.install(
      version: '1.0.4',
      asset: _asset(null),
    );

    expect(fetched, isFalse);
    expect(outcome.status, InstallStatus.failed);
    expect(outcome.message, contains('did not publish a SHA-256'));
    expect(outcome.needsUserAction, isTrue);
  });

  test('a mismatched package is deleted, not kept for later', () async {
    final File package = File('${temp.path}/downloaded.apk');
    await package.writeAsString('not the published bytes');

    final PackageInstaller installer = PackageInstaller(
      fetch: (ReleaseAsset asset, void Function(int, int)? progress) async =>
          package,
      platform: TargetPlatform.android,
      launchInstaller: (Uri uri) async =>
          fail('an unverified file must not open'),
    );

    final InstallOutcome outcome = await installer.install(
      version: '1.0.4',
      // A syntactically valid SHA-256 that is not this file's digest.
      asset: _asset(List<String>.filled(64, 'b').join()),
    );

    expect(outcome.status, InstallStatus.failed);
    expect(outcome.message, contains('did not match its published SHA-256'));
    expect(await package.exists(), isFalse);
  });

  test('a verified Android package is handed off, not called installed',
      () async {
    final File package = File('${temp.path}/digital_saver.apk');
    await package.writeAsString('verified bytes');
    final String digest = await _digestOf(package);

    Uri? opened;
    final PackageInstaller installer = PackageInstaller(
      fetch: (ReleaseAsset asset, void Function(int, int)? progress) async {
        progress?.call(11, 11);
        return package;
      },
      platform: TargetPlatform.android,
      launchInstaller: (Uri uri) async {
        opened = uri;
        return true;
      },
    );

    final InstallOutcome outcome = await installer.install(
      version: '1.0.4',
      asset: _asset(digest),
    );

    expect(outcome.status, InstallStatus.handedOff);
    expect(outcome.ok, isFalse);
    expect(outcome.handedOff, isTrue);
    expect(outcome.needsUserAction, isTrue);
    expect(opened, isNotNull);
    expect(opened!.pathSegments.last, 'digital_saver.apk');
    expect(File(opened!.toFilePath()).existsSync(), isTrue);
    expect(outcome.message, contains('has not marked it installed'));
    // The system installer may still be reading it.
    expect(await package.exists(), isTrue);
  });

  test('a failed Android launch keeps the verified file and says where it is',
      () async {
    final File package = File('${temp.path}/digital_saver.apk');
    await package.writeAsString('verified bytes');
    final String digest = await _digestOf(package);

    final PackageInstaller installer = PackageInstaller(
      fetch: (ReleaseAsset asset, void Function(int, int)? progress) async =>
          package,
      platform: TargetPlatform.android,
      launchInstaller: (Uri uri) async => false,
    );

    final InstallOutcome outcome = await installer.install(
      version: '1.0.4',
      asset: _asset(digest),
    );

    expect(outcome.status, InstallStatus.failed);
    expect(outcome.message, contains('verified file is at ${package.path}'));
    expect(await package.exists(), isTrue);
  });

  test('an unversioned desktop install refuses rather than unpacking',
      () async {
    final File package = File('${temp.path}/windows.zip');
    await package.writeAsString('verified bytes');
    final String digest = await _digestOf(package);

    final InstallLayout flat = InstallLayout.detect(
      executablePath: '${temp.path}/Digital Saver/digital_saver.exe',
    );
    expect(flat.isVersioned, isFalse);

    final PackageInstaller installer = PackageInstaller(
      fetch: (ReleaseAsset asset, void Function(int, int)? progress) async =>
          package,
      platform: TargetPlatform.windows,
      layout: () => flat,
    );

    final InstallOutcome outcome = await installer.install(
      version: '1.0.4',
      asset: _asset(digest, name: 'windows.zip'),
    );

    expect(outcome.status, InstallStatus.failed);
    expect(
        outcome.message, contains('not installed with the setup executable'));
    expect(outcome.needsUserAction, isTrue);
    // Desktop extraction did not happen, so the download copy is disposable.
    expect(await package.exists(), isFalse);
  });

  test('an empty version is rejected before anything is fetched', () async {
    final PackageInstaller installer = PackageInstaller(
      fetch: (ReleaseAsset asset, void Function(int, int)? progress) async =>
          fail('nothing should be fetched without a version'),
      platform: TargetPlatform.android,
    );

    final InstallOutcome outcome = await installer.install(
      version: '  ',
      asset: _asset(List<String>.filled(64, 'a').join()),
    );

    expect(outcome.status, InstallStatus.failed);
    expect(outcome.message, contains('No version'));
  });
}
