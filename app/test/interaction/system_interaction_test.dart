// Interaction tests for the system surfaces: Watch memory, diagnostics, the
// face preview, Settings, the AI assistant and the app lock.
//
// Settings is the largest control surface in the app, so it is split by
// section. Everything here asserts the owning service or SharedPreferences,
// not only the pixels: a snackbar alone does not prove a write happened.
library;

import 'package:digital_saver/core/models/health_models.dart';
import 'package:digital_saver/features/screens/ai_assistant_screen.dart';
import 'package:digital_saver/features/screens/device_diagnostics_screen.dart';
import 'package:digital_saver/features/screens/lock_screen.dart';
import 'package:digital_saver/features/screens/memory_screen.dart';
import 'package:digital_saver/features/screens/settings_screen.dart';
import 'package:digital_saver/features/screens/watch_simulator_screen.dart';
import 'package:digital_saver/core/services/app_lock.dart';
import 'package:digital_saver/core/services/ble_service.dart';
import 'package:digital_saver/core/services/locale_service.dart';
import 'package:digital_saver/core/services/local_store.dart';
import 'package:digital_saver/core/services/storage_service.dart';
import 'package:digital_saver/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/stub_notifications.dart';
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

/// The [IconButton] that owns a tooltip, so its enabled state can be read.
Finder iconButtonWithTooltip(String tooltip) {
  return find
      .ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      )
      .first;
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
  // Some settings screens touch the notifications plugin while initialising.
  setUpAll(useStubNotifications);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final Size size in interactionSizes) {
    final String at = '${size.width.toInt()}x${size.height.toInt()}';

    group('watch memory at $at', () {
      testWidgets('an unreadable log offers retry, and reload asks again',
          (WidgetTester tester) async {
        var calls = 0;
        Future<List<WatchSample>> loader() async {
          calls++;
          if (calls == 1) throw StateError('disk unreadable');
          return <WatchSample>[];
        }

        await pumpScreen(tester, MemoryScreen(loadSamples: loader), size: size);

        expect(calls, 1);
        expect(find.text('Stored samples could not be read'), findsOneWidget);
        expect(find.textContaining('disk unreadable'), findsOneWidget);

        await tapVisible(tester, buttonWithText('Try again'));
        await settleLoads(tester);

        expect(calls, 2);
        expect(find.text('No samples yet'), findsOneWidget);
        expect(
          find.textContaining('there is nothing to average'),
          findsOneWidget,
          reason: 'an empty log must not print zeroes as readings',
        );

        expect(
          tester
              .widget<FilledButton>(buttonWithText('Pull from Veyro'))
              .onPressed,
          isNull,
          reason: 'a pull cannot run while no watch is connected',
        );
        expect(
          find.textContaining('Pull is disabled until a watch is connected'),
          findsOneWidget,
        );

        await tapVisible(
          tester,
          find.byTooltip('Reload the samples saved on this phone'),
        );
        await settleLoads(tester);
        expect(calls, 3);
        expect(find.text('No samples yet'), findsOneWidget);
      });

      testWidgets('a stored log shows measured averages and the pull reports',
          (WidgetTester tester) async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final List<WatchSample> samples = <WatchSample>[
          WatchSample(unix: now - 7200, hr: 62, spo2: 97, steps: 120, bat: 81),
          WatchSample(unix: now - 3600, hr: 84, spo2: 95, steps: 240, bat: 80),
        ];

        await pumpScreen(
          tester,
          MemoryScreen(loadSamples: () async => samples),
          size: size,
        );

        expect(find.text('No samples yet'), findsNothing);
        expect(metricValue('Samples', '2'), findsOneWidget);
        expect(metricValue('Average heart rate', '73'), findsOneWidget);
        expect(metricValue('Resting heart rate', '62'), findsOneWidget);
        expect(metricValue('Average oxygen', '96'), findsOneWidget);
        expect(metricValue('Fall flags', '0'), findsOneWidget);
        expect(find.textContaining('2 samples from'), findsOneWidget);

        // The watch-tab facts are dashes because no info frame has arrived;
        // none of the measured tiles may read as zero.
        expect(
          find.descendant(
            of: cardWithText('AVERAGE HEART RATE'),
            matching: find.text('--'),
          ),
          findsNothing,
        );
        expect(
          find.textContaining('Oldest sample drops around'),
          findsOneWidget,
        );

        final BleService ble = serviceOf<BleService>(tester);
        ble.startDemo();
        await tester.pump();

        await tapVisible(tester, buttonWithText('Pull from Veyro'));
        await settleLoads(tester);

        // Demo mode has no command characteristic, so the sync finishes with
        // no rows instead of leaving a spinner up.
        expect(
          find.text('The pull finished. The watch had no new rows to copy.'),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(
          tester
              .widget<FilledButton>(buttonWithText('Pull from Veyro'))
              .onPressed,
          isNotNull,
        );

        await stopDemoAndDispose(tester);
      });
    });

    group('device diagnostics at $at', () {
      testWidgets('face choice is kept while disconnected and sent when paired',
          (WidgetTester tester) async {
        await pumpScreen(tester, const DeviceDiagnosticsScreen(), size: size);

        expect(find.text('Device diagnostics'), findsOneWidget);
        expect(find.text('No watch is connected'), findsOneWidget);
        expect(find.text('Not connected'), findsOneWidget);
        // Firmware, samples, free space and battery have not been read.
        expect(find.text('--'), findsNWidgets(4));

        final Finder faceEight = find.text('8');
        await scrollTo(tester, faceEight);
        await tester.tap(faceEight);
        await tester.pump();

        final Finder send = buttonWithText('Send face 8');
        expect(
          tester.widget<FilledButton>(send).onPressed,
          isNull,
          reason: 'there is no watch to send a face to',
        );
        expect(
          find.textContaining('Connect and pair a watch to send a face'),
          findsOneWidget,
        );
        expect(await StorageService.watchFace(), 0);

        final BleService ble = serviceOf<BleService>(tester);
        ble.startDemo();
        await tester.pump();

        expect(find.text('Demo'), findsOneWidget);
        expect(
          find.textContaining('Demo mode is on. The numbers below'),
          findsOneWidget,
        );

        await tapVisible(tester, send);
        await settleLoads(tester);

        expect(
          find.text('Face 8 saved and sent to the watch.'),
          findsOneWidget,
        );
        expect(await StorageService.watchFace(), 7);

        // The face index is read back from storage on the next open, even
        // though the watch is gone.
        await pumpScreen(tester, const DeviceDiagnosticsScreen(), size: size);
        expect(buttonWithText('Send face 8'), findsOneWidget);
        expect(find.text('No watch is connected'), findsOneWidget);

        await stopDemoAndDispose(tester);
      });
    });

    group('watch simulator at $at', () {
      testWidgets('all three previews are selectable and labelled as samples',
          (WidgetTester tester) async {
        await pumpScreen(tester, const WatchSimulatorScreen(), size: size);

        expect(find.text('Preview only'), findsOneWidget);
        expect(
          find.textContaining('Nothing on this screen is connected'),
          findsOneWidget,
        );
        // Analog draws no text.
        expect(find.text('10:10'), findsNothing);
        expect(find.text('steps · sample'), findsNothing);

        await tapVisible(tester, find.text('Digital'));
        expect(find.text('10:10'), findsOneWidget);
        expect(find.text('TUE 20 OCT'), findsOneWidget);
        expect(find.text('72 bpm'), findsOneWidget);
        expect(find.text('8,420'), findsOneWidget);
        expect(find.text('SAMPLE'), findsOneWidget);

        await tapVisible(tester, find.text('Rings'));
        expect(find.text('10:10'), findsNothing);
        expect(find.text('steps · sample'), findsOneWidget);
        expect(find.text('8,420'), findsOneWidget);

        await tapVisible(tester, find.text('Analog'));
        expect(find.text('10:10'), findsNothing);
        expect(find.text('steps · sample'), findsNothing);
        expect(
          find.textContaining('It cannot change anything on a watch'),
          findsOneWidget,
        );
      });
    });

    group('settings appearance and watch at $at', () {
      testWidgets('theme, language and sync switches save where they belong',
          (WidgetTester tester) async {
        await pumpScreen(tester, const SettingsScreen(), size: size);

        final ThemeService theme = serviceOf<ThemeService>(tester);
        await tapVisible(
          tester,
          find.widgetWithText(SwitchListTile, 'Dark theme'),
        );
        expect(theme.themeModeType, AppThemeMode.dark);
        expect(
          tester
              .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, 'Dark theme'),
              )
              .value,
          isTrue,
        );

        // Dim after dark schedules a clock-boundary timer. Turn it back off so
        // the test does not end with a pending timer.
        final Finder dim =
            find.widgetWithText(SwitchListTile, 'Dim after dark');
        await tapVisible(tester, dim);
        await tester.pump(const Duration(milliseconds: 200));
        expect(theme.dimAfterDark, isTrue);
        expect(await StorageService.dimAfterDark(), isTrue);
        expect(
          find.textContaining('On. The dark theme is used from 20:00 to 07:00.'),
          findsOneWidget,
        );

        await tapVisible(tester, dim);
        await tester.pump(const Duration(milliseconds: 200));
        expect(theme.dimAfterDark, isFalse);
        expect(await StorageService.dimAfterDark(), isFalse);

        await chooseFromDropdown(
          tester,
          'App language',
          'العربية (مصر / الفصحى)',
        );
        expect(serviceOf<LocaleService>(tester).currentLanguage, 'العربية');

        final Finder autoSync =
            find.widgetWithText(SwitchListTile, 'Remember auto-sync choice');
        await tapVisible(tester, autoSync);
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.autoSyncHistory(), isFalse);

        final Finder demo = find.widgetWithText(SwitchListTile, 'Demo mode');
        await tapVisible(tester, demo);
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.demoMode(), isTrue);
        expect(
          tester.widget<SwitchListTile>(demo).value,
          isTrue,
          reason: 'the switch has to show the value it stored',
        );
      });

      testWidgets('face, complications and thresholds save and reload',
          (WidgetTester tester) async {
        await pumpScreen(tester, const SettingsScreen(), size: size);

        await chooseFromDropdown(
          tester,
          'Active watch face',
          'Face 3: Cyberpunk Pixel',
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.watchFace(), 2);

        await chooseFromDropdown(tester, 'Top slot', 'Battery Level');
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.complicationTop(), 'Battery Level');

        await chooseFromDropdown(tester, 'Bottom slot', 'None');
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.complicationBottom(), 'None');

        // Sliders are dragged, not invoked through their callbacks, so the
        // gesture path is the one the person uses.
        await scrollTo(tester, find.byType(Slider).first);
        await tester.drag(find.byType(Slider).first, const Offset(2000, 0));
        await tester.pump();
        expect(find.text('Saved at 180 BPM or above.'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.highHrThreshold(), 180);

        await scrollTo(tester, find.byType(Slider).at(1));
        await tester.drag(find.byType(Slider).at(1), const Offset(-2000, 0));
        await tester.pump();
        expect(find.text('Saved at 80% or below.'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
        expect(await StorageService.lowSpo2Threshold(), 80);

        await pumpScreen(tester, const SettingsScreen(), size: size);

        expect(find.text('Saved at 180 BPM or above.'), findsOneWidget);
        expect(find.text('Saved at 80% or below.'), findsOneWidget);
        expect(find.text('Face 3: Cyberpunk Pixel'), findsOneWidget);
        expect(find.text('Battery Level'), findsOneWidget);
        expect(find.text('None'), findsOneWidget);
        expect(await StorageService.watchFace(), 2);
        expect(await StorageService.highHrThreshold(), 180);
        expect(await StorageService.lowSpo2Threshold(), 80);
      });

      testWidgets('profile and contact forms validate, persist and remove',
          (WidgetTester tester) async {
        await pumpScreen(tester, const SettingsScreen(), size: size);

        await tapVisible(tester, buttonWithText('Save profile'));
        await settleLoads(tester);
        expect(
          find.textContaining('Enter a name, or leave the field blank'),
          findsOneWidget,
        );

        await enterByLabel(tester, 'Name', 'Sam', index: 0);
        await enterByLabel(tester, 'Age', '30');
        await enterByLabel(tester, 'Weight (kg)', '72.5');
        await tapVisible(tester, buttonWithText('Save profile'));
        await settleLoads(tester);

        expect(find.text('Profile saved on this phone.'), findsOneWidget);
        UserProfile profile = await LocalStore.loadProfile();
        expect(profile.name, 'Sam');
        expect(profile.age, 30);
        expect(profile.weightKg, 72.5);
        // Let the profile snackbar leave before the contact one is queued.
        await tester.pump(const Duration(seconds: 5));

        await tapVisible(tester, buttonWithText('Add contact'));
        await settleLoads(tester);
        expect(
          find.text('A contact needs a name and a phone number.'),
          findsOneWidget,
        );
        expect(await LocalStore.loadContacts(), isEmpty);

        // The second "Name" field belongs to the contact form.
        await enterByLabel(tester, 'Name', 'Alex', index: 1);
        await enterByLabel(tester, 'Phone', '555 0100');
        await enterByLabel(tester, 'Relation', 'Sister');
        await tapVisible(tester, buttonWithText('Add contact'));
        await settleLoads(tester);

        expect(
          find.text('Contact added. It is stored on this phone.'),
          findsOneWidget,
        );
        List<EmergencyContact> contacts = await LocalStore.loadContacts();
        expect(contacts, hasLength(1));
        expect(contacts.single.name, 'Alex');
        expect(contacts.single.phone, '555 0100');
        expect(contacts.single.relation, 'Sister');

        // A fresh open reads both records back from LocalStore.
        await pumpScreen(tester, const SettingsScreen(), size: size);
        expect(find.text('Sam'), findsOneWidget);
        expect(find.text('Alex'), findsOneWidget);
        expect(find.text('555 0100'), findsOneWidget);
        profile = await LocalStore.loadProfile();
        expect(profile.name, 'Sam');

        await tapVisible(tester, find.byTooltip('Remove Alex'));
        await settleLoads(tester);
        expect(find.text('Contact removed.'), findsOneWidget);
        contacts = await LocalStore.loadContacts();
        expect(contacts, isEmpty);
        expect(
          find.textContaining('No emergency contacts yet.'),
          findsOneWidget,
        );
      });

      testWidgets('quick replies validate, add, remove and keep one',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'quick_replies': <String>['Only one'],
        });
        await pumpScreen(tester, const SettingsScreen(), size: size);

        final Finder keepOne = iconButtonWithTooltip('Keep at least one reply');
        await scrollTo(tester, keepOne);
        expect(
          tester.widget<IconButton>(keepOne).onPressed,
          isNull,
          reason: 'the last reply must not be removable',
        );
        expect(
          find.textContaining('One reply is kept'),
          findsOneWidget,
        );

        await tapVisible(tester, buttonWithText('Add a reply'));
        await settleDialog(tester);
        expect(find.text('Add a quick reply'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Add'),
          ),
        );
        await tester.pump();
        expect(find.text('Write something first.'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Cancel'),
          ),
        );
        await settleDialog(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(await StorageService.quickReplies(), <String>['Only one']);

        await tapVisible(tester, buttonWithText('Add a reply'));
        await settleDialog(tester);
        await enterByLabel(tester, 'Reply text', 'On a call.');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Add'),
          ),
        );
        await settleLoads(tester);

        expect(
          find.text('Quick reply added to this phone.'),
          findsOneWidget,
        );
        expect(
          await StorageService.quickReplies(),
          <String>['Only one', 'On a call.'],
        );
        // Let this snackbar leave before the removal one is queued.
        await tester.pump(const Duration(seconds: 5));

        await tapVisible(tester, find.byTooltip('Remove this reply').first);
        await settleLoads(tester);
        expect(find.text('Quick reply removed.'), findsOneWidget);
        expect(await StorageService.quickReplies(), <String>['On a call.']);
        expect(
          tester.widget<IconButton>(keepOne).onPressed,
          isNull,
          reason: 'removal stopped at the one reply that is kept',
        );
      });

      testWidgets('the PIN dialog validates, cancels, then sets a PIN',
          (WidgetTester tester) async {
        await pumpScreen(tester, const SettingsScreen(), size: size);
        final AppLock lock = serviceOf<AppLock>(tester);
        expect(lock.hasLock, isFalse);

        await tapVisible(tester, buttonWithText('Set a 6-digit PIN'));
        await settleDialog(tester);
        expect(find.text('Set a PIN'), findsOneWidget);

        // Too short and then mismatched: both are refused before any hash is
        // computed.
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Set PIN'),
          ),
        );
        await tester.pump();
        expect(find.text('Use exactly 6 digits, 0 to 9.'), findsOneWidget);

        await enterByLabel(tester, 'New 6-digit PIN', '123456');
        await enterByLabel(tester, 'Confirm the new PIN', '654321');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Set PIN'),
          ),
        );
        await tester.pump();
        expect(find.text('The two new PINs do not match.'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Cancel'),
          ),
        );
        await settleDialog(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(lock.hasLock, isFalse);

        await tapVisible(tester, buttonWithText('Set a 6-digit PIN'));
        await settleDialog(tester);
        await enterByLabel(tester, 'New 6-digit PIN', '123456');
        await enterByLabel(tester, 'Confirm the new PIN', '123456');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Set PIN'),
          ),
        );
        await settleLoads(tester);
        await settleDialog(tester);

        expect(find.byType(AlertDialog), findsNothing);
        expect(
          find.text(
            'PIN set. Changing or removing it will ask for this PIN first.',
          ),
          findsOneWidget,
        );
        expect(lock.hasLock, isTrue);
        expect(find.text('PIN set'), findsOneWidget);

        // The other two PIN actions are opened and cancelled; the hashing paths
        // are covered by the service tests, not repeated here for every width.
        await tapVisible(tester, buttonWithText('Change PIN'));
        await settleDialog(tester);
        expect(find.text('Change the PIN'), findsOneWidget);
        expect(find.text('Current PIN'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Cancel'),
          ),
        );
        await settleDialog(tester);

        await tapVisible(tester, buttonWithText('Remove PIN'));
        await settleDialog(tester);
        expect(find.text('Remove the PIN'), findsOneWidget);
        expect(
          find.textContaining('Removing the PIN deletes the stored hash'),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: buttonWithText('Cancel'),
          ),
        );
        await settleDialog(tester);

        await tapVisible(tester, buttonWithText('Lock now'));
        expect(lock.unlocked, isFalse);
        expect(lock.hasLock, isTrue);
      });

      testWidgets('CSV and JSON read the stored log and report the failure',
          (WidgetTester tester) async {
        await pumpScreen(tester, const SettingsScreen(), size: size);

        // Widget tests have no application-support directory, so LocalStore
        // cannot read. The screen must say so instead of showing an empty or
        // invented table.
        await tapVisible(tester, buttonWithText('View CSV'));
        await settleLoads(tester);
        expect(
          find.textContaining('Stored samples could not be read:'),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsNothing);
        await tester.pump(const Duration(seconds: 5));

        await tapVisible(tester, buttonWithText('View JSON'));
        await settleLoads(tester);
        expect(
          find.textContaining('Stored samples could not be read:'),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsNothing);
        expect(
          find.textContaining('Nothing is uploaded'),
          findsOneWidget,
        );
      });
    });

    group('AI assistant at $at', () {
      testWidgets('chat sends, a quick chip sends, and clear resets the log',
          (WidgetTester tester) async {
        await pumpScreen(tester, const AIAssistantScreen(), size: size);

        expect(find.text('Digital Saver AI'), findsOneWidget);
        expect(find.text('Chat'), findsOneWidget);
        expect(find.textContaining('powered by Gemini'), findsOneWidget);

        final Finder composer = find.byWidgetPredicate(
          (Widget widget) =>
              widget is TextField &&
              widget.textInputAction == TextInputAction.send,
        );
        await tester.enterText(composer, 'How is my heart rate today?');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await settleLoads(tester);
        await tester.pump(const Duration(milliseconds: 400));

        // The test HTTP client refuses the relay, so the deterministic offline
        // advisor answers. That is the app's own fallback path.
        expect(
          find.textContaining('Normal resting heart rate for healthy adults'),
          findsOneWidget,
        );
        // One copy is the chip, one is the message bubble.
        expect(find.text('How is my heart rate today?'), findsNWidgets(2));
        expect(
          find.text('Digital Saver AI is thinking...'),
          findsNothing,
          reason: 'the thinking row must stop when the answer arrives',
        );

        // The chip row scrolls horizontally on a phone; bring the second chip
        // into view before tapping it.
        final Finder chip = find.text('Explain my sleep quality');
        if (chip.evaluate().isEmpty) {
          await tester.drag(find.byType(ListView).first, const Offset(-250, 0));
          await tester.pump();
        }
        await tester.ensureVisible(chip);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(chip);
        await settleLoads(tester);
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.textContaining('7 to 9 hours'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Clear Chat'));
        await tester.pump();
        expect(
          find.text(
            'Chat history cleared. How can I assist you with your health today?',
          ),
          findsOneWidget,
        );
        // The chip row stays; the conversation and its answers are gone. The
        // row was scrolled to the second chip, so the first one is not built.
        expect(find.text('Explain my sleep quality'), findsOneWidget);
        expect(
          find.textContaining('Normal resting heart rate for healthy adults'),
          findsNothing,
        );
        expect(find.textContaining('powered by Gemini'), findsNothing);
      });

      testWidgets('personality settings save and are read back',
          (WidgetTester tester) async {
        await pumpScreen(tester, const AIAssistantScreen(), size: size);

        await tester.tap(find.text('AI Personality & Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('AI Personality & Tone'), findsOneWidget);

        await chooseFromDropdown(
          tester,
          'Tone of Voice',
          'Clinical & Medical (Doctor-like)',
        );
        await chooseFromDropdown(
          tester,
          'Primary Health Focus',
          'Sleep & Stress Recovery',
        );
        await chooseFromDropdown(
          tester,
          'Conversation Language',
          'العربية (Egyptian Arabic / Fusha)',
        );

        final Finder telemetry = find.widgetWithText(
          SwitchListTile,
          'Include live watch vitals in prompts',
        );
        await revealInAiSettings(tester, telemetry);
        await tester.tap(telemetry);
        await tester.pump();
        expect(tester.widget<SwitchListTile>(telemetry).value, isFalse);

        final Finder notes = find.byWidgetPredicate(
          (Widget widget) => widget is TextField && widget.maxLines == 4,
        );
        await revealInAiSettings(tester, notes);
        await tester.enterText(notes, 'I have mild asthma.');

        final Finder save =
            buttonWithText('Save Personality & Instructions');
        await revealInAiSettings(tester, save);
        await tester.tap(save);
        await settleLoads(tester);

        expect(
          find.text('AI Personality & Instructions Saved!'),
          findsOneWidget,
        );
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_tone'), 'Clinical & Medical (Doctor-like)');
        expect(prefs.getString('ai_focus'), 'Sleep & Stress Recovery');
        expect(prefs.getString('ai_language'),
            'العربية (Egyptian Arabic / Fusha)');
        expect(prefs.getBool('ai_include_telemetry'), isFalse);
        expect(prefs.getString('ai_custom_instructions'), 'I have mild asthma.');

        await pumpScreen(tester, const AIAssistantScreen(), size: size);
        await tester.tap(find.text('AI Personality & Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          find.text('Clinical & Medical (Doctor-like)'),
          findsOneWidget,
        );
        expect(
          find.text('Sleep & Stress Recovery'),
          findsOneWidget,
        );
        final Finder storedNotes = find.byWidgetPredicate(
          (Widget widget) => widget is TextField && widget.maxLines == 4,
        );
        expect(
          tester.widget<TextField>(storedNotes).controller!.text,
          'I have mild asthma.',
        );
        final Finder storedTelemetry = find.widgetWithText(
          SwitchListTile,
          'Include live watch vitals in prompts',
        );
        await revealInAiSettings(tester, storedTelemetry);
        expect(
          tester.widget<SwitchListTile>(storedTelemetry).value,
          isFalse,
        );
      });
    });

    group('app lock at $at', () {
      testWidgets('the gate refuses a short and a wrong PIN, then opens',
          (WidgetTester tester) async {
        await pumpScreen(
          tester,
          const LockGate(child: Text('app content')),
          size: size,
        );

        final AppLock lock = serviceOf<AppLock>(tester);
        await lock.load();
        await tester.pump();

        // No PIN means the gate opens; nothing is hidden behind a lock that
        // was never set.
        expect(find.text('app content'), findsOneWidget);

        await lock.setPin('123456');
        await lock.lockNow();
        await tester.pump();

        expect(find.text('app content'), findsNothing);
        expect(find.text('Digital Saver is locked'), findsOneWidget);
        expect(
          find.text('Enter your six-digit PIN to continue.'),
          findsOneWidget,
        );

        await tester.enterText(find.byType(TextField), '123');
        await tapVisible(tester, buttonWithText('Unlock'));
        expect(find.text('The PIN is six digits.'), findsOneWidget);
        expect(find.text('app content'), findsNothing);

        await tester.enterText(find.byType(TextField), '000000');
        await tapVisible(tester, buttonWithText('Unlock'));
        await settleLoads(tester);
        expect(find.text('That PIN is not right.'), findsOneWidget);
        expect(find.text('app content'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
          reason: 'a refused PIN is cleared from the field',
        );

        await tester.enterText(find.byType(TextField), '123456');
        await tapVisible(tester, buttonWithText('Unlock'));
        await settleLoads(tester);
        expect(find.text('app content'), findsOneWidget);
        expect(find.text('Digital Saver is locked'), findsNothing);
        expect(lock.unlocked, isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  }
}

/// Scrolls the AI settings list to [target].
///
/// The screen keeps both tabs alive, so the settings [ListView] is the last
/// [Scrollable] in the tree; the chat composer and the horizontal chip row are
/// earlier siblings.
Future<void> revealInAiSettings(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 40,
    );
  }
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));
}
