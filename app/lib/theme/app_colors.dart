import 'package:flutter/material.dart';

/// The colour system for Digital Saver.
///
/// Two layers:
///
///  * **Semantic** ([AppColors]) - what a colour *means*. Heart rate is red
///    wherever it appears, warning is amber wherever it appears. Screens never
///    pick a hex value; they name a role.
///  * **Surface** ([AppSurfaces]) - the light and dark background ramps.
///
/// The previous palette defined flat colours with no dark mode, so anything
/// drawn from it was unreadable on a dark background. Every semantic colour now
/// has a light and a dark form, and [of] resolves between them.
///
/// Existing call sites keep working: the flat members are the light values.
class AppColors {
  const AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B6FE0);
  static const Color primaryDark = Color(0xFF24509F);
  static const Color accent = Color(0xFF12A594);

  // ── Status ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF12855F);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFC63A34);
  static const Color dangerDark = Color(0xFF9E2A26);

  // ── Surfaces and text ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textMuted = Color(0xFF8A94A6);
  static const Color border = Color(0xFFE2E6EF);

  // ── Health domains ────────────────────────────────────────────────────
  static const Color heartRed = Color(0xFFC63A34);
  static const Color bpBlue = Color(0xFF3B6FE0);
  static const Color oxyGreen = Color(0xFF12855F);
  static const Color stepAmber = Color(0xFFB26A00);
  static const Color sleepPurple = Color(0xFF6C4BD1);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: <Color>[Color(0xFF24509F), Color(0xFF4E82F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientHeart = LinearGradient(
    colors: <Color>[Color(0xFFA32B26), Color(0xFFE0665F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientBP = LinearGradient(
    colors: <Color>[Color(0xFF24509F), Color(0xFF6E9BF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientOxy = LinearGradient(
    colors: <Color>[Color(0xFF0C6E4F), Color(0xFF27A87C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientSleep = LinearGradient(
    colors: <Color>[Color(0xFF52389E), Color(0xFF8B72E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientActivity = LinearGradient(
    colors: <Color>[Color(0xFF8F5500), Color(0xFFD08A1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Dark-mode forms ───────────────────────────────────────────────────
  // Lifted and desaturated: the light values are too dark to read on a dark
  // surface, so these are distinct colours rather than the same hex.
  static const Color darkPrimary = Color(0xFF7FA8FF);
  static const Color darkAccent = Color(0xFF35D0BC);
  static const Color darkSuccess = Color(0xFF43C79A);
  static const Color darkWarning = Color(0xFFE8A33C);
  static const Color darkDanger = Color(0xFFF0736B);
  static const Color darkTextPrimary = Color(0xFFEDF0F6);
  static const Color darkTextSecondary = Color(0xFFA8B2C6);
  static const Color darkTextMuted = Color(0xFF737E92);
  static const Color darkHeart = Color(0xFFF0736B);
  static const Color darkBp = Color(0xFF7FA8FF);
  static const Color darkOxy = Color(0xFF43C79A);
  static const Color darkStep = Color(0xFFE8A33C);
  static const Color darkSleep = Color(0xFFA78BFA);

  /// Resolve a semantic colour for the current brightness.
  ///
  /// Used by widgets that need a flat colour rather than a theme colour.
  static Color of(Color light, Color dark, BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Background, surface and border ramps for both brightnesses.
class AppSurfaces {
  const AppSurfaces._();

  /// Page background.
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color darkBackground = Color(0xFF0E1116);

  /// Raised surface (cards).
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF161B23);

  /// Surface above a card (nested panels, inputs).
  static const Color lightSurfaceRaised = Color(0xFFFAFBFE);
  static const Color darkSurfaceRaised = Color(0xFF1D232D);

  /// Hairline.
  static const Color lightBorder = Color(0xFFE2E6EF);
  static const Color darkBorder = Color(0xFF262E3A);
}

/// Elevation, expressed as shadow.
///
/// Kept because several screens still reference it, but the rebuilt theme uses
/// hairline borders instead of shadows on cards: a soft shadow disappears on a
/// dark surface and reads as smudge rather than depth. These remain for the
/// places where a genuine lift is wanted, such as a floating action button or a
/// dragged surface.
class AppShadows {
  const AppShadows._();

  /// Subtle lift for a resting card.
  static List<BoxShadow> card = <BoxShadow>[
    const BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  /// A tinted lift that picks up an accent colour.
  static List<BoxShadow> coloredCard(Color c) => <BoxShadow>[
    BoxShadow(
      color: c.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// A strong lift for a surface that is genuinely above the page.
  static List<BoxShadow> float = <BoxShadow>[
    const BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];
}

/// The meaning a reading carries, so colour is never the only signal.
///
/// Colour alone excludes anyone who cannot distinguish red from green, which
/// for a health product is not an acceptable gap. Every status is also carried
/// by an icon and a word.
enum HealthStatus {
  /// Normal, in range.
  normal('Normal', Icons.check_circle_outline),

  /// Worth watching.
  elevated('Watch', Icons.trending_up),

  /// Needs attention.
  high('High', Icons.warning_amber_rounded),

  /// Needs urgent attention.
  critical('Critical', Icons.error_outline),

  /// No reading available.
  unknown('No data', Icons.help_outline);

  const HealthStatus(this.label, this.icon);

  /// Word shown to the user.
  final String label;

  /// Shape cue, so status does not rely on hue alone.
  final IconData icon;
}
/// The colour for a reading's status, resolved against the active theme.
///
/// A getter on the enum cannot do this: colour depends on whether the app is in
/// light or dark mode, which needs a [BuildContext]. Screens were each picking
/// their own colour for the same status, which is how one screen could show an
/// elevated reading in amber and another in red.
///
/// Colour is never the only signal. Each status also carries a [HealthStatus.label]
/// and a distinct [HealthStatus.icon], so this carries meaning rather than
/// decoration.
Color healthStatusColor(HealthStatus status, BuildContext context) {
  switch (status) {
    case HealthStatus.normal:
      return AppColors.of(AppColors.success, AppColors.darkSuccess, context);
    case HealthStatus.elevated:
      return AppColors.of(AppColors.warning, AppColors.darkWarning, context);
    case HealthStatus.high:
      return AppColors.of(AppColors.danger, AppColors.darkDanger, context);
    case HealthStatus.critical:
      return AppColors.of(AppColors.danger, AppColors.darkDanger, context);
    case HealthStatus.unknown:
      return AppColors.of(AppColors.textMuted, AppColors.darkTextMuted, context);
  }
}
