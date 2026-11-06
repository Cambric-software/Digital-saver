/// Turns reminders and medication schedules into a flat list of alerts.
///
/// The platform notification APIs take one notification per firing, so a
/// repeating reminder becomes several scheduled entries. Doing that conversion
/// in a pure function means the arithmetic can be tested without a plugin, a
/// device or a clock, and the screen, the app startup path and the tests all
/// build the same list.
///
/// The horizon is deliberately finite. Android caps the number of pending
/// alarms per app, and a list scheduled years ahead would be both wasteful and
/// wrong the first time the person changed a time. The app reschedules on
/// launch and after every edit, which keeps the near horizon full.
library;

import 'dart:math' as math;

import '../models/medication.dart';
import '../models/reminder.dart';
import '../models/stable_id.dart';

/// One notification that should exist on the platform.
class ScheduledAlert {
  /// Create an alert.
  const ScheduledAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.payload,
    required this.vibrate,
  });

  /// Platform notification id, stable for the same alert.
  final int id;

  /// Bold line in the notification.
  final String title;

  /// Second line in the notification.
  final String body;

  /// When it should fire, in the device's local clock.
  final DateTime at;

  /// Data handed back when the notification is opened, e.g. `reminder:r123`.
  final String payload;

  /// Whether the device should vibrate.
  final bool vibrate;

  @override
  String toString() => 'ScheduledAlert($id, $title, $at)';
}

/// Pure planning for every alert the app wants scheduled.
abstract final class SchedulePlanner {
  /// How far ahead reminders are scheduled. A month covers every weekly
  /// selection many times over.
  static const int defaultHorizonDays = 30;

  /// How far ahead medication doses are scheduled. Two weeks keeps the pending
  /// list small while still covering a fortnight without opening the app.
  static const int medicationHorizonDays = 14;

  /// Most alerts one reminder may produce.
  static const int maxPerReminder = 30;

  /// Most alerts one medication may produce.
  static const int maxPerMedication = 40;

  /// Hard cap across everything, below the platform limits observed on Android.
  static const int maxTotal = 400;

  /// Build every alert due after [from].
  ///
  /// The result is sorted by time, then by id so two alerts at the same minute
  /// have a stable order. Disabled reminders, medications without times and
  /// past one-off reminders produce nothing.
  static List<ScheduledAlert> build({
    required List<Reminder> reminders,
    required List<Medication> medications,
    required DateTime from,
    int horizonDays = defaultHorizonDays,
    int maxTotal = 400,
  }) {
    final List<ScheduledAlert> alerts = <ScheduledAlert>[];
    final Set<int> usedIds = <int>{};

    int nextId(String key) {
      int id = stableNotificationId(key);
      while (usedIds.contains(id)) {
        id = id == 0x7ffffffe ? 1 : id + 1;
      }
      usedIds.add(id);
      return id;
    }

    for (final Reminder reminder in reminders) {
      if (!reminder.enabled) continue;
      final List<DateTime> occurrences = reminder.nextOccurrences(
        from,
        horizonDays: horizonDays,
        limit: maxPerReminder,
      );
      for (final DateTime at in occurrences) {
        alerts.add(
          ScheduledAlert(
            id: nextId(
              'reminder|${reminder.id}|${at.millisecondsSinceEpoch}',
            ),
            title: reminder.title,
            body: _reminderBody(reminder),
            at: at,
            payload: 'reminder:${reminder.id}',
            vibrate: reminder.vibrate,
          ),
        );
      }
    }

    for (final Medication medication in medications) {
      if (!medication.isScheduled) continue;
      final List<DateTime> occurrences = medication.nextOccurrences(
        from,
        horizonDays: math.min(horizonDays, medicationHorizonDays),
        limit: maxPerMedication,
      );
      for (final DateTime at in occurrences) {
        final String time = '${at.hour.toString().padLeft(2, '0')}:'
            '${at.minute.toString().padLeft(2, '0')}';
        alerts.add(
          ScheduledAlert(
            id: nextId(
              'medication|${medication.id}|$time|${at.millisecondsSinceEpoch}',
            ),
            title: medication.name,
            body: _medicationBody(medication),
            at: at,
            payload: 'medication:${medication.id}|$time',
            vibrate: true,
          ),
        );
      }
    }

    alerts.sort((ScheduledAlert a, ScheduledAlert b) {
      final int byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

    if (alerts.length <= maxTotal) {
      return List<ScheduledAlert>.unmodifiable(alerts);
    }
    return List<ScheduledAlert>.unmodifiable(alerts.sublist(0, maxTotal));
  }

  static String _reminderBody(Reminder reminder) {
    final String note = reminder.body.trim();
    if (note.isNotEmpty) return note;
    return switch (reminder.kind) {
      ReminderKind.alarm => 'Alarm',
      ReminderKind.hydration => 'Time for a glass of water.',
      ReminderKind.reminder => 'Reminder',
    };
  }

  static String _medicationBody(Medication medication) {
    final String dose = medication.dose.trim();
    final String notes = medication.notes.trim();
    final StringBuffer out = StringBuffer();
    if (dose.isNotEmpty) out.write(dose);
    if (notes.isNotEmpty) {
      if (out.isNotEmpty) out.write(' — ');
      out.write(notes);
    }
    if (out.isEmpty) out.write('Scheduled dose.');
    return out.toString();
  }
}
