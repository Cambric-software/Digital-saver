/// The guided breathing screen.
///
/// The old card was a single countdown that never named the phase. This screen
/// must show the real phase, its remaining seconds and the elapsed session, and
/// only add to today's total when the person finishes or saves.
library;

import 'package:digital_saver/core/services/daily_log.dart';
import 'package:digital_saver/features/screens/breathing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders every pattern and the first phase', (tester) async {
    await pumpScreen(tester, const BreathingScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Breathing & relaxation'), findsOneWidget);
    expect(find.text('Choose a rhythm'), findsOneWidget);
    expect(find.text('Box'), findsWidgets);
    expect(find.text('4-7-8'), findsOneWidget);
    expect(find.text('Coherent'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Quick reset'), findsOneWidget);

    // At zero seconds the box pattern is in its first inhale, with four
    // seconds left in it.
    expect(find.text('Breathe in'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Cycle 1'), findsOneWidget);
    expect(find.text('Nothing recorded yet today.'), findsOneWidget);
  });

  testWidgets('choosing another pattern changes the rhythm and resets',
      (tester) async {
    await pumpScreen(tester, const BreathingScreen());

    await tester.tap(find.text('4-7-8'));
    await tester.pump();

    expect(
      find.text('Four in, seven hold, eight out.'),
      findsOneWidget,
    );
    expect(find.text('0s of 3m'), findsOneWidget);
  });

  testWidgets('starting advances the phase and saving records the time',
      (tester) async {
    await pumpScreen(tester, const BreathingScreen());

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.widgetWithText(FilledButton, 'Pause'), findsOneWidget);
    expect(find.text('2s of 3m'), findsOneWidget);

    await scrollTo(tester, find.text('Finish & save'));
    await tester.tap(find.text('Finish & save'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await DailyLog.counter(DailyLog.breathingSeconds), 2);
    expect(find.text('2s recorded today.'), findsOneWidget);
  });

  testWidgets('discarding a session records nothing', (tester) async {
    await pumpScreen(tester, const BreathingScreen());

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await scrollTo(tester, find.text('Discard'));
    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await DailyLog.counter(DailyLog.breathingSeconds), 0);
    expect(find.text('Nothing recorded yet today.'), findsOneWidget);
    expect(find.text('0s of 3m'), findsOneWidget);
  });
}
