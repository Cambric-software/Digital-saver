/// The Watch screen: what the watch holds and what has been pulled from it.
///
/// Rebuilt. The previous version put a [Scaffold] and an [AppBar] inside the
/// shell, so the app drew two page frames and the screen carried a second back
/// button that never belonged there. It also spun forever when the local log
/// could not be read, and when the log was empty it printed a row of zeros -
/// "Samples 0, Avg HR 0, Falls 0" - which reads as measured stillness rather
/// than as no data. The pull action waited a fixed two seconds and then said
/// nothing about what had happened.
///
/// What is here now: a [DsPage] with no frame of its own, honest watch facts
/// (retention, free space, rows waiting), a pull control that is disabled with
/// a reason when no watch is connected and that reports progress and failure,
/// and an explicit empty state instead of a dashboard of zeros. A zero from
/// [MemoryAnalyzer] means "not measured" and is shown as `--`, never as a
/// reading.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/local_store.dart';
import '../services/memory_analyzer.dart';
import '../services/veyro_protocol.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';

/// Saved watch history, and how much the watch is still holding.
class MemoryScreen extends StatefulWidget {
  /// Create the screen.
  ///
  /// [loadSamples] exists so a test can hand the screen a known log without a
  /// filesystem. In the app it is null and the screen reads [LocalStore].
  const MemoryScreen({super.key, this.loadSamples});

  /// Where the stored samples come from. Null means [LocalStore.loadAll].
  final Future<List<WatchSample>> Function()? loadSamples;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  MemoryReport? _report;
  bool _loading = true;
  String? _loadError;

  bool _pulling = false;
  String? _pullError;
  String? _pullMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final Future<List<WatchSample>> Function() loader =
          widget.loadSamples ?? LocalStore.loadAll;
      final List<WatchSample> samples = await loader();
      if (!mounted) return;
      setState(() {
        _report = MemoryAnalyzer.analyze(samples);
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _load();
  }

  /// Ask the watch for its log and wait for it to say it is done.
  ///
  /// The old version waited a fixed two seconds and reloaded, so a slow watch
  /// looked like a successful sync that had copied nothing. This waits on
  /// [BleService.syncingMemory] and gives up with an explanation rather than
  /// leaving a spinner up forever.
  Future<void> _pull(BleService ble) async {
    if (!ble.isConnected) {
      setState(() {
        _pullError = 'No watch is connected. Pair Veyro first, then pull its '
            'log. Nothing is copied while the watch is away.';
        _pullMessage = null;
      });
      return;
    }

    setState(() {
      _pulling = true;
      _pullError = null;
      _pullMessage = null;
    });

    try {
      await ble.startMemorySync();
      final bool finished = await _waitForSync(ble);
      if (!mounted) return;
      if (!finished) {
        setState(() {
          _pullError = 'The watch did not confirm that the copy finished. It '
              'may still be sending rows; pull again once it is idle.';
        });
        return;
      }

      await _load();
      if (!mounted) return;
      final int rows = ble.memoryRows;
      setState(() {
        _pullMessage = rows == 0
            ? 'The pull finished. The watch had no new rows to copy.'
            : 'Copied $rows rows from the watch into this phone.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _pullError = 'The pull failed: $error');
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  Future<bool> _waitForSync(BleService ble) async {
    // Rows arrive over BLE one at a time. Forty seconds is long enough for a
    // large day and short enough that a stalled watch is reported, not hidden.
    const int checks = 160;
    for (int i = 0; i < checks; i++) {
      if (!ble.syncingMemory) return true;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return false;
    }
    return !ble.syncingMemory;
  }

  @override
  Widget build(BuildContext context) {
    final BleService ble = context.watch<BleService>();
    final ThemeData theme = Theme.of(context);
    final MemoryReport? report = _report;

    return DsPage(
      title: 'Watch memory',
      actions: <Widget>[
        IconButton(
          tooltip: 'Reload the samples saved on this phone',
          onPressed: _loading ? null : _retry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _WatchPanel(
            ble: ble,
            pulling: _pulling,
            pullError: _pullError,
            pullMessage: _pullMessage,
            onPull: () => _pull(ble),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Saved on this phone',
            subtitle: 'Pulled from the watch log, oldest first',
            child: _buildHistory(theme, report),
          ),
          if (report != null && report.samples > 0) ...<Widget>[
            const SizedBox(height: Space.xxl),
            DsSection(
              title: 'Reading the log',
              subtitle: 'What the numbers do and do not mean',
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final String note in report.notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: Space.sm),
                              child: Icon(
                                Icons.circle,
                                size: Space.xs + Space.xxs,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: Text(
                                note,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistory(ThemeData theme, MemoryReport? report) {
    if (_loading) {
      return DsCard(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: Space.lg),
                Text(
                  'Reading the samples saved on this phone…',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return DsCard(
        borderColor: theme.colorScheme.error,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'Stored samples could not be read',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              _loadError!,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (report == null || report.samples == 0) {
      return const DsCard(
        child: DsEmptyState(
          icon: Icons.watch_off_outlined,
          title: 'No samples yet',
          message:
              'Pair the watch and pull once. Until there is a stored sample, '
              'there is nothing to average - so nothing is shown as zero.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DsGrid(
          minTileWidth: 190,
          children: <Widget>[
            DsMetricTile(
              label: 'Samples',
              value: '${report.samples}',
              accent: theme.colorScheme.primary,
              icon: Icons.storage_rounded,
            ),
            DsMetricTile(
              label: 'Average heart rate',
              value: report.avgHr > 0 ? '${report.avgHr}' : '--',
              unit: report.avgHr > 0 ? 'BPM' : null,
              accent: AppColors.of(
                AppColors.heartRed,
                AppColors.darkHeart,
                context,
              ),
              icon: Icons.favorite_rounded,
            ),
            DsMetricTile(
              label: 'Resting heart rate',
              value: report.restHr > 0 ? '${report.restHr}' : '--',
              unit: report.restHr > 0 ? 'BPM' : null,
              accent: AppColors.of(
                AppColors.heartRed,
                AppColors.darkHeart,
                context,
              ),
              icon: Icons.nightlight_round,
            ),
            DsMetricTile(
              label: 'Average oxygen',
              value: report.avgSpo2 > 0 ? '${report.avgSpo2}' : '--',
              unit: report.avgSpo2 > 0 ? '%' : null,
              accent: AppColors.of(
                AppColors.oxyGreen,
                AppColors.darkOxy,
                context,
              ),
              icon: Icons.air_rounded,
            ),
            DsMetricTile(
              label: 'Fall flags',
              // Zero fall flags in a non-empty log is a real count, not a
              // missing reading, so it stays a number.
              value: '${report.falls}',
              accent: AppColors.of(
                AppColors.stepAmber,
                AppColors.darkStep,
                context,
              ),
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        if (report.avgHr == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text(
              'The log has samples but no usable heart-rate values. The sensor '
              'needs skin contact and a wrist that is not moving much.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (report.first != null)
          Text(
            'Oldest sample drops around ${_day(report.deletesAfter)}. The watch '
            'keeps ${VeyroProtocol.retainDays} days on flash and deletes older '
            'days so the chip does not fill up. This is normal, not data loss.',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  static String _day(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime date = value.toLocal();
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Connection state, the pull control, and what the watch itself reports.
class _WatchPanel extends StatelessWidget {
  const _WatchPanel({
    required this.ble,
    required this.pulling,
    required this.pullError,
    required this.pullMessage,
    required this.onPull,
  });

  final BleService ble;
  final bool pulling;
  final String? pullError;
  final String? pullMessage;
  final VoidCallback onPull;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WatchInfo info = ble.watchInfo;
    final bool infoRead = info.fw.isNotEmpty;
    final bool connected = ble.isConnected;
    final Color stateColor = connected
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurfaceVariant;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: <Widget>[
              DsStatusPill(
                label: connected ? 'Watch connected' : 'No watch connected',
                icon: connected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_disabled_rounded,
                color: stateColor,
              ),
              if (connected && infoRead)
                Text(
                  'Firmware ${info.fw}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          DsGrid(
            minTileWidth: 170,
            children: <Widget>[
              const _Fact(
                label: 'Retained by the watch',
                value: '${VeyroProtocol.retainDays}',
                unit: 'days',
              ),
              _Fact(
                label: 'Free on the watch',
                // Zero free KB has not been reported when no info frame has
                // arrived; showing "0 KB" would claim a full chip.
                value: infoRead ? '${info.freeKb}' : '--',
                unit: infoRead ? 'KB' : null,
              ),
              _Fact(
                label: 'Rows a sync will copy',
                value: infoRead ? '${info.samples}' : '--',
                unit: infoRead ? 'rows' : null,
              ),
              _Fact(
                label: 'Watch battery',
                value: infoRead && info.battery > 0 ? '${info.battery}' : '--',
                unit: infoRead && info.battery > 0 ? '%' : null,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Veyro keeps ${VeyroProtocol.retainDays} days of samples on flash. '
            'Older days are deleted by the watch so the chip does not fill up.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.md,
            runSpacing: Space.sm,
            children: <Widget>[
              FilledButton.icon(
                onPressed: connected && !pulling ? onPull : null,
                icon: pulling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(pulling ? 'Copying…' : 'Pull from Veyro'),
              ),
              if (!connected)
                Text(
                  'Pull is disabled until a watch is connected. The status '
                  'bar above shows the connection.',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          if (pulling) ...<Widget>[
            const SizedBox(height: Space.md),
            const LinearProgressIndicator(),
            const SizedBox(height: Space.sm),
            Text(
              'Copying the watch log… ${ble.memoryRows} rows received so far.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (pullMessage != null) ...<Widget>[
            const SizedBox(height: Space.md),
            Text(
              pullMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
          if (pullError != null) ...<Widget>[
            const SizedBox(height: Space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    pullError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One labelled fact about the watch, or `--` when it has not reported.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DsLabel(label, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: Space.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Flexible(
              child: Text(
                value,
                style: Type.metricSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit != null) ...<Widget>[
              const SizedBox(width: Space.xxs),
              Text(unit!, style: theme.textTheme.labelMedium),
            ],
          ],
        ),
      ],
    );
  }
}
