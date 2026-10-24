import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:digital_saver/widgets/ds_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests that every destination can actually be opened.
///
/// This is the bug these tests were written for: the bottom bar held five of six
/// destinations and the rail only appears at 1100px, so below that width the
/// Watch screen had no route at all. A destination that cannot be opened is not
/// a feature, and nothing in the suite could see it because each screen was
/// tested on its own.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget shell() {
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
        home: const DsShell(),
      ),
    );
  }

  testWidgets('at phone width, every destination is reachable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    await tester.pump(const Duration(milliseconds: 300));

    // The four in the bar. Scoped to the bar, because the dashboard is titled
    // "Today" too and an unscoped finder cannot tell the two apart.
    final Finder bar = find.byType(NavigationBar);
    for (final String label in <String>[
      'Today',
      'Vitals',
      'Insights',
      'Coach',
    ]) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
        reason: '$label is missing from the bar',
      );
    }

    // Everything else, through More.
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    for (final String label in <String>['Health hub', 'Watch', 'Settings']) {
      expect(find.text(label), findsOneWidget, reason: '$label is not listed');
    }

    await tester.tap(find.text('Health hub'));
    await tester.pumpAndSettle();

    // The hub is now the visible screen, and it says so.
    expect(find.text('Tool suites'), findsOneWidget);
  });

  testWidgets('at laptop width, the rail lists every destination',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    await tester.pump(const Duration(milliseconds: 300));

    for (final String label in <String>[
      'Today',
      'Vitals',
      'Insights',
      'Coach',
      'Health hub',
      'Watch',
      'Settings',
    ]) {
      // Page titles repeat some labels ("Today"), so presence is the claim,
      // not uniqueness.
      expect(find.text(label), findsWidgets, reason: '$label is missing');
    }

    // The rail replaces the bar, so there is no More to open.
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Health hub').first);
    await tester.pumpAndSettle();
    expect(find.text('Tool suites'), findsOneWidget);

    // Two pumps rather than settle: the Watch screen shows a progress spinner
    // while it loads stored samples, and a spinner never settles.
    await tester.tap(find.text('Watch').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Watch memory'), findsOneWidget);
  });
}
