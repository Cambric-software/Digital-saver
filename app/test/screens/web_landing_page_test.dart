import 'package:digital_saver/screens/web_landing_page.dart';
import 'package:digital_saver/widgets/glassmorphic_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The public download page at the two widths it is read at.
///
/// There was no test for this page at all, which is how its download links came
/// to point at filenames that had never existed on a release. These tests pin
/// the three platforms and the glass panels that replaced the opaque cards on
/// 2026-10-21.
void main() {
  for (final ({String name, Size size}) viewport
      in <({String name, Size size})>[
    (name: 'phone', size: const Size(390, 844)),
    (name: 'laptop', size: const Size(1440, 900)),
  ]) {
    testWidgets('the download page renders at ${viewport.name} width',
        (WidgetTester tester) async {
      tester.view.physicalSize = viewport.size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: WebLandingPage()),
      );
      // One pump for the frame and one for the async tag read, which fails
      // without a network and must not stop the page rendering.
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      // The header nav carries the same words as the section heading.
      expect(find.text('Download for your platform'), findsWidgets);
      for (final String platform in <String>['Windows', 'Linux', 'Android']) {
        expect(find.text(platform), findsWidgets, reason: '$platform missing');
      }
      expect(
        find.byType(GlassCard),
        findsNWidgets(3),
        reason: 'each platform card is a glass panel',
      );
    });
  }
}
