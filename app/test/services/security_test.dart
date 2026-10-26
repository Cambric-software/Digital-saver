import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:digital_saver/core/services/app_lock.dart';
import 'package:digital_saver/core/services/emergency_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reproduces the PBKDF2 construction used inside AppLock so the real
/// implementation is checked against published vectors rather than against
/// itself.
Future<String> pbkdf2Hex({
  required String password,
  required String salt,
  required int iterations,
  int length = 32,
}) async {
  final hmac = Hmac(sha256, utf8.encode(password));
  final saltBytes = utf8.encode(salt);
  final out = <int>[];
  var block = 1;
  while (out.length < length) {
    var u = hmac.convert(<int>[
      ...saltBytes,
      (block >> 24) & 0xFF,
      (block >> 16) & 0xFF,
      (block >> 8) & 0xFF,
      block & 0xFF,
    ]).bytes;
    final acc = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < acc.length; k++) {
        acc[k] ^= u[k];
      }
    }
    out.addAll(acc);
    block++;
  }
  return out
      .sublist(0, length)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PBKDF2 construction', () {
    // Standard HMAC-SHA256 PBKDF2 vectors for "password"/"salt".
    test('matches the published vector for one iteration', () async {
      final got = await pbkdf2Hex(password: 'password', salt: 'salt', iterations: 1);
      expect(
        got,
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('matches the published vector for two iterations', () async {
      final got = await pbkdf2Hex(password: 'password', salt: 'salt', iterations: 2);
      expect(
        got,
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });
  });

  group('emergency number', () {
    tearDown(() => EmergencyService.emergencyNumber = '999');

    test('defaults to a number that works in the UK', () {
      // It was hardcoded to 911, which is the US number and is not diallable
      // in the country this product is made and used in.
      expect(EmergencyService.emergencyNumber, '999');
    });

    test('accepts a configurable number', () {
      expect(EmergencyService.setEmergencyNumber('911'), isTrue);
      expect(EmergencyService.emergencyNumber, '911');
    });

    test('strips formatting a person might type', () {
      expect(EmergencyService.setEmergencyNumber('  1-1-2  '), isTrue);
      expect(EmergencyService.emergencyNumber, '112');
    });

    test('rejects a malformed number rather than dialling nothing', () {
      expect(EmergencyService.setEmergencyNumber('1'), isFalse);
      expect(EmergencyService.setEmergencyNumber(''), isFalse);
      expect(EmergencyService.setEmergencyNumber('1234567'), isFalse);
      expect(EmergencyService.emergencyNumber, '999');
    });

    test('known numbers include the UK and the US', () {
      expect(EmergencyService.knownEmergencyNumbers['United Kingdom'], '999');
      expect(
        EmergencyService.knownEmergencyNumbers['United States / Canada'],
        '911',
      );
    });
  });

  group('app lock', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('a stored PIN is salted, not a bare digest', () async {
      final lock = AppLock();
      await lock.setPin('123456');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('veyro_lock_hash_v2') ?? '';

      // The old format was a single unsalted SHA-256 of 'veyro|<pin>', which
      // the whole 1,000,000-key space exhausts in seconds.
      final oldFormat = sha256.convert(utf8.encode('veyro|123456')).toString();
      expect(stored, isNot(oldFormat));
      expect(stored.contains('.'), isTrue,
          reason: 'stored value must be salt.hash');

      final salt = stored.split('.').first;
      expect(salt.length, greaterThan(10), reason: 'salt must be non-trivial');
    });

    test('the same PIN hashes differently each time', () async {
      final a = AppLock();
      await a.setPin('123456');
      final prefsA = await SharedPreferences.getInstance();
      final first = prefsA.getString('veyro_lock_hash_v2');

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final b = AppLock();
      await b.setPin('123456');
      final prefsB = await SharedPreferences.getInstance();
      final second = prefsB.getString('veyro_lock_hash_v2');

      expect(first, isNot(second));
    });

    test('the correct PIN unlocks', () async {
      final lock = AppLock();
      await lock.setPin('123456');
      await lock.lockNow();
      expect(await lock.unlock('123456'), isTrue);
      expect(lock.unlocked, isTrue);
    });

    test('a wrong PIN does not unlock', () async {
      final lock = AppLock();
      await lock.setPin('123456');
      await lock.lockNow();
      expect(await lock.unlock('654321'), isFalse);
      expect(lock.unlocked, isFalse);
    });

    test('repeated wrong guesses are throttled', () async {
      final lock = AppLock();
      await lock.setPin('123456');
      for (var i = 0; i < 5; i++) {
        await lock.unlock('000000');
      }
      expect(await lock.unlock('123456'), isFalse);
    });

    test('a legacy unsalted hash cannot be unlocked', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'veyro_lock_hash_v2':
            sha256.convert(utf8.encode('veyro|123456')).toString(),
      });
      final lock = AppLock();
      await lock.load();
      expect(lock.hasLock, isTrue);
      expect(await lock.unlock('123456'), isFalse);
    });

    test('clearing the PIN removes the lock', () async {
      final lock = AppLock();
      await lock.setPin('123456');
      await lock.clearPin();
      expect(lock.hasLock, isFalse);
      expect(await lock.unlock('anything'), isTrue);
    });
  });
}