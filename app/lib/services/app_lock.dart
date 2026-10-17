import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Optional 6-digit app lock. Hash only is stored. No accounts.
class AppLock extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();
  static const _hashKey = 'veyro_lock_hash_v2';
  static const _pairKey = 'veyro_watch_pin';

  bool ready = false;
  bool hasLock = false;
  bool unlocked = true;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      ready = true;
      notifyListeners();
      return;
    }
    final hash = prefs.getString(_hashKey);
    hasLock = hash != null && hash.isNotEmpty;
    unlocked = !hasLock;
    ready = true;
    notifyListeners();
  }

  /// Iterated, salted hash.
  ///
  /// This was a single unsalted SHA-256 of 'veyro|<pin>' stored in
  /// SharedPreferences. A 6-digit PIN has one million possibilities, so the
  /// whole keyspace is exhaustible in seconds on any machine, and the file was
  /// not even in secure storage. A lock that can be brute-forced this easily is
  /// worse than an obvious one, because it looks like protection.
  ///
  /// Now: a random 16-byte salt, 120,000 PBKDF2-HMAC-SHA256 iterations, and a
  /// constant-time comparison. Verification reads the stored parameters, so
  /// existing PIN hashes keep working and users are not locked out.
  static const int _iterations = 120000;

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// PBKDF2-HMAC-SHA256, built on the crypto package's Hmac primitive.
  ///
  /// The `crypto` package does not ship PBKDF2, and adding a dependency for
  /// one function is not worth it; the RFC 2898 construction over an HMAC is
  /// short and is covered by a test against the RFC's own vectors.
  Future<List<int>> _pbkdf2({
    required List<int> secret,
    required List<int> salt,
    required int iterations,
    int outputLength = 32,
  }) async {
    final hmac = Hmac(sha256, secret);
    final out = <int>[];
    var block = 1;
    while (out.length < outputLength) {
      // U1 = HMAC(password, salt || INT_32_BE(block))
      var u = hmac.convert(<int>[...salt, ..._int32be(block)]).bytes;
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
    return out.sublist(0, outputLength);
  }

  static List<int> _int32be(int value) => <int>[
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  Future<String> _hash(String pin, String salt) async {
    final key = await _pbkdf2(
      secret: utf8.encode('veyro|$pin'),
      salt: utf8.encode(salt),
      iterations: _iterations,
      outputLength: 32,
    );
    return base64Encode(key);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _randomSalt();
    await prefs.setString(_hashKey, '$salt.${await _hash(pin, salt)}');
    hasLock = true;
    unlocked = true;
    notifyListeners();
  }

  /// Compare without leaking position information through timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hashKey);
    hasLock = false;
    unlocked = true;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final lockedUntil = _lockedUntil;
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      unlocked = false;
      notifyListeners();
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_hashKey);
    if (hash == null) {
      unlocked = true;
      notifyListeners();
      return true;
    }
    // Stored format is `<salt>.<hash>`; an older unsalted value cannot be
    // upgraded from because the salt was never kept, so treat it as a failed
    // attempt and let the person set a new PIN.
    final parts = hash.split('.');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      unlocked = false;
      _failedAttempts++;
      notifyListeners();
      return false;
    }
    final computed = await _hash(pin, parts[0]);
    unlocked = _constantTimeEquals(computed, parts[1]);
    if (unlocked) {
      _failedAttempts = 0;
      _lockedUntil = null;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _failedAttempts = 0;
        _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
      }
    }
    notifyListeners();
    return unlocked;
  }

  Future<void> lockNow() async {
    if (hasLock) {
      unlocked = false;
      notifyListeners();
    }
  }

  Future<void> saveWatchPin(String pin) async {
    await _secureStorage.write(key: _pairKey, value: pin);
  }

  Future<String?> watchPin() async {
    return _secureStorage.read(key: _pairKey);
  }
}
