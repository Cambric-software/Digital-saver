/// The one owner of the small numbers the habit screens keep from day to day.
///
/// Hydration glasses, coffees, movement breaks, mood, energy and the start of a
/// fast were all `setState` fields on the tool screens: the number was real
/// while the screen was open and gone the moment it was closed. The few that
/// were written down used one global `shared_preferences` key each, so
/// yesterday's glasses were still in the count this morning, and no file could
/// say what the keys meant or what their defaults were.
///
/// Here every daily value is keyed by the local day (`yyyy-mm-dd`) and stored
/// as a single JSON object per day. A corrupt or half-written value reads as
/// "nothing logged" rather than throwing, because a tracker that fails to open
/// is worse than one that honestly shows zero. Walking stride and the chosen
/// fasting plan are preferences rather than daily values, so they live outside
/// the day keys; they are still owned here so nobody invents a second key.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Typed access to the daily counters and short entries the tools record.
abstract final class DailyLog {
  /// Glasses of water logged today. One glass is 250 ml by convention in the
  /// wellness screen, which is the only place that converts it.
  static const String hydrationGlasses = 'hydration_glasses';

  /// Coffees and teas logged today.
  static const String coffees = 'coffees';

  /// When the last coffee or tea was logged.
  static const String lastCoffee = 'last_coffee';

  /// Movement breaks counted today, from countdowns that actually finished.
  static const String breaks = 'breaks';

  /// How the person said they felt today, e.g. `Good`.
  static const String mood = 'mood';

  /// Energy today, 1 to 10.
  static const String energy = 'energy';

  /// Optional words the person attached to today's mood.
  static const String moodTags = 'mood_tags';

  /// When the current fast started. Absent means no fast is running.
  static const String fastingStart = 'fasting_start';

  static const String _dayPrefix = 'daily_log_';
  static const String _settingPrefix = 'daily_log_setting_';
  static const String _strideKey = 'stride_cm';
  static const String _planKey = 'fasting_plan';

  static const String _counters = 'counters';
  static const String _entries = 'entries';
  static const String _times = 'times';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  /// A counter for today. Anything unreadable is zero.
  static Future<int> counter(String key, {DateTime? now}) async {
    final Map<String, Object?> day = await _loadDay(now);
    return _asCounter(_section(day, _counters)[key]);
  }

  /// Store a counter for today. Negative values are stored as zero.
  static Future<void> setCounter(
    String key,
    int value, {
    DateTime? now,
  }) {
    return _update(now, (Map<String, Object?> day) {
      final Map<String, Object?> counters = _section(day, _counters);
      counters[key] = value < 0 ? 0 : value;
      day[_counters] = counters;
    });
  }

  /// A short entry for today, or null when nothing was written.
  static Future<String?> entry(String key, {DateTime? now}) async {
    final Map<String, Object?> day = await _loadDay(now);
    final Object? raw = _section(day, _entries)[key];
    if (raw is! String || raw.trim().isEmpty) return null;
    return raw;
  }

  /// Store a short entry for today. An empty value removes it.
  static Future<void> setEntry(
    String key,
    String? value, {
    DateTime? now,
  }) {
    return _update(now, (Map<String, Object?> day) {
      final Map<String, Object?> entries = _section(day, _entries);
      final String trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) {
        entries.remove(key);
      } else {
        entries[key] = trimmed;
      }
      day[_entries] = entries;
    });
  }

  /// A timestamp stored against today, or null when nothing was recorded.
  static Future<DateTime?> time(String key, {DateTime? now}) async {
    final Map<String, Object?> day = await _loadDay(now);
    final Object? raw = _section(day, _times)[key];
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  /// Store a timestamp for today. Null removes it.
  static Future<void> setTime(
    String key,
    DateTime? value, {
    DateTime? now,
  }) {
    return _update(now, (Map<String, Object?> day) {
      final Map<String, Object?> times = _section(day, _times);
      if (value == null) {
        times.remove(key);
      } else {
        times[key] = value.toIso8601String();
      }
      day[_times] = times;
    });
  }

  /// The walking stride in centimetres, or null when it has not been set.
  ///
  /// Values outside a plausible adult range are treated as corrupt rather than
  /// used to produce a distance that is wrong by a factor of ten.
  static Future<double?> strideCm() async {
    final String? raw =
        (await _prefs).getString('$_settingPrefix$_strideKey');
    final double? value = raw == null ? null : double.tryParse(raw);
    if (value == null || value < 30 || value > 160) return null;
    return value;
  }

  /// Store the walking stride, or clear it with null.
  static Future<void> setStrideCm(double? value) async {
    final SharedPreferences prefs = await _prefs;
    const String key = '$_settingPrefix$_strideKey';
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.toStringAsFixed(1));
  }

  /// The fasting plan last chosen, e.g. `16:8`. Null when never chosen.
  static Future<String?> fastingPlan() async {
    final String? value =
        (await _prefs).getString('$_settingPrefix$_planKey');
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  /// Store the chosen fasting plan, or clear it with null.
  static Future<void> setFastingPlan(String? value) async {
    final SharedPreferences prefs = await _prefs;
    const String key = '$_settingPrefix$_planKey';
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, trimmed);
  }

  /// Forget one day. Other days are untouched.
  static Future<void> clearDay({DateTime? now}) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_storageKey(now ?? DateTime.now()));
  }

  /// Forget every day and every preference this class owns.
  static Future<void> clear() async {
    final SharedPreferences prefs = await _prefs;
    for (final String key in prefs.getKeys().toList()) {
      if (key.startsWith(_dayPrefix) || key.startsWith(_settingPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Read-modify-write one day, and drop the key once the day is empty so a
  /// cleared day does not leave an empty object behind forever.
  static Future<void> _update(
    DateTime? now,
    void Function(Map<String, Object?> day) change,
  ) async {
    final DateTime day = now ?? DateTime.now();
    final String storageKey = _storageKey(day);
    final Map<String, Object?> value = await _read(storageKey);
    change(value);
    final SharedPreferences prefs = await _prefs;
    final bool empty = _section(value, _counters).isEmpty &&
        _section(value, _entries).isEmpty &&
        _section(value, _times).isEmpty;
    if (empty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(storageKey, jsonEncode(value));
  }

  static Future<Map<String, Object?>> _loadDay(DateTime? now) =>
      _read(_storageKey(now ?? DateTime.now()));

  static Future<Map<String, Object?>> _read(String storageKey) async {
    final String? raw = (await _prefs).getString(storageKey);
    if (raw == null || raw.isEmpty) return <String, Object?>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Object?>{};
      final Map<String, Object?> value = <String, Object?>{};
      decoded.forEach((Object? key, Object? item) {
        if (key is String) value[key] = item;
      });
      return value;
    } on FormatException {
      return <String, Object?>{};
    }
  }

  static Map<String, Object?> _section(
    Map<String, Object?> day,
    String name,
  ) {
    final Object? raw = day[name];
    if (raw is! Map) return <String, Object?>{};
    final Map<String, Object?> value = <String, Object?>{};
    raw.forEach((Object? key, Object? item) {
      if (key is String) value[key] = item;
    });
    return value;
  }

  static int _asCounter(Object? raw) {
    final int value;
    if (raw is int) {
      value = raw;
    } else if (raw is double && raw.isFinite) {
      value = raw.round();
    } else {
      return 0;
    }
    return value < 0 ? 0 : value;
  }

  static String _storageKey(DateTime date) => '$_dayPrefix${_dayKey(date)}';

  static String _dayKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
