/// Renders the rebuilt watch simulator at both real widths and checks that it
/// describes itself as a preview rather than a connection.
library;

import 'package:digital_saver/screens/watch_simulator_screen.dart';
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

Future<void> _pumpSimulator(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(const WatchSimulatorScreen()));
  await tester.pump();
}

/// The screen no longer animates, but the binding should still be left with no
/// live ticker in case one is added back.
Future<void> _disposeSimulator(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const List<String> headings = <String>[
    'Preview only',
    'Face preview',
    'What this preview cannot do',
  ];

  for (final Size size in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'renders every retained card at ${size.width.toInt()}x'
      '${size.height.toInt()}',
      (tester) async {
        await _pumpSimulator(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('Watch simulator'), findsOneWidget);
        for (final String heading in headings) {
          expect(
            find.text(heading),
            findsOneWidget,
            reason: '$heading is missing',
          );
        }

        // The old screen called itself connected and printed a firmware and a
        // sync time it never read.
        expect(find.text('Connected'), findsNothing);
        expect(find.text('v2.3.1'), findsNothing);
        expect(find.text('Last Sync'), findsNothing);

        await _disposeSimulator(tester);
      },
    );
  }

  testWidgets('switching the preview to digital draws the sample layout',
      (tester) async {
    await _pumpSimulator(tester, const Size(390, 844));

    await tester.tap(find.text('Digital'));
    await tester.pump();

    expect(find.text('10:10'), findsOneWidget);
    expect(find.text('SAMPLE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _disposeSimulator(tester);
  });
}
