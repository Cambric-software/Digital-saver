/// Renders the rebuilt lifestyle screen at both real widths and checks that a
/// saved mood entry is stored and comes back.
library;

import 'package:digital_saver/screens/lifestyle_tools_screen.dart';
import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/daily_log.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The providers the app supplies around a pushed screen.
Widget _harness(Widget child) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<BleService>(create: (_) => BleService()),
      ChangeNotifierProvider<HeartRateTracker>(
        create: (_) => HeartRateTracker(),
      ),
      ChangeNotifierProvider<AppLock>(create: (_) => AppLock()),
      ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
      ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
      ChangeNotifierProvider<AutoUpdateService>(
        create: (_) => AutoUpdateService(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: child,
    ),
  );
}

Future<void> _pumpLifestyle(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(const LifestyleToolsScreen()));
  // Two fixed pumps rather than pumpAndSettle: the screen shows a spinner
  // while the stored day loads, and an indeterminate spinner never settles.
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const List<String> headings = <String>[
    'Fasting timer',
    'Mood and energy',
    'Basal metabolic rate',
    'Movement breaks',
    'About these tools',
  ];

  for (final Size size in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'renders every retained card at ${size.width.toInt()}x'
      '${size.height.toInt()}',
      (tester) async {
        await _pumpLifestyle(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('Lifestyle tools'), findsOneWidget);
        for (final String heading in headings) {
          expect(
            find.text(heading),
            findsOneWidget,
            reason: '$heading is missing',
          );
        }

        // Nothing was measured: no sleep average, no decibel level.
        expect(find.textContaining('dB'), findsNothing);
        expect(find.text('No estimate yet'), findsOneWidget);
        expect(find.text('Nothing saved for today yet.'), findsOneWidget);
      },
    );
  }

  testWidgets('saving a mood writes today\'s entry and comes back on reopen',
      (tester) async {
    await _pumpLifestyle(tester, const Size(390, 844));

    await tester.ensureVisible(find.text('Tired'));
    await tester.pump();
    await tester.tap(find.text('Tired'));
    await tester.pump();

    final Finder save = find.widgetWithText(FilledButton, 'Save today');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(await DailyLog.entry(DailyLog.mood), 'Tired');
    expect(await DailyLog.counter(DailyLog.energy), 5);
    expect(find.text('Saved today: Tired · energy 5/10'), findsOneWidget);

    // A fresh screen reads today's entry rather than starting blank.
    await tester.pumpWidget(_harness(const LifestyleToolsScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text('Saved today: Tired · energy 5/10'), findsOneWidget);
  });
}
