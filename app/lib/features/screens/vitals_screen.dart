/// Vitals and diagnostics.
///
/// Rebuilt on the shared components. The previous version put a [Row] of icon,
/// title and status in every sensor card; the status strings are long - "Active
/// (I2C 0x57)", "Armed & Active" - and the row overflowed by up to 61 pixels at
/// phone width. The four tabs are unchanged, and so is every piece of
/// information shown, but the layout now responds to the width it is given.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ble_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import 'activity_screen.dart';
import 'heart_screen.dart';
import 'sleep_screen.dart';

/// The four views this screen switches between.
enum _Tab { heart, activity, sleep, sensors }

/// Readings, motion, sleep and the hardware behind them.
class VitalsScreen extends StatefulWidget {
  /// Create the screen.
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  _Tab _tab = _Tab.heart;

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: 'Vitals & Diagnostics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TabSwitch(
            current: _tab,
            onChanged: (_Tab tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: Space.lg),
          // Keyed so switching tabs rebuilds the child from scratch. Without
          // it the previous tab's scroll position and state leak into the next.
          KeyedSubtree(
            key: ValueKey<_Tab>(_tab),
            child: switch (_tab) {
              _Tab.heart => const HeartScreen(),
              _Tab.activity => const ActivityScreen(),
              _Tab.sleep => const SleepScreen(),
              _Tab.sensors => const _SensorsSafetyView(),
            },
          ),
        ],
      ),
    );
  }
}

/// Tabs as a segmented control rather than a [TabBar].
///
/// A [TabBar] with an icon and a label per tab cannot fit four of them at
/// 390px without either scrolling - which hides options with no indication that
/// more exist - or shrinking the labels until they are unreadable.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.current, required this.onChanged});

  final _Tab current;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    return DsSegmented<_Tab>(
      value: current,
      onChanged: onChanged,
      options: const <DsSegment<_Tab>>[
        DsSegment<_Tab>(
          value: _Tab.heart,
          label: 'Heart & O₂',
          icon: Icons.favorite_rounded,
        ),
        DsSegment<_Tab>(
          value: _Tab.activity,
          label: 'Motion',
          icon: Icons.directions_walk_rounded,
        ),
        DsSegment<_Tab>(
          value: _Tab.sleep,
          label: 'Sleep & HRV',
          icon: Icons.bedtime_rounded,
        ),
        DsSegment<_Tab>(
          value: _Tab.sensors,
          label: 'Sensors',
          icon: Icons.sensors_rounded,
        ),
      ],
    );
  }
}

/// The hardware behind the readings.
class _SensorsSafetyView extends StatelessWidget {
  const _SensorsSafetyView();

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final connected = ble.isConnected;

    // "Unknown" rather than a green tick when disconnected: a battery reading
    // of zero means the gauge has not reported, not that the battery is empty.
    final battery = ble.batteryLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DsSection(
          title: 'Sensors & safety',
          subtitle: connected
              ? 'Reporting from the connected watch'
              : 'Details shown for reference. Connect a watch for live state.',
          child: Column(
            children: <Widget>[
              const _StatusAwareSensorCard(
                title: 'MAX30102 Optical PPG',
                subtitle: 'Heart rate and optical SpO2',
                icon: Icons.monitor_heart_rounded,
                activeLabel: 'Active (I2C 0x57)',
                idleLabel: 'Standby',
                details: <String>[
                  'Sampling rate: 100 Hz LED pulse',
                  'Red and infrared channels for optical reflection',
                  'Heart rate range: 30 to 240 BPM live window',
                  'SpO2 by optical ratio, R-curve estimate',
                ],
              ),
              const SizedBox(height: Space.md),
              const _StatusAwareSensorCard(
                title: 'MPU6050 6-axis IMU',
                subtitle: 'Accelerometer and gyroscope',
                icon: Icons.sensors_rounded,
                activeLabel: 'Active (I2C 0x68)',
                idleLabel: 'Standby',
                details: <String>[
                  'Step threshold: 1.2g vector magnitude crossing',
                  'Debounce filter: 240ms minimum window between steps',
                  'Fall detection: freefall below 0.4g then impact above 2.5g',
                  'Wrist wake: angular tilt detection enabled',
                ],
              ),
              const SizedBox(height: Space.md),
              DsSensorCard(
                title: 'Power and fuel gauge',
                subtitle: 'Battery voltage and hardware telemetry',
                // Reports the real level. The previous version showed this as
                // healthy at 0%, which is not what a battery reading of zero
                // means.
                status: !connected
                    ? 'Unknown'
                    : battery > 20
                        ? '$battery% charge'
                        : '$battery% - low',
                icon: Icons.battery_charging_full_rounded,
                details: const <String>[
                  'ADC monitor: GPIO34 with a 2x100kΩ divider',
                  'Operating range: 3.3V to 4.2V Li-Po battery',
                  'Charging circuit: TP4056 with thermal regulation',
                  'Estimated life: 36 to 48 hours of active logging',
                ],
              ),
              const SizedBox(height: Space.md),
              const DsSensorCard(
                title: 'Emergency fall and SOS system',
                subtitle: 'Hardware-triggered alerting',
                // Always armed: this is a capability of the watch itself, not a
                // connection state, so it does not depend on the phone.
                status: 'Armed on the watch',
                icon: Icons.emergency_rounded,
                details: <String>[
                  'Hardware SOS button: GPIO32, two-second hold',
                  'Automatic fall trigger sends an alert over BLE',
                  'Emergency contacts are set in Settings',
                  'Location beacon is sent with the alert on trigger',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A sensor card whose status reflects whether the watch is connected.
class _StatusAwareSensorCard extends StatelessWidget {
  const _StatusAwareSensorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activeLabel,
    required this.idleLabel,
    required this.details,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String activeLabel;
  final String idleLabel;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final connected = ble.isConnected;

    return DsSensorCard(
      title: title,
      subtitle: subtitle,
      status: connected ? activeLabel : idleLabel,
      icon: icon,
      details: details,
    );
  }
}