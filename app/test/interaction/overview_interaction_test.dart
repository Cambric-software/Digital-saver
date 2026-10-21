// Interaction tests for the overview screens: Today, Vitals and its four
// bodies, and Insights and its three.
//
// Every control is driven at both required widths. A screen whose body has no
// controls is covered through its host, because rendering it on its own would
// not exercise anything its host does.
library;

import 'package:digital_saver/screens/activity_screen.dart';
import 'package:digital_saver/screens/dashboard_screen.dart';
import 'package:digital_saver/screens/heart_screen.dart';
import 'package:digital_saver/screens/insights_screen.dart';
import 'package:digital_saver/screens/sleep_screen.dart';
import 'package:digital_saver/screens/vitals_screen.dart';
import 'package:digital_saver/services/daily_log.dart';
import 'package:digital_saver/widgets/ds_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/stub_notifications.dart';
import '../support/app_harness.dart';

/// Taps a segmented-control option, scrolling it into view first.
Future<void> tapOption(WidgetTester tester, Finder option) async {
  await tester.ensureVisible(option);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(option);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Taps a segmented-control option by its exact label.
Future<void> tapSegment(WidgetTester tester, String label) {
  return tapOption(tester, find.text(label));
}

void main() {
  setUpAll(useStubNotifications);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final Size size in interactionSizes) {
    final String at = '${size.width.toInt()}x${size.height.toInt()}';

    group('dashboard at $at', () {
      testWidgets('data-source button switches modes and BP tile navigates',
          (WidgetTester tester) async {
        await pumpScreen(tester, const DashboardScreen(), size: size);

        expect(find.text('No watch connected'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.sensors_rounded));
        await tester.pump();
        expect(find.text('Watch connected'), findsOneWidget);
        expect(find.text('76%'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.science_outlined));
        await tester.pump();
        expect(find.text('No watch connected'), findsOneWidget);

        await scrollTo(tester, find.text('BLOOD PRESSURE'));
        await tester.tap(find.text('BLOOD PRESSURE'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('What the bands are'), findsOneWidget);
      });

      testWidgets('quick actions log water and open both tools',
          (WidgetTester tester) async {
        await pumpScreen(tester, const DashboardScreen(), size: size);

        await scrollTo(tester, find.text('Log water'));
        await tester.tap(find.text('Log water'));
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('1 glass today.'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.hydrationGlasses), 1);

        await scrollTo(tester, find.text('Breathe'));
        await tester.tap(find.text('Breathe'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Box breathing'), findsOneWidget);
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await scrollTo(tester, find.text('Log mood'));
        await tester.tap(find.text('Log mood'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Mood and energy'), findsOneWidget);
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // The command channel is never ready without a real watch, so the
        // control is disabled and the card says why.
        expect(
          find.text('Connect the watch to pull its memory.'),
          findsOneWidget,
        );
        expect(tester.widget<DsCard>(cardWithText('Pull watch memory')).onTap,
            isNull);
      });
    });

    group('vitals at $at', () {
      testWidgets('all four tabs render their own body',
          (WidgetTester tester) async {
        await pumpScreen(tester, const VitalsScreen(), size: size);

        expect(find.text('Heart rate variability'), findsOneWidget);

        await tapSegment(tester, 'Motion');
        expect(find.text('Steps by hour'), findsOneWidget);

        await tapSegment(tester, 'Sleep & HRV');
        // The tab body is built on selection, so its history load has not had
        // the harness's real-event-loop turns yet.
        await settleLoads(tester);
        expect(find.text('Stored history could not be read'), findsOneWidget);

        await tapSegment(tester, 'Sensors');
        expect(find.text('MAX30102 Optical PPG'), findsOneWidget);
        expect(find.text('MPU6050 6-axis IMU'), findsOneWidget);

        await tapOption(tester, find.textContaining('Heart &'));
        expect(find.text('Heart rate variability'), findsOneWidget);
      });
    });

    group('heart at $at', () {
      testWidgets('body renders its four panels', (WidgetTester tester) async {
        await pumpScreen(tester, const HeartScreen(), size: size, embedded: true);
        expect(find.text('Heart rate variability'), findsOneWidget);
        expect(find.text('Heart rhythm'), findsOneWidget);
        expect(find.text('Training zones'), findsOneWidget);
      });
    });

    group('activity at $at', () {
      testWidgets('body renders its five panels', (WidgetTester tester) async {
        await pumpScreen(tester, const ActivityScreen(), size: size,
            embedded: true);
        expect(find.text('Steps'), findsWidgets);
        expect(find.text('Daily goals'), findsOneWidget);
        expect(find.text('Fall detection active'), findsOneWidget);
      });
    });

    group('sleep at $at', () {
      testWidgets('body says what is missing rather than inventing a night',
          (WidgetTester tester) async {
        await pumpScreen(tester, const SleepScreen(), size: size,
            embedded: true);
        expect(find.text('Stored history could not be read'), findsOneWidget);
        expect(find.text('Sleep stages are not available'), findsNothing);
      });
    });

    group('insights at $at', () {
      testWidgets('all three segments render their own body',
          (WidgetTester tester) async {
        await pumpScreen(tester, const InsightsScreen(), size: size);

        expect(find.text('Health trends'), findsOneWidget);

        await tapSegment(tester, 'Guidance');
        expect(find.text('Reading guidance'), findsOneWidget);

        await tapSegment(tester, 'Progress');
        expect(find.text('Milestones'), findsOneWidget);

        await tapSegment(tester, 'Trends');
        expect(find.text('Health trends'), findsOneWidget);
      });
    });
  }
}
