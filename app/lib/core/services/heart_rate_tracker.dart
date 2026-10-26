import 'package:flutter/foundation.dart';

/// Tracks heart rate min / max over the current connected session and over
/// the full app lifetime using loaded LocalStore history.
///
/// The BleService calls [record] every time a live HR sample arrives.
/// HeartScreen reads [sessionMin] and [sessionMax] instead of the fake
/// multiplier approximations that were there before.
class HeartRateTracker extends ChangeNotifier {
  int _sessionMin = 0;
  int _sessionMax = 0;
  int _historyMin = 0;
  int _historyMax = 0;

  // Getters expose 0 when no data has arrived yet so callers can show '--'.
  int get sessionMin => _sessionMin;
  int get sessionMax => _sessionMax;

  /// Overall min from loaded history (if supplied via [seedFromHistory]).
  int get historyMin => _historyMin;

  /// Overall max from loaded history (if supplied via [seedFromHistory]).
  int get historyMax => _historyMax;

  /// Best combined min / max: prefers history if available, falls back to session.
  int get bestMin => _historyMin > 0 ? _historyMin : _sessionMin;
  int get bestMax => _historyMax > 0 ? _historyMax : _sessionMax;

  /// Reset session counters when the watch disconnects.
  void resetSession() {
    _sessionMin = 0;
    _sessionMax = 0;
    notifyListeners();
  }

  /// Called by BleService every time a live HR value arrives.
  void record(int bpm) {
    if (bpm < 30 || bpm > 250) return; // sanity-reject noise
    bool changed = false;
    if (_sessionMin == 0 || bpm < _sessionMin) {
      _sessionMin = bpm;
      changed = true;
    }
    if (bpm > _sessionMax) {
      _sessionMax = bpm;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Seed min / max from a list of historical HR values (e.g. LocalStore samples).
  void seedFromHistory(Iterable<int> hrValues) {
    final valid = hrValues.where((v) => v >= 30 && v <= 250);
    if (valid.isEmpty) return;
    int mn = valid.reduce((a, b) => a < b ? a : b);
    int mx = valid.reduce((a, b) => a > b ? a : b);
    bool changed = false;
    if (mn != _historyMin) { _historyMin = mn; changed = true; }
    if (mx != _historyMax) { _historyMax = mx; changed = true; }
    if (changed) notifyListeners();
  }
}
