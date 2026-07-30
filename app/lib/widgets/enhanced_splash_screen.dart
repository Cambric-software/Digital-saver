import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cambric_auth_service_v2.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';

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
    
    // Main entrance animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Icon pulse animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    
    // Main fade and scale
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );
    
    // Text animations
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    
    // Glow animation
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _mainController.forward();
    
    // Start icon pulse after scale completes
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _iconController.repeat(reverse: true);
    });
    
    // Start text animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    
    // Show disclaimer
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showDisclaimer = true);
    });
    
    // Expand disclaimer
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
    super.dispose();
  }

  void _acceptAndContinue() {
    final auth = context.read<AuthProvider>();
    
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNav()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AuthScreen(
          onSignedIn: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNav()),
            );
          },
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFF1E3A5F),
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Animated App Icon with glow
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) => Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                    child: AnimatedBuilder(
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
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(_glowAnimation.value),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(_glowAnimation.value * 0.5),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Transform.scale(
                          scale: 1.0 + (_iconController.value * 0.05),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/digital-saver-icon-transparent.png',
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 36),
                  
                  // Animated Title
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) => Opacity(
                      opacity: _textOpacity.value,
                      child: SlideTransition(
                        position: _textSlide,
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Digital Saver',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.6),
                              Colors.white.withOpacity(0.9),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Health Monitoring System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cambric Badge
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) => Opacity(
                      opacity: _textOpacity.value,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.shield, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Made by Cambric',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Disclaimer Section
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _showDisclaimer
                        ? AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Medical Disclaimer',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    children: [
                                      const Text(
                                        'Digital Saver is for informational purposes only and is NOT a substitute for professional healthcare advice. Always consult a qualified healthcare professional for medical concerns.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.amber, size: 18),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'This app is NOT a certified medical device. Readings may not be 100% accurate.',
                                                style: TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _acceptAndContinue,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(0xFF2563EB),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'I Understand & Continue',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  crossFadeState: _disclaimerExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 400),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.5),
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.5),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
