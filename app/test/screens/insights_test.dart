/// Renders the Insights page at the two widths the app is used at and checks
/// that each segment can be reached.
///
/// The three bodies read stored history in `initState`, and that read never
/// completes in a widget test because the platform directory plugin is not
/// registered. The screen therefore stays on its loading card, which is why the
/// assertions are about the page frame and the section headings rather than
/// about values. `pumpAndSettle` is not used: a progress indicator never
/// settles.
library;

import 'package:digital_saver/screens/insights_screen.dart';
import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stub_notifications.dart';

/// The providers the app supplies, matching the screen capture harness.
Widget _harness() {
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
      home: const Scaffold(body: InsightsScreen()),
    ),
  );
}

/// Pump the page and let one async state change land.
Future<void> _pumpPage(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_harness());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Tap a segment and let its body build.
Future<void> _select(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(useStubNotifications);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final Size size in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'insights renders and switches segments at ${size.width.toInt()}px',
      (WidgetTester tester) async {
        await _pumpPage(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('Trends'), findsOneWidget);
        expect(find.text('Guidance'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Health trends'), findsOneWidget);

        await _select(tester, 'Guidance');
        expect(tester.takeException(), isNull);
        expect(find.text('Reading guidance'), findsOneWidget);
        expect(find.text('Health trends'), findsNothing);

        await _select(tester, 'Progress');
        expect(tester.takeException(), isNull);
        expect(find.text('Milestones'), findsOneWidget);
        expect(find.text('Reading guidance'), findsNothing);

        await _select(tester, 'Trends');
        expect(tester.takeException(), isNull);
        expect(find.text('Health trends'), findsOneWidget);
      },
    );
  }
}
