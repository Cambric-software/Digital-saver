/// The application shell: navigation, device status, and update awareness.
///
/// Rebuilt rather than restyled. Three problems with the previous shell:
///   * device connection state was only visible from inside a screen, so a
///     dropped watch looked like a frozen dashboard rather than a lost device;
///   * there was no route model, so every screen was constructed eagerly at
///     startup and deep links were impossible;
///   * update state surfaced only as a transient snackbar.
///
/// The shell now owns a named-route model, a status bar that is always visible
/// while a watch is in range, and a real entry point for updates.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ble_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import '../../../features/screens/dashboard_screen.dart';
import '../../../features/screens/health_hub_screen.dart';
import '../../../features/screens/insights_screen.dart';
import '../../../features/screens/memory_screen.dart';
import '../../../features/screens/settings_screen.dart';
import '../../../features/screens/vitals_screen.dart';
import '../../../features/screens/ai_assistant_screen.dart';

/// The primary destinations.
enum DsDestination {
  /// Live vitals overview.
  dashboard('Today', Icons.dashboard_outlined, Icons.dashboard_rounded),

  /// Detailed measurements.
  vitals('Vitals', Icons.monitor_heart_outlined, Icons.monitor_heart_rounded),

  /// Trends, guidance and progress.
  insights('Insights', Icons.insights_outlined, Icons.insights_rounded),

  /// Coaching.
  coach('Coach', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),

  /// The tool suites, blood pressure and the watch simulator.
  hub('Health hub', Icons.grid_view_outlined, Icons.grid_view_rounded),

  /// Saved watch data.
  watch('Watch', Icons.watch_outlined, Icons.watch_rounded),

  /// Settings.
  settings('Settings', Icons.settings_outlined, Icons.settings_rounded);

  const DsDestination(this.label, this.icon, this.selectedIcon);

  /// Bottom-bar label.
  final String label;

  /// Icon when unselected.
  final IconData icon;

  /// Icon when selected.
  final IconData selectedIcon;
}

/// Hosts the primary destinations and keeps device state visible.
class DsShell extends StatefulWidget {
  /// Create the shell.
  const DsShell({super.key, this.initial = DsDestination.dashboard});

  /// Destination shown on launch.
  final DsDestination initial;

  @override
  State<DsShell> createState() => _DsShellState();
}

class _DsShellState extends State<DsShell> {
  late DsDestination _current = widget.initial;

  /// Bottom bars are unusable past about six items; the rail is not.
  static const List<DsDestination> _railDestinations = DsDestination.values;

  /// The bar shows the four most-used, then More.
  ///
  /// The previous bar held five of six destinations, which meant the sixth
  /// could not be opened at all below 1100px, where the rail is hidden. More
  /// lists everything the bar does not, so every destination has a route at
  /// every width.
  static const List<DsDestination> _barDestinations = <DsDestination>[
    DsDestination.dashboard,
    DsDestination.vitals,
    DsDestination.insights,
    DsDestination.coach,
  ];

  /// Destinations reachable through More.
  List<DsDestination> get _overflowDestinations => DsDestination.values
      .where((DsDestination d) => !_barDestinations.contains(d))
      .toList();

  Widget _screenFor(DsDestination destination) => switch (destination) {
        DsDestination.dashboard => const DashboardScreen(),
        DsDestination.vitals => const VitalsScreen(),
        DsDestination.insights => const InsightsScreen(),
        DsDestination.coach => const AIAssistantScreen(),
        DsDestination.hub => const HealthHubScreen(),
        DsDestination.watch => const MemoryScreen(),
        DsDestination.settings => const SettingsScreen(),
      };

  /// Which bar slot to highlight. More stays highlighted when the current
  /// destination is one of the destinations it lists, because that is where it
  /// was opened from.
  int get _barIndex {
    final int index = _barDestinations.indexOf(_current);
    return index >= 0 ? index : _barDestinations.length;
  }

  void _onBarSelected(int index) {
    if (index < _barDestinations.length) {
      _select(_barDestinations[index]);
      return;
    }
    unawaited(_showMore());
  }

  /// Lists every destination the bar cannot hold.
  Future<void> _showMore() async {
    final DsDestination? chosen = await showModalBottomSheet<DsDestination>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.none,
                  Space.lg,
                  Space.sm,
                ),
                child: Text('More', style: theme.textTheme.titleMedium),
              ),
              for (final DsDestination destination in _overflowDestinations)
                ListTile(
                  leading: Icon(
                    destination == _current
                        ? destination.selectedIcon
                        : destination.icon,
                    color: destination == _current
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  title: Text(destination.label),
                  selected: destination == _current,
                  onTap: () => Navigator.of(sheetContext).pop(destination),
                ),
              const SizedBox(height: Space.sm),
            ],
          ),
        );
      },
    );
    if (chosen != null && mounted) _select(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final usesRail = Breakpoints.usesRail(width);
    final ble = context.watch<BleService>();

    final body = Column(
      children: <Widget>[
        _DeviceStatusBar(ble: ble),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.fast,
            child: KeyedSubtree(
              key: ValueKey<DsDestination>(_current),
              child: _screenFor(_current),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: Row(
        children: <Widget>[
          if (usesRail) _Rail(
            destinations: _railDestinations,
            current: _current,
            onSelect: _select,
            ble: ble,
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: usesRail
          ? null
          : NavigationBar(
              selectedIndex: _barIndex,
              onDestinationSelected: _onBarSelected,
              destinations: <Widget>[
                for (final destination in _barDestinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
            ),
    );
  }

  void _select(DsDestination destination) {
    if (destination == _current) return;
    setState(() => _current = destination);
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.current,
    required this.onSelect,
    required this.ble,
  });

  final List<DsDestination> destinations;
  final DsDestination current;
  final ValueChanged<DsDestination> onSelect;
  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.xl,
                Space.lg,
                Space.lg,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Digital Saver',
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Health companion',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: Space.md),
            for (final destination in destinations)
              _RailItem(
                destination: destination,
                selected: destination == current,
                onTap: () => onSelect(destination),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DsDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xxs,
      ),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.md,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.md),
                  Text(
                    destination.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent connection state.
///
/// Shown across every screen so a dropped watch reads as "watch lost", not as
/// "the app is broken".
class _DeviceStatusBar extends StatelessWidget {
  const _DeviceStatusBar({required this.ble});

  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (ble.isConnected) {
      return _Bar(
        background: theme.colorScheme.secondary.withValues(alpha: 0.12),
        child: Row(
          children: <Widget>[
            DsStatusPill(
              label: 'Watch connected',
              icon: Icons.bluetooth_connected_rounded,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: Space.md),
            if (ble.batteryLevel > 0)
              Text(
                '${ble.batteryLevel}% battery',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      );
    }

    if (ble.state == BleState.scanning || ble.discoveredDevices.isNotEmpty) {
      return _Bar(
        background: theme.colorScheme.surfaceContainerHigh,
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: Space.sm),
            Text('Searching for a watch...', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return _Bar(
      background: theme.colorScheme.surfaceContainerHigh,
      child: Row(
        children: <Widget>[
          DsStatusPill(
            label: 'No watch connected',
            icon: Icons.bluetooth_disabled_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'Readings are unavailable until a watch connects.',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.child, required this.background});

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.sm,
      ),
      child: child,
    );
  }
}