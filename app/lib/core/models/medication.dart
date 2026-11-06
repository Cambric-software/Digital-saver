/// A medication or supplement the person keeps on their own list.
///
/// The previous model was a name and an optional dose, and its documentation
/// said plainly that there was no schedule, no reminder and no interval. That
/// made the list a note rather than something the app could act on.
///
/// A medication now carries the times of day it is taken and the weekdays it
/// applies to. Those times are what the notification scheduler turns into
/// reminders, and what the medication screen uses to show today's doses. Nothing
/// is inferred: a medication with no times set has no schedule and produces no
/// reminders.
library;

import 'stable_id.dart';

/// A medication, supplement or other scheduled dose.
class Medication {
  /// Create an entry.
  const Medication({
    required this.name,
    this.id = '',
    this.dose = '',
    this.notes = '',
    this.times = const <String>[],
    this.days = const <int>[],
  });

  /// Stable identifier used to link today's doses and notification ids.
  final String id;

  /// What it is, e.g. `Vitamin D3`.
  final String name;

  /// Strength or note, e.g. `2000 IU`. May be empty.
  final String dose;

  /// Free text such as `With food`.
  final String notes;

  /// Times of day as `HH:MM`, sorted. Empty means no reminder is scheduled.
  final List<String> times;

  /// Weekdays it applies to, 1 (Monday) to 7 (Sunday). Empty means every day.
  final List<int> days;

  /// Whether at least one time of day is set.
  bool get isScheduled => times.isNotEmpty;

  /// Whether the medication applies on [weekday] (1 to 7).
  bool appliesOn(int weekday) => days.isEmpty || days.contains(weekday);

  /// The local times this medication is due on [day], sorted.
  List<DateTime> dueOn(DateTime day) {
    if (!appliesOn(day.weekday)) return <DateTime>[];
    final List<DateTime> due = <DateTime>[];
    for (final String value in times) {
      final (int hour, int minute)? parsed = parseTime(value);
      if (parsed == null) continue;
      due.add(DateTime(day.year, day.month, day.day, parsed.$1, parsed.$2));
    }
    due.sort();
    return due;
  }

  /// The next occurrences strictly after [from].
  List<DateTime> nextOccurrences(
    DateTime from, {
    int horizonDays = 14,
    int limit = 40,
  }) {
    if (!isScheduled || limit <= 0 || horizonDays < 0) return <DateTime>[];
    final List<DateTime> found = <DateTime>[];
    for (int offset = 0;
        offset <= horizonDays && found.length < limit;
        offset++) {
      final DateTime day = DateTime(from.year, from.month, from.day + offset);
      for (final DateTime at in dueOn(day)) {
        if (at.isAfter(from)) found.add(at);
        if (found.length >= limit) break;
      }
    }
    return found;
  }

  /// `Every day` or the selected weekdays.
  String get repeatLabel {
    if (days.isEmpty || days.length == 7) return 'Every day';
    final Set<int> set = days.toSet();
    if (set.length == 5 && set.containsAll(const <int>[1, 2, 3, 4, 5])) {
      return 'Weekdays';
    }
    if (set.length == 2 && set.containsAll(const <int>[6, 7])) {
      return 'Weekends';
    }
    const List<String> names = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final List<int> sorted = days.toList()..sort();
    return sorted.map((int day) => names[day - 1]).join(', ');
  }

  /// `08:00, 20:00` or `No times set`.
  String get timesLabel => times.isEmpty ? 'No times set' : times.join(', ');

  /// Copy with selected fields replaced.
  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    String? notes,
    List<String>? times,
    List<int>? days,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      notes: notes ?? this.notes,
      times: times ?? this.times,
      days: days ?? this.days,
    );
  }

  /// Read from stored JSON, or null when the object is not a usable entry.
  static Medication? fromJson(Object? value, {int index = 0}) {
    if (value is! Map) return null;
    final Object? name = value['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final Object? rawDose = value['dose'];
    final Object? rawNotes = value['notes'];
    final Object? rawId = value['id'];
    final List<String> times = normalizeTimes(value['times']);
    final List<int> days = normalizeDays(value['days']);
    final String dose = rawDose is String ? rawDose.trim() : '';
    final String storedId = rawId is String ? rawId.trim() : '';
    return Medication(
      id: storedId.isNotEmpty ? storedId : legacyId(name.trim(), dose, index),
      name: name.trim(),
      dose: dose,
      notes: rawNotes is String ? rawNotes.trim() : '',
      times: times,
      days: days,
    );
  }

  /// Write as stored JSON.
  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'name': name,
        'dose': dose,
        'notes': notes,
        'times': times,
        'days': days,
      };

  /// Turn stored values into sorted, unique `HH:MM` strings.
  static List<String> normalizeTimes(Object? value) {
    if (value is! List) return <String>[];
    final Set<String> seen = <String>{};
    for (final Object? item in value) {
      if (item is! String) continue;
      final (int, int)? parsed = parseTime(item);
      if (parsed == null) continue;
      seen.add(
        '${parsed.$1.toString().padLeft(2, '0')}:'
        '${parsed.$2.toString().padLeft(2, '0')}',
      );
    }
    final List<String> out = seen.toList()..sort();
    return out;
  }

  /// Turn stored values into sorted, unique weekday numbers.
  static List<int> normalizeDays(Object? value) {
    if (value is! List) return <int>[];
    final Set<int> days = <int>{};
    for (final Object? item in value) {
      if (item is int && item >= 1 && item <= 7) days.add(item);
    }
    final List<int> out = days.toList()..sort();
    return out;
  }

  /// Parse `H:MM` or `HH:MM` into an hour and minute, or null.
  static (int, int)? parseTime(String value) {
    final RegExp pattern = RegExp(r'^(\d{1,2}):(\d{2})$');
    final RegExpMatch? match = pattern.firstMatch(value.trim());
    if (match == null) return null;
    final int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  /// A deterministic id for entries written before ids existed.
  static String legacyId(String name, String dose, int index) =>
      'med_${stableNotificationId('$name|$dose|$index').toRadixString(36)}';

  /// A new identifier that does not repeat within the same microsecond.
  static String newId([DateTime? now]) {
    final int stamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
    return 'med_${stamp.toRadixString(36)}';
  }
}
