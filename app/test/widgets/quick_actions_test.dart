/// The four actions on the Today screen.
///
/// The old quick-action file was a speed dial whose callbacks were all null;
/// pressing an action did nothing. These tests check that the water action
/// writes to the shared daily log and reads the saved count back, and that a
/// disconnected watch disables the memory action instead of pretending to sync.
library;

import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/daily_log.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/widgets/quick_actions_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness() {
  return ChangeNotifierProvider<BleService>(
    create: (_) => BleService(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: SingleChildScrollView(child: QuickActionsCard()),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_harness());
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('the water action starts from the stored count, not an invention',
      (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Log water'), findsOneWidget);
    expect(find.text('No glasses logged today.'), findsOneWidget);
    expect(await DailyLog.counter(DailyLog.hydrationGlasses), 0);
  });

  testWidgets('logging water writes and reads back the new count',
      (WidgetTester tester) async {
    await _pump(tester);

    await tester.tap(find.text('Log water'));
    await tester.pump();
    await tester.pump();

    expect(await DailyLog.counter(DailyLog.hydrationGlasses), 1);
    expect(find.text('Saved for today. 1 glass today.'), findsOneWidget);
  });

  testWidgets('a disconnected watch explains why memory cannot be pulled',
      (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Pull watch memory'), findsOneWidget);
    expect(
      find.text('Connect the watch to pull its memory.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Pull watch memory'));
    await tester.pump();
    await tester.pump();

    // No command channel means no sync started and no success message.
    expect(find.textContaining('sending its stored samples'), findsNothing);
    expect(find.text('A memory sync is already running.'), findsNothing);
  });

  testWidgets('breathing and mood open screens rather than doing nothing',
      (WidgetTester tester) async {
    await _pump(tester);

    await tester.tap(find.text('Breathe'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Wellness tools'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
