import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digital_saver/theme/app_theme.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final int batteryLevel;
  final DateTime? lastSync;
  final VoidCallback? onConnect;

  const ConnectionStatusWidget({
    super.key,
    required this.isConnected,
    this.batteryLevel = 100,
    this.lastSync,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          // Connection Status
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getConnectionColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getConnectionIcon(),
              color: _getConnectionColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Connection Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Digital Saver Watch' : 'Watch Disconnected',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected 
                      ? _getSyncText()
                      : 'Tap to connect',
                  style: AppTheme.bodySmall.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Battery Indicator (when connected)
          if (isConnected) ...[
            _buildBatteryIndicator(),
            const SizedBox(width: 12),
          ],
          
          // Connect/Disconnect Button
          if (isConnected)
            GestureDetector(
              onTap: onConnect,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onConnect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connect',
                  style: AppTheme.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    Color batteryColor;
    IconData batteryIcon;
    
    if (batteryLevel > 80) {
      batteryColor = AppTheme.healthyGreen;
      batteryIcon = Icons.battery_full_rounded;
    } else if (batteryLevel > 50) {
      batteryColor = AppTheme.healthyGreen;
      batteryIcon = Icons.battery_5_bar_rounded;
    } else if (batteryLevel > 20) {
      batteryColor = AppTheme.warningOrange;
      batteryIcon = Icons.battery_3_bar_rounded;
    } else {
      batteryColor = AppTheme.dangerRed;
      batteryIcon = Icons.battery_1_bar_rounded;
    }
    
    return Row(
      children: [
        Icon(batteryIcon, color: batteryColor, size: 20),
        const SizedBox(width: 4),
        Text(
          '$batteryLevel%',
          style: AppTheme.labelSmall.copyWith(
            color: batteryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getConnectionColor() {
    return isConnected ? AppTheme.healthyGreen : Colors.grey;
  }

  IconData _getConnectionIcon() {
    return isConnected ? Icons.watch_rounded : Icons.watch_off_rounded;
  }

  String _getSyncText() {
    if (lastSync == null) return 'Connected';
    
    final now = DateTime.now();
    final diff = now.difference(lastSync!);
    
    if (diff.inMinutes < 1) return 'Synced just now';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
    
    return 'Synced ${DateFormat.MMMd().format(lastSync!)}';
  }
}
