/// The one owner of the app's stored preferences and personal records.
///
/// This file used to hold a second copy of profile and emergency-contact
/// storage, duplicating [LocalStore], and nothing imported it. The real gap was
/// somewhere else: every switch, threshold, watch face and quick reply was read
/// and written through shared_preferences by hand, at two places per key, with
/// the default written out twice.
///
/// That is how a setting silently stops working. `_load` reads
/// `prefs.getBool('demo_mode') ?? false` and `_saveSettings` writes
/// `prefs.setBool('demo_mode', _demoMode)`. A typo in either string, or a
/// changed default in only one of them, produces a switch that appears to save
/// and reverts on the next open. The key and its default now exist once, here,
/// and both sides of the app go through them.
///
/// Profile and emergency contacts deliberately stay in [LocalStore]: one owner
/// per key, not two.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A dated entry in the reflection log.
class Reflection {
  /// Create an entry.
  const Reflection({required this.date, required this.text});

  /// Day the entry belongs to, as `yyyy-mm-dd`.
  final String date;

  /// What was written.
  final String text;

  /// Read from stored JSON, tolerating anything unexpected.
  static Reflection? fromJson(Object? value) {
    if (value is! Map) return null;
    final Object? date = value['date'];
    final Object? text = value['text'];
    if (date is! String || text is! String) return null;
    return Reflection(date: date, text: text);
  }

  /// Write as stored JSON.
  Map<String, Object> toJson() => <String, Object>{'date': date, 'text': text};
}

/// A medication or supplement the person keeps on their own list.
///
/// Just a name and an optional dose. There is no schedule, no reminder and no
/// interval: the watch has no alarm API, and the phone app does not send
/// notifications from this list.
class Medication {
  /// Create an entry.
  const Medication({required this.name, this.dose = ''});

  /// What it is, e.g. `Vitamin D3`.
  final String name;

  /// Strength or note, e.g. `2000 IU`. May be empty.
  final String dose;

  /// Read from stored JSON, or null when the object is not a usable entry.
  static Medication? fromJson(Object? value) {
    if (value is! Map) return null;
    final Object? name = value['name'];
    final Object? dose = value['dose'];
    if (name is! String || name.trim().isEmpty) return null;
    return Medication(
      name: name.trim(),
      dose: dose is String ? dose.trim() : '',
    );
  }

  /// Write as stored JSON.
  Map<String, Object> toJson() =>
      <String, Object>{'name': name, 'dose': dose};
}

/// Typed access to stored settings and records.
abstract final class StorageService {
  /// The most reflection entries kept. Older ones are dropped rather than
  /// letting one key grow without limit.
  static const int maxReflections = 30;

  static const String _keyDemoMode = 'demo_mode';
  static const String _keyWatchFace = 'selected_watch_face';
  static const String _keyAutoSync = 'auto_sync_history';
  static const String _keyHighHr = 'high_hr_threshold';
  static const String _keyLowSpo2 = 'low_spo2_threshold';
  static const String _keyComplicationTop = 'complication_top';
  static const String _keyComplicationBottom = 'complication_bottom';
  static const String _keyQuickReplies = 'quick_replies';
  static const String _keyReflections = 'reflections';
  static const String _keyBreathHoldBest = 'breath_hold_best_seconds';
  static const String _keyMedications = 'medications';

  /// The defaults, in one place, so load and save cannot disagree.
  static const bool defaultDemoMode = false;
  static const int defaultWatchFace = 0;
  static const bool defaultAutoSyncHistory = true;
  static const double defaultHighHrThreshold = 120;
  static const double defaultLowSpo2Threshold = 90;
  static const String defaultComplicationTop = 'Steps';
  static const String defaultComplicationBottom = 'Heart Rate';
  static const List<String> defaultQuickReplies = <String>[
    'In a meeting, call you later.',
    'On my way!',
    "Can't talk right now.",
    'Got it, thanks!',
  ];
  static const int defaultBreathHoldBest = 0;
  static const List<Medication> defaultMedications = <Medication>[];

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  /// Whether the app shows sample readings instead of live ones.
  static Future<bool> demoMode() async =>
      (await _prefs).getBool(_keyDemoMode) ?? defaultDemoMode;

  /// Store the demo-mode choice.
  static Future<void> setDemoMode(bool value) async =>
      (await _prefs).setBool(_keyDemoMode, value);

  /// The watch face index currently chosen.
  static Future<int> watchFace() async =>
      (await _prefs).getInt(_keyWatchFace) ?? defaultWatchFace;

  /// Store the chosen watch face.
  static Future<void> setWatchFace(int value) async =>
      (await _prefs).setInt(_keyWatchFace, value);

  /// Whether history syncs on connect.
  static Future<bool> autoSyncHistory() async =>
      (await _prefs).getBool(_keyAutoSync) ?? defaultAutoSyncHistory;

  /// Store the history-sync choice.
  static Future<void> setAutoSyncHistory(bool value) async =>
      (await _prefs).setBool(_keyAutoSync, value);

  /// Heart rate at or above which a reading is flagged.
  static Future<double> highHrThreshold() async =>
      (await _prefs).getDouble(_keyHighHr) ?? defaultHighHrThreshold;

  /// Store the high heart-rate threshold.
  static Future<void> setHighHrThreshold(double value) async =>
      (await _prefs).setDouble(_keyHighHr, value);

  /// Oxygen saturation at or below which a reading is flagged.
  static Future<double> lowSpo2Threshold() async =>
      (await _prefs).getDouble(_keyLowSpo2) ?? defaultLowSpo2Threshold;

  /// Store the low-oxygen threshold.
  static Future<void> setLowSpo2Threshold(double value) async =>
      (await _prefs).setDouble(_keyLowSpo2, value);

  /// Which reading the watch shows in its top complication slot.
  static Future<String> complicationTop() async =>
      (await _prefs).getString(_keyComplicationTop) ?? defaultComplicationTop;

  /// Store the top complication.
  static Future<void> setComplicationTop(String value) async =>
      (await _prefs).setString(_keyComplicationTop, value);

  /// Which reading the watch shows in its bottom complication slot.
  static Future<String> complicationBottom() async =>
      (await _prefs).getString(_keyComplicationBottom) ??
      defaultComplicationBottom;

  /// Store the bottom complication.
  static Future<void> setComplicationBottom(String value) async =>
      (await _prefs).setString(_keyComplicationBottom, value);

  /// The quick replies offered when answering from the watch.
  ///
  /// An empty stored list is treated as "not set", because an empty list means
  /// the person deleted every reply and would then have no way to add one back.
  static Future<List<String>> quickReplies() async {
    final List<String>? stored = (await _prefs).getStringList(_keyQuickReplies);
    if (stored == null || stored.isEmpty) {
      return List<String>.of(defaultQuickReplies);
    }
    return stored;
  }

  /// Store the quick replies.
  static Future<void> setQuickReplies(List<String> value) async =>
      (await _prefs).setStringList(_keyQuickReplies, value);

  /// The reflection log, newest first.
  ///
  /// Anything unreadable is skipped rather than thrown away wholesale: one
  /// corrupt entry should not lose the rest of the log.
  static Future<List<Reflection>> reflections() async {
    final String? raw = (await _prefs).getString(_keyReflections);
    if (raw == null) return <Reflection>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <Reflection>[];
      return decoded
          .map(Reflection.fromJson)
          .whereType<Reflection>()
          .toList(growable: false);
    } on FormatException {
      return <Reflection>[];
    }
  }

  /// Add or replace today's reflection.
  ///
  /// Writing twice on the same day replaces the entry rather than appending a
  /// second one, so the log reads as one line per day.
  static Future<void> saveReflection(String text, {DateTime? now}) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final String day = _dayKey(now ?? DateTime.now());
    final List<Reflection> existing = await reflections();
    final List<Reflection> next = <Reflection>[
      Reflection(date: day, text: trimmed),
      ...existing.where((Reflection entry) => entry.date != day),
    ];
    await (await _prefs).setString(
      _keyReflections,
      jsonEncode(
        next
            .take(maxReflections)
            .map((Reflection entry) => entry.toJson())
            .toList(),
      ),
    );
  }

  /// Today's reflection, or null when nothing was written.
  static Future<Reflection?> todayReflection({DateTime? now}) async {
    final String day = _dayKey(now ?? DateTime.now());
    for (final Reflection entry in await reflections()) {
      if (entry.date == day) return entry;
    }
    return null;
  }

  /// The longest breath hold recorded, in seconds.
  ///
  /// Zero means nothing has been recorded, which is not the same as a hold of
  /// zero seconds, so callers show `--` rather than a number.
  static Future<int> breathHoldBest() async =>
      (await _prefs).getInt(_keyBreathHoldBest) ?? defaultBreathHoldBest;

  /// Record a breath hold, keeping it only if it beats the stored best.
  ///
  /// Returns the best after the attempt, so the caller can say whether it stood.
  static Future<int> recordBreathHold(int seconds) async {
    final int best = await breathHoldBest();
    if (seconds > best) {
      await (await _prefs).setInt(_keyBreathHoldBest, seconds);
      return seconds;
    }
    return best;
  }

  /// The medication and supplement list, in the order the person arranged it.
  ///
  /// The list starts empty. The previous screen opened with three named
  /// products already in it, so the list read as a schedule the app had
  /// somehow established rather than one the person had written.
  ///
  /// Entries that cannot be read are skipped rather than discarding the whole
  /// list, for the same reason the reflection log does it: one bad entry should
  /// not erase the others.
  static Future<List<Medication>> medications() async {
    final String? raw = (await _prefs).getString(_keyMedications);
    if (raw == null) return <Medication>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <Medication>[];
      return decoded
          .map(Medication.fromJson)
          .whereType<Medication>()
          .toList(growable: false);
    } on FormatException {
      return <Medication>[];
    }
  }

  /// Replace the medication and supplement list.
  static Future<void> setMedications(List<Medication> value) async {
    await (await _prefs).setString(
      _keyMedications,
      jsonEncode(
        value.map((Medication entry) => entry.toJson()).toList(),
      ),
    );
  }

  /// Forgets everything this service stores. Used by tests and by a factory
  /// reset; the profile and contacts in [LocalStore] are untouched.
  static Future<void> clear() async {
    final SharedPreferences prefs = await _prefs;
    for (final String key in <String>[
      _keyDemoMode,
      _keyWatchFace,
      _keyAutoSync,
      _keyHighHr,
      _keyLowSpo2,
      _keyComplicationTop,
      _keyComplicationBottom,
      _keyQuickReplies,
      _keyReflections,
      _keyBreathHoldBest,
      _keyMedications,
    ]) {
      await prefs.remove(key);
    }
  }

  static String _dayKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
