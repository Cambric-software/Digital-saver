// Settings has to render at both widths, and every control that claims to save
// has to reach StorageService. These tests render the real screen with the
// providers main.dart supplies, then exercise the two settings whose failure
// would be easiest to miss: demo mode and a threshold.

import 'package:digital_saver/screens/settings_screen.dart';
import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stub_notifications.dart';

/// The same provider set the capture harness uses, because Settings reads all
/// of them during its first frame.
Widget harness(Widget child) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<BleService>(create: (_) => BleService()),
      ChangeNotifierProvider<HeartRateTracker>(
          create: (_) => HeartRateTracker()),
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
      home: Scaffold(body: child),
    ),
  );
}

/// Renders Settings at [size] and waits for the stored values to arrive.
///
/// Two fixed pumps rather than pumpAndSettle: while the load is running the
/// page shows a [CircularProgressIndicator], which never settles.
Future<void> pumpSettings(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(harness(const SettingsScreen()));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(useStubNotifications);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const List<Size> sizes = <Size>[
    Size(390, 844),
    Size(1440, 900),
  ];

  const List<String> headings = <String>[
    'Appearance & language',
    'Watch & sync',
    'Watch face & complications',
    'Health alerts',
    'Quick replies',
    'Profile',
    'Emergency contacts',
    'App lock',
    'Your data',
    'About & updates',
    'Licence',
  ];

  for (final Size size in sizes) {
    testWidgets(
      'renders every section at ${size.width.toInt()}x${size.height.toInt()}',
      (WidgetTester tester) async {
        await pumpSettings(tester, size);

        expect(tester.takeException(), isNull);
        for (final String heading in headings) {
          expect(
            find.text(heading),
            findsOneWidget,
            reason: '$heading is missing at ${size.width.toInt()}px',
          );
        }

        // The screen is a page inside the shell, not a second Scaffold with an
        // AppBar. Finding either here means the frame was nested again.
        expect(find.byType(AppBar), findsNothing);
      },
    );
  }

  testWidgets('toggling demo mode persists through StorageService',
      (WidgetTester tester) async {
    await pumpSettings(tester, const Size(390, 844));

    expect(await StorageService.demoMode(), isFalse);

    final Finder tile = find.widgetWithText(SwitchListTile, 'Demo mode');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();
    await tester.pump();

    expect(await StorageService.demoMode(), isTrue);
    expect(
      await StorageService.demoMode(),
      isNot(StorageService.defaultDemoMode),
      reason: 'the saved value, not just the switch, has to change',
    );
  });

  testWidgets('the dim-after-dark switch saves and explains the hours',
      (WidgetTester tester) async {
    await pumpSettings(tester, const Size(390, 844));

    expect(await StorageService.dimAfterDark(), isFalse);
    final Finder tile = find.widgetWithText(SwitchListTile, 'Dim after dark');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Off. The theme you picked is used all day.'),
      findsOneWidget,
    );

    await tester.tap(tile);
    await tester.pump();
    await tester.pump();

    expect(await StorageService.dimAfterDark(), isTrue);
    expect(
      find.textContaining(
        'On. The dark theme is used from 20:00 to 07:00.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('changing each threshold persists', (WidgetTester tester) async {
    await pumpSettings(tester, const Size(390, 844));

    expect(find.byType(Slider), findsNWidgets(2));

    // High heart rate.
    await tester.ensureVisible(find.byType(Slider).first);
    await tester.pumpAndSettle();
    Slider slider = tester.widget<Slider>(find.byType(Slider).first);
    slider.onChanged!(130);
    await tester.pump();
    slider = tester.widget<Slider>(find.byType(Slider).first);
    slider.onChangeEnd!(130);
    await tester.pump();
    await tester.pump();

    expect(await StorageService.highHrThreshold(), 130);
    expect(find.text('Saved at 130 BPM or above.'), findsOneWidget);

    // Low oxygen.
    Slider oxygen = tester.widget<Slider>(find.byType(Slider).at(1));
    oxygen.onChanged!(88);
    await tester.pump();
    oxygen = tester.widget<Slider>(find.byType(Slider).at(1));
    oxygen.onChangeEnd!(88);
    await tester.pump();
    await tester.pump();

    expect(await StorageService.lowSpo2Threshold(), 88);
    expect(find.text('Saved at 88% or below.'), findsOneWidget);
  });
}
