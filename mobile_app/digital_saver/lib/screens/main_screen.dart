import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/services/ble_advanced_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/screens/dashboard_screen.dart';
import 'package:digital_saver/screens/heart_screen.dart';
import 'package:digital_saver/screens/blood_pressure_screen.dart';
import 'package:digital_saver/screens/activity_screen.dart';
import 'package:digital_saver/screens/sleep_screen.dart';
import 'package:digital_saver/screens/settings_screen.dart';
import 'package:digital_saver/widgets/connection_status_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    HeartScreen(),
    BloodPressureScreen(),
    ActivityScreen(),
    SleepScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bleService = context.watch<BleAdvancedService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Connection Status Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: ConnectionStatusWidget(
                isConnected: bleService.isConnected,
                batteryLevel: bleService.batteryLevel,
                lastSync: bleService.lastSync,
                onConnect: () => _showConnectionSheet(context),
              ),
            ),
            
            // Main Content
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, t.navDashboard),
                _buildNavItem(1, Icons.favorite_rounded, t.navHeart),
                _buildNavItem(2, Icons.water_drop_rounded, t.navBP),
                _buildNavItem(3, Icons.directions_run_rounded, t.navActivity),
                _buildNavItem(4, Icons.bedtime_rounded, t.navSleep),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected 
        ? AppTheme.primaryColor 
        : (isDark ? Colors.grey[500] : Colors.grey[400]);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionSheet(BuildContext context) {
    final bleService = context.read<BleAdvancedService>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.watch,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              bleService.isConnected ? 'Watch Connected' : 'Connect Watch',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (bleService.isConnected) ...[
              _buildInfoRow('Device', bleService.connectedDevice?.platformName ?? 'Unknown'),
              _buildInfoRow('Battery', '${bleService.batteryLevel}%'),
              _buildInfoRow('Signal', '${bleService.signalStrength}%'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    bleService.disconnect();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              if (bleService.isScanning)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: () => bleService.startScan(),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan for Devices'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(value, style: AppTheme.titleMedium),
        ],
      ),
    );
  }
}
