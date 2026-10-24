/// The splash backdrop is a painting, not an animation.
///
/// The old effects file started a repeating controller for every decoration.
/// This test checks that the replacement schedules no frames and that its edge
/// cases (zero layers) do not throw.
library;

import 'package:digital_saver/features/widgets/creative_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _backdrop({int layers = 3}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: WaveBackdrop(layers: layers)),
          const Center(child: Text('content')),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('draws without scheduling an animation',
      (WidgetTester tester) async {
    await tester.pumpWidget(_backdrop());
    await tester.pumpAndSettle();

    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('time passing does not change the painting',
      (WidgetTester tester) async {
    await tester.pumpWidget(_backdrop());
    await tester.pump(const Duration(seconds: 5));

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero layers is a valid, empty backdrop',
      (WidgetTester tester) async {
    await tester.pumpWidget(_backdrop(layers: 0));
    await tester.pump();

    expect(find.byType(WaveBackdrop), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
