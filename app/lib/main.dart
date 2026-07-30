import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/ble_service.dart';
import 'services/cambric_auth_service_v2.dart';
import 'services/theme_service.dart';
import 'services/dynamic_theme_service.dart';
import 'services/auto_update_service.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/heart_screen.dart';
import 'screens/bp_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/web_landing_page.dart';
import 'widgets/enhanced_splash.dart';

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
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => DynamicThemeService()),
        ChangeNotifierProvider(create: (_) => AutoUpdateService()),
      ],
      child: const DigitalSaverApp(),
    ),
  );
}

class DigitalSaverApp extends StatefulWidget {
  const DigitalSaverApp({super.key});

  @override
  State<DigitalSaverApp> createState() => _DigitalSaverAppState();
}

class _DigitalSaverAppState extends State<DigitalSaverApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    if (kIsWeb) return;
    await context.read<AutoUpdateService>().checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final dynamicTheme = context.watch<DynamicThemeService>();
    final updateService = context.watch<AutoUpdateService>();

    // Use dynamic theme if enabled
    final useDynamicTheme = dynamicTheme.autoMode;

    return MaterialApp(
      title: 'Digital Saver',
      debugShowCheckedModeBanner: false,
      theme: useDynamicTheme ? dynamicTheme.getThemeData() : themeService.getLightTheme(),
      darkTheme: useDynamicTheme ? dynamicTheme.getThemeData() : themeService.getDarkTheme(),
      themeMode: useDynamicTheme ? ThemeMode.system : themeService.themeMode,
      home: kIsWeb
          ? const WebLandingPage()
          : _UpdateWrapper(
              updateService: updateService,
              child: const EnhancedSplashScreen(),
            ),
    );
  }
}

class _UpdateWrapper extends StatefulWidget {
  final Widget child;
  final AutoUpdateService updateService;

  const _UpdateWrapper({required this.child, required this.updateService});

  @override
  State<_UpdateWrapper> createState() => _UpdateWrapperState();
}

class _UpdateWrapperState extends State<_UpdateWrapper> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.updateService.updateAvailable) {
        _showUpdateDialog();
      }
    });
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.system_update_alt, color: Theme.of(ctx).primaryColor),
          const SizedBox(width: 8),
          const Text('Update Available!'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Version ${widget.updateService.latestUpdate?.version ?? "3.0.7"} is now available!'),
          const SizedBox(height: 12),
          if (widget.updateService.latestUpdate?.releaseNotes != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(widget.updateService.latestUpdate!.releaseNotes, style: Theme.of(ctx).textTheme.bodySmall),
            ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(widget.updateService.latestUpdate?.downloadUrl ?? AppVersion.downloadUrl);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
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

  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _authChecked = false;
  }

  void _checkAuth() {
    if (_authChecked) return;  // Prevent multiple navigation attempts
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated && !auth.loading) {
      _authChecked = true;  // Mark as checked before navigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_authChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
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

    // Not authenticated AND not loading = redirect to auth screen
    if (!auth.isAuthenticated) {
      if (!_authChecked) {
        _authChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
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
        });
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      _authChecked = true;  // Reset flag when authenticated
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
