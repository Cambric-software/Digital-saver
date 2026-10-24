import 'package:digital_saver/features/widgets/ds_timers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests that the timers keep time.
///
/// These exist because the controls they replace did not: "Start Breath Hold"
/// set a boolean and the seconds never moved. A test that pumps a second and
/// reads the clock back is the difference between a timer and a picture of one.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  testWidgets('a countdown counts down and reaches zero', (tester) async {
    int finished = 0;
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        DsCountdown(
          title: 'Wash your hands',
          icon: Icons.clean_hands_outlined,
          duration: const Duration(seconds: 10),
          onFinished: () => finished++,
        ),
      ),
    );

    expect(find.text('00:10'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('00:08'), findsOneWidget);
    expect(finished, 0);

    // Pause holds the value.
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:08'), findsOneWidget);

    // Resume finishes it, and says so once.
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Start again'), findsOneWidget);
    expect(finished, 1);
  });

  testWidgets('reset returns a countdown to its full length', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DsCountdown(
          title: 'Eye break',
          icon: Icons.remove_red_eye_outlined,
          duration: Duration(seconds: 20),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:15'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('00:20'), findsOneWidget);
  });

  testWidgets('a stepped countdown names the current step', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DsCountdown(
          title: 'Brush your teeth',
          icon: Icons.sentiment_very_satisfied_outlined,
          duration: Duration(minutes: 2),
          steps: 4,
          stepLabel: 'Quadrant',
        ),
      ),
    );

    expect(find.text('Quadrant 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Quadrant 2 of 4'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Quadrant 4 of 4'), findsOneWidget);
  });

  testWidgets('a stopwatch counts up and reports the target once',
      (tester) async {
    int reached = 0;
    await tester.pumpWidget(
      wrap(
        DsStopwatch(
          title: 'Morning light',
          icon: Icons.wb_sunny_outlined,
          target: const Duration(minutes: 1),
          reachedLabel: 'Target reached',
          onReachTarget: () => reached++,
        ),
      ),
    );

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('of 01:00'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('00:30'), findsOneWidget);
    expect(reached, 0);

    await tester.pump(const Duration(seconds: 35));
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('Target reached'), findsOneWidget);
    expect(reached, 1);
  });

  testWidgets('recording hands back the elapsed time', (tester) async {
    Duration? recorded;
    await tester.pumpWidget(
      wrap(
        DsStopwatch(
          title: 'Breath hold',
          icon: Icons.air_outlined,
          recordLabel: 'Record',
          onRecord: (Duration held) => recorded = held,
        ),
      ),
    );

    // Nothing to record before the timer has run.
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Record'),
      ).onPressed,
      isNull,
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 12));
    await tester.tap(find.text('Record'));
    await tester.pump();

    expect(recorded, const Duration(seconds: 12));
  });

  testWidgets('a stopwatch pauses and resets', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DsStopwatch(
          title: 'Cold exposure',
          icon: Icons.ac_unit_outlined,
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('00:04'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('00:04'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);
  });
}
