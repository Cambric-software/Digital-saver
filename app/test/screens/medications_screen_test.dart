/// The medication screen, rendered with stored schedules.
///
/// Two things matter here: the times the person entered become today's doses,
/// and marking one taken writes a timestamp that survives leaving the screen.
/// The app does not calculate doses, so the tests assert only what was entered.
library;

import 'package:digital_saver/core/services/daily_log.dart';
import 'package:digital_saver/core/services/storage_service.dart';
import 'package:digital_saver/features/screens/medications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders an honest empty state', (tester) async {
    await pumpScreen(tester, const MedicationsScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Medications'), findsOneWidget);
    expect(find.text('No doses scheduled for today'), findsOneWidget);
    expect(find.text('Your list is empty'), findsOneWidget);
    expect(
      find.textContaining('This is your own list, not a prescription.'),
      findsOneWidget,
    );
  });

  testWidgets('a stored schedule becomes today\'s doses', (tester) async {
    await StorageService.setMedications(const <Medication>[
      Medication(
        id: 'med_a',
        name: 'Metformin',
        dose: '500 mg',
        times: <String>['08:00', '20:00'],
      ),
    ]);

    await pumpScreen(tester, const MedicationsScreen());

    expect(find.text('Today\'s doses'), findsOneWidget);
    expect(find.text('Metformin'), findsNWidgets(3));
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Taken'), findsNWidgets(2));
    expect(find.textContaining('due so far'), findsOneWidget);
  });

  testWidgets('marking a dose taken is recorded and can be undone',
      (tester) async {
    await StorageService.setMedications(const <Medication>[
      Medication(
        id: 'med_a',
        name: 'Metformin',
        times: <String>['08:00'],
      ),
    ]);

    await pumpScreen(tester, const MedicationsScreen());

    await tester.tap(find.widgetWithText(FilledButton, 'Taken'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      await DailyLog.time('med_med_a_08:00'),
      isNotNull,
    );
    expect(find.text('Undo'), findsOneWidget);
    expect(
      find.textContaining('marked taken'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await DailyLog.time('med_med_a_08:00'), isNull);
  });

  testWidgets('a medication without a time is saved without a reminder',
      (tester) async {
    await pumpScreen(tester, const MedicationsScreen());

    await tester.tap(find.byTooltip('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Vitamin D3',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final List<Medication> stored = await StorageService.medications();
    expect(stored, hasLength(1));
    expect(stored.single.name, 'Vitamin D3');
    expect(stored.single.isScheduled, isFalse);
    expect(
      find.textContaining('without a time, so no reminder is scheduled'),
      findsOneWidget,
    );
  });

  testWidgets('an empty name is refused', (tester) async {
    await pumpScreen(tester, const MedicationsScreen());

    await tester.tap(find.byTooltip('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Give the medication a name.'), findsOneWidget);
    expect(await StorageService.medications(), isEmpty);
  });
}
