/// The translucent panel used by the public download page.
///
/// This file used to hold five widgets written in a different visual language:
/// a translucent card, a fixed blue-to-purple gradient card, a glowing button,
/// a glowing icon button and a pulsing status dot. Nothing imported any of
/// them, and the three glow widgets each ran an animation that never stopped.
///
/// [GlassCard] now has a job: the three download cards on the web landing page
/// are the one surface that sits above the page rather than in it. The caller
/// supplies the surface colour and border from the page's own tokens, so the
/// palette is unchanged; the blur and the lift are the deliberate departure
/// decided on 2026-10-21. The other four widgets were removed rather than left
/// as code nothing uses - the page's buttons already lift on hover, so a second
/// glowing button would have given one action two looks.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// A blurred, translucent panel with a hairline border and a soft lift.
///
/// The background is see-through enough that whatever is behind it reads as
/// texture rather than as a second colour, so this belongs over a page with
/// something to blur, not over a flat in-app surface. Inside the app, use
/// [DsCard] instead.
class GlassCard extends StatelessWidget {
  /// Create a glass panel.
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.backgroundColor,
    this.onTap,
    this.border,
  });

  /// Panel content.
  final Widget child;

  /// Space around the content.
  final EdgeInsetsGeometry? padding;

  /// Space around the panel.
  final EdgeInsetsGeometry? margin;

  /// Corner radius.
  final double borderRadius;

  /// Blur applied to whatever is behind the panel.
  final double blur;

  /// Panel fill. Defaults to translucent white.
  final Color? backgroundColor;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Optional border. Defaults to a translucent white hairline.
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor ??
                      (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: border ??
                      Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
