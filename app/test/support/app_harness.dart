// One rig for every screen test.
//
// The capture tests and the interaction tests have to render a screen the way
// the app does: the same providers, the same theme, and a Scaffold above it.
// Keeping that in one place means a new provider is added once rather than in
// every test file, and a test cannot quietly pass under a different theme from
// the one people use.
library;

import 'package:digital_saver/services/app_lock.dart';
import 'package:digital_saver/services/auto_update_service.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/heart_rate_tracker.dart';
import 'package:digital_saver/services/locale_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The phone viewport the app is designed against.
const Size phoneSize = Size(390, 844);

/// The laptop viewport the app is designed against.
const Size laptopSize = Size(1440, 900);

/// Both required widths, in one list so a test cannot cover only one.
const List<Size> interactionSizes = <Size>[phoneSize, laptopSize];

/// Wraps a screen in the providers and theme the app supplies.
///
/// [embedded] says the widget is a body inside another page - one of the Vitals
/// or Insights tabs - and therefore needs a [DsPage] here, because that is what
/// its host gives it. A full page brings its own frame and gets only a
/// [Scaffold], which is still required: material widgets such as [TextField]
/// throw "No Material widget found" without one.
Widget appHarness(Widget child, {bool embedded = false}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<BleService>(create: (_) => BleService()),
      // main.dart supplies this; the heart screen reads it for the session
      // minimum and maximum, and omitting it is a ProviderNotFoundException
      // rather than a missing-value message.
      ChangeNotifierProvider<HeartRateTracker>(create: (_) => HeartRateTracker()),
      ChangeNotifierProvider<AppLock>(create: (_) => AppLock()),
      ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
      // Settings reads the current language during initState.
      ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
      ChangeNotifierProvider<AutoUpdateService>(
        create: (_) => AutoUpdateService(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(body: embedded ? DsPage(child: child) : child),
    ),
  );
}

/// Renders [child] at [size] and lets the first frame's async loads land.
///
/// Fixed pumps rather than [WidgetTester.pumpAndSettle]: several screens show an
/// indeterminate [CircularProgressIndicator] while they load, and that never
/// settles. 120ms is enough for a microtask plus a listener rebuild, and is the
/// same pump the capture harness has always used.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size size = phoneSize,
  bool embedded = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Start from an empty tree first. `pumpWidget` reuses a provider whose
  // widget type and position are unchanged, so rendering the same screen twice
  // would keep the old State and its providers - and a "reopen the screen"
  // test would quietly assert against the widgets it never left. Tearing down
  // first makes the second open read the stores again.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.pumpWidget(appHarness(child, embedded: embedded));
  await settleLoads(tester);
}

/// Pumps the fixed number of frames the harness uses for asynchronous loads.
///
/// The short [WidgetTester.runAsync] turns are what let a plugin call fail.
/// `SharedPreferences` is mocked, but `path_provider` is not: its
/// `MissingPluginException` is delivered on the real event loop, which
/// [WidgetTester.pump]'s fake clock never advances. Without these turns every
/// history screen would still be showing its spinner and a test could assert
/// nothing about how it handles an unreadable store.
Future<void> settleLoads(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Finds a button whose visible label is [text], whichever button class it is.
///
/// `find.widgetWithText(FilledButton, ...)` misses an `OutlinedButton` with the
/// same label, and the design system uses several kinds for the same kind of
/// action. This looks for the shared superclass instead.
Finder buttonWithText(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((Widget widget) {
      return widget is ButtonStyleButton;
    }),
  );
}

/// Reads a provider from the rendered tree, for asserting that a control
/// changed real state rather than only what is on screen.
T serviceOf<T extends ChangeNotifier>(WidgetTester tester) {
  return Provider.of<T>(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
}

/// Scrolls [finder] into view inside the page's scroll view.
///
/// A fixed number of pixels per step, with a cap, so a missing control fails
/// with the finder's own message rather than looping forever.
Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double step = 300,
  int maxSteps = 40,
}) async {
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

/// The outermost [DsCard] that contains [text].
///
/// Timer cards and metric tiles are all [DsCard]s, so this scopes a finder to
/// one card when the same label - "Start", "Reset", "Save" - appears in several.
Finder cardWithText(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(DsCard),
  ).first;
}

/// Finds [finder] inside the card that contains [title].
Finder inCard(String title, Finder finder) {
  return find.descendant(of: cardWithText(title), matching: finder);
}

/// Finds a button labelled [label] inside the card that contains [title].
Finder buttonInCard(String title, String label) {
  return inCard(title, buttonWithText(label));
}

/// The outermost [DsSection] that contains [text].
///
/// Section headings sit outside their [DsCard], so [cardWithText] cannot scope
/// a control to, say, "Hydration today". This can.
Finder sectionWithText(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(DsSection),
  ).first;
}

/// Finds [finder] inside the section that contains [title].
Finder inSection(String title, Finder finder) {
  return find.descendant(of: sectionWithText(title), matching: finder);
}

/// Finds a button labelled [label] inside the section that contains [title].
Finder buttonInSection(String title, String label) {
  return inSection(title, buttonWithText(label));
}

/// Scrolls the first [Scrollable] until [finder] is found, then returns.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 100));
    return;
  }
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 60,
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Types [text] into the field labelled [label].
///
/// [index] picks among fields that share a label, in tree order. Settings has
/// two fields labelled "Name" - the profile and a new contact.
Future<void> enterByLabel(
  WidgetTester tester,
  String label,
  String text, {
  int index = 0,
}) async {
  final Finder field = find.widgetWithText(TextField, label).at(index);
  await scrollTo(tester, field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Opens a dropdown by its visible label and chooses [option].
Future<void> chooseFromDropdown(
  WidgetTester tester,
  String label,
  String option, {
  int index = 0,
}) async {
  final Finder dropdown = find
      .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is DropdownButtonFormField,
        ),
      )
      .at(index);
  await scrollTo(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(option).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
