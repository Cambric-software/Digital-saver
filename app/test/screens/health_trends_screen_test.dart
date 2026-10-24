/// The Patterns panel on the Trends page.
///
/// These tests supply samples directly, so they do not depend on the platform
/// directory plugin. They check the three states the panel can be in: no
/// history at all, a window with no measured values, and enough readings for a
/// resting estimate and a direction.
library;

import 'package:digital_saver/features/screens/health_trends_screen.dart';
import 'package:digital_saver/core/services/local_store.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WatchSample _sample(DateTime at, {int hr = 0, int spo2 = 0}) {
  return WatchSample(
    unix: at.toUtc().millisecondsSinceEpoch ~/ 1000,
    hr: hr,
    spo2: spo2,
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<WatchSample> samples,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HealthTrendsScreen(samples: samples),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('no stored history says so instead of drawing a pattern',
      (WidgetTester tester) async {
    await _pump(tester, const <WatchSample>[]);

    expect(find.text('No watch history yet'), findsOneWidget);
    expect(find.text('Patterns'), findsNothing);
  });

  testWidgets('a window with no measured value has an honest empty state',
      (WidgetTester tester) async {
    final DateTime now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12);
    await _pump(tester, <WatchSample>[
      _sample(now.subtract(const Duration(hours: 1))),
      _sample(now.subtract(const Duration(hours: 2))),
    ]);

    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('No patterns in this window'), findsOneWidget);
    expect(
      find.textContaining('nothing is inferred from an empty window'),
      findsOneWidget,
    );
  });

  testWidgets('enough readings produce a resting estimate and a direction',
      (WidgetTester tester) async {
    final DateTime now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12);
    await _pump(tester, <WatchSample>[
      _sample(now.subtract(const Duration(days: 1, hours: 2)),
          hr: 50, spo2: 98),
      _sample(now.subtract(const Duration(days: 1, hours: 1)),
          hr: 60, spo2: 96),
      _sample(now.subtract(const Duration(hours: 2)), hr: 70, spo2: 95),
      _sample(now.subtract(const Duration(hours: 1)), hr: 80, spo2: 99),
    ]);

    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Resting heart rate'), findsOneWidget);
    expect(find.text('50 BPM'), findsOneWidget);
    expect(find.text('Rising (+20 BPM)'), findsOneWidget);
    expect(find.text('Lowest oxygen'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(
      find.textContaining('Mean of the lowest quarter of 4 measured readings'),
      findsOneWidget,
    );
  });

  testWidgets('too few readings show -- and the shortfall',
      (WidgetTester tester) async {
    final DateTime now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12);
    await _pump(tester, <WatchSample>[
      _sample(now.subtract(const Duration(hours: 2)), hr: 60),
      _sample(now.subtract(const Duration(hours: 1)), hr: 62),
    ]);

    expect(find.text('Resting heart rate'), findsOneWidget);
    expect(find.text('--'), findsWidgets);
    expect(
      find.textContaining('This window has 2 on 1 day.'),
      findsOneWidget,
    );
  });
}
