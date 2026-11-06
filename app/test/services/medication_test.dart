/// The medication model, tested without a widget tree.
///
/// The schedule is the reason this model exists: a name and a dose could not
/// produce a reminder. These tests cover time parsing, weekday filtering, the
/// next occurrences and the identifiers that link a dose to its notification.
library;

import 'package:digital_saver/core/models/medication.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('time parsing', () {
    test('accepts one or two digit hours and two digit minutes', () {
      expect(Medication.parseTime('8:00'), (8, 0));
      expect(Medication.parseTime('08:05'), (8, 5));
      expect(Medication.parseTime(' 23:59 '), (23, 59));
    });

    test('rejects impossible or malformed times', () {
      expect(Medication.parseTime('24:00'), isNull);
      expect(Medication.parseTime('12:60'), isNull);
      expect(Medication.parseTime('8:5'), isNull);
      expect(Medication.parseTime('0800'), isNull);
      expect(Medication.parseTime(''), isNull);
    });

    test('stored times are normalised, sorted and deduplicated', () {
      final List<String> times = Medication.normalizeTimes(
        <Object>['20:00', '8:00', '08:00', 'bad', 12, '23:59'],
      );

      expect(times, <String>['08:00', '20:00', '23:59']);
      expect(Medication.normalizeTimes(null), isEmpty);
      expect(Medication.normalizeTimes('08:00'), isEmpty);
    });

    test('stored weekdays are sorted, deduplicated and range checked', () {
      expect(
        Medication.normalizeDays(<Object>[5, 1, 1, 0, 8, '3']),
        <int>[1, 5],
      );
      expect(Medication.normalizeDays(null), isEmpty);
    });
  });

  group('schedule', () {
    const Medication daily = Medication(
      id: 'med_a',
      name: 'Metformin',
      dose: '500 mg',
      times: <String>['08:00', '20:00'],
    );

    test('a medication without times is not scheduled', () {
      const Medication unscheduled = Medication(name: 'Vitamin D3');

      expect(unscheduled.isScheduled, isFalse);
      expect(unscheduled.nextOccurrences(DateTime(2026, 11, 6)), isEmpty);
      expect(unscheduled.timesLabel, 'No times set');
    });

    test('dueOn returns the day at each stored time', () {
      expect(
        daily.dueOn(DateTime(2026, 11, 6)),
        <DateTime>[
          DateTime(2026, 11, 6, 8, 0),
          DateTime(2026, 11, 6, 20, 0),
        ],
      );
    });

    test('nextOccurrences starts strictly after the moment', () {
      final List<DateTime> next = daily.nextOccurrences(
        DateTime(2026, 11, 6, 8, 0),
        horizonDays: 1,
      );

      expect(next, <DateTime>[
        DateTime(2026, 11, 6, 20, 0),
        DateTime(2026, 11, 7, 8, 0),
        DateTime(2026, 11, 7, 20, 0),
      ]);
    });

    test('weekday selection is respected', () {
      const Medication mondaysOnly = Medication(
        id: 'med_m',
        name: 'Weekly',
        times: <String>['09:00'],
        days: <int>[1],
      );

      // Friday 6 November 2026.
      final DateTime from = DateTime(2026, 11, 6, 6, 0);

      expect(mondaysOnly.appliesOn(5), isFalse);
      expect(mondaysOnly.dueOn(from), isEmpty);
      expect(
        mondaysOnly.nextOccurrences(from, horizonDays: 7),
        <DateTime>[DateTime(2026, 11, 9, 9, 0)],
      );
    });

    test('an empty weekday list means every day', () {
      expect(daily.appliesOn(1), isTrue);
      expect(daily.appliesOn(7), isTrue);
      expect(daily.repeatLabel, 'Every day');
    });

    test('the limit stops the search', () {
      expect(
        daily.nextOccurrences(DateTime(2026, 11, 6, 6, 0), limit: 3),
        hasLength(3),
      );
      expect(
        daily.nextOccurrences(DateTime(2026, 11, 6, 6, 0), limit: 0),
        isEmpty,
      );
    });

    test('the repeat label names the common patterns', () {
      Medication withDays(List<int> days) => Medication(
            name: 't',
            times: const <String>['08:00'],
            days: days,
          );

      expect(withDays(<int>[1, 2, 3, 4, 5]).repeatLabel, 'Weekdays');
      expect(withDays(<int>[6, 7]).repeatLabel, 'Weekends');
      expect(withDays(<int>[5, 1]).repeatLabel, 'Mon, Fri');
    });
  });

  group('identifiers and storage', () {
    test('an entry written before ids existed gets a stable id', () {
      final Medication? first = Medication.fromJson(
        <String, Object>{'name': 'Iron', 'dose': '50 mg'},
      );
      final Medication? second = Medication.fromJson(
        <String, Object>{'name': 'Iron', 'dose': '50 mg'},
      );

      expect(first, isNotNull);
      expect(first!.id, isNotEmpty);
      expect(first.id, second!.id);
      expect(first.id, startsWith('med_'));
    });

    test('a stored id is kept', () {
      final Medication? read = Medication.fromJson(<String, Object>{
        'id': 'med_known',
        'name': 'Iron',
      });

      expect(read!.id, 'med_known');
    });

    test('the index keeps two old entries with the same name apart', () {
      final Medication? first =
          Medication.fromJson(<String, Object>{'name': 'Iron'}, index: 0);
      final Medication? second =
          Medication.fromJson(<String, Object>{'name': 'Iron'}, index: 1);

      expect(first!.id, isNot(second!.id));
    });

    test('an unreadable entry is rejected instead of half-read', () {
      expect(Medication.fromJson(null), isNull);
      expect(Medication.fromJson(<String, Object>{'name': ''}), isNull);
      expect(Medication.fromJson(<String, Object>{'dose': '5 mg'}), isNull);
    });

    test('a medication round-trips through JSON', () {
      const Medication medication = Medication(
        id: 'med_a',
        name: 'Metformin',
        dose: '500 mg',
        notes: 'With food',
        times: <String>['08:00', '20:00'],
        days: <int>[1, 5],
      );

      final Medication? read = Medication.fromJson(medication.toJson());

      expect(read!.id, 'med_a');
      expect(read.name, 'Metformin');
      expect(read.dose, '500 mg');
      expect(read.notes, 'With food');
      expect(read.times, <String>['08:00', '20:00']);
      expect(read.days, <int>[1, 5]);
    });

    test('newId is based on the supplied moment', () {
      final String id =
          Medication.newId(DateTime.fromMicrosecondsSinceEpoch(123456));

      expect(id, startsWith('med_'));
      expect(id, Medication.newId(DateTime.fromMicrosecondsSinceEpoch(123456)));
    });

    test('copyWith replaces only the named fields', () {
      const Medication medication = Medication(
        id: 'med_a',
        name: 'Metformin',
        times: <String>['08:00'],
      );

      final Medication copy = medication.copyWith(notes: 'With food');

      expect(copy.notes, 'With food');
      expect(copy.id, 'med_a');
      expect(copy.name, 'Metformin');
      expect(copy.times, <String>['08:00']);
    });
  });
}
