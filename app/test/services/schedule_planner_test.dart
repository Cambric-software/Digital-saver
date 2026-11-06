/// The pure conversion from reminders and medication schedules to alerts.
///
/// The platform API takes one notification per firing, so this list is what the
/// app actually schedules. The tests cover what it includes, what it skips, the
/// ordering and the caps that keep the pending list small.
library;

import 'package:digital_saver/core/models/medication.dart';
import 'package:digital_saver/core/models/reminder.dart';
import 'package:digital_saver/core/services/schedule_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Friday 6 November 2026, 06:00.
  final DateTime from = DateTime(2026, 11, 6, 6, 0);

  group('reminders', () {
    test('a daily reminder becomes one alert per day in the horizon', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
        kind: ReminderKind.alarm,
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: <Reminder>[reminder],
        medications: const <Medication>[],
        from: from,
        horizonDays: 2,
      );

      expect(alerts, hasLength(3));
      expect(alerts.first.at, DateTime(2026, 11, 6, 7, 0));
      expect(alerts.first.title, 'Wake up');
      expect(alerts.first.body, 'Alarm');
      expect(alerts.first.payload, 'reminder:r1');
      expect(alerts.first.vibrate, isTrue);
      expect(alerts.map((ScheduledAlert a) => a.at), <DateTime>[
        DateTime(2026, 11, 6, 7, 0),
        DateTime(2026, 11, 7, 7, 0),
        DateTime(2026, 11, 8, 7, 0),
      ]);
    });

    test('a custom message replaces the default body', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Water',
        hour: 10,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
        kind: ReminderKind.hydration,
        body: 'Have a glass.',
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: <Reminder>[reminder],
        medications: const <Medication>[],
        from: from,
        horizonDays: 0,
      );

      expect(alerts.single.body, 'Have a glass.');
    });

    test('a hydration reminder without a message says what it is for', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Water',
        hour: 10,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
        kind: ReminderKind.hydration,
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: <Reminder>[reminder],
        medications: const <Medication>[],
        from: from,
        horizonDays: 0,
      );

      expect(alerts.single.body, 'Time for a glass of water.');
    });

    test('a disabled reminder is skipped', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
        enabled: false,
      );

      expect(
        SchedulePlanner.build(
          reminders: <Reminder>[reminder],
          medications: const <Medication>[],
          from: from,
        ),
        isEmpty,
      );
    });

    test('a passed one-off reminder is skipped', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Dentist',
        hour: 9,
        minute: 0,
        date: '2026-01-01',
      );

      expect(
        SchedulePlanner.build(
          reminders: <Reminder>[reminder],
          medications: const <Medication>[],
          from: from,
        ),
        isEmpty,
      );
    });
  });

  group('medications', () {
    test('each stored time becomes an alert', () {
      const Medication medication = Medication(
        id: 'med_a',
        name: 'Metformin',
        dose: '500 mg',
        notes: 'With food',
        times: <String>['08:00', '20:00'],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: const <Reminder>[],
        medications: <Medication>[medication],
        from: from,
        horizonDays: 0,
      );

      expect(alerts, hasLength(2));
      expect(alerts.first.at, DateTime(2026, 11, 6, 8, 0));
      expect(alerts.first.title, 'Metformin');
      expect(alerts.first.body, contains('500 mg'));
      expect(alerts.first.body, contains('With food'));
      expect(alerts.first.payload, 'medication:med_a|08:00');
      expect(alerts.last.at, DateTime(2026, 11, 6, 20, 0));
    });

    test('a dose without a strength or note still says something useful', () {
      const Medication medication = Medication(
        id: 'med_a',
        name: 'Metformin',
        times: <String>['08:00'],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: const <Reminder>[],
        medications: <Medication>[medication],
        from: from,
        horizonDays: 0,
      );

      expect(alerts.single.body, 'Scheduled dose.');
    });

    test('a medication without times is skipped', () {
      const Medication medication = Medication(name: 'Vitamin D3');

      expect(
        SchedulePlanner.build(
          reminders: const <Reminder>[],
          medications: <Medication>[medication],
          from: from,
        ),
        isEmpty,
      );
    });

    test('the medication horizon is capped below the reminder horizon', () {
      const Medication medication = Medication(
        id: 'med_a',
        name: 'Metformin',
        times: <String>['08:00', '20:00'],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: const <Reminder>[],
        medications: <Medication>[medication],
        from: from,
        horizonDays: 90,
      );

      // Two doses a day, from today through the horizon day inclusive.
      expect(
        alerts,
        hasLength((SchedulePlanner.medicationHorizonDays + 1) * 2),
      );
      expect(alerts.last.at, DateTime(2026, 11, 20, 20, 0));
    });

    test('weekday selection limits the doses', () {
      const Medication medication = Medication(
        id: 'med_m',
        name: 'Weekly',
        times: <String>['09:00'],
        days: <int>[1],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: const <Reminder>[],
        medications: <Medication>[medication],
        from: from,
        horizonDays: 14,
      );

      expect(alerts.map((ScheduledAlert a) => a.at), <DateTime>[
        DateTime(2026, 11, 9, 9, 0),
        DateTime(2026, 11, 16, 9, 0),
      ]);
    });
  });

  group('the combined list', () {
    test('is sorted by time regardless of input order', () {
      const Reminder late = Reminder(
        id: 'r_late',
        title: 'Late',
        hour: 21,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );
      const Reminder early = Reminder(
        id: 'r_early',
        title: 'Early',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: <Reminder>[late, early],
        medications: const <Medication>[],
        from: from,
        horizonDays: 0,
      );

      expect(
          alerts.map((ScheduledAlert a) => a.title), <String>['Early', 'Late']);
    });

    test('uses a distinct id for every alert', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );
      const Medication medication = Medication(
        id: 'med_a',
        name: 'Metformin',
        times: <String>['07:00'],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: <Reminder>[reminder],
        medications: <Medication>[medication],
        from: from,
        horizonDays: 30,
      );

      expect(alerts, isNotEmpty);
      expect(
        alerts.map((ScheduledAlert a) => a.id).toSet(),
        hasLength(alerts.length),
      );
    });

    test('is stable across two builds of the same data', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );

      List<ScheduledAlert> build() => SchedulePlanner.build(
            reminders: <Reminder>[reminder],
            medications: const <Medication>[],
            from: from,
            horizonDays: 5,
          );

      expect(
        build().map((ScheduledAlert a) => a.id),
        build().map((ScheduledAlert a) => a.id),
      );
    });

    test('the total cap truncates the list', () {
      const Reminder reminder = Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
      );

      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: <Reminder>[reminder],
        medications: const <Medication>[],
        from: from,
        horizonDays: 30,
        maxTotal: 10,
      );

      expect(alerts, hasLength(10));
      // The list stays in time order after truncation.
      for (int i = 1; i < alerts.length; i++) {
        expect(alerts[i].at.isBefore(alerts[i - 1].at), isFalse);
      }
    });

    test('an empty plan is an empty list, not an error', () {
      expect(
        SchedulePlanner.build(
          reminders: const <Reminder>[],
          medications: const <Medication>[],
          from: from,
        ),
        isEmpty,
      );
    });
  });
}
