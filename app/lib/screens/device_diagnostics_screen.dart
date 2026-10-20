/// Device diagnostics, rebuilt to report only what the BLE service knows.
///
/// The old screen was forty numbered cards of hardware controls that did not
/// exist. It offered a vibration pattern creator and a "test on watch" button
/// with no haptic command behind it; a battery estimator whose runtime came
/// from multipliers typed into the source; a smart sleep-window alarm; an SOS
/// beacon over "Simulated Coordinates" with no GPS; an encrypted backup whose
/// button slept for 700 ms and then reported 342 records, and a "Verify Backup"
/// that printed "checksum matches" without computing a checksum. It named an
/// "Active Boot Slot" and a "Recovery Slot", reported a
/// "Wear-Leveling Health Score: 99.4%", streamed a "Raw PPG" value generated
/// from the millisecond hand of the clock, and offered twilight dimming,
/// tilt-wake, ultra-low-power mode, water ejection and 100-pace stride
/// calibration - none of which the watch can be told to do.
///
/// What is here now: the connection state, the firmware, the sample count, the
/// free space and the battery the watch actually reports, the rows a sync is
/// copying, and one control that exists - a watch face index. The last sync
/// timestamp is stated as unrecorded, because the app keeps samples but no sync
/// time. A card lists what the app can and cannot change on the watch so the
/// absence of those switches is not mistaken for a missing feature.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/ds_widgets.dart';

/// The watch as the app can actually see it.
class DeviceDiagnosticsScreen extends StatefulWidget {
  /// Create the screen.
  const DeviceDiagnosticsScreen({super.key});

  @override
  State<DeviceDiagnosticsScreen> createState() =>
      _DeviceDiagnosticsScreenState();
}

class _DeviceDiagnosticsScreenState extends State<DeviceDiagnosticsScreen> {
  /// The watch accepts face indices 0 to 7.
  static const int _faceCount = 8;

  int _face = StorageService.defaultWatchFace;
  bool _sendingFace = false;

  @override
  void initState() {
    super.initState();
    _loadFace();
  }

  Future<void> _loadFace() async {
    final int stored = await StorageService.watchFace();
    if (!mounted) return;
    setState(() {
      _face = stored >= 0 && stored < _faceCount
          ? stored
          : StorageService.defaultWatchFace;
    });
  }

  Future<void> _sendFace(BleService ble) async {
    if (!ble.isConnected || _sendingFace) return;
    setState(() => _sendingFace = true);
    try {
      await StorageService.setWatchFace(_face);
      await ble.setWatchFace(_face);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face ${_face + 1} saved and sent to the watch.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The watch did not accept the face change: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingFace = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BleService ble = context.watch<BleService>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Device diagnostics')),
      body: DsPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _connectionSection(context, ble: ble, theme: theme),
            const SizedBox(height: Space.xl),
            _watchSection(context, ble: ble, theme: theme),
            const SizedBox(height: Space.xl),
            _syncSection(context, ble: ble, theme: theme),
            const SizedBox(height: Space.xl),
            _faceSection(context, ble: ble, theme: theme),
            const SizedBox(height: Space.xl),
            _capabilitiesSection(context, theme: theme),
            const SizedBox(height: Space.xxl),
            const DsSection(
              title: 'About these readings',
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Everything above comes from the watch\'s info '
                      'characteristic or from the live notification stream. A '
                      'dash means the app has no reading, not zero.',
                    ),
                    SizedBox(height: Space.sm),
                    Text(
                      'Samples are stored on this phone. Nothing here is '
                      'uploaded, and this screen does not change a sensor '
                      'setting because the watch exposes no such setting.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionSection(
    BuildContext context, {
    required BleService ble,
    required ThemeData theme,
  }) {
    final ({String label, IconData icon, Color color}) status =
        _connectionStatus(theme, ble);
    final bool connected = ble.isConnected;

    return DsSection(
      title: 'Connection',
      subtitle: 'The state reported by the BLE service.',
      child: DsCard(
        borderColor: status.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(status.icon, size: 18, color: status.color),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    connected
                        ? 'Veyro watch'
                        : 'No watch is connected',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                DsStatusPill(
                  label: status.label,
                  color: status.color,
                  icon: status.icon,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              connected
                  ? (ble.demoMode
                      ? 'Demo mode is on. The numbers below are generated by '
                          'the app, not read from hardware.'
                      : ble.watchInfo.paired
                          ? 'Paired with the watch. The app can read its '
                              'details and send the commands listed below.'
                          : 'Connected but not paired. Pairing needs the '
                              'six-digit PIN shown on the watch face.')
                  : 'Connection details, firmware and storage appear only '
                      'while a watch is connected and paired.',
              style: theme.textTheme.bodySmall,
            ),
            if (ble.errorMessage.isNotEmpty) ...<Widget>[
              const SizedBox(height: Space.sm),
              Text(
                ble.errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _watchSection(
    BuildContext context, {
    required BleService ble,
    required ThemeData theme,
  }) {
    final WatchInfo info = ble.watchInfo;
    // The firmware string is the only field that proves the info
    // characteristic was read. A connected watch with an empty firmware string
    // has not answered yet, so zeros from the default WatchInfo are not shown
    // as real storage values.
    final bool infoRead = ble.isConnected && info.fw.isNotEmpty;

    return DsSection(
      title: 'Watch',
      subtitle: 'Reported by the watch itself. A dash means no reading.',
      child: DsGrid(
        minTileWidth: 180,
        children: <Widget>[
          DsMetricTile(
            label: 'Firmware',
            value: infoRead ? info.fw : '--',
            accent: theme.colorScheme.primary,
            icon: Icons.memory_outlined,
          ),
          DsMetricTile(
            label: 'Samples on watch',
            value: infoRead ? '${info.samples}' : '--',
            unit: infoRead ? 'rows' : null,
            accent: theme.colorScheme.secondary,
            icon: Icons.dataset_outlined,
          ),
          DsMetricTile(
            label: 'Free space',
            value: infoRead ? '${info.freeKb}' : '--',
            unit: infoRead ? 'KB' : null,
            accent: theme.colorScheme.tertiary,
            icon: Icons.sd_storage_outlined,
          ),
          DsMetricTile(
            label: 'Battery',
            value: infoRead && info.battery > 0 ? '${info.battery}' : '--',
            unit: infoRead && info.battery > 0 ? '%' : null,
            accent: theme.colorScheme.primary,
            icon: Icons.battery_std_outlined,
          ),
        ],
      ),
    );
  }

  Widget _syncSection(
    BuildContext context, {
    required BleService ble,
    required ThemeData theme,
  }) {
    return DsSection(
      title: 'Memory sync',
      subtitle: 'What a sync is doing, and what the app does not keep.',
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _FactRow(
              label: 'Sync state',
              value: ble.syncingMemory ? 'Copying rows' : 'Idle',
            ),
            const SizedBox(height: Space.sm),
            _FactRow(
              label: 'Rows received this session',
              value: '${ble.memoryRows}',
            ),
            const SizedBox(height: Space.sm),
            const _FactRow(
              label: 'Last sync',
              value: 'Not recorded',
            ),
            const SizedBox(height: Space.md),
            Text(
              'The app copies each row the watch sends and stores it by day. '
              'It does not record when a sync ran, so this line says so rather '
              'than showing a time it never saved. A sync starts after pairing '
              'and from the Memory screen.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _faceSection(
    BuildContext context, {
    required BleService ble,
    required ThemeData theme,
  }) {
    return DsSection(
      title: 'Watch face',
      subtitle: 'The one display setting the command characteristic accepts.',
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DsLabel('Face'),
            const SizedBox(height: Space.xs),
            DsSegmented<int>(
              value: _face,
              options: <DsSegment<int>>[
                for (int i = 0; i < _faceCount; i++)
                  DsSegment<int>(value: i, label: '${i + 1}'),
              ],
              onChanged: (int value) => setState(() => _face = value),
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: ble.isConnected && !_sendingFace
                  ? () => _sendFace(ble)
                  : null,
              icon: const Icon(Icons.watch_outlined, size: 18),
              label: Text(
                _sendingFace ? 'Sending…' : 'Send face ${_face + 1}',
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              ble.isConnected
                  ? 'Sending writes the face index to the watch command '
                      'characteristic. The watch applies it when it processes '
                      'the command.'
                  : 'Connect and pair a watch to send a face. The choice is '
                      'kept on this phone either way.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _capabilitiesSection(
    BuildContext context, {
    required ThemeData theme,
  }) {
    final Color canColor = theme.colorScheme.secondary;
    final Color cannotColor = theme.colorScheme.onSurfaceVariant;

    return DsSection(
      title: 'What this app can and cannot do',
      subtitle: 'The watch command set is small. This is all of it.',
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _CapabilityBlock(
              title: 'This app can',
              icon: Icons.check_circle_outline,
              color: canColor,
              items: const <String>[
                'Scan for a watch, connect, and pair with the six-digit PIN '
                    'shown on its face.',
                'Read firmware, sample count, free space and battery from the '
                    'info characteristic.',
                'Start a memory sync and store the rows the watch sends.',
                'Set one of eight watch face indices.',
                'Write a raw packet to the command characteristic; pairing, '
                    'time, face and sync are the only uses the app makes of '
                    'that path.',
              ],
            ),
            const SizedBox(height: Space.lg),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: Space.lg),
            _CapabilityBlock(
              title: 'This app cannot',
              icon: Icons.remove_circle_outline,
              color: cannotColor,
              items: const <String>[
                'Set an alarm, a silent alarm or a smart wake window.',
                'Start a vibration, a haptic pattern or a find-my-watch page.',
                'Eject water from the speaker.',
                'Send an SOS or report a GPS position.',
                'Update firmware, choose a boot slot or read flash wear.',
                'Change sensor polling, start a raw sensor stream, or read a '
                    'raw PPG value.',
                'Change brightness, tilt-wake or an ultra-low-power mode.',
                'Sync a weather forecast.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  static ({String label, IconData icon, Color color}) _connectionStatus(
    ThemeData theme,
    BleService ble,
  ) {
    return switch (ble.state) {
      BleState.connected => (
          label: ble.demoMode ? 'Demo' : 'Connected',
          icon: Icons.check_circle_outline,
          color: theme.colorScheme.secondary,
        ),
      BleState.scanning => (
          label: 'Scanning',
          icon: Icons.search_rounded,
          color: theme.colorScheme.primary,
        ),
      BleState.connecting => (
          label: 'Connecting',
          icon: Icons.bluetooth_searching_rounded,
          color: theme.colorScheme.tertiary,
        ),
      BleState.error => (
          label: 'Error',
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
        ),
      BleState.disconnected => (
          label: 'Not connected',
          icon: Icons.bluetooth_disabled_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
    };
  }
}

/// A label and value on one line.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: Space.md),
        Text(
          value,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleSmall,
        ),
      ],
    );
  }
}

/// A titled bullet list of one capability group.
class _CapabilityBlock extends StatelessWidget {
  const _CapabilityBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: Space.sm),
            Text(title, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: Space.sm),
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.circle, size: 6, color: color),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(item, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
