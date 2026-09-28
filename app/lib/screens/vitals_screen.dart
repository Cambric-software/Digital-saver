import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import 'heart_screen.dart';
import 'activity_screen.dart';
import 'sleep_screen.dart';

class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vitals & Diagnostics'),
          elevation: 0,
          backgroundColor: AppColors.surface,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.favorite_outline), text: 'Heart & O2'),
              Tab(icon: Icon(Icons.directions_walk_outlined), text: 'Motion & Steps'),
              Tab(icon: Icon(Icons.bedtime_outlined), text: 'Sleep & HRV'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Sensors & Safety'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HeartScreen(),
            ActivityScreen(),
            SleepScreen(),
            _SensorsSafetyView(),
          ],
        ),
      ),
    );
  }
}

class _SensorsSafetyView extends StatelessWidget {
  const _SensorsSafetyView();

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSensorCard(
          context,
          title: 'MAX30102 Optical PPG',
          subtitle: 'Heart Rate & Optical SpO2 Photoplethysmography',
          status: ble.isConnected ? 'Active (I2C 0x57)' : 'Standby / Disconnected',
          statusColor: ble.isConnected ? Colors.green : Colors.orange,
          icon: Icons.monitor_heart,
          details: [
            'Sampling Rate: 100 Hz LED pulse',
            'Red & IR Channels: Dual LED optical reflection',
            'HR Range: 30 - 240 BPM live window',
            'SpO2: Optical ratio calculation (R-curve estimate)',
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          context,
          title: 'MPU6050 6-Axis IMU',
          subtitle: 'Accelerometer & Gyroscope Motion Tracking',
          status: ble.isConnected ? 'Active (I2C 0x68)' : 'Standby / Disconnected',
          statusColor: ble.isConnected ? Colors.green : Colors.orange,
          icon: Icons.sensors,
          details: [
            'Step Threshold: 1.2g vector magnitude crossing',
            'Debounce Filter: 240ms minimum inter-step window',
            'Fall Detection: <0.4g freefall followed by >2.5g impact',
            'Wrist Wake: Angular tilt detection enabled',
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          context,
          title: 'Power & Fuel Gauge',
          subtitle: 'Battery Voltage & Hardware Telemetry',
          status: ble.isConnected ? '${ble.batteryLevel}% Charge' : 'Unknown',
          statusColor: ble.batteryLevel > 20 ? Colors.green : Colors.red,
          icon: Icons.battery_charging_full,
          details: [
            'ADC Monitor: GPIO34 with 2x100kΩ divider',
            'Operating Range: 3.3V - 4.2V Li-Po battery',
            'Charging Circuit: TP4056 with thermal regulation',
            'Estimated Life: 36-48 hours active sensor logging',
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          context,
          title: 'Emergency Fall & SOS System',
          subtitle: 'Hardware Triggered Telemetry',
          status: 'Armed & Active',
          statusColor: Colors.blue,
          icon: Icons.emergency_outlined,
          details: [
            'Hardware SOS Button: GPIO32 (2-second hold)',
            'Automatic Fall Trigger: Spike alert sent to phone via BLE',
            'Emergency Contacts: Configured in Settings',
            'Location Beacon: Dispatched with alert upon trigger',
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required IconData icon,
    required List<String> details,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(d, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
