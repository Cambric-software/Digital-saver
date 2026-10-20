/// Guidance derived from the app's own thresholds.
///
/// The previous version was a carousel of eight fixed "daily" tips:
///
/// * the tip of the day was `DateTime.now().hour % 8`, so it was the tip of the
///   hour, and the same eight strings were the entire content of the screen;
/// * the strings made health claims presented as fact - "Drink at least 8
///   glasses of water daily", "Just 2 minutes of stair climbing can improve
///   heart health", "Normal levels are 95-100%" - with no source and no regard
///   for who was reading them;
/// * the eight "actions" below each tip ("Check your heart rate now", "Set a
///   bedtime reminder", "Track your meals") were plain [Text], not buttons.
///   Nothing happened when they were read, and nothing could happen;
/// * "Swipe to see more tips" appeared above a screen with no swipe gesture;
/// * fixed colours and a shadow meant it ignored the theme entirely.
///
/// What replaces it is generated from an actual stored or live reading using
/// [health_interpretation.dart]: the band the number falls in, what that band
/// means, and the next step the app suggests. The band table uses the same
/// constants as every other screen, so the wording here cannot drift from the
/// numbers there. No food, water, exercise or treatment targets are given,
/// because the app has no basis for personalising them.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/local_store.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../utils/health_interpretation.dart';
import '../widgets/ds_widgets.dart';

/// What the app's bands mean for the readings it has.
class HealthTipsScreen extends StatefulWidget {
  /// Create the guidance view.
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  List<WatchSample> _samples = const <WatchSample>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final List<WatchSample> samples = await LocalStore.loadAll();
      if (!mounted) return;
      setState(() {
        _samples = samples;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final BleService ble = context.watch<BleService>();
    final WatchSample? stored = _latestStored(_samples);

    // A disconnected watch reports zero, and a zero is not a reading. Prefer
    // the live value only when it exists, then fall back to what is stored.
    final int liveHr = ble.isConnected ? ble.heartRate.bpm : 0;
    final int liveOxygen = ble.isConnected ? ble.oxygen.spO2 : 0;
    final int liveHrv = ble.isConnected ? ble.heartRate.hrv : 0;
    final bool hasLive = liveHr > 0 || liveOxygen > 0 || liveHrv > 0;

    final int heartRate = liveHr > 0 ? liveHr : (stored?.hr ?? 0);
    final int oxygen = liveOxygen > 0 ? liveOxygen : (stored?.spo2 ?? 0);
    final int hrv = liveHrv > 0 ? liveHrv : (stored?.hrv ?? 0);
    final bool hasReading = heartRate > 0 || oxygen > 0 || hrv > 0;

    final String source = hasLive
        ? ble.demoMode
            ? 'From a simulated demo reading. It is not a measurement.'
            : 'From the live reading on the connected watch.'
        : stored == null
            ? 'No reading has been stored yet.'
            : 'From the reading stored on ${_dayLabel(stored.at)} at '
                '${_clockLabel(stored.at)}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DsSection(
          title: 'Reading guidance',
          subtitle: 'Based on the ranges this app uses. Screening cues, not a '
              'diagnosis.',
          trailing: IconButton(
            tooltip: 'Reload stored history',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          child: _loading
              ? const _LoadingCard(label: 'Reading stored history…')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_error != null) ...<Widget>[
                      _UnreadableHistory(error: _error!),
                      const SizedBox(height: Space.lg),
                    ],
                    if (ble.demoMode) ...<Widget>[
                      const _DemoNotice(),
                      const SizedBox(height: Space.lg),
                    ],
                    if (!hasReading)
                      const _NoReadingYet()
                    else ...<Widget>[
                      if (heartRate > 0)
                        _ReadingCard(
                          label: 'Heart rate',
                          metric: 'heart rate',
                          value: '$heartRate',
                          unit: 'BPM',
                          status: interpretHeartRate(heartRate),
                          icon: Icons.favorite_rounded,
                          accent: AppColors.of(
                            AppColors.heartRed,
                            AppColors.darkHeart,
                            context,
                          ),
                          source: source,
                        ),
                      if (heartRate > 0 && oxygen > 0)
                        const SizedBox(height: Space.lg),
                      if (oxygen > 0)
                        _ReadingCard(
                          label: 'Oxygen saturation',
                          metric: 'oxygen saturation',
                          value: '$oxygen',
                          unit: '%',
                          status: interpretOxygen(oxygen),
                          icon: Icons.air_rounded,
                          accent: AppColors.of(
                            AppColors.oxyGreen,
                            AppColors.darkOxy,
                            context,
                          ),
                          source: source,
                        ),
                      if (hrv > 0) ...<Widget>[
                        if (heartRate > 0 || oxygen > 0)
                          const SizedBox(height: Space.lg),
                        _HrvCard(value: hrv, source: source),
                      ],
                    ],
                  ],
                ),
        ),
        const SizedBox(height: Space.xxl),
        DsSection(
          title: 'What the bands mean',
          subtitle: 'The same boundaries every other screen uses',
          child: DsGrid(
            minTileWidth: 320,
            children: <Widget>[
              _BandCard(
                title: 'Heart rate',
                metric: 'heart rate',
                accent: AppColors.of(
                  AppColors.heartRed,
                  AppColors.darkHeart,
                  context,
                ),
                bands: const <_Band>[
                  _Band(
                    status: HealthStatus.normal,
                    range: '50–100 BPM',
                  ),
                  _Band(
                    status: HealthStatus.elevated,
                    range: '101–120 BPM',
                  ),
                  _Band(
                    status: HealthStatus.high,
                    range: '40–49 or 121–180 BPM',
                  ),
                  _Band(
                    status: HealthStatus.critical,
                    range: 'Below 40 or above 180 BPM',
                  ),
                ],
              ),
              _BandCard(
                title: 'Oxygen saturation',
                metric: 'oxygen saturation',
                accent: AppColors.of(
                  AppColors.oxyGreen,
                  AppColors.darkOxy,
                  context,
                ),
                bands: const <_Band>[
                  _Band(
                    status: HealthStatus.normal,
                    range: '96–100%',
                  ),
                  _Band(
                    status: HealthStatus.elevated,
                    range: '94–95%',
                  ),
                  _Band(
                    status: HealthStatus.high,
                    range: '90–93%',
                  ),
                  _Band(
                    status: HealthStatus.critical,
                    range: 'Below 90%',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xxl),
        const DsSection(
          title: 'Getting a usable reading',
          subtitle: 'What the hardware needs, not what to do about a number',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Bullet(
                  'The optical sensor needs skin contact. A loose strap records '
                  'nothing, which this app shows as "--" rather than zero.',
                ),
                _Bullet(
                  'Movement during a reading adds noise to heart rate and '
                  'oxygen. Sit still for the duration of a measurement.',
                ),
                _Bullet(
                  'Oxygen saturation from this sensor is a trend estimate, not '
                  'a hospital measurement.',
                ),
                _Bullet(
                  'One reading is a moment, not a pattern. The trends pages use '
                  'the samples the watch stores, one a minute while it sees a '
                  'pulse or steps.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xxl),
        const DsSection(
          title: 'What this page does not do',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Bullet(
                  'It does not diagnose anything. A band describes how a number '
                  'compares with the ranges this app treats as usual.',
                ),
                _Bullet(
                  'It does not tell you to start or stop any treatment, food, '
                  'drink or exercise.',
                ),
                _Bullet(
                  'If a reading stays outside the usual range, or you feel '
                  'unwell, the next step is a clinician or emergency services.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The newest stored sample that carried any interpretable value.
WatchSample? _latestStored(List<WatchSample> samples) {
  for (var i = samples.length - 1; i >= 0; i--) {
    final WatchSample sample = samples[i];
    if (sample.hr > 0 || sample.spo2 > 0 || sample.hrv > 0) return sample;
  }
  return null;
}

const List<String> _monthNames = <String>[
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

String _dayLabel(DateTime time) =>
    '${time.day} ${_monthNames[time.month - 1]}';

String _clockLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// The app's suggestion for a band, or a description when nothing is suggested.
String _bandMeaning(HealthStatus status, String metric) =>
    guidanceFor(status, metric) ??
    'Inside the range this app treats as usual for $metric. That describes '
        'the number, not a diagnosis.';

/// One measured value, its band and the suggested next step.
class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.label,
    required this.metric,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.accent,
    required this.source,
  });

  final String label;
  final String metric;
  final String value;
  final String unit;
  final HealthStatus status;
  final IconData icon;
  final Color accent;
  final String source;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: Space.sm),
              Expanded(
                child: DsLabel(
                  label,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              DsStatusPill(
                label: status.label,
                color: healthStatusColor(status, context),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: Type.metricSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: Space.xxs),
              Text(unit, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            _bandMeaning(status, metric),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(source, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Heart rate variability, described only as far as the app interprets it.
class _HrvCard extends StatelessWidget {
  const _HrvCard({required this.value, required this.source});

  final int value;
  final String source;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool low = isRecoveryLow(hrv: value, restingHrv: 0);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.monitor_heart_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: DsLabel(
                  'Heart rate variability',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '$value',
                style: Type.metricSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: Space.xxs),
              Text('ms', style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            low
                ? 'Below the single low threshold this app uses '
                    '($kLowHrvMs ms). One reading is not meaningful on its '
                    'own: HRV moves with sleep, stress, alcohol and illness.'
                : 'Above the single low threshold this app uses '
                    '($kLowHrvMs ms). The app does not interpret HRV beyond '
                    'that flag.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(source, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// One band in the reference table.
class _Band {
  const _Band({required this.status, required this.range});

  final HealthStatus status;
  final String range;
}

/// The bands for one metric.
class _BandCard extends StatelessWidget {
  const _BandCard({
    required this.title,
    required this.metric,
    required this.accent,
    required this.bands,
  });

  final String title;
  final String metric;
  final Color accent;
  final List<_Band> bands;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          for (final _Band band in bands)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    band.status.icon,
                    size: 16,
                    color: healthStatusColor(band.status, context),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(band.range, style: theme.textTheme.labelLarge),
                            Text(
                              band.status.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: healthStatusColor(
                                  band.status,
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.xxs),
                        Text(
                          _bandMeaning(band.status, metric),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Screening bands for an adult at rest. A single reading is not a '
            'diagnosis, and a clinician reading the same number may interpret '
            'it differently.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// A sentence with a leading dot, used in short reference lists.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 6,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// A progress indicator with a caption, used while the history is opened.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xl),
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: Space.md),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// The stored history could not be opened.
class _UnreadableHistory extends StatelessWidget {
  const _UnreadableHistory({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: DsEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Stored history could not be read',
        message: 'The samples saved on this phone could not be opened '
            '($error). Live readings can still be described below, but stored '
            'history cannot.',
      ),
    );
  }
}

/// Makes it unambiguous that a demo reading is simulated.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warning = AppColors.of(
      AppColors.warning,
      AppColors.darkWarning,
      context,
    );

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.science_outlined, size: 18, color: warning),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'Demo mode is on. The reading below is simulated by the app, not '
              'measured by a watch.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nothing to interpret yet.
class _NoReadingYet extends StatelessWidget {
  const _NoReadingYet();

  @override
  Widget build(BuildContext context) {
    return const DsCard(
      child: DsEmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: 'No reading to guide yet',
        message: 'Guidance here is derived from your own readings. Pair the '
            'watch and take a reading, or let its stored history sync, and '
            'this page will explain the band each number falls in.',
      ),
    );
  }
}
