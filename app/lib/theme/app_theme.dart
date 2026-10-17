import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

// Many screens reach AppColors through the theme rather than importing the
// colour file directly. Re-exported so both routes work from one definition.
export 'app_colors.dart';
export 'design_tokens.dart';

/// The application theme.
///
/// Rebuilt around the token files. The previous version derived everything
/// from a single seed colour, which meant light and dark were not really two
/// designs but one design plus an automatic inversion, and the semantic health
/// colours had no dark forms at all.
class AppTheme {
  const AppTheme._();

  /// Light theme.
  static ThemeData get light => _build(Brightness.light);

  /// Dark theme.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.primary,
      onPrimary: isDark ? const Color(0xFF06152F) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF1B2A4A)
          : const Color(0xFFDCE7FF),
      onPrimaryContainer: isDark
          ? AppColors.darkPrimary
          : AppColors.primaryDark,
      secondary: isDark ? AppColors.darkAccent : AppColors.accent,
      onSecondary: isDark ? const Color(0xFF00201C) : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF0B3330) : const Color(0xFFD3F5EF),
      onSecondaryContainer:
          isDark ? AppColors.darkAccent : const Color(0xFF00504A),
      tertiary: isDark ? AppColors.darkSleep : AppColors.sleepPurple,
      onTertiary: Colors.white,
      error: isDark ? AppColors.darkDanger : AppColors.danger,
      onError: isDark ? const Color(0xFF2A0906) : Colors.white,
      errorContainer: isDark ? const Color(0xFF3B1512) : const Color(0xFFFBE3E1),
      onErrorContainer: isDark ? AppColors.darkDanger : AppColors.dangerDark,
      surface: isDark ? AppSurfaces.darkSurface : AppSurfaces.lightSurface,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      surfaceContainerLowest:
          isDark ? AppSurfaces.darkBackground : AppSurfaces.lightSurface,
      surfaceContainerLow: isDark
          ? AppSurfaces.darkBackground
          : AppSurfaces.lightSurfaceRaised,
      surfaceContainer: isDark
          ? AppSurfaces.darkSurfaceRaised
          : AppSurfaces.lightSurfaceRaised,
      surfaceContainerHigh:
          isDark ? const Color(0xFF222933) : const Color(0xFFF1F4FA),
      surfaceContainerHighest:
          isDark ? const Color(0xFF28313D) : const Color(0xFFE9EDF5),
      onSurfaceVariant: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      outline: isDark ? AppSurfaces.darkBorder : AppColors.border,
      outlineVariant:
          isDark ? const Color(0xFF1F2630) : const Color(0xFFEDF0F6),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? const Color(0xFFE8ECF3) : const Color(0xFF1B2330),
      onInverseSurface: isDark ? const Color(0xFF1B2330) : Colors.white,
      inversePrimary:
          isDark ? AppColors.primary : AppColors.darkPrimary,
    );

    final text = _textTheme(scheme, isDark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppSurfaces.darkBackground : AppSurfaces.lightBackground,
      textTheme: text,
      // Cards are the main grouping device in this app, so their default is
      // tuned deliberately rather than inherited.
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppSurfaces.darkBackground : AppSurfaces.lightBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle:
            WidgetStatePropertyAll<TextStyle>(text.labelMedium ?? const TextStyle()),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, kMinTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm + 2),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, kMinTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.md,
          ),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm + 2),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm + 2),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm + 2),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm + 2),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm + 2),
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        side: BorderSide(color: scheme.outline),
        labelStyle: text.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: Space.xl,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        minVerticalPadding: Space.md,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.xl),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHigh,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme, bool isDark) {
    final primary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return TextTheme(
      displaySmall: Type.display.copyWith(color: primary),
      headlineMedium: Type.display.copyWith(color: primary, fontSize: 27),
      headlineSmall: Type.title.copyWith(color: primary, fontSize: 22),
      titleLarge: Type.title.copyWith(color: primary, fontSize: 20),
      titleMedium: Type.title.copyWith(color: primary),
      titleSmall: Type.caption.copyWith(color: primary, fontWeight: FontWeight.w600),
      bodyLarge: Type.body.copyWith(color: primary),
      bodyMedium: Type.body.copyWith(color: secondary, fontSize: 14),
      bodySmall: Type.caption.copyWith(color: secondary, fontSize: 12),
      labelLarge: Type.caption.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: Type.caption.copyWith(color: secondary, fontSize: 12),
      labelSmall: Type.overline.copyWith(color: secondary),
    );
  }
}