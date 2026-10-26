import 'package:digital_saver/features/screens/health_hub_screen.dart';
import 'package:digital_saver/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests that the hub does what its cards claim.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpHub(WidgetTester tester) async {
    // Tall enough that the whole page builds, so a control further down can be
    // tapped without scrolling surprises.
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HealthHubScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the suites and measurements are all listed', (tester) async {
    await pumpHub(tester);

    for (final String title in <String>[
      'Wellness',
      'Fitness',
      'Lifestyle',
      'Device & sensors',
      'Blood pressure',
      'Watch simulator',
    ]) {
      expect(find.text(title), findsOneWidget, reason: '$title is missing');
    }
  });

  testWidgets('the everyday timers are real controls', (tester) async {
    await pumpHub(tester);

    expect(find.text('Wash your hands'), findsOneWidget);
    expect(find.text('Brush your teeth'), findsOneWidget);
    expect(find.text('Eye break (20-20-20)'), findsOneWidget);
    expect(find.text('Focused work'), findsOneWidget);
    expect(find.text('Morning light'), findsOneWidget);
    expect(find.text('Cold exposure'), findsOneWidget);
    expect(find.text('Breath hold'), findsOneWidget);

    // No personal best has been recorded, so none is shown: zero seconds is
    // "nothing recorded", not a hold of zero.
    expect(find.textContaining('Best'), findsNothing);
  });

  testWidgets('saving a reflection stores it and shows it as written today',
      (tester) async {
    await pumpHub(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'Walked before work.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection saved'), findsOneWidget);
    final Reflection? stored = await StorageService.todayReflection();
    expect(stored, isNotNull);
    expect(stored!.text, 'Walked before work.');
    expect(find.textContaining('Written today'), findsOneWidget);
  });

  testWidgets('a stored reflection is shown when the hub opens',
      (tester) async {
    await StorageService.saveReflection('Slept eight hours.');
    await pumpHub(tester);

    expect(find.textContaining('Written today'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!
          .text,
      'Slept eight hours.',
    );
  });

  testWidgets('recording a breath hold keeps the longest', (tester) async {
    await pumpHub(tester);

    Finder record = find.widgetWithText(OutlinedButton, 'Record');
    await tester.ensureVisible(record);
    await tester.pumpAndSettle();

    // Nothing recorded yet, so the best is not shown.
    expect(find.textContaining('Best '), findsNothing);

    await tester.ensureVisible(find.text('Start').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));

    record = find.widgetWithText(OutlinedButton, 'Record');
    await tester.ensureVisible(record);
    await tester.pumpAndSettle();
    await tester.tap(record);
    await tester.pumpAndSettle();

    expect(await StorageService.breathHoldBest(), 21);
    expect(find.textContaining('New longest hold: 21s'), findsOneWidget);
    expect(find.textContaining('Best 00:21'), findsOneWidget);
  });
}
