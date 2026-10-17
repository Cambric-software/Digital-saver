import 'package:flutter/material.dart';

/// The single source of truth for every colour in the product.
///
/// This lives in its own file because it is used from screens, widgets and the
/// theme alike. It used to be defined inside `app_theme.dart`, which meant any
/// screen wanting a colour had to import the whole theme - and five screens
/// imported a non-existent `app_colors.dart` instead, which left the project
/// with 53 compile errors. Keep the palette here so there is exactly one
/// definition and every consumer can reach it cheaply.
///
/// All values are `const`, so they can be used in `const` widget trees.
class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────
  static const primary = Color(0xFF526B7D);
  static const primaryDark = Color(0xFF314A5B);
  static const accent = Color(0xFF4C647A);

  // ── Status ────────────────────────────────────────────────────────────
  static const success = Color(0xFF3F7A68);
  static const warning = Color(0xFF9A6B32);
  static const danger = Color(0xFFAA514F);
  static const dangerDark = Color(0xFF991B1B);

  // ── Surfaces and text ─────────────────────────────────────────────────
  static const background = Color(0xFFF1F5FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);

  // ── Health domains ────────────────────────────────────────────────────
  static const heartRed = Color(0xFFAA514F);
  static const bpBlue = Color(0xFF4C647A);
  static const oxyGreen = Color(0xFF3F7A68);
  static const stepAmber = Color(0xFF9A6B32);
  static const sleepPurple = Color(0xFF596A78);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF314A5B), Color(0xFF5F7890)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientHeart = LinearGradient(
    colors: [Color(0xFF7D4E4C), Color(0xFFAA514F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientBP = LinearGradient(
    colors: [Color(0xFF4C647A), Color(0xFF71879A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientOxy = LinearGradient(
    colors: [Color(0xFF3F7A68), Color(0xFF5E9180)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSleep = LinearGradient(
    colors: [Color(0xFF465A6A), Color(0xFF6A7C8B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientActivity = LinearGradient(
    colors: [Color(0xFF8A6337), Color(0xFFB0834D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}