/// Design tokens: the small set of numbers the whole interface is built from.
///
/// Every spacing, radius and duration in the app comes from here. When a screen
/// needs a value that is not in this file, that is a signal the value is
/// arbitrary, not that the token table is incomplete. Hard-coded numbers across
/// twenty screens is what made the previous interface feel assembled rather
/// than designed.
library;

import 'package:flutter/widgets.dart';

/// Spacing scale. Everything is a multiple of 4.
class Space {
  const Space._();

  /// Nothing.
  static const double none = 0;

  /// 2dp - hairline gaps.
  static const double xxs = 2;

  /// 4dp - icon to label.
  static const double xs = 4;

  /// 8dp - inside a chip.
  static const double sm = 8;

  /// 12dp - inside a compact card.
  static const double md = 12;

  /// 16dp - the default gap between elements.
  static const double lg = 16;

  /// 24dp - between groups.
  static const double xl = 24;

  /// 32dp - between sections.
  static const double xxl = 32;

  /// 48dp - page padding on large screens.
  static const double page = 48;
}

/// Corner radii.
class Radii {
  const Radii._();

  /// Pills and tags.
  static const double pill = 999;

  /// Small chips and inputs.
  static const double sm = 8;

  /// The default card radius.
  static const double md = 14;

  /// Large panels.
  static const double lg = 20;

  /// Sheets and dialogs.
  static const double xl = 28;
}

/// Type scale. Named by role rather than by size so a screen asks for
/// "a card title", not "18sp".
class Type {
  const Type._();

  /// Screen titles.
  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Large numbers, e.g. a heart-rate reading.
  static const TextStyle metric = TextStyle(
    fontSize: 44,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  /// Secondary numbers.
  static const TextStyle metricSmall = TextStyle(
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  /// Card and section titles.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  /// Body.
  static const TextStyle body = TextStyle(fontSize: 15, height: 1.45);

  /// Supporting detail.
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  /// Section labels and table headers, always upper case in use.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}

/// Motion. Short and purposeful; long durations read as sluggish on a
/// dashboard that people glance at.
class Motion {
  const Motion._();

  /// Press feedback.
  static const Duration fast = Duration(milliseconds: 120);

  /// State changes.
  static const Duration normal = Duration(milliseconds: 220);

  /// Larger transitions.
  static const Duration slow = Duration(milliseconds: 380);

  /// Standard easing.
  static const Curve enter = Curves.easeOutCubic;

  /// Standard exit easing.
  static const Curve exit = Curves.easeInCubic;
}

/// Breakpoints, used instead of scattering magic widths through the app.
class Breakpoints {
  const Breakpoints._();

  /// Below this, a single column.
  static const double compact = 600;

  /// At or above this, two columns are worth it.
  static const double medium = 900;

  /// At or above this, show the navigation rail.
  static const double expanded = 1100;

  /// True when the layout should be a single column.
  static bool isCompact(double width) => width < compact;

  /// True when a navigation rail should be shown.
  static bool usesRail(double width) => width >= expanded;
}

/// Minimum touch target. Accessibility, not taste.
const double kMinTouchTarget = 48;