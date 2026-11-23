import 'package:cambric_design/cambric_design.dart';
import 'package:flutter/material.dart';

import 'theme_service.dart';

/// Builds the app theme for one person's choices.
///
/// The Cambric design system defines the surfaces, text, borders and semantic
/// health colours, and those stay fixed: a warning must stay a warning, and a
/// card must stay the same card. Only the primary, secondary and tertiary
/// families are re-derived from the person's [AppAccent] seed, so a change of
/// accent is visible on every button, link and highlight without a second
/// design system.
///
/// High contrast widens the hairlines and darkens the outline. It is a real
/// change to the rendered theme, not a switch that is remembered and ignored.
ThemeData buildAppTheme({
  required Brightness brightness,
  required AppAccent accent,
  required bool highContrast,
}) {
  final bool isDark = brightness == Brightness.dark;
  final ThemeData base = isDark ? AppTheme.dark : AppTheme.light;
  final ColorScheme baseScheme = base.colorScheme;

  final ColorScheme derived = ColorScheme.fromSeed(
    seedColor: accent.seed,
    brightness: brightness,
  );

  final Color outline = highContrast
      ? (isDark ? const Color(0xFF93A1B8) : const Color(0xFF485266))
      : baseScheme.outline;
  final Color outlineVariant =
      highContrast ? outline : baseScheme.outlineVariant;
  final double borderWidth = highContrast ? 2.0 : 1.0;

  final ColorScheme scheme = baseScheme.copyWith(
    primary: derived.primary,
    onPrimary: derived.onPrimary,
    primaryContainer: derived.primaryContainer,
    onPrimaryContainer: derived.onPrimaryContainer,
    secondary: derived.secondary,
    onSecondary: derived.onSecondary,
    secondaryContainer: derived.secondaryContainer,
    onSecondaryContainer: derived.onSecondaryContainer,
    tertiary: derived.tertiary,
    onTertiary: derived.onTertiary,
    inversePrimary: derived.primary,
    outline: outline,
    outlineVariant: outlineVariant,
  );

  final BorderRadius fieldRadius = BorderRadius.circular(Radii.sm + 2);

  return base.copyWith(
    colorScheme: scheme,
    cardTheme: base.cardTheme.copyWith(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: scheme.outline, width: borderWidth),
      ),
    ),
    dividerTheme: base.dividerTheme.copyWith(
      color: scheme.outline,
      thickness: borderWidth,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainer,
      side: BorderSide(color: scheme.outline, width: borderWidth),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      indicatorColor:
          scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      indicatorColor:
          scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      selectedIconTheme: IconThemeData(color: scheme.primary, size: 24),
      selectedLabelTextStyle: base.navigationRailTheme.selectedLabelTextStyle
          ?.copyWith(color: scheme.primary),
    ),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
      color: scheme.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHigh,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: scheme.outline, width: borderWidth),
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: scheme.outline, width: borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: scheme.outline, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: scheme.error, width: borderWidth),
      ),
    ),
  );
}

/// Combines the operating system's text scale with the person's own scale.
///
/// The setting multiplies rather than replaces the system value, so someone who
/// already runs their OS at 1.3 does not lose that by choosing 1.1 here. The
/// product of the two is clamped so a large OS scale plus the largest setting
/// cannot make a screen impossible to use.
double effectiveTextScale(double systemScale, double setting) {
  final double safeSystem =
      systemScale.isFinite && systemScale > 0 ? systemScale : 1.0;
  return (safeSystem * setting).clamp(0.8, 3.0).toDouble();
}
