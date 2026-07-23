import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/ble_service.dart';
import 'services/cambric_auth_service_v2.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/heart_screen.dart';
import 'screens/bp_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dafgzzkerytjuvxzymnq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhZmd6emtlcnl0anV2eHp5bW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MTE1MDUsImV4cCI6MjA5OTI4NzUwNX0.bZdxqNuy1ZyHMGzBieq7BzUd6IUEhfHEZxL-YTka3DQ',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const DigitalSaverApp(),
    ),
  );
}

class DigitalSaverApp extends StatelessWidget {
  const DigitalSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563eb),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563eb),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showDisclaimer = true; // FORCE SHOW IMMEDIATELY
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _controller.forward();

    // Show disclaimer after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showDisclaimer = true;
        });
      }
    });

    // FALLBACK: Show disclaimer after 3 seconds if not shown
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_showDisclaimer) {
        setState(() {
          _showDisclaimer = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _acceptAndContinue() {
    // Skip auth entirely, go directly to sign in
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AuthScreen(
        onSignedIn: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNav()),
          );
        },
      )),
    );
    return;
  }

  void _OLD_acceptAndContinue() {
    final auth = context.read<AuthProvider>();
    setState(() {
      _accepted = true;
    });
    
    // Wait for auth to finish loading before navigating
    Future.delayed(const Duration(milliseconds: 300), () async {
      // If still loading, wait for it (max 5 seconds to prevent infinite loop)
      final startTime = DateTime.now();
      if (auth.loading) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          if (elapsed > 5) {
            debugPrint('Auth loading timeout after 5s, proceeding...');
            return false;
          }
          return context.mounted && auth.loading;
        });
      }
      
      if (mounted) {
        // Navigate based on auth status
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth - this triggers session restoration
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite, color: Color(0xFF2563EB), size: 50),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Digital Saver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Health Monitoring System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Made by Cambric',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Session status indicator
                  if (auth.loading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Restoring session...', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    )
                  else if (auth.isAuthenticated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Signed in', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  const Spacer(),
                  if (_showDisclaimer && !_accepted)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Important Disclaimer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Do NOT rely on this app data to help diagnose, treat, or manage any health condition or disease.',
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This app is for wellness and educational purposes ONLY. Always consult a qualified healthcare professional for medical advice.',
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Digital Saver is NOT a certified medical device. The data shown may not be 100% accurate.',
                            style: TextStyle(color: Color(0xFFFFD54F), fontSize: 12, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _acceptAndContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'I Understand & Continue',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!_showDisclaimer)
                    Column(
                      children: [
                        const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
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

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    HeartScreen(),
    BpScreen(),
    ActivityScreen(),
    SleepScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Check auth status after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated && !auth.loading) {
      // Not authenticated, redirect to auth screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final auth = context.watch<AuthProvider>();

    // Show loading ONLY when actively loading
    if (auth.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Not authenticated AND not loading = show auth screen
    if (!auth.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Not authenticated'),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (ble.state == BleState.scanning)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563eb),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text('Scanning for Digital Saver watch...', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          if (ble.state == BleState.connecting)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text('Connecting...', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Heart'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: 'BP'),
          NavigationDestination(icon: Icon(Icons.directions_run_outlined), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.bedtime_outlined), label: 'Sleep'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
