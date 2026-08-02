import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cambric_auth_service_v2.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../main.dart' show MainNav;

class EnhancedSplashScreen extends StatefulWidget {
  const EnhancedSplashScreen({super.key});

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late AnimationController _particlesController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _glowAnimation;

  bool _showDisclaimer = false;
  bool _disclaimerExpanded = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _particlesController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _iconController.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showDisclaimer = true);
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _disclaimerExpanded = true);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _particlesController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _acceptAndContinue() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNav()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AuthScreen(onSignedIn: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNav()));
        })),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated wave background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SplashWavePainter(_waveController.value),
                  size: Size.infinite,
                );
              },
            ),
          ),
          
          // Floating particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SplashParticlePainter(_particlesController.value),
                  size: Size.infinite,
                );
              },
            ),
          ),
          
          // Main content
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E3A5F).withOpacity(0.8),
                  const Color(0xFF0F172A).withOpacity(0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) => Opacity(opacity: _fadeAnimation.value, child: child),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Animated App Icon with glow and particles
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) => Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow ring
                              AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, _) {
                                  return Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withOpacity(_glowAnimation.value * 0.3),
                                          blurRadius: 60,
                                          spreadRadius: 20,
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withOpacity(_glowAnimation.value * 0.2),
                                          blurRadius: 80,
                                          spreadRadius: 30,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Main icon
                              AnimatedBuilder(
                                animation: _iconController,
                                builder: (context, child) => AnimatedBuilder(
                                  animation: _glowController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(32),
                                        boxShadow: [
                                          BoxShadow(color: const Color(0xFF2563EB).withOpacity(_glowAnimation.value), blurRadius: 30, spreadRadius: 5),
                                          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(_glowAnimation.value * 0.5), blurRadius: 50, spreadRadius: 10),
                                        ],
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Transform.scale(
                                    scale: 1.0 + (_iconController.value * 0.08),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.asset('assets/digital-saver-icon-transparent.png', width: 130, height: 130, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Colors.white, size: 70)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Animated Title with neon effect
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) => Opacity(
                          opacity: _textOpacity.value,
                          child: SlideTransition(position: _textSlide, child: child),
                        ),
                        child: Column(
                          children: [
                            // Neon glow text
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFF60A5FA), Colors.white],
                              ).createShader(bounds),
                              child: AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, _) {
                                  return Text(
                                    'Digital Saver',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(color: const Color(0xFF2563EB).withOpacity(_glowAnimation.value), blurRadius: 20),
                                        Shadow(color: const Color(0xFF7C3AED).withOpacity(_glowAnimation.value * 0.5), blurRadius: 40),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subtitle
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, _) {
                                return ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.7 + _glowAnimation.value * 0.3),
                                      Colors.white.withOpacity(0.5),
                                      Colors.white.withOpacity(0.7 + _glowAnimation.value * 0.3),
                                    ],
                                  ).createShader(bounds),
                                  child: const Text('Health Monitoring System', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Cambric Badge with pulse
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) => Opacity(opacity: _textOpacity.value, child: child),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1 + _glowAnimation.value * 0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.2 + _glowAnimation.value * 0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(_glowAnimation.value * 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15 + _glowAnimation.value * 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.shield, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text('Made by Cambric', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                              ]),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Stats row
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) => Opacity(opacity: _textOpacity.value, child: child),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('❤️', 'Heart Rate', 'Real-time'),
                            _buildStatItem('💨', 'SpO2', 'Monitoring'),
                            _buildStatItem('🚨', 'Fall Detection', 'Alert'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Disclaimer Section
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _showDisclaimer
                          ? AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(children: [
                                Row(children: [
                                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24)),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Text('Medical Disclaimer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                                ]),
                                const SizedBox(height: 16),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(children: [
                                    const Text('Digital Saver is for informational purposes only. Always consult a qualified healthcare professional for medical concerns.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                                    const SizedBox(height: 12),
                                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.3))), child: const Row(children: [
                                      Icon(Icons.info_outline, color: Colors.amber, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('This app is NOT a certified medical device.', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w500))),
                                    ])),
                                    const SizedBox(height: 20),
                                    SizedBox(width: double.infinity, child: ElevatedButton(
                                      onPressed: _acceptAndContinue,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4),
                                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('I Understand & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 20)]),
                                    )),
                                  ]),
                                  crossFadeState: _disclaimerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 400),
                                ),
                              ]),
                            )
                          : Column(children: [
                              SizedBox(width: 50, height: 50, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white.withOpacity(0.8))),
                              const SizedBox(height: 16),
                              const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ]),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
      ],
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  final double animation;
  
  _SplashWavePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF2563EB).withOpacity(0.1),
      const Color(0xFF7C3AED).withOpacity(0.1),
      const Color(0xFF06B6D4).withOpacity(0.05),
    ];

    for (int i = 0; i < colors.length; i++) {
      final path = Path();
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final offset = i * 0.3;
      final amplitude = 30.0 - i * 8.0;
      final frequency = 0.8 + i * 0.2;

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 5) {
        final y = size.height * (0.6 + i * 0.1) +
            amplitude * math.sin((x / size.width * frequency * 2 * math.pi) + (animation + offset) * 2 * math.pi);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _SplashParticlePainter extends CustomPainter {
  final double animation;
  final _random = math.Random(42);
  late final List<_Particle> _particles;

  _SplashParticlePainter(this.animation) {
    _particles = List.generate(25, (_) => _Particle(_random));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final yOffset = (animation * particle.speed * size.height) % size.height;
      final xWobble = math.sin(animation * particle.wobbleSpeed * 2 * math.pi) * 30;
      
      final x = particle.x * size.width + xWobble;
      final y = (particle.y * size.height + yOffset) % size.height;

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double wobbleSpeed;
  final Color color;

  _Particle(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 2 + random.nextDouble() * 3,
        speed = 0.1 + random.nextDouble() * 0.2,
        opacity = 0.1 + random.nextDouble() * 0.3,
        wobbleSpeed = 0.5 + random.nextDouble(),
        color = [
          const Color(0xFF2563EB),
          const Color(0xFF7C3AED),
          const Color(0xFF06B6D4),
          const Color(0xFF10B981),
        ][random.nextInt(4)];
}
