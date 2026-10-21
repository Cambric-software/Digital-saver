// Interaction tests for the health screens: the hub, blood pressure, trends,
// guidance and milestones.
//
// Every control is driven at both required widths. Screens with no controls of
// their own (blood pressure) are covered through the navigation that opens
// them, and say so in the report.
library;

import 'package:digital_saver/screens/achievements_screen.dart';
import 'package:digital_saver/screens/bp_screen.dart';
import 'package:digital_saver/screens/health_hub_screen.dart';
import 'package:digital_saver/screens/health_tips_screen.dart';
import 'package:digital_saver/screens/health_trends_screen.dart';
import 'package:digital_saver/services/local_store.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

/// Taps a section or segment by its visible label.
Future<void> tapLabel(WidgetTester tester, String label) async {
  final Finder target = find.text(label).first;
  await scrollTo(tester, target);
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 250));
}

/// The value shown on the metric tile labelled [label].
Finder metricValue(String label, String value) {
  return find.descendant(
    of: cardWithText(label.toUpperCase()),
    matching: find.text(value),
  );
}

/// A sample [ago] before [now], with a distinct heart rate and oxygen value.
WatchSample sampleAgo(
  DateTime now,
  Duration ago, {
  required int hr,
  required int spo2,
}) {
  return WatchSample(
    unix: now.subtract(ago).millisecondsSinceEpoch ~/ 1000,
    hr: hr,
    spo2: spo2,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final Size size in interactionSizes) {
    final String at = '${size.width.toInt()}x${size.height.toInt()}';

    group('health hub at $at', () {
      testWidgets('every suite card opens its own screen',
          (WidgetTester tester) async {
        await pumpScreen(tester, const HealthHubScreen(), size: size);
        expect(find.text('Health hub'), findsOneWidget);

        const Map<String, String> destinations = <String, String>{
          'Wellness': 'Wellness tools',
          'Fitness': 'Fitness tools',
          'Lifestyle': 'Lifestyle tools',
          'Device & sensors': 'Device diagnostics',
          // Both of these repeat their card title in the app bar, so the
          // destination is asserted on a heading only that screen has.
          'Blood pressure': 'What the bands are',
          'Watch simulator': 'Preview only',
        };

        for (final MapEntry<String, String> entry in destinations.entries) {
          await scrollTo(tester, find.text(entry.key));
          await tester.tap(find.text(entry.key));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.text(entry.value),
            findsOneWidget,
            reason: '${entry.key} did not open ${entry.value}',
          );

          await tester.pageBack();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }
      });

      testWidgets('a reflection is saved and read back',
          (WidgetTester tester) async {
        await pumpScreen(tester, const HealthHubScreen(), size: size);

        await enterByLabel(
          tester,
          'What went well today?',
          'Walked before work.',
        );
        await scrollTo(tester, find.text('Save'));
        await tester.tap(buttonWithText('Save'));
        await settleLoads(tester);

        expect(find.text('Reflection saved'), findsOneWidget);
        expect(find.textContaining('Written today'), findsOneWidget);
        final Reflection? stored = await StorageService.todayReflection();
        expect(stored?.text, 'Walked before work.');

        // A fresh screen reads the stored note instead of a blank field.
        await pumpScreen(tester, const HealthHubScreen(), size: size);
        expect(
          tester
              .widget<TextField>(
                find.widgetWithText(TextField, 'What went well today?'),
              )
              .controller!
              .text,
          'Walked before work.',
        );
      });

      testWidgets('all four countdowns and three stopwatches run and stop',
          (WidgetTester tester) async {
        await pumpScreen(tester, const HealthHubScreen(), size: size);

        const Map<String, (String, String)> countdowns =
            <String, (String, String)>{
          'Wash your hands': ('00:20', '00:19'),
          'Brush your teeth': ('02:00', '01:59'),
          'Eye break (20-20-20)': ('00:20', '00:19'),
          'Focused work': ('25:00', '24:59'),
        };

        for (final MapEntry<String, (String, String)> entry
            in countdowns.entries) {
          final String title = entry.key;
          final String initial = entry.value.$1;
          final String ticked = entry.value.$2;

          await scrollTo(tester, find.text(title));
          expect(inCard(title, find.text(initial)), findsOneWidget);

          await tester.tap(buttonInCard(title, 'Start'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(
            inCard(title, find.text(ticked)),
            findsOneWidget,
            reason: '$title did not count down',
          );

          await tester.tap(buttonInCard(title, 'Pause'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(
            inCard(title, find.text(ticked)),
            findsOneWidget,
            reason: '$title kept counting after Pause',
          );

          await tester.tap(buttonInCard(title, 'Reset'));
          await tester.pump();
          expect(
            inCard(title, find.text(initial)),
            findsOneWidget,
            reason: '$title did not return to $initial',
          );
        }

        const List<String> stopwatches = <String>[
          'Morning light',
          'Cold exposure',
        ];
        for (final String title in stopwatches) {
          await scrollTo(tester, find.text(title));
          expect(inCard(title, find.text('00:00')), findsOneWidget);
          await tester.tap(buttonInCard(title, 'Start'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(inCard(title, find.text('00:01')), findsOneWidget);

          await tester.tap(buttonInCard(title, 'Pause'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(
            inCard(title, find.text('00:01')),
            findsOneWidget,
            reason: '$title kept counting after Pause',
          );
          await tester.tap(buttonInCard(title, 'Reset'));
          await tester.pump();
          expect(inCard(title, find.text('00:00')), findsOneWidget);
        }

        // The breath-hold stopwatch records only what was actually held.
        await scrollTo(tester, find.text('Breath hold'));
        expect(
          tester
              .widget<OutlinedButton>(buttonInCard('Breath hold', 'Record'))
              .onPressed,
          isNull,
          reason: 'Record must be disabled before any hold is counted',
        );
        await tester.tap(buttonInCard('Breath hold', 'Start'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(buttonInCard('Breath hold', 'Record'));
        await settleLoads(tester);

        expect(find.text('New longest hold: 2s'), findsOneWidget);
        expect(inCard('Breath hold', find.text('Best 00:02')), findsOneWidget);
        expect(await StorageService.breathHoldBest(), 2);

        await tester.tap(buttonInCard('Breath hold', 'Reset'));
        await tester.pump();
        expect(inCard('Breath hold', find.text('00:00')), findsOneWidget);
      });
    });

    group('blood pressure at $at', () {
      testWidgets('states why there is no reading and has no dead controls',
          (WidgetTester tester) async {
        await pumpScreen(tester, const BpScreen(), size: size);

        expect(find.text('Blood pressure'), findsOneWidget);
        expect(find.text('What the bands are'), findsOneWidget);
        // The watch reports no blood pressure, so the screen must say that
        // rather than print a plausible number.
        expect(
          find.text('No watch is connected, so there is nothing to show.'),
          findsOneWidget,
        );
        expect(find.text('--'), findsWidgets);
        // Nothing on this screen claims to be a control, so there is nothing
        // dead to find.
        expect(find.byType(ButtonStyleButton), findsNothing);
      });
    });

    group('health trends at $at', () {
      testWidgets('period segments change the window and reload is live',
          (WidgetTester tester) async {
        final DateTime now = DateTime.now();
        final List<WatchSample> samples = <WatchSample>[
          sampleAgo(now, const Duration(hours: 1), hr: 60, spo2: 98),
          sampleAgo(now, const Duration(days: 3), hr: 70, spo2: 96),
          sampleAgo(now, const Duration(days: 20), hr: 80, spo2: 95),
          sampleAgo(now, const Duration(days: 60), hr: 90, spo2: 94),
        ];

        await pumpScreen(
          tester,
          HealthTrendsScreen(samples: samples),
          size: size,
          embedded: true,
        );

        expect(find.text('Health trends'), findsOneWidget);
        expect(metricValue('Readings in window', '2'), findsOneWidget);

        await tapLabel(tester, '24 hours');
        expect(metricValue('Readings in window', '1'), findsOneWidget);

        await tapLabel(tester, '30 days');
        expect(metricValue('Readings in window', '3'), findsOneWidget);

        await tapLabel(tester, 'All kept');
        expect(metricValue('Readings in window', '4'), findsOneWidget);

        await tapLabel(tester, '7 days');
        expect(metricValue('Readings in window', '2'), findsOneWidget);

        // The reload button re-runs the real read. Supplied samples are not
        // the stored history, so in a test harness without a filesystem the
        // read fails and the screen says so rather than keeping stale numbers.
        await scrollTo(tester, find.byTooltip('Reload stored history'));
        await tester.tap(find.byTooltip('Reload stored history'));
        await tester.pump();
        expect(find.text('Reading stored history…'), findsOneWidget);
        await settleLoads(tester);
        expect(find.text('Stored history could not be read'), findsOneWidget);
      });
    });

    group('health guidance at $at', () {
      testWidgets('reload runs the stored read and reports its failure',
          (WidgetTester tester) async {
        await pumpScreen(tester, const HealthTipsScreen(), size: size,
            embedded: true);

        expect(find.text('Reading guidance'), findsOneWidget);
        expect(find.text('What the bands mean'), findsOneWidget);
        expect(find.text('Stored history could not be read'), findsOneWidget);

        await scrollTo(tester, find.byTooltip('Reload stored history'));
        await tester.tap(find.byTooltip('Reload stored history'));
        await tester.pump();
        expect(find.text('Reading stored history…'), findsOneWidget);
        await settleLoads(tester);
        expect(find.text('Stored history could not be read'), findsOneWidget);
      });
    });

    group('achievements at $at', () {
      testWidgets('reload runs the stored count and reports its failure',
          (WidgetTester tester) async {
        await pumpScreen(tester, const AchievementsScreen(), size: size,
            embedded: true);

        expect(find.text('Milestones'), findsOneWidget);
        expect(find.text('Stored history could not be read'), findsOneWidget);

        await scrollTo(tester, find.byTooltip('Reload stored history'));
        await tester.tap(find.byTooltip('Reload stored history'));
        await tester.pump();
        expect(find.text('Counting stored samples…'), findsOneWidget);
        await settleLoads(tester);
        expect(find.text('Stored history could not be read'), findsOneWidget);
      });
    });
  }
}
