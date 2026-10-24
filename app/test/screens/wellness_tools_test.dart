/// Renders the rebuilt wellness screen at both real widths and checks that what
/// it claims to keep is actually kept.
library;

import 'package:digital_saver/screens/wellness_tools_screen.dart';
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

Future<void> _pumpWellness(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(const WellnessToolsScreen()));
  // Two fixed pumps rather than pumpAndSettle: the screen shows a spinner
  // while the stored counts load, and an indeterminate spinner never settles.
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const List<String> headings = <String>[
    'Hydration today',
    'Emergency card',
    'Box breathing',
    'Caffeine today',
    'Rest between sets',
    'Walking stride',
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
        await _pumpWellness(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('Wellness tools'), findsOneWidget);
        for (final String heading in headings) {
          expect(
            find.text(heading),
            findsOneWidget,
            reason: '$heading is missing',
          );
        }

        // Nothing has been entered, so no emergency details are invented.
        expect(find.text('No emergency details yet'), findsOneWidget);
        expect(find.text('A+'), findsNothing);
        expect(find.text('0 of 8 glasses'), findsOneWidget);
      },
    );
  }

  testWidgets('logging a glass survives reopening the screen', (tester) async {
    await _pumpWellness(tester, const Size(390, 844));

    await tester.tap(find.widgetWithText(FilledButton, 'Add a glass'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(await DailyLog.counter(DailyLog.hydrationGlasses), 1);
    expect(find.text('1 of 8 glasses'), findsOneWidget);

    // A fresh screen reads the stored day rather than starting at zero.
    await tester.pumpWidget(_harness(const WellnessToolsScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text('1 of 8 glasses'), findsOneWidget);
  });
}
