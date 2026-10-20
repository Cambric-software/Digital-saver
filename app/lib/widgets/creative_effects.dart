/// The one background worth keeping from the old effects file: a still wave.
///
/// `creative_effects.dart` used to hold seven animated decorations - a moving
/// wave, floating particles, neon text, a rotating gradient border, pulsing
/// dots, a progress ring and a synthetic ECG. None was mounted, and each one
/// started an `AnimationController` that repeated forever. A decoration that
/// no screen uses still ticks in tests and, if it is ever mounted, keeps
/// repainting the whole background whether or not anything changed.
///
/// [WaveBackdrop] keeps the shape and drops the motion. It is a static painting
/// drawn from the app's own colour roles, so the splash screen can have a
/// backdrop that is part of the product rather than a separate palette. There
/// is no controller, so there is no ticker to leak.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A layered, static wave used behind the splash content.
class WaveBackdrop extends StatelessWidget {
  /// Create a wave backdrop.
  ///
  /// [color] sets the base hue; [layers] controls how many bands are drawn;
  /// [opacity] is the alpha of the front band. The back bands are lighter.
  const WaveBackdrop({
    super.key,
    this.color,
    this.layers = 3,
    this.opacity = 0.14,
    this.child,
  });

  /// Base colour, or the theme's primary when null.
  final Color? color;

  /// Number of bands. Values below one draw nothing.
  final int layers;

  /// Alpha of the nearest band.
  final double opacity;

  /// Optional content drawn on top of the waves.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Color base = color ??
        AppColors.of(AppColors.primary, AppColors.darkPrimary, context);
    final int count = layers < 0 ? 0 : layers;
    final List<Color> colors = <Color>[
      for (var i = 0; i < count; i++)
        base.withValues(
          alpha: (opacity * (1 - i / (count + 1))).clamp(0.0, 1.0),
        ),
    ];

    return RepaintBoundary(
      child: CustomPaint(
        painter: _WavePainter(colors),
        child: child,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;

    for (var i = 0; i < colors.length; i++) {
      final Path path = Path();
      final Paint paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final double phase = i * 1.3;
      final double baseline = size.height * (0.58 + i * 0.09);
      final double amplitude = size.height * (0.05 - i * 0.009);
      final double frequency = 1.1 + i * 0.25;

      path.moveTo(0, size.height);
      final double step = math.max(1, size.width / 120);
      for (double x = 0; x <= size.width; x += step) {
        final double turn = (x / size.width) * frequency * 2 * math.pi;
        final double y = baseline +
            amplitude * math.sin(turn + phase) +
            amplitude * 0.35 * math.sin(turn * 2.1 - phase);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    if (oldDelegate.colors.length != colors.length) return true;
    for (var i = 0; i < colors.length; i++) {
      if (oldDelegate.colors[i] != colors[i]) return true;
    }
    return false;
  }
}
