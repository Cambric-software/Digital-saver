/// Renders the rebuilt diagnostics screen at both real widths and checks that
/// the disconnected state reports nothing it has not read.
library;

import 'package:digital_saver/screens/device_diagnostics_screen.dart';
import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:digital_saver/theme/app_theme.dart';
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

Future<void> _pumpDiagnostics(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(const DeviceDiagnosticsScreen()));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const List<String> headings = <String>[
    'Connection',
    'Watch',
    'Memory sync',
    'Watch face',
    'What this app can and cannot do',
    'About these readings',
  ];

  for (final Size size in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'renders every retained card at ${size.width.toInt()}x'
      '${size.height.toInt()}',
      (tester) async {
        await _pumpDiagnostics(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('Device diagnostics'), findsOneWidget);
        for (final String heading in headings) {
          expect(
            find.text(heading),
            findsOneWidget,
            reason: '$heading is missing',
          );
        }

        expect(find.text('No watch is connected'), findsOneWidget);
        expect(find.text('Not connected'), findsOneWidget);
        // Firmware, samples, free space and battery are all unknown.
        expect(find.text('--'), findsNWidgets(4));
        expect(find.text('Not recorded'), findsOneWidget);

        // The old screen printed these as facts without reading them.
        expect(find.text('ota_0 (Running v1.0.3-beta)'), findsNothing);
        expect(find.text('99.4'), findsNothing);
        expect(find.text('Raw PPG'), findsNothing);
      },
    );
  }

  testWidgets('sending a face is disabled with no watch connected',
      (tester) async {
    await _pumpDiagnostics(tester, const Size(390, 844));

    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send face 1'),
    );
    expect(button.onPressed, isNull);
  });
}
