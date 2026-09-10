import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/ble_service.dart';
import 'services/app_lock.dart';
import 'services/theme_service.dart';
import 'services/auto_update_service.dart';
import 'services/heart_rate_tracker.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vitals_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/web_landing_page.dart';
import 'screens/insights_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/memory_screen.dart';
import 'widgets/enhanced_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appLock = AppLock();
  await appLock.load();

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
        ChangeNotifierProvider.value(value: appLock),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AutoUpdateService()),
        ChangeNotifierProvider(create: (_) => HeartRateTracker()),
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
    final updateService = context.watch<AutoUpdateService>();

    return MaterialApp(
      title: 'Digital Saver',
      debugShowCheckedModeBanner: false,
      theme: themeService.getLightTheme(),
      darkTheme: themeService.getDarkTheme(),
      themeMode: themeService.themeMode,
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
  bool _manualPromptShown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.updateService.updateAvailable) {
        _showUpdateDialog();
      }
    });
  }

  @override
  void didUpdateWidget(_UpdateWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If silent install failed, show manual prompt once.
    if (!_manualPromptShown && widget.updateService.needsManualInstall) {
      _manualPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showManualInstallDialog();
      });
    }
  }

  void _showManualInstallDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.download_for_offline, color: Theme.of(ctx).primaryColor),
          const SizedBox(width: 8),
          const Text('Update Ready'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Version ${widget.updateService.latestUpdate?.version ?? ""} is available.'),
          const SizedBox(height: 10),
          const Text(
            'Automatic install is not available on your device. Tap Download to get the latest APK and install it manually.',
            style: TextStyle(fontSize: 13),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              widget.updateService.openDownloadPage();
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Download'),
          ),
        ],
      ),
    );
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
          Text('Version ${widget.updateService.latestUpdate?.version ?? "3.1.7"} is now available!'),
          const SizedBox(height: 12),
          if (widget.updateService.latestUpdate?.releaseNotes != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(widget.updateService.latestUpdate?.releaseNotes ?? '', style: Theme.of(ctx).textTheme.bodySmall),
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
    VitalsScreen(),
    ActivityScreen(),
    SleepScreen(),
    InsightsScreen(),
    AIAssistantScreen(),
    MemoryScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Vitals'),
    NavigationDestination(icon: Icon(Icons.directions_run_outlined), label: 'Activity'),
    NavigationDestination(icon: Icon(Icons.bedtime_outlined), selectedIcon: Icon(Icons.bedtime), label: 'Sleep'),
    NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
    NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Assistant'),
    NavigationDestination(icon: Icon(Icons.watch_outlined), selectedIcon: Icon(Icons.watch), label: 'Watch'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              minWidth: 78,
              backgroundColor: AppColors.surface,
              leading: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 21),
                ),
              ),
              destinations: _destinations
                  .map((destination) => NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ))
                  .toList(),
            ),
          Expanded(
            child: Stack(
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
                    color: AppColors.primaryDark,
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
                    color: AppColors.primaryDark,
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
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              backgroundColor: AppColors.surface,
              elevation: 0,
              destinations: _destinations,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
    );
  }
}
