/// Four actions the Today screen can actually perform.
///
/// The previous file was a floating emergency button with a speed dial. Nothing
/// mounted it, and it could not have worked if something had: every action was
/// an optional callback that no caller supplied, so pressing "Emergency" or
/// "Call Doctor" would have done exactly nothing. It also shipped two more
/// unused widgets whose colours and shadows were hard-coded.
///
/// The job now is smaller and real. Each action either writes through a service
/// this app already owns or opens a screen that exists:
///
///  * water is saved to [DailyLog] for today and read back before the count is
///    shown, so the number on screen is stored rather than assumed;
///  * breathing and mood open the wellness and lifestyle tools;
///  * pulling watch memory asks [BleService] for a sync and reports whether one
///    actually started. A disconnected watch is disabled rather than pretending.
///
/// There is no snackbar-only action and no success message for a write that was
/// not read back.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/screens/lifestyle_tools_screen.dart';
import '../../../features/screens/wellness_tools_screen.dart';
import '../../../core/services/ble_service.dart';
import '../../../core/services/daily_log.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';

/// The quick-action panel used on the Today screen.
class QuickActionsCard extends StatefulWidget {
  /// Create the panel.
  const QuickActionsCard({super.key});

  @override
  State<QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends State<QuickActionsCard> {
  int _glasses = 0;
  bool _loadingWater = true;
  bool _savingWater = false;
  String? _waterMessage;

  bool _memoryBusy = false;
  String? _memoryMessage;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  Future<void> _loadWater() async {
    int stored = 0;
    try {
      stored = await DailyLog.counter(DailyLog.hydrationGlasses);
    } catch (_) {
      // A store that cannot be opened means "nothing logged", not a crash and
      // not an invented count.
      stored = 0;
    }
    if (!mounted) return;
    setState(() {
      _glasses = stored;
      _loadingWater = false;
    });
  }

  Future<void> _logWater() async {
    if (_savingWater) return;
    setState(() {
      _savingWater = true;
      _waterMessage = null;
    });

    try {
      final int before = await DailyLog.counter(DailyLog.hydrationGlasses);
      await DailyLog.setCounter(DailyLog.hydrationGlasses, before + 1);
      // Read it back. The count is only reported once the store agrees.
      final int after = await DailyLog.counter(DailyLog.hydrationGlasses);
      if (!mounted) return;
      setState(() {
        _glasses = after;
        _savingWater = false;
        _waterMessage = after > before
            ? 'Saved for today.'
            : 'The glass could not be saved.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingWater = false;
        _waterMessage = 'The glass could not be saved on this device.';
      });
    }
  }

  Future<void> _pullMemory() async {
    final BleService ble = context.read<BleService>();
    if (!ble.canSendRawCommand) {
      setState(() {
        _memoryMessage = 'Connect the watch before pulling its memory.';
      });
      return;
    }
    if (ble.syncingMemory) {
      setState(() {
        _memoryMessage = 'A memory sync is already running.';
      });
      return;
    }

    setState(() {
      _memoryBusy = true;
      _memoryMessage = 'Asking the watch to start a sync…';
    });

    await ble.startMemorySync();

    if (!mounted) return;
    final bool started = ble.syncingMemory;
    setState(() {
      _memoryBusy = false;
      _memoryMessage = started
          ? 'The watch is sending its stored samples now.'
          : 'No sync started. The watch may be out of range or already '
              'syncing.';
    });
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BleService ble = context.watch<BleService>();
    final ThemeData theme = Theme.of(context);
    final bool memoryReady = ble.canSendRawCommand && !ble.syncingMemory;

    return DsGrid(
      minTileWidth: 180,
      children: <Widget>[
        _QuickAction(
          icon: Icons.water_drop_outlined,
          label: 'Log water',
          detail: _waterDetail(),
          accent: theme.colorScheme.primary,
          busy: _savingWater,
          onTap: _savingWater ? null : _logWater,
        ),
        _QuickAction(
          icon: Icons.air_rounded,
          label: 'Breathe',
          detail: 'Opens the guided breathing tools.',
          accent: theme.colorScheme.secondary,
          onTap: () => _open(const WellnessToolsScreen()),
        ),
        _QuickAction(
          icon: Icons.mood_outlined,
          label: 'Log mood',
          detail: 'Opens the mood and lifestyle tools.',
          accent: theme.colorScheme.tertiary,
          onTap: () => _open(const LifestyleToolsScreen()),
        ),
        _QuickAction(
          icon: Icons.sync_rounded,
          label: 'Pull watch memory',
          detail: _memoryDetail(memoryReady, ble),
          accent: _memoryMessage != null && ble.canSendRawCommand
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurfaceVariant,
          busy: _memoryBusy,
          onTap: memoryReady && !_memoryBusy ? _pullMemory : null,
        ),
      ],
    );
  }

  String _waterDetail() {
    if (_loadingWater) return 'Reading today’s log…';
    if (_waterMessage != null) {
      if (_glasses == 1) return '$_waterMessage 1 glass today.';
      return '$_waterMessage $_glasses glasses today.';
    }
    if (_glasses == 0) return 'No glasses logged today.';
    if (_glasses == 1) return '1 glass logged today.';
    return '$_glasses glasses logged today.';
  }

  String _memoryDetail(bool ready, BleService ble) {
    if (_memoryMessage != null) return _memoryMessage!;
    if (!ble.isConnected) return 'Connect the watch to pull its memory.';
    if (ble.syncingMemory) return 'A memory sync is already running.';
    if (!ble.canSendRawCommand) {
      return 'The watch is connected but its command channel is not ready.';
    }
    return ready
        ? 'Asks the watch to send the samples it has stored.'
        : 'Memory sync is not available right now.';
  }
}

/// One action inside the panel.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.accent,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color accent;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onTap != null;
    final Color foreground =
        enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: DsCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: enabled ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
