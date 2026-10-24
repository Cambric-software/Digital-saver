import 'package:digital_saver/models/health_models.dart';
import 'package:digital_saver/screens/dashboard_screen.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Wraps a screen in the providers and theme it expects.
Widget harness(Widget child, {BleService? ble}) {
  return ChangeNotifierProvider<BleService>.value(
    value: ble ?? BleService(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('dashboard renders', () {
    testWidgets('shows the Today heading', (tester) async {
      await tester.pumpWidget(harness(const DashboardScreen()));
      await tester.pump();
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('says plainly that no watch is connected', (tester) async {
      await tester.pumpWidget(harness(const DashboardScreen()));
      await tester.pump();
      expect(find.text('No watch connected'), findsWidgets);
      expect(
        find.textContaining('Open the Watch tab'),
        findsOneWidget,
        reason: 'it must tell the person what to do, not just that it is broken',
      );
    });

    testWidgets('shows each vital by name', (tester) async {
      await tester.pumpWidget(harness(const DashboardScreen()));
      await tester.pump();
      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('BLOOD PRESSURE'), findsOneWidget);
      expect(find.text('OXYGEN'), findsOneWidget);
    });

    testWidgets('renders without overflowing at a phone width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(const DashboardScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at desktop width', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(const DashboardScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('a reading of zero is shown as missing, not as a number', () {
    testWidgets('no data means dashes, not "0"', (tester) async {
      await tester.pumpWidget(harness(const DashboardScreen()));
      await tester.pump();
      // A heart rate of 0 bpm is not a measurement, and showing it as one
      // invites someone to act on it.
      expect(find.text('0'), findsNothing);
      expect(find.text('--'), findsWidgets);
    });
  });

  group('health status carries meaning beyond colour', () {
    test('each status has a word and an icon', () {
      for (final status in HealthStatus.values) {
        expect(status.label, isNotEmpty, reason: '$status needs a label');
        expect(status.icon, isNotNull, reason: '$status needs a shape cue');
      }
    });

    test('normal and unknown are distinguishable', () {
      expect(HealthStatus.normal.label, isNot(HealthStatus.unknown.label));
      expect(HealthStatus.normal.icon, isNot(HealthStatus.unknown.icon));
    });

    test('critical is visually distinct from elevated', () {
      expect(HealthStatus.critical.icon, isNot(HealthStatus.elevated.icon));
      expect(HealthStatus.critical.label, isNot(HealthStatus.elevated.label));
    });
  });

  group('model defaults', () {
    test('an unset heart rate reports zero, which the UI must treat as absent',
        () {
      final hr = HeartRateData();
      expect(hr.bpm, 0);
    });

    test('an unset blood pressure reports zero', () {
      final bp = BloodPressureData();
      expect(bp.systolic, 0);
      expect(bp.diastolic, 0);
    });
  });
}