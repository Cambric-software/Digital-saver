// Renders every screen at a phone size and a laptop size, writes PNGs, and
// fails if any screen throws or overflows.
//
// Two jobs. The PNGs let the interface be looked at rather than guessed at, and
// the assertions catch the failures that only appear at one width - a row of
// tiles that fits at 1440 and overflows at 390, a sheet that assumes a pointer.
//
// Run with:
//   flutter test test/screens/ui_capture_test.dart
// Images land in build/ui_capture/. They are build output, not committed, so
// they never go stale in the repository.
library;

import 'dart:io';

import 'package:digital_saver/screens/achievements_screen.dart';
import 'package:digital_saver/screens/activity_screen.dart';
import 'package:digital_saver/screens/ai_assistant_screen.dart';
import 'package:digital_saver/screens/bp_screen.dart';
import 'package:digital_saver/screens/dashboard_screen.dart';
import 'package:digital_saver/screens/device_diagnostics_screen.dart';
import 'package:digital_saver/screens/fitness_tools_screen.dart';
import 'package:digital_saver/screens/health_hub_screen.dart';
import 'package:digital_saver/screens/health_tips_screen.dart';
import 'package:digital_saver/screens/health_trends_screen.dart';
import 'package:digital_saver/screens/heart_screen.dart';
import 'package:digital_saver/screens/insights_screen.dart';
import 'package:digital_saver/screens/lifestyle_tools_screen.dart';
import 'package:digital_saver/screens/memory_screen.dart';
import 'package:digital_saver/screens/settings_screen.dart';
import 'package:digital_saver/screens/sleep_screen.dart';
import 'package:digital_saver/screens/vitals_screen.dart';
import 'package:digital_saver/screens/watch_simulator_screen.dart';
import 'package:digital_saver/screens/wellness_tools_screen.dart';
import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/widgets/ds_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stub_notifications.dart';
import 'package:provider/provider.dart';

/// Whether to write the rendered images.
///
/// Off unless CAPTURE_UI=1, so a normal test run asserts behaviour and does not
/// compare against stored pixels.
final bool captureImages =
    Platform.environment['CAPTURE_UI'] == '1';

/// Phone and laptop, chosen because they are the two the app is actually used
/// at and the two most layouts are written for.
const List<({String name, Size size})> _viewports = <({String name, Size size})>[
  (name: 'phone', size: Size(390, 844)),
  (name: 'laptop', size: Size(1440, 900)),
];

/// Screens that are bodies inside another page, and therefore rely on their host
/// to supply the page frame and the scroll view: the three Vitals tab bodies and
/// the three Insights bodies. Every other screen brings its own frame.
///
/// This distinction matters for what is captured. Rendering a body without its
/// host hides the overflow it causes; rendering a full page inside a second
/// page draws padding and a title bar the app never shows.
const Set<String> _embeddedScreens = <String>{
  'heart',
  'activity',
  'sleep',
  'health_trends',
  'health_tips',
  'achievements',
};

final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'dashboard': DashboardScreen.new,
  'vitals': VitalsScreen.new,
  'heart': HeartScreen.new,
  'bp': BpScreen.new,
  'activity': ActivityScreen.new,
  'sleep': SleepScreen.new,
  'insights': InsightsScreen.new,
  'health_hub': HealthHubScreen.new,
  'health_trends': HealthTrendsScreen.new,
  'health_tips': HealthTipsScreen.new,
  'fitness_tools': FitnessToolsScreen.new,
  'lifestyle_tools': LifestyleToolsScreen.new,
  'wellness_tools': WellnessToolsScreen.new,
  'achievements': AchievementsScreen.new,
  'ai_assistant': AIAssistantScreen.new,
  'memory': MemoryScreen.new,
  'device_diagnostics': DeviceDiagnosticsScreen.new,
  'watch_simulator': WatchSimulatorScreen.new,
  'settings': SettingsScreen.new,
};

/// Loads real fonts so the captures are readable.
///
/// By default the test environment substitutes a font that draws every glyph as
/// a filled rectangle. The first capture proved that: the layout was visible
/// but every label was a black box, so the images could not actually be read and
/// were no better than guessing.
///
/// These are the same files the Flutter SDK ships and the app uses at runtime,
/// so what is captured is what a person sees.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      r'C:\src\flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) {
    // Not fatal: the assertions still run. The images just render as boxes.
    // ignore: avoid_print
    print('Material fonts not found at ${dir.path}; text will not be readable');
    return;
  }

  Future<void> load(String family, String file) async {
    final bytes = File('${dir.path}/$file').readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  // Every weight goes under the one family. Registering only roboto-regular
  // left bold and medium text with nothing to use, so it fell back to the
  // placeholder font and rendered as filled rectangles: the first capture of
  // the rebuilt heart screen was full of red blocks where the numbers should
  // have been, which looked like a colour bug in the screen rather than a
  // missing font in the harness.
  for (final weight in <String>[
    'roboto-light',
    'roboto-regular',
    'roboto-medium',
    'roboto-bold',
  ]) {
    await load('Roboto', '$weight.ttf');
  }
  await load('MaterialIcons', 'materialicons-regular.otf');
}

/// Wraps a screen in the providers the app supplies, and paints the real theme
/// so the capture reflects what someone would see.
///
/// [isEmbedded] says the screen is a body inside another page; it is given a
/// [DsPage] here because that is what its host gives it in the app. A full page
/// is given only a Scaffold, because it supplies its own frame and the real
/// shell always has a Scaffold above it. Either way there is a Scaffold, because
/// material widgets need a Material ancestor; without one, the first TextField
/// or button added to a screen failed with "No Material widget found".
Widget harness(Widget child, {required bool isEmbedded}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<BleService>(create: (_) => BleService()),
      // Supplied by main.dart, and the heart screen reads it for the session
      // minimum and maximum. Omitting it produced a ProviderNotFoundException
      // rather than a missing-value message, which is a poor way to find out a
      // screen needs a provider.
      ChangeNotifierProvider<HeartRateTracker>(create: (_) => HeartRateTracker()),
      ChangeNotifierProvider<AppLock>(create: (_) => AppLock()),
      ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
      // Settings reads the current language from this during initState.
      // Without it the lookup threw inside a setState callback, the exception
      // never surfaced, and the screen sat on its loading spinner forever -
      // which is exactly how a person would report "settings is broken".
      ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
      ChangeNotifierProvider<AutoUpdateService>(
        create: (_) => AutoUpdateService(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: isEmbedded ? DsPage(child: child) : child,
      ),
    ),
  );
}

/// Writes the rendered frame to disk.
///
/// Uses Flutter's own golden mechanism rather than a hand-rolled toImage call.
/// That call hangs headless: it waits on a layer tree which is never
/// composited in the test environment, so every screen timed out at 25s.
///
/// Images land in build/ui_capture/. They are build output rather than committed
/// goldens, so they cannot go stale in the repository, which is the usual reason
/// golden files rot and stop being looked at.
Future<void> _capture(WidgetTester tester, String name) async {
  // Opt-in. Without this the golden comparison runs on every test, and a screen
  // that rendered correctly would fail because antialiasing differed by a shade
  // from the stored image. Capturing is a thing a person asks for; verifying is
  // something CI does.
  if (!captureImages) return;

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../build/ui_capture/$name.png'),
  );
}

/// Collects framework errors instead of letting them end the test.
///
/// A RenderFlex overflow is reported through FlutterError.onError. Left alone,
/// the first one throws out of the test and leaves the binding in a state where
/// every later test in the same file fails immediately without rendering
/// anything - which is how four overflowing screens came to look like all
/// nineteen were broken.
///
/// Collecting them means each screen is judged on its own, and the message can
/// be reported precisely instead of as a generic failure.
final List<String> _collectedErrors = <String>[];

/// Installs the collector for the duration of one test.
///
/// The binding installs its own FlutterError.onError for each test. The
/// previous handler is kept here rather than assumed, because restoring
/// [FlutterError.presentError] instead of the binding's handler makes the
/// binding assert that the test never put it back — and that assertion leaves
/// the test hung until its timeout rather than reporting the real failure.
void Function(FlutterErrorDetails)? _savedHandler;

void _startCollecting() {
  _collectedErrors.clear();
  _savedHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.exceptionAsString();
    // The full details, not just the one-line exception: the details include
    // the widget and the source line, so a failure names what overflowed
    // instead of leaving the next person to guess.
    _collectedErrors.add(details.toString());
    // Anything that is not a layout problem still goes to the original handler,
    // so a genuine error surfaces loudly rather than being swept up.
    if (!text.contains('overflowed')) _savedHandler?.call(details);
  };
}

/// Stops collecting and returns what was seen.
List<String> _stopCollecting() {
  final found = List<String>.of(_collectedErrors);
  final saved = _savedHandler;
  if (saved != null) FlutterError.onError = saved;
  return found;
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    useStubNotifications();
  });

  setUp(() {
    // Each test starts from empty preferences.
    //
    // Several screens read and write SharedPreferences - sleep reads demo_mode,
    // settings writes six keys - and in a single test file that store persists
    // between tests. Without this, state left by one screen changed what the
    // next one rendered, and once a test threw, every later test in the file
    // failed immediately without rendering anything at all.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final viewport in _viewports) {
    group('at ${viewport.name} (${viewport.size.width.toInt()}px)', () {
      for (final entry in _screens.entries) {
        testWidgets(
          '${entry.key} renders without throwing',
          (tester) async {
            tester.view.physicalSize = viewport.size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            _startCollecting();
            addTearDown(_stopCollecting);

            // Inside the body, not in a teardown: the binding checks for live animations as
            // soon as the body returns, which is before tearDowns run.
            //
            // watch_simulator runs two AnimationControllers with repeat(). They
            // are disposed correctly in the widget's own dispose(), but that
            // only runs once the tree is torn down. Without doing it here, the
            // scheduler reported "an animation is still running even after the
            // widget tree was disposed" against whichever test ran next, so one
            // screen's animation made every screen after it look broken.
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(milliseconds: 20));

            await tester.pumpWidget(
              harness(
                entry.value(),
                isEmbedded: _embeddedScreens.contains(entry.key),
              ),
            );
            // Fixed pumps, not settle: an indeterminate progress indicator
            // never settles, so pumpAndSettle would hang until timeout.
            for (var i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 120));
            }

            final thrown = tester.takeException();
            final overflows = _collectedErrors
                .where((String e) => e.contains('overflowed'))
                .toList();

            // Put the binding's handler back before asserting. Asserting with
            // a custom handler still installed makes the binding complain that
            // it was never restored and hang the test until its timeout, which
            // hides the failure that actually matters.
            _stopCollecting();

            expect(
              thrown,
              isNull,
              reason: '${entry.key} threw at '
                  '${viewport.size.width.toInt()}px wide',
            );
            expect(
              overflows,
              isEmpty,
              reason: '${entry.key} overflows at '
                  '${viewport.size.width.toInt()}px wide:\n'
                  '${overflows.join('\n')}',
            );

            await _capture(tester, '${entry.key}_${viewport.name}');
          },
          // Several screens start timers and network reads on open. Without a
          // bound, one of them stalls the whole run for ten minutes before the
          // failure is reported.
          timeout: const Timeout(Duration(seconds: 25)),
        );
      }
    });
  }

  test('every screen in lib/screens is covered', () {
    // Guards against a new screen being added and never looked at.
    final onDisk = Directory('lib/screens')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'))
        .map((f) => f.uri.pathSegments[2].replaceAll('_screen.dart', ''))
        .where((n) => !n.startsWith('web_landing'))
        .toSet();

    final captured = _screens.keys.toSet();
    final missing = onDisk.difference(captured);
    expect(missing, isEmpty, reason: 'screens not captured: $missing');
  });
}