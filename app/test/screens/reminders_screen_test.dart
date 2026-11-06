/// The alarm and reminder screen, rendered the way the app renders it.
///
/// The screen must work on a host with no notification plugin as well as on a
/// phone: the schedule is still stored, and the screen says plainly that
/// nothing will alert there. These tests run on the unsupported branch so the
/// wording and the stored state are both checked without a platform channel.
library;

import 'package:digital_saver/core/models/reminder.dart';
import 'package:digital_saver/core/services/notification_service.dart';
import 'package:digital_saver/core/services/storage_service.dart';
import 'package:digital_saver/features/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the empty state and says delivery is unavailable',
      (tester) async {
    await pumpScreen(tester, const RemindersScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Alarms & reminders'), findsOneWidget);
    expect(find.text('No alarms or reminders yet'), findsOneWidget);

    // The test host has no notification plugin. On the platforms the plugin
    // does support the permission therefore reads as blocked; elsewhere the
    // screen says the platform cannot deliver at all.
    if (NotificationService.platformSupported) {
      expect(find.text('Blocked'), findsOneWidget);
    } else {
      expect(find.text('Not available here'), findsOneWidget);
      expect(
        find.textContaining('nothing will alert you on this device'),
        findsOneWidget,
      );
    }
    expect(find.text('About timing'), findsOneWidget);
  });

  testWidgets('a quick preset is stored and appears in the list',
      (tester) async {
    await pumpScreen(tester, const RemindersScreen());

    await scrollTo(tester, find.text('Wake-up alarm'));
    await tester.tap(find.text('Wake-up alarm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final List<Reminder> stored = await StorageService.reminders();
    expect(stored, hasLength(1));
    expect(stored.single.title, 'Wake up');
    expect(stored.single.hour, 7);
    expect(stored.single.minute, 0);
    expect(stored.single.repeatLabel, 'Every day');
    expect(find.text('Wake up added at 07:00.'), findsOneWidget);
  });

  testWidgets('the add form validates the name and stores a new reminder',
      (tester) async {
    await pumpScreen(tester, const RemindersScreen());

    await tester.tap(find.byTooltip('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // An empty name is refused with a message, not silently saved.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(find.text('Give the reminder a name.'), findsOneWidget);
    expect(await StorageService.reminders(), isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Call home',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final List<Reminder> stored = await StorageService.reminders();
    expect(stored, hasLength(1));
    expect(stored.single.title, 'Call home');
    expect(stored.single.repeatLabel, 'Every day');
  });

  testWidgets('switching a reminder off is stored immediately', (tester) async {
    await StorageService.setReminders(<Reminder>[
      const Reminder(
        id: 'r1',
        title: 'Wake up',
        hour: 7,
        minute: 0,
        days: <int>[1, 2, 3, 4, 5, 6, 7],
        kind: ReminderKind.alarm,
      ),
    ]);

    await pumpScreen(tester, const RemindersScreen());
    expect(find.text('07:00'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final List<Reminder> stored = await StorageService.reminders();
    expect(stored.single.enabled, isFalse);
    expect(find.text('Paused'), findsOneWidget);
  });
}
