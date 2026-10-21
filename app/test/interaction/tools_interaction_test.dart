// Interaction tests for the three tool suites.
//
// These screens are mostly forms, timers and counters, so the assertions go to
// the owning service as well as the screen: a snackbar on its own does not
// prove that anything was stored.
library;

import 'package:digital_saver/models/health_models.dart';
import 'package:digital_saver/screens/fitness_tools_screen.dart';
import 'package:digital_saver/screens/lifestyle_tools_screen.dart';
import 'package:digital_saver/screens/wellness_tools_screen.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/daily_log.dart';
import 'package:digital_saver/services/local_store.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

/// Pumps until an asynchronous dialog or route has finished animating.
Future<void> settleDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Scrolls [target] into view, then taps it.
///
/// `ensureVisible` aligns a control with the top of the viewport, so a tap made
/// after an earlier scroll can land above the screen once a card has changed
/// height. Every tap in this file goes through here for that reason.
Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await scrollTo(tester, target);
  await tester.tap(target);
  await tester.pump();
}

/// Stops the demo timer and tears the tree down so no repeating timer outlives
/// the test.
Future<void> stopDemoAndDispose(WidgetTester tester) async {
  serviceOf<BleService>(tester).stopDemo();
  await tester.pump();
  await tester.pumpWidget(const SizedBox.shrink());
}

/// The value on the metric tile labelled [label], uppercase because DsLabel
/// upper-cases it.
Finder metricValue(String label, String value) {
  return find.descendant(
    of: cardWithText(label.toUpperCase()),
    matching: find.text(value),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final Size size in interactionSizes) {
    final String at = '${size.width.toInt()}x${size.height.toInt()}';

    group('fitness tools at $at', () {
      testWidgets('medication can be cancelled, added, edited and removed',
          (WidgetTester tester) async {
        await pumpScreen(tester, const FitnessToolsScreen(), size: size);
        expect(find.text('Nothing on the list yet'), findsOneWidget);

        await scrollTo(tester, find.text('Add one'));
        await tester.tap(buttonWithText('Add one'));
        await settleDialog(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: buttonWithText('Cancel'),
        ));
        await settleDialog(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(await StorageService.medications(), isEmpty);

        await tapVisible(tester, buttonWithText('Add one'));
        await settleDialog(tester);
        final Finder fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), 'Ibuprofen');
        await tester.enterText(fields.at(1), '200 mg');
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: buttonWithText('Save'),
        ));
        await settleLoads(tester);

        expect(find.text('Saved on this phone.'), findsOneWidget);
        // Let the snackbar leave so the next one is not queued behind it.
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Ibuprofen'), findsOneWidget);
        expect(find.text('200 mg'), findsOneWidget);
        var stored = await StorageService.medications();
        expect(stored, hasLength(1));
        expect(stored.single.name, 'Ibuprofen');

        await scrollTo(tester, find.byTooltip('Edit Ibuprofen'));
        await tester.tap(find.byTooltip('Edit Ibuprofen'));
        await settleDialog(tester);
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ).first,
          'Ibuprofen 200',
        );
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: buttonWithText('Save'),
        ));
        await settleLoads(tester);

        expect(find.text('Ibuprofen 200'), findsOneWidget);
        stored = await StorageService.medications();
        expect(stored.single.name, 'Ibuprofen 200');
        // This edit's snackbar also has to clear before the removal message.
        await tester.pump(const Duration(seconds: 5));

        await scrollTo(tester, find.byTooltip('Remove Ibuprofen 200'));
        await tester.tap(find.byTooltip('Remove Ibuprofen 200'));
        await settleLoads(tester);
        expect(find.text('Removed Ibuprofen 200.'), findsOneWidget);
        expect(find.text('Nothing on the list yet'), findsOneWidget);
        expect(await StorageService.medications(), isEmpty);
      });

      testWidgets('workout session and effort survive the next rebuild',
          (WidgetTester tester) async {
        await pumpScreen(tester, const FitnessToolsScreen(), size: size);

        await tapVisible(tester, find.text('Running'));

        await tapVisible(tester, buttonInCard('Session', 'Start'));
        await tester.pump(const Duration(seconds: 2));
        expect(inCard('Session', find.text('00:02')), findsOneWidget);

        await tapVisible(tester, buttonInCard('Session', 'Save session'));
        expect(find.text('LAST SAVED SESSION'), findsOneWidget);
        expect(find.text('Running · 00:02'), findsOneWidget);
        expect(
          find.text('No weight saved, so no energy estimate.'),
          findsOneWidget,
        );

        await tapVisible(tester, buttonInCard('Session', 'Reset'));
        expect(inCard('Session', find.text('00:00')), findsOneWidget);

        await scrollTo(tester, find.byType(Slider));
        await tester.drag(find.byType(Slider), const Offset(500, 0));
        await tester.pump();
        expect(find.text('RPE 10 / 10'), findsOneWidget);

        await scrollTo(tester, find.byType(TextField));
        await tester.enterText(
          find.byType(TextField),
          'Steady until the last ten minutes.',
        );
        // Drop focus: the focused field asks the page to keep it on screen,
        // which moves the save button between ensureVisible and the tap.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tapVisible(tester, buttonWithText('Save today\'s rating'));
        await settleLoads(tester);

        expect(find.text('Saved today: RPE 10/10.'), findsOneWidget);
        expect(find.text('Saved today: 10 / 10'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.rpe), 10);
        expect(
          await DailyLog.entry(DailyLog.rpeNote),
          'Steady until the last ten minutes.',
        );

        // The rating and its note are read back from the log, not kept only in
        // the widget that saved them.
        await pumpScreen(tester, const FitnessToolsScreen(), size: size);
        expect(find.text('Saved today: 10 / 10'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Steady until the last ten minutes.',
        );
      });

      testWidgets('recovery test reads demo rates and stops its timers',
          (WidgetTester tester) async {
        await pumpScreen(tester, const FitnessToolsScreen(), size: size);

        expect(find.text('No watch connected'), findsOneWidget);
        serviceOf<BleService>(tester).startDemo();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2100));
        expect(find.textContaining('Live: '), findsOneWidget);
        expect(find.textContaining('generated by the app'), findsOneWidget);

        await scrollTo(tester, find.text('Record resting rate'));
        await tester.tap(buttonWithText('Record resting rate'));
        await tester.pump();

        expect(find.textContaining('Resting rate recorded:'), findsOneWidget);
        expect(find.text('Two-minute wait'), findsOneWidget);

        // The countdown does not start itself; the person presses Start.
        await tapVisible(tester, buttonInCard('Two-minute wait', 'Start'));
        await tester.pump(const Duration(seconds: 1));
        expect(
          inCard('Two-minute wait', find.text('01:59')),
          findsOneWidget,
        );
        await tapVisible(tester, buttonInCard('Two-minute wait', 'Pause'));
        await tester.pump(const Duration(seconds: 1));
        expect(
          inCard('Two-minute wait', find.text('01:59')),
          findsOneWidget,
          reason: 'the countdown kept running after Pause',
        );

        await tapVisible(tester, buttonWithText('Cancel test'));
        expect(find.text('Record resting rate'), findsOneWidget);

        await tapVisible(tester, buttonWithText('Record resting rate'));
        await tapVisible(tester, buttonInCard('Two-minute wait', 'Start'));
        await tester.pump(const Duration(minutes: 2));
        await tester.pump();

        expect(find.text('TWO MINUTES LATER'), findsOneWidget);
        expect(find.text('Start a new test'), findsOneWidget);
        await tapVisible(tester, buttonWithText('Start a new test'));
        expect(find.text('Record resting rate'), findsOneWidget);

        await stopDemoAndDispose(tester);
      });

      testWidgets('a stored profile drives the zones and the calorie note',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'veyro_profile': '{"age":30,"weightKg":70,"heightCm":170}',
        });
        await pumpScreen(tester, const FitnessToolsScreen(), size: size);

        expect(find.text('Estimated maximum: 190 bpm'), findsOneWidget);
        expect(find.text('95–114 bpm'), findsOneWidget);
        expect(
          find.textContaining('uses 70 kg from your profile'),
          findsOneWidget,
        );

        serviceOf<BleService>(tester).startDemo();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2100));
        expect(find.text('Below zone 1'), findsOneWidget);

        await stopDemoAndDispose(tester);
      });
    });

    group('lifestyle tools at $at', () {
      testWidgets('fasting plan, fast and mood entry are stored',
          (WidgetTester tester) async {
        await pumpScreen(tester, const LifestyleToolsScreen(), size: size);

        expect(find.text('Target: 16 hours.'), findsOneWidget);
        await tapVisible(tester, find.text('14:10'));
        expect(find.text('Target: 14 hours.'), findsOneWidget);
        expect(await DailyLog.fastingPlan(), '14:10');

        await tapVisible(tester, buttonWithText('Start fast'));
        expect(find.text('Running'), findsOneWidget);
        expect(find.text('Elapsed. Target: 14 hours.'), findsOneWidget);
        await tapVisible(tester, buttonWithText('End fast'));
        expect(find.text('Not started'), findsOneWidget);
        expect(await DailyLog.time(DailyLog.fastingStart), isNull);

        expect(
          tester.widget<FilledButton>(buttonWithText('Save today')).onPressed,
          isNull,
          reason: 'a mood must be chosen before it can be saved',
        );
        expect(find.text('Nothing saved for today yet.'), findsOneWidget);

        await tapVisible(tester, find.text('Good'));
        await tapVisible(tester, find.widgetWithText(FilterChip, 'Slept well'));
        await tapVisible(tester, find.widgetWithText(FilterChip, 'Busy day'));
        await scrollTo(tester, find.byType(Slider));
        await tester.drag(find.byType(Slider), const Offset(500, 0));
        await tester.pump();
        expect(find.text('10 / 10'), findsOneWidget);

        await tapVisible(tester, buttonWithText('Save today'));
        await settleLoads(tester);

        expect(find.text('Today\'s entry saved.'), findsOneWidget);
        expect(find.text('Saved today: Good · energy 10/10'), findsOneWidget);
        expect(await DailyLog.entry(DailyLog.mood), 'Good');
        expect(await DailyLog.counter(DailyLog.energy), 10);
        expect(await DailyLog.entry(DailyLog.moodTags), 'Busy day, Slept well');

        await pumpScreen(tester, const LifestyleToolsScreen(), size: size);
        expect(find.text('Saved today: Good · energy 10/10'), findsOneWidget);
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Slept well'))
              .selected,
          isTrue,
        );
      });

      testWidgets('BMR rejects bad numbers and saves the good ones',
          (WidgetTester tester) async {
        await pumpScreen(tester, const LifestyleToolsScreen(), size: size);

        expect(find.text('No estimate yet'), findsOneWidget);
        await scrollTo(tester, find.text('Save these numbers to my profile'));
        await tester.tap(buttonWithText('Save these numbers to my profile'));
        await settleLoads(tester);
        expect(
          find.textContaining('Enter an age from 1 to 120'),
          findsOneWidget,
        );
        // The error snackbar has to leave before the success one is shown.
        await tester.pump(const Duration(seconds: 5));

        await enterByLabel(tester, 'Age', '30');
        await enterByLabel(tester, 'Weight', '70');
        await enterByLabel(tester, 'Height', '175');
        expect(metricValue('BMR estimate', '1,649'), findsOneWidget);
        expect(metricValue('TDEE estimate', '2,267'), findsOneWidget);

        await tapVisible(tester, find.text('Female (−161)'));
        expect(metricValue('BMR estimate', '1,483'), findsOneWidget);
        expect(metricValue('TDEE estimate', '2,039'), findsOneWidget);

        await tapVisible(tester, find.text('Moderate'));
        expect(metricValue('TDEE estimate', '2,298'), findsOneWidget);

        await tapVisible(
          tester,
          buttonWithText('Save these numbers to my profile'),
        );
        await settleLoads(tester);
        expect(
          find.text('Saved to your profile on this phone.'),
          findsOneWidget,
        );
        final UserProfile profile = await LocalStore.loadProfile();
        expect(profile.age, 30);
        expect(profile.weightKg, 70);
        expect(profile.heightCm, 175);
      });

      testWidgets('the break dialog both declines and logs a break',
          (WidgetTester tester) async {
        await pumpScreen(tester, const LifestyleToolsScreen(), size: size);

        await tapVisible(tester, buttonInCard('Stand up and move', 'Start'));
        await tester.pump(const Duration(minutes: 30));
        await tester.pump();

        final Finder dialogTitle = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Time to move'),
        );
        expect(dialogTitle, findsOneWidget);
        await tester.tap(buttonWithText('Not now'));
        await settleDialog(tester);
        expect(find.text('0 breaks logged today'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.breaks), 0);

        // The finished card offers "Start again", which only resets it; the
        // next run needs its own Start.
        await tapVisible(
          tester,
          buttonInCard('Stand up and move', 'Start again'),
        );
        await tapVisible(tester, buttonInCard('Stand up and move', 'Start'));
        await tester.pump(const Duration(minutes: 30));
        await tester.pump();
        expect(dialogTitle, findsOneWidget);
        await tester.tap(buttonWithText('Done'));
        await settleLoads(tester);

        expect(find.text('1 break logged today'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.breaks), 1);

        await tester.pumpWidget(const SizedBox.shrink());
      });
    });

    group('wellness tools at $at', () {
      testWidgets('water and coffee counters add, remove and reset',
          (WidgetTester tester) async {
        await pumpScreen(tester, const WellnessToolsScreen(), size: size);

        expect(find.text('0 of 8 glasses'), findsOneWidget);
        expect(find.text('0 ml'), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(buttonInSection('Hydration today',
                  'Remove one'))
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(
                  buttonInSection('Hydration today', 'Reset today'))
              .onPressed,
          isNull,
        );

        for (var i = 0; i < 3; i++) {
          await tapVisible(
            tester,
            buttonInSection('Hydration today', 'Add a glass'),
          );
        }
        expect(find.text('3 of 8 glasses'), findsOneWidget);
        expect(find.text('750 ml'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.hydrationGlasses), 3);

        await tapVisible(
          tester,
          buttonInSection('Hydration today', 'Remove one'),
        );
        expect(find.text('2 of 8 glasses'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.hydrationGlasses), 2);

        await tapVisible(
          tester,
          buttonInSection('Hydration today', 'Reset today'),
        );
        expect(find.text('0 of 8 glasses'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.hydrationGlasses), 0);

        expect(find.text('0 coffees and teas'), findsOneWidget);
        expect(find.text('None logged'), findsOneWidget);
        await tapVisible(tester, buttonInSection('Caffeine today', 'Log one'));
        await tapVisible(tester, buttonInSection('Caffeine today', 'Log one'));
        expect(find.text('2 coffees and teas'), findsOneWidget);
        expect(find.textContaining('Last at '), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.coffees), 2);

        await tapVisible(
          tester,
          buttonInSection('Caffeine today', 'Reset today'),
        );
        expect(find.text('0 coffees and teas'), findsOneWidget);
        expect(find.text('None logged'), findsOneWidget);
        expect(await DailyLog.counter(DailyLog.coffees), 0);
      });

      testWidgets('emergency card cancels, saves, reloads and edits',
          (WidgetTester tester) async {
        await pumpScreen(tester, const WellnessToolsScreen(), size: size);

        await scrollTo(tester, find.text('No emergency details yet'));
        await tester.tap(buttonWithText('Add details'));
        await settleDialog(tester);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Emergency card'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: buttonWithText('Cancel'),
        ));
        await settleDialog(tester);
        expect(find.text('No emergency details yet'), findsOneWidget);

        await tapVisible(tester, buttonWithText('Add details'));
        await settleDialog(tester);
        await enterByLabel(tester, 'Blood type', 'O+');
        await enterByLabel(tester, 'Emergency contact', '555 0100');
        await enterByLabel(tester, 'Allergies', 'Penicillin');
        await enterByLabel(tester, 'Medical notes', 'Mild asthma');
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: buttonWithText('Save'),
        ));
        await settleLoads(tester);

        expect(
          find.text('Emergency card saved on this phone.'),
          findsOneWidget,
        );
        expect(find.text('O+'), findsOneWidget);
        expect(find.text('555 0100'), findsOneWidget);
        expect(find.text('Penicillin'), findsOneWidget);
        expect(find.text('Mild asthma'), findsOneWidget);

        await pumpScreen(tester, const WellnessToolsScreen(), size: size);
        expect(find.text('O+'), findsOneWidget);
        expect(find.text('Penicillin'), findsOneWidget);

        await tapVisible(tester, buttonWithText('Edit details'));
        await settleDialog(tester);
        await enterByLabel(tester, 'Blood type', 'AB+');
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: buttonWithText('Save'),
        ));
        await settleLoads(tester);
        expect(find.text('AB+'), findsOneWidget);
        expect(find.text('O+'), findsNothing);
      });

      testWidgets('breathing, rest and stride controls tick and save',
          (WidgetTester tester) async {
        await pumpScreen(tester, const WellnessToolsScreen(), size: size);

        await scrollTo(tester, find.text('Box breathing cycle'));
        await tapVisible(tester, buttonInCard('Box breathing cycle', 'Start'));
        await tester.pump(const Duration(seconds: 4));
        expect(inCard('Box breathing cycle', find.text('00:12')), findsOneWidget);
        expect(find.text('Phase 2 of 4'), findsOneWidget);

        await tapVisible(tester, buttonInCard('Box breathing cycle', 'Pause'));
        await tester.pump(const Duration(seconds: 1));
        expect(inCard('Box breathing cycle', find.text('00:12')), findsOneWidget);

        await tapVisible(tester, buttonInCard('Box breathing cycle', 'Reset'));
        expect(inCard('Box breathing cycle', find.text('00:16')), findsOneWidget);

        await tapVisible(tester, find.text('30 s'));
        expect(inCard('Rest timer', find.text('00:30')), findsOneWidget);
        await tapVisible(tester, buttonInCard('Rest timer', 'Start'));
        await tester.pump(const Duration(seconds: 3));
        expect(inCard('Rest timer', find.text('00:27')), findsOneWidget);
        await tapVisible(tester, buttonInCard('Rest timer', 'Pause'));
        await tapVisible(tester, buttonInCard('Rest timer', 'Reset'));
        expect(inCard('Rest timer', find.text('00:30')), findsOneWidget);

        await scrollTo(tester, find.byType(Slider));
        await tester.drag(find.byType(Slider), const Offset(2000, 0));
        await tester.pump();
        expect(find.text('120 cm per step'), findsOneWidget);
        expect(await DailyLog.strideCm(), 120);

        await pumpScreen(tester, const WellnessToolsScreen(), size: size);
        expect(find.text('120 cm per step'), findsOneWidget);
      });
    });
  }
}
