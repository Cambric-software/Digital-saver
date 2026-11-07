/// The part of the phone's reminder list the watch can ring on its own.
///
/// The watch has no calendar and no notification service. It can hold a small
/// set of weekly alarms: a time, a weekday mask and a label. This file decides
/// which reminders qualify and builds the commands that replace the watch's
/// set, without any BLE or widget code, so the mapping can be tested directly.
///
/// Rules, in order:
/// - only enabled reminders are sent;
/// - only repeating reminders are sent, because a one-off alarm that outlives
///   its date would be wrong on a watch that cannot delete it;
/// - alarms are preferred over general reminders, then earlier times;
/// - identical time-and-day entries are sent once, keeping the first label;
/// - at most [maxWatchAlarms] entries, matching the firmware's ALARM_MAX.
library;

import 'dart:convert';

import '../models/reminder.dart';

/// The number of alarm slots in the ESP32-S3 firmware (ALARM_MAX).
const int maxWatchAlarms = 8;

/// The most label bytes the firmware keeps (ALARM_LABEL_MAX - 1).
const int _maxLabelBytes = 23;

/// Convert weekday numbers (1 = Monday, 7 = Sunday) to the firmware mask.
///
/// Bit 0 is Sunday because the firmware tests the mask against `struct tm`'s
/// `tm_wday`, which is 0 for Sunday. So Monday is bit 1 and Sunday is bit 0.
int weekdayMask(Iterable<int> days) {
  int mask = 0;
  for (final int day in days) {
    if (day < 1 || day > 7) continue;
    mask |= 1 << (day % 7);
  }
  return mask;
}

/// Truncate a label to whole UTF-8 characters that fit the firmware buffer.
String watchAlarmLabel(String title) {
  final String trimmed = title.trim();
  if (utf8.encode(trimmed).length <= _maxLabelBytes) return trimmed;
  final StringBuffer out = StringBuffer();
  int used = 0;
  for (final int rune in trimmed.runes) {
    final int size = utf8.encode(String.fromCharCode(rune)).length;
    if (used + size > _maxLabelBytes) break;
    out.writeCharCode(rune);
    used += size;
  }
  return out.toString();
}

/// The commands that replace the watch's alarm set.
///
/// The set is split into one small write per alarm. A single JSON array of
/// eight labelled alarms is larger than the ATT payload the command
/// characteristic can take in one write, so the phone clears, appends, then
/// commits. An interrupted sync leaves the previous set in flash.
List<Map<String, Object>> watchAlarmCommands(List<Reminder> reminders) {
  final List<Reminder> eligible = reminders
      .where(
          (Reminder reminder) => reminder.enabled && reminder.days.isNotEmpty)
      .toList(growable: false)
    ..sort((Reminder a, Reminder b) {
      final int byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      final int byTime =
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
      if (byTime != 0) return byTime;
      return a.title.compareTo(b.title);
    });

  final List<Map<String, Object>> commands = <Map<String, Object>>[
    <String, Object>{'op': 'alarm_clear'},
  ];
  final Set<String> seen = <String>{};
  int sent = 0;
  for (final Reminder reminder in eligible) {
    if (sent >= maxWatchAlarms) break;
    final int mask = weekdayMask(reminder.days);
    if (mask == 0) continue;
    final String key = '${reminder.hour}:${reminder.minute}:$mask';
    if (!seen.add(key)) continue;
    commands.add(<String, Object>{
      'op': 'alarm',
      'h': reminder.hour,
      'm': reminder.minute,
      'days': mask,
      'on': true,
      'label': watchAlarmLabel(reminder.title),
    });
    sent++;
  }
  commands.add(<String, Object>{'op': 'alarm_commit'});
  return commands;
}
