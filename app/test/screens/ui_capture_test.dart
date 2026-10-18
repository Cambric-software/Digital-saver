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
import 'package:digital_saver/services/theme_service.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/widgets/ds_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// Screens rebuilt onto the design system. These render inside [DsPage].
const Set<String> _contentScreens = <String>{
  'dashboard',
  'vitals',
  'heart',
  'activity',
  'sleep',
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
/// [isContent] distinguishes screens that render inside [DsPage] from screens
/// that are pages in their own right. Content screens must not provide their own
/// Scaffold, because DsPage supplies the title bar and the scroll view; giving
/// one here reproduces a nested scroll that the real shell would not have.
Widget harness(Widget child, {required bool isContent}) {
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
      ChangeNotifierProvider<AutoUpdateService>(
        create: (_) => AutoUpdateService(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: isContent ? DsPage(child: child) : Scaffold(body: child),
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

void main() {
  setUpAll(loadRealFonts);

  for (final viewport in _viewports) {
    group('at ${viewport.name} (${viewport.size.width.toInt()}px)', () {
      for (final entry in _screens.entries) {
        testWidgets(
          '${entry.key} renders without throwing',
          (tester) async {
            tester.view.physicalSize = viewport.size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
            harness(entry.value(), isContent: _contentScreens.contains(entry.key)),
          );
            // Fixed pumps, not settle: an indeterminate progress indicator
            // never settles, so pumpAndSettle would hang until timeout.
            for (var i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 120));
            }

            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} threw at '
                  '${viewport.size.width.toInt()}px wide',
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