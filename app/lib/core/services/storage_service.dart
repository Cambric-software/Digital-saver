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

import '../models/medication.dart';
import '../models/reminder.dart';

// Existing screens import `storage_service.dart` to reach [Medication]. Keeping
// the export here means those imports do not have to change while the model
// itself lives with the other pure models.
export '../models/medication.dart';

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

/// Typed access to stored settings and records.
abstract final class StorageService {
  /// The most reflection entries kept. Older ones are dropped rather than
  /// letting one key grow without limit.
  static const int maxReflections = 30;

  static const String _keyDemoMode = 'demo_mode';
  static const String _keyWatchFace = 'selected_watch_face';
  static const String _keyWatchTheme = 'selected_watch_theme';
  static const String _keyWatchBrightness = 'watch_brightness_pct';
  static const String _keyAutoSync = 'auto_sync_history';
  static const String _keyHighHr = 'high_hr_threshold';
  static const String _keyLowSpo2 = 'low_spo2_threshold';
  static const String _keyComplicationTop = 'complication_top';
  static const String _keyComplicationBottom = 'complication_bottom';
  static const String _keyQuickReplies = 'quick_replies';
  static const String _keyReflections = 'reflections';
  static const String _keyBreathHoldBest = 'breath_hold_best_seconds';
  static const String _keyMedications = 'medications';
  static const String _keyDimAfterDark = 'dim_after_dark';
  static const String _keyReminders = 'reminders';
  static const String _keyScheduledIds = 'scheduled_notification_ids';
  static const String _keyHydrationGoal = 'hydration_goal_glasses';
  static const String _keyGlassMl = 'hydration_glass_ml';

  /// The defaults, in one place, so load and save cannot disagree.
  static const bool defaultDemoMode = false;
  static const int defaultWatchFace = 0;
  static const int defaultWatchTheme = 0;

  /// Matches the firmware's power-on backlight level.
  static const int defaultWatchBrightness = 60;
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
  static const bool defaultDimAfterDark = false;
  static const List<Reminder> defaultReminders = <Reminder>[];
  static const int defaultHydrationGoal = 8;
  static const int defaultGlassMl = 250;
  static const int minHydrationGoal = 1;
  static const int maxHydrationGoal = 30;
  static const int minGlassMl = 100;
  static const int maxGlassMl = 1000;

  /// The glass sizes the wellness screen offers.
  ///
  /// Storage accepts the wider [minGlassMl]..[maxGlassMl] range so an older or
  /// hand-edited value is not thrown away; the screen adds the stored value to
  /// this list when it builds the menu, so a value outside the common sizes is
  /// still selectable rather than an assertion failure.
  static const List<int> glassSizes = <int>[
    150,
    200,
    250,
    300,
    350,
    400,
    500,
  ];

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

  /// The watch colour theme index currently chosen.
  static Future<int> watchTheme() async =>
      (await _prefs).getInt(_keyWatchTheme) ?? defaultWatchTheme;

  /// Store the chosen watch colour theme.
  static Future<void> setWatchTheme(int value) async =>
      (await _prefs).setInt(_keyWatchTheme, value);

  /// The watch backlight percentage currently chosen (1-100).
  static Future<int> watchBrightness() async =>
      (await _prefs).getInt(_keyWatchBrightness) ?? defaultWatchBrightness;

  /// Store the chosen watch backlight percentage.
  static Future<void> setWatchBrightness(int value) async =>
      (await _prefs).setInt(_keyWatchBrightness, value);

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
  ///
  /// Entries written before ids existed are given a deterministic id here, so a
  /// dose already ticked off today stays linked to the same medication after the
  /// app restarts. Duplicate ids are made unique in list order.
  static Future<List<Medication>> medications() async {
    final String? raw = (await _prefs).getString(_keyMedications);
    if (raw == null) return <Medication>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <Medication>[];
      final List<Medication> out = <Medication>[];
      final Set<String> seen = <String>{};
      for (int index = 0; index < decoded.length; index++) {
        final Medication? entry =
            Medication.fromJson(decoded[index], index: index);
        if (entry == null) continue;
        String id = entry.id;
        if (id.isEmpty || seen.contains(id)) {
          id = Medication.legacyId(entry.name, entry.dose, index);
          while (seen.contains(id)) {
            id = '${id}_';
          }
        }
        seen.add(id);
        out.add(entry.copyWith(id: id));
      }
      return List<Medication>.unmodifiable(out);
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

  /// The alarms and reminders the person set, in the order they were added.
  ///
  /// Unreadable entries are skipped for the same reason as the medication list:
  /// one bad object must not erase every alarm.
  static Future<List<Reminder>> reminders() async {
    final String? raw = (await _prefs).getString(_keyReminders);
    if (raw == null) return <Reminder>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <Reminder>[];
      final List<Reminder> out = <Reminder>[];
      final Set<String> seen = <String>{};
      for (final Object? item in decoded) {
        final Reminder? entry = Reminder.fromJson(item);
        if (entry == null || seen.contains(entry.id)) continue;
        seen.add(entry.id);
        out.add(entry);
      }
      return List<Reminder>.unmodifiable(out);
    } on FormatException {
      return <Reminder>[];
    }
  }

  /// Replace the alarm and reminder list.
  static Future<void> setReminders(List<Reminder> value) async {
    await (await _prefs).setString(
      _keyReminders,
      jsonEncode(value.map((Reminder entry) => entry.toJson()).toList()),
    );
  }

  /// The notification ids this app last scheduled.
  ///
  /// Kept so a resync cancels exactly what it created instead of calling
  /// `cancelAll`, which would also dismiss reminders the person has not read.
  static Future<List<int>> scheduledNotificationIds() async {
    final List<String>? stored = (await _prefs).getStringList(_keyScheduledIds);
    if (stored == null) return <int>[];
    return stored.map(int.tryParse).whereType<int>().toList(growable: false);
  }

  /// Store the notification ids currently scheduled.
  static Future<void> setScheduledNotificationIds(List<int> value) async {
    await (await _prefs).setStringList(
      _keyScheduledIds,
      value.map((int id) => id.toString()).toList(),
    );
  }

  /// How many glasses count as the day's goal. Clamped to a usable range.
  static Future<int> hydrationGoal() async {
    final int? stored = (await _prefs).getInt(_keyHydrationGoal);
    if (stored == null) return defaultHydrationGoal;
    return stored.clamp(minHydrationGoal, maxHydrationGoal);
  }

  /// Store the daily glass goal.
  static Future<void> setHydrationGoal(int value) async =>
      (await _prefs).setInt(
        _keyHydrationGoal,
        value.clamp(minHydrationGoal, maxHydrationGoal),
      );

  /// How many millilitres one logged glass counts as. Clamped.
  static Future<int> glassMl() async {
    final int? stored = (await _prefs).getInt(_keyGlassMl);
    if (stored == null) return defaultGlassMl;
    return stored.clamp(minGlassMl, maxGlassMl);
  }

  /// Store the glass size.
  static Future<void> setGlassMl(int value) async => (await _prefs).setInt(
        _keyGlassMl,
        value.clamp(minGlassMl, maxGlassMl),
      );

  /// Whether the app may switch to the dark theme after dark.
  ///
  /// Anything other than a stored boolean is treated as unset rather than
  /// throwing: a preference that cannot be read must not stop the app opening.
  static Future<bool> dimAfterDark() async {
    final Object? raw = (await _prefs).get(_keyDimAfterDark);
    return raw is bool ? raw : defaultDimAfterDark;
  }

  /// Store the "Dim after dark" choice.
  static Future<void> setDimAfterDark(bool value) async =>
      (await _prefs).setBool(_keyDimAfterDark, value);

  /// Forgets everything this service stores. Used by tests and by a factory
  /// reset; the profile and contacts in [LocalStore] are untouched.
  static Future<void> clear() async {
    final SharedPreferences prefs = await _prefs;
    for (final String key in <String>[
      _keyDemoMode,
      _keyWatchFace,
      _keyWatchTheme,
      _keyWatchBrightness,
      _keyAutoSync,
      _keyHighHr,
      _keyLowSpo2,
      _keyComplicationTop,
      _keyComplicationBottom,
      _keyQuickReplies,
      _keyReflections,
      _keyBreathHoldBest,
      _keyMedications,
      _keyDimAfterDark,
      _keyReminders,
      _keyScheduledIds,
      _keyHydrationGoal,
      _keyGlassMl,
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
