/// Renders the rebuilt fitness screen at both real widths and checks the two
/// things that used to be fake: the medication list and the recovery empty
/// state.
library;

import 'package:digital_saver/screens/fitness_tools_screen.dart';
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

Future<void> _pumpFitness(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(const FitnessToolsScreen()));
  // Fixed pumps rather than pumpAndSettle: the screen shows a spinner while
  // the stored list, profile and rating load, and a spinner never settles.
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const List<String> headings = <String>[
    'Medications and supplements',
    'Heart rate recovery',
    'Workout timer',
    'Heart rate zones',
    'Effort (RPE)',
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
        await _pumpFitness(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('Fitness tools'), findsOneWidget);
        for (final String heading in headings) {
          expect(
            find.text(heading),
            findsOneWidget,
            reason: '$heading is missing',
          );
        }

        // No watch is connected in the harness, so the recovery card explains
        // what it needs instead of showing a sample peak and post rate.
        expect(find.text('No watch connected'), findsOneWidget);
        expect(find.text('Record resting rate'), findsNothing);
        expect(find.text('155'), findsNothing);
        expect(find.text('120'), findsNothing);

        // No profile is stored either, so zones do not invent an age.
        expect(find.text('No age saved'), findsOneWidget);
        expect(find.text('Estimated maximum: 204 bpm'), findsNothing);

        // The old screen opened with three named products. None are here.
        expect(find.text('Vitamin D3'), findsNothing);
        expect(find.text('Nothing on the list yet'), findsOneWidget);
      },
    );
  }

  testWidgets('a medication survives reopening the screen', (tester) async {
    await _pumpFitness(tester, const Size(390, 844));

    await tester.tap(find.widgetWithText(FilledButton, 'Add one'));
    await tester.pumpAndSettle();

    // Scope the fields to the dialog: the screen behind it also has a
    // TextField for the effort note, and it comes first in the tree.
    final Finder fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'Vitamin D3');
    await tester.enterText(fields.last, '2000 IU');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    final List<Medication> stored = await StorageService.medications();
    expect(stored, hasLength(1));
    expect(stored.single.name, 'Vitamin D3');
    expect(stored.single.dose, '2000 IU');
    expect(find.text('Vitamin D3'), findsOneWidget);

    // A fresh screen reads the stored list instead of starting empty.
    await tester.pumpWidget(_harness(const FitnessToolsScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text('Vitamin D3'), findsOneWidget);
    expect(find.text('2000 IU'), findsOneWidget);
    expect(find.text('Nothing on the list yet'), findsNothing);
  });

  testWidgets('a saved profile shows bands without a live rate',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'veyro_profile': '{"age":30,"weightKg":70,"heightCm":170}',
    });
    await _pumpFitness(tester, const Size(390, 844));

    // 220 − 30. The bands are printed; no live rate is marked.
    expect(find.text('Estimated maximum: 190 bpm'), findsOneWidget);
    expect(find.text('95–114 bpm'), findsOneWidget);
    expect(
      find.text('No live heart rate, so no band is marked. The bands are shown '
          'on their own.'),
      findsOneWidget,
    );
    expect(find.text('No age saved'), findsNothing);
  });
}
