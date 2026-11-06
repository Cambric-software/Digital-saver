/// The reminder model, tested without a widget tree or a plugin.
///
/// The occurrence maths is the part that can silently be wrong: an alarm that
/// fires on the wrong weekday, or a one-off that repeats because a stored date
/// was ignored. These tests pin the behaviour to plain dates.
library;

import 'package:digital_saver/core/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextOccurrences', () {
    test('a weekday reminder skips the weekend', () {
      // Friday 6 November 2026, 06:00.
      final DateTime from = DateTime(2026, 11, 6, 6, 0);
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5],
      );

      final List<DateTime> next = reminder.nextOccurrences(from, limit: 3);

      expect(next, <DateTime>[
        DateTime(2026, 11, 6, 7, 0),
        DateTime(2026, 11, 9, 7, 0),
        DateTime(2026, 11, 10, 7, 0),
      ]);
    });

    test('a time exactly at the moment is not repeated', () {
      final DateTime from = DateTime(2026, 11, 6, 7, 0);
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );

      expect(
        reminder.nextOccurrences(from, limit: 1).single,
        DateTime(2026, 11, 7, 7, 0),
      );
    });

    test('a one-off reminder happens once on its stored date', () {
      const Reminder reminder = Reminder(
        id: 'r2',
        title: 'Dentist',
        hour: 9,
        minute: 30,
        date: '2026-12-14',
      );

      expect(
        reminder.nextOccurrences(DateTime(2026, 11, 6, 12, 0)),
        <DateTime>[DateTime(2026, 12, 14, 9, 30)],
      );
      expect(reminder.repeats, isFalse);
      expect(reminder.repeatLabel, 'Once on Mon 14 Dec');
    });

    test('a passed one-off reminder has no next occurrence', () {
      const Reminder reminder = Reminder(
        id: 'r2',
        title: 'Dentist',
        hour: 9,
        minute: 30,
        date: '2026-01-14',
      );

      expect(
        reminder.nextOccurrences(DateTime(2026, 11, 6)),
        isEmpty,
      );
    });

    test('a one-off with an unreadable date is never scheduled', () {
      const Reminder reminder = Reminder(
        id: 'r2',
        title: 'Dentist',
        hour: 9,
        minute: 30,
        date: 'not-a-date',
      );

      expect(reminder.onceDate, isNull);
      expect(reminder.nextOccurrences(DateTime(2026, 11, 6)), isEmpty);
      expect(reminder.nextOccurrence(DateTime(2026, 11, 6)), isNull);
    });

    test('a disabled reminder produces nothing', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
        enabled: false,
      );

      expect(reminder.nextOccurrences(DateTime(2026, 11, 6)), isEmpty);
    });

    test('the horizon limits how far ahead a reminder reaches', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Weekly',
        hour: 7,
        minute: 0,
        days: <int>[1],
      );

      // Monday 6 November 2026 is a Friday, so the next Monday is three days
      // away and falls outside a one-day horizon.
      final DateTime from = DateTime(2026, 11, 6, 8, 0);
      expect(
        reminder.nextOccurrences(from, horizonDays: 1),
        isEmpty,
      );
      expect(
        reminder.nextOccurrences(from, horizonDays: 3),
        <DateTime>[DateTime(2026, 11, 9, 7, 0)],
      );
    });

    test('a zero limit produces nothing', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );

      expect(
        reminder.nextOccurrences(DateTime(2026, 11, 6), limit: 0),
        isEmpty,
      );
    });
  });

  group('labels', () {
    test('the repeat label names the common patterns', () {
      Reminder withDays(List<int> days) => Reminder(
            id: 'r',
            title: 't',
            hour: 7,
            minute: 0,
            days: days,
          );

      expect(withDays(<int>[1, 2, 3, 4, 5, 6, 7]).repeatLabel, 'Every day');
      expect(withDays(<int>[1, 2, 3, 4, 5]).repeatLabel, 'Weekdays');
      expect(withDays(<int>[6, 7]).repeatLabel, 'Weekends');
      expect(withDays(<int>[5, 1, 3]).repeatLabel, 'Mon, Wed, Fri');
    });

    test('the time label is zero padded', () {
      const Reminder reminder = Reminder(
        id: 'r',
        title: 't',
        hour: 8,
        minute: 5,
      );
      expect(reminder.timeLabel, '08:05');
    });

    test('weekday and date helpers do not depend on locale data', () {
      expect(shortDayName(1), 'Mon');
      expect(shortDayName(7), 'Sun');
      expect(shortDayName(0), '');
      expect(shortDayName(8), '');
      expect(formatDay(DateTime(2026, 11, 3)), 'Tue 3 Nov');
    });
  });

  group('stored form', () {
    test('a reminder round-trips through JSON', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Stretch',
        hour: 15,
        minute: 5,
        days: <int>[1, 3, 5],
        kind: ReminderKind.reminder,
        body: 'Stand up',
        enabled: false,
        vibrate: false,
      );

      final Reminder? read = Reminder.fromJson(reminder.toJson());

      expect(read, isNotNull);
      expect(read!.id, 'r1');
      expect(read.title, 'Stretch');
      expect(read.hour, 15);
      expect(read.minute, 5);
      expect(read.days, <int>[1, 3, 5]);
      expect(read.kind, ReminderKind.reminder);
      expect(read.body, 'Stand up');
      expect(read.enabled, isFalse);
      expect(read.vibrate, isFalse);
    });

    test('stored days are sorted, deduplicated and range checked', () {
      final Reminder? read = Reminder.fromJson(<String, Object>{
        'id': 'r1',
        'title': 'Wake up',
        'hour': 7,
        'minute': 0,
        'days': <Object>[5, 1, 1, 0, 8, '3'],
      });

      expect(read, isNotNull);
      expect(read!.days, <int>[1, 5]);
    });

    test('a repeating reminder does not keep a one-off date', () {
      final Reminder? read = Reminder.fromJson(<String, Object>{
        'id': 'r1',
        'title': 'Wake up',
        'hour': 7,
        'minute': 0,
        'days': <int>[1, 2, 3, 4, 5, 6, 7],
        'date': '2026-11-06',
      });

      expect(read!.date, '');
    });

    test('an unknown kind falls back to a plain reminder', () {
      final Reminder? read = Reminder.fromJson(<String, Object>{
        'id': 'r1',
        'title': 'Wake up',
        'hour': 7,
        'minute': 0,
        'days': <int>[1],
        'kind': 'something-else',
      });

      expect(read!.kind, ReminderKind.reminder);
    });

    test('an unreadable reminder is rejected instead of half-read', () {
      expect(Reminder.fromJson(null), isNull);
      expect(Reminder.fromJson('text'), isNull);
      expect(
        Reminder.fromJson(<String, Object>{
          'title': 'No id',
          'hour': 7,
          'minute': 0,
          'days': <int>[1],
        }),
        isNull,
      );
      expect(
        Reminder.fromJson(<String, Object>{
          'id': 'r1',
          'title': 'Bad hour',
          'hour': 24,
          'minute': 0,
          'days': <int>[1],
        }),
        isNull,
      );
      expect(
        Reminder.fromJson(<String, Object>{
          'id': 'r1',
          'title': 'Bad minute',
          'hour': 7,
          'minute': 60,
          'days': <int>[1],
        }),
        isNull,
      );
      expect(
        Reminder.fromJson(<String, Object>{
          'id': 'r1',
          'title': 'No days and no date',
          'hour': 7,
          'minute': 0,
        }),
        isNull,
      );
    });

    test('copyWith replaces only the named fields', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1],
      );

      final Reminder copy = reminder.copyWith(enabled: false);

      expect(copy.enabled, isFalse);
      expect(copy.id, 'r1');
      expect(copy.title, 'Wake up');
      expect(copy.days, <int>[1]);
    });
  });
}
