import 'dart:math' as math;
import 'package:flutter/material.dart';

// Animated wave background
class WaveBackground extends StatefulWidget {
  final List<Color>? colors;
  final double height;

  const WaveBackground({
    super.key,
    this.colors,
    this.height = 200,
  });

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? [
      const Color(0xFF2563EB).withOpacity(0.3),
      const Color(0xFF7C3AED).withOpacity(0.3),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WavePainter(
            animation: _controller.value,
            colors: colors,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  _WavePainter({required this.animation, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    for (int wave = 0; wave < colors.length; wave++) {
      final path = Path();
      final paint = Paint()
        ..color = colors[wave]
        ..style = PaintingStyle.fill;

      final offset = wave * 0.5;
      final amplitude = 20.0 - wave * 5;
      final frequency = 1.5 + wave * 0.3;

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.5 +
            amplitude *
                math.sin((x / size.width * frequency * 2 * math.pi) +
                    (animation + offset) * 2 * math.pi);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

// Floating particles background
class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color? color;
  final double size;

  const FloatingParticles({
    super.key,
    this.particleCount = 30,
    this.color,
    this.size = 100,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingParticle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particles = List.generate(widget.particleCount, (_) => _FloatingParticle(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF2563EB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FloatingParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _FloatingParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double wobbleSpeed;

  _FloatingParticle(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 2 + random.nextDouble() * 4,
        speed = 0.1 + random.nextDouble() * 0.3,
        opacity = 0.1 + random.nextDouble() * 0.4,
        wobbleSpeed = 0.5 + random.nextDouble();
}

class _FloatingParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final Color color;

  _FloatingParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final yOffset = (progress * particle.speed * size.height) % size.height;
      final xWobble = math.sin(progress * particle.wobbleSpeed * 2 * math.pi) * 20;
      
      final x = particle.x * size.width + xWobble;
      final y = (particle.y * size.height + yOffset) % size.height;

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Neon glow text
class NeonText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double glowRadius;

  const NeonText({
    super.key,
    required this.text,
    this.style,
    this.glowColor = const Color(0xFF2563EB),
    this.glowRadius = 10,
  });

  @override
  State<NeonText> createState() => _NeonTextState();
}

class _NeonTextState extends State<NeonText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          widget.text,
          style: widget.style?.copyWith(
            shadows: [
              Shadow(
                color: widget.glowColor.withOpacity(_animation.value),
                blurRadius: widget.glowRadius * _animation.value,
              ),
              Shadow(
                color: widget.glowColor.withOpacity(_animation.value * 0.5),
                blurRadius: widget.glowRadius * 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Animated gradient border
class GradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final Duration duration;

  const GradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = 16,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<GradientBorder> createState() => _GradientBorderState();
}

class _GradientBorderState extends State<GradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 2 * math.pi,
              colors: const [
                Color(0xFF2563EB),
                Color(0xFF7C3AED),
                Color(0xFFEC4899),
                Color(0xFF10B981),
                Color(0xFF2563EB),
              ],
              stops: [
                (_controller.value - 0.2).clamp(0.0, 1.0),
                (_controller.value).clamp(0.0, 1.0),
                (_controller.value + 0.2).clamp(0.0, 1.0),
                (_controller.value + 0.4).clamp(0.0, 1.0),
                (_controller.value + 0.6).clamp(0.0, 1.0),
              ],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Pulsing dots indicator
class PulsingDots extends StatefulWidget {
  final int dotCount;
  final Color color;
  final double size;

  const PulsingDots({
    super.key,
    this.dotCount = 3,
    this.color = const Color(0xFF2563EB),
    this.size = 10,
  });

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index / widget.dotCount;
            final value = ((_controller.value + delay) % 1.0);
            final scale = 0.5 + value * 0.5;
            final opacity = 0.3 + value * 0.7;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(opacity * 0.5),
                    blurRadius: widget.size * scale,
                    spreadRadius: widget.size * scale * 0.2,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

// Animated progress ring
class AnimatedProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final Widget? child;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor = Colors.white12,
    this.progressColor = const Color(0xFF2563EB),
    this.child,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _oldProgress = _animation.value;
      _animation = Tween<double>(begin: _oldProgress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: widget.backgroundColor,
                  progressColor: widget.progressColor,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          );
        },
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          progressColor,
          progressColor.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Heart rate line animation
class HeartRateLine extends StatefulWidget {
  final double height;
  final Color color;

  const HeartRateLine({
    super.key,
    this.height = 100,
    this.color = Colors.red,
  });

  @override
  State<HeartRateLine> createState() => _HeartRateLineState();
}

class _HeartRateLineState extends State<HeartRateLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _HeartRateLinePainter(
            animation: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _HeartRateLinePainter extends CustomPainter {
  final double animation;
  final Color color;

  _HeartRateLinePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = 50;
    final stepX = size.width / points;

    path.moveTo(0, size.height / 2);

    for (int i = 0; i <= points; i++) {
      final x = i * stepX;
      final normalizedX = i / points;
      
      // Create ECG-like pattern
      double y;
      final phase = (normalizedX + animation) % 1.0;
      
      if (phase < 0.1) {
        // Flat line
        y = size.height / 2;
      } else if (phase < 0.15) {
        // P wave
        y = size.height / 2 - 10 * math.sin((phase - 0.1) * math.pi / 0.05);
      } else if (phase < 0.2) {
        // Back to baseline
        y = size.height / 2;
      } else if (phase < 0.25) {
        // Q dip
        y = size.height / 2 + 15 * math.sin((phase - 0.2) * math.pi / 0.05);
      } else if (phase < 0.35) {
        // R spike up
        y = size.height / 2 - 40 * math.sin((phase - 0.25) * math.pi / 0.1);
      } else if (phase < 0.4) {
        // S dip
        y = size.height / 2 + 20 * math.sin((phase - 0.35) * math.pi / 0.05);
      } else {
        // Return to baseline
        y = size.height / 2;
      }

      if (i > 0) {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw glow
    paint
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeartRateLinePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
