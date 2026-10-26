/// Blood pressure, with the categories the rest of the app uses.
///
/// Rebuilt onto the design system. It also had its own idea of the thresholds:
/// this screen called 120/80 "Elevated" and 130/80 "High Stage 1", while
/// `health_interpretation.dart` - which the dashboard and the licence both point
/// at - puts elevated at 130/85 and high at 140/90. The same reading therefore
/// carried two different words depending on which screen was open, which is the
/// one thing a threshold table is supposed to prevent. The categories now come
/// from that shared module, and the guide below is printed from the same
/// constants, so it cannot drift again.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/health_models.dart';
import '../../../core/services/ble_service.dart';
import '../../../core/services/health_analysis_service.dart';
import 'package:cambric_design/cambric_design.dart';
import '../../../shared/utils/health_interpretation.dart';

/// Blood pressure in detail.
class BpScreen extends StatelessWidget {
  /// Create the screen.
  const BpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BleService ble = context.watch<BleService>();
    final BloodPressureData bp = ble.bloodPressure;
    final bool has = hasBloodPressure(bp);
    final HealthStatus status = interpretBloodPressure(bp);
    final int? vascularAge = has
        ? HealthAnalysisService.estimateVascularAge(
            bp.systolic.toDouble(),
            bp.diastolic.toDouble(),
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Blood pressure')),
      body: DsPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Reading(
              bp: bp,
              status: status,
              connected: ble.isConnected,
            ),
            const SizedBox(height: Space.xl),
            DsSection(
              title: 'Derived from this reading',
              subtitle: 'Arithmetic on the numbers above, nothing more',
              child: DsGrid(
                minTileWidth: 200,
                children: <Widget>[
                  DsMetricTile(
                    label: 'Pulse pressure',
                    value: has ? '${bp.systolic - bp.diastolic}' : '--',
                    unit: has ? 'mmHg' : null,
                    accent: _bp(context),
                    icon: Icons.compress_rounded,
                  ),
                  DsMetricTile(
                    label: 'Mean arterial pressure',
                    value: has
                        ? '${((bp.systolic + 2 * bp.diastolic) / 3).round()}'
                        : '--',
                    unit: has ? 'mmHg' : null,
                    accent: _bp(context),
                    icon: Icons.show_chart_rounded,
                  ),
                  DsMetricTile(
                    label: 'Vascular age (estimate)',
                    value: vascularAge != null ? '$vascularAge' : '--',
                    unit: vascularAge != null ? 'years' : null,
                    accent: _bp(context),
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                  DsMetricTile(
                    label: 'Heart rate variability',
                    value: hasHeartRate(ble.heartRate.hrv)
                        ? '${ble.heartRate.hrv}'
                        : '--',
                    unit: hasHeartRate(ble.heartRate.hrv) ? 'ms' : null,
                    accent: _bp(context),
                    icon: Icons.monitor_heart_outlined,
                  ),
                ],
              ),
            ),
            if (guidanceFor(status, 'blood pressure') != null) ...<Widget>[
              const SizedBox(height: Space.xl),
              DsCard(
                borderColor: healthStatusColor(status, context),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(status.icon, size: 18, color: healthStatusColor(status, context)),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        guidanceFor(status, 'blood pressure')!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Space.xxl),
            const DsSection(
              title: 'What the bands are',
              subtitle: 'Commonly cited adult screening ranges',
              child: _BandGuide(),
            ),
            const SizedBox(height: Space.xxl),
            DsSection(
              title: 'Next steps',
              subtitle: 'Matched to the band above',
              child: _Steps(status: status),
            ),
            const SizedBox(height: Space.xxl),
            const DsSection(
              title: 'Before you act on this',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'A wrist reading is an estimate. A cuff is the only '
                          'thing that measures blood pressure, so treat this as '
                          'a prompt to take a real reading, not as a result.',
                        ),
                        SizedBox(height: Space.sm),
                        Text(
                          'One reading does not diagnose anything. Blood '
                          'pressure moves with stress, caffeine, sleep, how '
                          'you are sitting and the time of day.',
                        ),
                        SizedBox(height: Space.sm),
                        Text(
                          'The bands above are the AHA and ACC screening '
                          'ranges for adults, printed from the same constants '
                          'the rest of the app uses.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _bp(BuildContext context) =>
      AppColors.of(AppColors.bpBlue, AppColors.darkBp, context);
}

/// The reading itself.
class _Reading extends StatelessWidget {
  const _Reading({
    required this.bp,
    required this.status,
    required this.connected,
  });

  final BloodPressureData bp;
  final HealthStatus status;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool has = hasBloodPressure(bp);
    final Color accent = AppColors.of(AppColors.bpBlue, AppColors.darkBp, context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bloodtype_outlined, size: 18, color: accent),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Systolic / diastolic',
                    style: theme.textTheme.titleSmall),
              ),
              if (has)
                DsStatusPill(
                  label: status.label,
                  icon: status.icon,
                  color: healthStatusColor(status, context),
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                formatBloodPressure(bp),
                style: Type.metric.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: Space.sm),
              Text(
                has ? 'mmHg' : '',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          if (!has) ...<Widget>[
            const SizedBox(height: Space.sm),
            Text(
              connected
                  ? 'The watch has not reported a blood pressure reading yet.'
                  : 'No watch is connected, so there is nothing to show.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// The band table, built from the shared constants.
class _BandGuide extends StatelessWidget {
  const _BandGuide();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<(String, String, HealthStatus)> bands =
        <(String, String, HealthStatus)>[
      (
        'In the usual range',
        'below $kSystolicElevated / $kDiastolicElevated',
        HealthStatus.normal,
      ),
      (
        'Slightly raised',
        '$kSystolicElevated+ / $kDiastolicElevated+',
        HealthStatus.elevated,
      ),
      (
        'Raised',
        '$kSystolicStage1+ / $kDiastolicStage1+',
        HealthStatus.high,
      ),
      (
        'Well above the usual range',
        '$kSystolicCrisis+ / $kDiastolicCrisis+',
        HealthStatus.critical,
      ),
    ];

    return DsCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < bands.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: Space.md),
            Row(
              children: <Widget>[
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: healthStatusColor(bands[i].$3, context),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(bands[i].$1, style: theme.textTheme.titleSmall),
                      const SizedBox(height: Space.xxs),
                      Text(
                        bands[i].$2,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  'mmHg',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// What to do next, matched to the band.
class _Steps extends StatelessWidget {
  const _Steps({required this.status});

  final HealthStatus status;

  @override
  Widget build(BuildContext context) {
    final List<String> steps = switch (status) {
      HealthStatus.normal => <String>[
          'Nothing to do. Keep taking readings the same way at the same time '
              'of day so the trend means something.',
          'Sitting still for five minutes before a reading removes most of the '
              'noise.',
        ],
      HealthStatus.elevated => <String>[
          'Take another reading in a few minutes, sitting still, arm supported '
              'at heart height.',
          'Note caffeine, salt and stress in the hours before, since those move '
              'a reading more than anything else.',
        ],
      HealthStatus.high => <String>[
          'Take a second reading and write it down with the time.',
          'If it stays in this band across readings, mention it to a clinician '
              'rather than waiting for a symptom.',
        ],
      HealthStatus.critical => <String>[
          'Take another reading after five minutes of sitting still.',
          'If it is still this high, or you have chest pain, trouble breathing, '
              'weakness, slurred speech or a bad headache, contact emergency '
              'services now.',
        ],
      HealthStatus.unknown => <String>[
          'No reading to act on yet.',
        ],
    };

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
