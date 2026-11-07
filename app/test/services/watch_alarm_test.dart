import 'package:digital_saver/core/models/reminder.dart';
import 'package:digital_saver/core/services/watch_alarm.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the reminder-to-watch mapping.
///
/// The firmware's rules are the contract: a weekday mask with Sunday in bit 0,
/// repeating entries only, and at most eight slots. These tests pin the
/// mapping so a change on either side fails here rather than on a watch.
void main() {
  Reminder reminder({
    String id = 'r1',
    String title = 'Wake up',
    int hour = 7,
    int minute = 0,
    List<int> days = const <int>[1, 2, 3, 4, 5],
    ReminderKind kind = ReminderKind.alarm,
    bool enabled = true,
    String date = '',
  }) {
    return Reminder(
      id: id,
      title: title,
      hour: hour,
      minute: minute,
      days: days,
      date: date,
      kind: kind,
      enabled: enabled,
    );
  }

  test('weekdays map to the firmware mask with Sunday in bit 0', () {
    expect(weekdayMask(const <int>[7]), 1); // Sunday
    expect(weekdayMask(const <int>[1]), 2); // Monday
    expect(weekdayMask(const <int>[6]), 64); // Saturday
    expect(weekdayMask(const <int>[1, 2, 3, 4, 5, 6, 7]), 127);
    expect(weekdayMask(const <int>[0, 8, -1]), 0);
  });

  test('labels are cut to whole UTF-8 characters inside 23 bytes', () {
    expect(watchAlarmLabel('Wake up'), 'Wake up');
    expect(watchAlarmLabel('  Wake up  '), 'Wake up');
    const String arabic = 'استيقظ الآن للصلاة';
    final String cut = watchAlarmLabel(arabic);
    expect(utf8Length(cut) <= 23, isTrue);
    expect(arabic.startsWith(cut), isTrue);
  });

  test('disabled and one-off reminders are not sent', () {
    final List<Map<String, Object>> commands = watchAlarmCommands(<Reminder>[
      reminder(id: 'off', enabled: false),
      reminder(id: 'once', days: const <int>[], date: '2026-11-07'),
      reminder(id: 'daily', days: const <int>[1, 2, 3, 4, 5, 6, 7]),
    ]);
    expect(commands.length, 3); // clear, one alarm, commit
    expect(commands.first['op'], 'alarm_clear');
    expect(commands.last['op'], 'alarm_commit');
    expect(commands[1]['days'], 127);
  });

  test('alarms sort before reminders and by time, and cap at eight', () {
    final List<Reminder> input = <Reminder>[
      for (int i = 0; i < 10; i++)
        reminder(
          id: 'r$i',
          title: 'Reminder $i',
          hour: 20 - i,
          kind: ReminderKind.reminder,
        ),
      reminder(id: 'a', title: 'Alarm', hour: 23, kind: ReminderKind.alarm),
    ];
    final List<Map<String, Object>> commands = watchAlarmCommands(input);
    final List<Map<String, Object>> alarms = commands
        .where((Map<String, Object> command) => command['op'] == 'alarm')
        .toList();
    expect(alarms.length, maxWatchAlarms);
    expect(alarms.first['label'], 'Alarm');
    expect(alarms[1]['h'], 11);
  });

  test('identical time and day entries are sent once', () {
    final List<Map<String, Object>> commands = watchAlarmCommands(<Reminder>[
      reminder(id: 'a', title: 'First'),
      reminder(id: 'b', title: 'Second'),
    ]);
    final List<Map<String, Object>> alarms = commands
        .where((Map<String, Object> command) => command['op'] == 'alarm')
        .toList();
    expect(alarms.length, 1);
    expect(alarms.single['label'], 'First');
  });

  test('an empty list still clears the watch', () {
    final List<Map<String, Object>> commands =
        watchAlarmCommands(const <Reminder>[]);
    expect(commands.length, 2);
    expect(commands.first['op'], 'alarm_clear');
    expect(commands.last['op'], 'alarm_commit');
  });
}

/// UTF-8 byte length without importing dart:convert in the test body.
int utf8Length(String value) {
  int bytes = 0;
  for (final int rune in value.runes) {
    if (rune <= 0x7F) {
      bytes += 1;
    } else if (rune <= 0x7FF) {
      bytes += 2;
    } else if (rune <= 0xFFFF) {
      bytes += 3;
    } else {
      bytes += 4;
    }
  }
  return bytes;
}
