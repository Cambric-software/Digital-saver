/// The pulse ring follows the measured heart rate, and stops when there is no
/// reading.
///
/// The old animation file had seven widgets, including a pulse that beat at a
/// fixed rate regardless of the data. These tests pin the relationship between
/// BPM and period, and check that a zero reading schedules no animation at all.
library;

import 'package:digital_saver/widgets/enhanced_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _ring(double bpm) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: HeartPulseRing(
          bpm: bpm,
          child: const Icon(Icons.favorite_rounded),
        ),
      ),
    ),
  );
}

void main() {
  group('the beat interval', () {
    test('one beat per second at 60 BPM', () {
      expect(
        HeartPulseRing.periodForBpm(60),
        const Duration(milliseconds: 1000),
      );
    });

    test('two beats per second at 120 BPM', () {
      expect(
        HeartPulseRing.periodForBpm(120),
        const Duration(milliseconds: 500),
      );
    });

    test('a slow rate produces a long interval', () {
      expect(
        HeartPulseRing.periodForBpm(40),
        const Duration(milliseconds: 1500),
      );
    });

    test('no reading means no period', () {
      expect(HeartPulseRing.periodForBpm(0), isNull);
      expect(HeartPulseRing.periodForBpm(-10), isNull);
      expect(HeartPulseRing.periodForBpm(double.nan), isNull);
      expect(HeartPulseRing.periodForBpm(double.infinity), isNull);
    });
  });

  testWidgets('a live reading schedules a repeating animation',
      (WidgetTester tester) async {
    await tester.pumpWidget(_ring(72));
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('a missing reading does not animate',
      (WidgetTester tester) async {
    await tester.pumpWidget(_ring(0));
    await tester.pumpAndSettle();

    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('disposing the ring leaves no ticker behind',
      (WidgetTester tester) async {
    await tester.pumpWidget(_ring(90));
    await tester.pump(const Duration(milliseconds: 16));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
