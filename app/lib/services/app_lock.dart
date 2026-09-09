import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Optional 6-digit app lock. Hash only is stored. No accounts.
class AppLock extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();
  static const _hashKey = 'veyro_lock_hash';
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

  String _hash(String pin) => sha256.convert(utf8.encode('veyro|$pin')).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hashKey, _hash(pin));
    hasLock = true;
    unlocked = true;
    notifyListeners();
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
    unlocked = hash == _hash(pin);
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
