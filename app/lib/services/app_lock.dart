import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Optional 6-digit app lock. Hash only is stored. No accounts.
class AppLock extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _hashKey = 'veyro_lock_hash';
  static const _pairKey = 'veyro_watch_pin';

  bool ready = false;
  bool hasLock = false;
  bool unlocked = true;

  Future<void> load() async {
    if (kIsWeb) {
      ready = true;
      notifyListeners();
      return;
    }
    final hash = await _storage.read(key: _hashKey);
    hasLock = hash != null && hash.isNotEmpty;
    unlocked = !hasLock;
    ready = true;
    notifyListeners();
  }

  String _hash(String pin) => sha256.convert(utf8.encode('veyro|$pin')).toString();

  Future<void> setPin(String pin) async {
    await _storage.write(key: _hashKey, value: _hash(pin));
    hasLock = true;
    unlocked = true;
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _hashKey);
    hasLock = false;
    unlocked = true;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final hash = await _storage.read(key: _hashKey);
    if (hash == null) {
      unlocked = true;
      notifyListeners();
      return true;
    }
    unlocked = hash == _hash(pin);
    notifyListeners();
    return unlocked;
  }

  Future<void> lockNow() async {
    if (hasLock) {
      unlocked = false;
      notifyListeners();
    }
  }

  Future<void> saveWatchPin(String pin) => _storage.write(key: _pairKey, value: pin);

  Future<String?> watchPin() => _storage.read(key: _pairKey);
}
