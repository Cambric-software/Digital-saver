/// The one animation worth keeping from the old effects file: a pulse that
/// follows the measured heart rate.
///
/// `enhanced_animations.dart` previously held seven widgets - a pulse ring, a
/// health-score counter, a breathing blob, confetti particles, a shimmer, a tilt
/// card and a counter. None was imported anywhere. Several of them animated on a
/// timer that had nothing to do with the data, so a "pulse" kept beating at a
/// fixed rate whether the watch reported 48 or 140 BPM, and the particles drew
/// invented celebration.
///
/// [HeartPulseRing] has one job and one input. Its period is the real beat
/// interval, `60000 / bpm` milliseconds, so a 60 BPM reading completes one ring
/// per second and 120 BPM completes two. When [bpm] is zero or not finite there
/// is no pulse to show: the ring is drawn statically and no animation runs,
/// because a moving ring over a missing reading would be a fabricated signal.
library;

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';

/// A ring that expands once per heartbeat.
class HeartPulseRing extends StatefulWidget {
  /// Create a pulse ring.
  const HeartPulseRing({
    super.key,
    required this.bpm,
    this.size = 56,
    this.color = AppColors.heartRed,
    this.strokeWidth = 2,
    this.child,
  });

  /// Measured heart rate. Zero means no reading.
  final double bpm;

  /// Outer diameter, including the part the ring expands into.
  final double size;

  /// Ring colour, normally the heart accent for the active theme.
  final Color color;

  /// Ring line width.
  final double strokeWidth;

  /// Content shown in the middle, usually a heart icon or a reading.
  final Widget? child;

  /// The beat interval for [bpm], or null when there is no reading.
  ///
  /// Public so the arithmetic can be stated in a test without pumping frames.
  static Duration? periodForBpm(double bpm) {
    if (!bpm.isFinite || bpm <= 0) return null;
    final int milliseconds = (60000 / bpm).round();
    if (milliseconds <= 0) return null;
    return Duration(milliseconds: milliseconds);
  }

  @override
  State<HeartPulseRing> createState() => _HeartPulseRingState();
}

class _HeartPulseRingState extends State<HeartPulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration? get _period => HeartPulseRing.periodForBpm(widget.bpm);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _period ?? const Duration(seconds: 1),
      vsync: this,
    );
    _sync();
  }

  @override
  void didUpdateWidget(HeartPulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) _sync(restart: true);
  }

  void _sync({bool restart = false}) {
    final Duration? period = _period;
    if (period == null) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    _controller.duration = period;
    if (restart || !_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasReading = _period != null;
    final Widget base = Container(
      width: widget.size * 0.82,
      height: widget.size * 0.82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: hasReading ? 0.30 : 0.16),
          width: widget.strokeWidth,
        ),
      ),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (hasReading)
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double value = _controller.value;
                return Transform.scale(
                  scale: 1 + value * 0.18,
                  child: Opacity(
                    opacity: (1 - value) * 0.55,
                    child: Container(
                      width: widget.size * 0.82,
                      height: widget.size * 0.82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color,
                          width: widget.strokeWidth,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          base,
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
