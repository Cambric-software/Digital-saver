// The Watch screen must never turn an absent measurement into a zero. An empty
// log gets an empty state; a log with two rows gets the two rows' actual
// averages. The pull control is disabled, with a reason, until a watch connects.

import 'package:digital_saver/screens/memory_screen.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/local_store.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The screen reads BleService for the watch's own state and for the pull.
Widget harness(Widget child) {
  return ChangeNotifierProvider<BleService>(
    create: (_) => BleService(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

Future<void> pumpMemory(
  WidgetTester tester,
  Future<List<WatchSample>> Function() loadSamples,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(harness(MemoryScreen(loadSamples: loadSamples)));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('an empty log shows the empty state, not zeros',
      (WidgetTester tester) async {
    await pumpMemory(tester, () async => <WatchSample>[]);

    expect(find.text('No samples yet'), findsOneWidget);
    expect(
      find.textContaining('Pair the watch and pull once'),
      findsOneWidget,
      reason: 'an empty screen has to say what would fill it',
    );

    // The old screen printed "Samples 0", "Avg HR 0" and "Falls 0", which
    // reads as a measurement rather than an absence.
    expect(find.text('0'), findsNothing);
    expect(find.text('AVERAGE HEART RATE'), findsNothing);

    // Pull is a real control, and it says why it cannot run.
    final FilledButton pull = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Pull from Veyro'),
    );
    expect(pull.onPressed, isNull);
    expect(
      find.textContaining('Pull is disabled until a watch is connected'),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a stored log shows its sample count and measured averages',
      (WidgetTester tester) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await pumpMemory(
      tester,
      () async => <WatchSample>[
        WatchSample(
          unix: now - 7200,
          hr: 62,
          spo2: 97,
          steps: 120,
          bat: 81,
        ),
        WatchSample(
          unix: now - 3600,
          hr: 84,
          spo2: 95,
          steps: 240,
          bat: 80,
        ),
      ],
    );

    expect(find.text('No samples yet'), findsNothing);

    // Two samples, average 73 BPM, resting estimate 62 BPM, average SpO2 96%.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
    expect(find.text('96'), findsOneWidget);

    // The analyzer's own account of the log is shown, including how many rows
    // it read.
    expect(find.textContaining('2 samples from'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
