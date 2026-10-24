/// Fitness tools, rebuilt onto the design system and stripped of claims.
///
/// The old screen was a numbered feature list - "Fitness & Smart Diagnostics
/// (9 Features)" down to "(#26)" - and most of the numbers under those headings
/// were typed into the source. The medication list opened with three products
/// already in it. The recovery test opened with a peak of 155 bpm and a two
/// minute rate of 120, then graded the 35 bpm difference as "Excellent" without
/// ever asking the watch. The heart-rate zones used a stored age that defaulted
/// to 16, and the workout calories used a hard-coded 65 kg with a MET constant
/// picked by substring-matching the activity name. The weekly "clinical health
/// brief" printed a fixed set of averages, including a sleep duration the app
/// does not measure, and called the result clinical.
///
/// Three cards could not work at all. "Find My Watch" sent a binary packet the
/// firmware does not define and then announced that the screen was flashing and
/// the vibration motor was running. The weather card showed a fixed Cairo
/// forecast with no weather service and no API key, and told the person it had
/// synced three days of it. The alarm card offered a smart wake window over
/// haptics, and the BLE service has no alarm or haptic command.
///
/// What is here now: a medication list that is stored, editable and removable;
/// a recovery test that reads two real heart rates from the watch two minutes
/// apart and shows the arithmetic; a workout timer that counts real seconds and
/// estimates energy from the weight in the stored profile, labelled as an
/// estimate; zone bands computed from 220 minus the profile age, labelled as an
/// estimate, with the live rate marked when there is one; and an effort rating
/// stored with the day. With no watch, each measurement card says what it needs
/// instead of showing a sample number.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_models.dart';
import '../services/ble_service.dart';
import '../services/daily_log.dart';
import '../services/local_store.dart';
import '../services/storage_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import '../utils/health_interpretation.dart';
import '../widgets/ds_timers.dart';
import 'package:cambric_design/cambric_design.dart';

/// Training aids and logged effort, with no simulated measurements.
class FitnessToolsScreen extends StatefulWidget {
  /// Create the screen.
  const FitnessToolsScreen({super.key});

  @override
  State<FitnessToolsScreen> createState() => _FitnessToolsScreenState();
}

class _FitnessToolsScreenState extends State<FitnessToolsScreen> {
  /// Rough MET values, one decimal at most. They describe an activity type,
  /// not the person doing it, so no finer number is shown.
  static const List<({String label, double met})> _activities =
      <({String label, double met})>[
    (label: 'Walking', met: 3.5),
    (label: 'Running', met: 9.0),
    (label: 'Cycling', met: 7.0),
    (label: 'Strength training', met: 5.0),
  ];

  /// The five bands, as fractions of the estimated maximum.
  static const List<({int zone, double low, double high})> _zoneBands =
      <({int zone, double low, double high})>[
    (zone: 1, low: 0.5, high: 0.6),
    (zone: 2, low: 0.6, high: 0.7),
    (zone: 3, low: 0.7, high: 0.8),
    (zone: 4, low: 0.8, high: 0.9),
    (zone: 5, low: 0.9, high: 1.0),
  ];

  bool _loading = true;
  String? _loadError;

  List<Medication> _medications = <Medication>[];

  UserProfile _profile = UserProfile();
  bool _hasProfile = false;

  int? _restBpm;
  int? _postBpm;
  String? _hrrProblem;
  int _hrrRun = 0;

  String _activity = 'Walking';
  ({String activity, Duration elapsed, double? kcal})? _lastWorkout;

  double _rpe = 5;
  int? _savedRpe;
  final TextEditingController _rpeNote = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rpeNote.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<Medication> medications = await StorageService.medications();
      final UserProfile profile = await LocalStore.loadProfile();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // A profile object always exists in memory with model defaults. Only a
      // stored one means the person actually entered an age and weight, so the
      // presence of the key decides whether those numbers may be used.
      final bool hasProfile = prefs.getString('veyro_profile') != null;
      final int savedRpe = await DailyLog.counter(DailyLog.rpe);
      final String? note = await DailyLog.entry(DailyLog.rpeNote);

      if (!mounted) return;
      setState(() {
        _medications = medications;
        _profile = profile;
        _hasProfile = hasProfile;
        if (savedRpe >= 1 && savedRpe <= 10) {
          _rpe = savedRpe.toDouble();
          _savedRpe = savedRpe;
        }
        _rpeNote.text = note ?? '';
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

  int? get _profileAge {
    if (!_hasProfile) return null;
    final int age = _profile.age;
    return age >= 1 && age <= 120 ? age : null;
  }

  double? get _profileWeight {
    if (!_hasProfile) return null;
    final double weight = _profile.weightKg;
    return weight >= 20 && weight <= 300 ? weight : null;
  }

  Future<void> _editMedication({int? index}) async {
    final Medication? existing =
        index == null || index >= _medications.length
            ? null
            : _medications[index];

    final Medication? result = await showDialog<Medication>(
      context: context,
      builder: (BuildContext ctx) => _MedicationDialog(existing: existing),
    );

    if (result == null) return;
    final List<Medication> next = List<Medication>.of(_medications);
    if (index == null || index >= next.length) {
      next.add(result);
    } else {
      next[index] = result;
    }
    setState(() => _medications = next);
    await StorageService.setMedications(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved on this phone.')),
    );
  }

  Future<void> _removeMedication(int index) async {
    if (index < 0 || index >= _medications.length) return;
    final Medication removed = _medications[index];
    final List<Medication> next = List<Medication>.of(_medications)
      ..removeAt(index);
    setState(() => _medications = next);
    await StorageService.setMedications(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${removed.name}.')),
    );
  }

  void _recordRestingRate() {
    final BleService ble = context.read<BleService>();
    final int bpm = ble.heartRate.bpm;
    if (!ble.isConnected || !hasHeartRate(bpm)) return;
    setState(() {
      _restBpm = bpm;
      _postBpm = null;
      _hrrProblem = null;
      _hrrRun++;
    });
  }

  void _finishHrr() {
    final BleService ble = context.read<BleService>();
    if (!ble.isConnected) {
      setState(() {
        _hrrProblem = 'The watch disconnected during the test, so there is no '
            'second reading to compare.';
      });
      return;
    }
    final int bpm = ble.heartRate.bpm;
    if (!hasHeartRate(bpm)) {
      setState(() {
        _hrrProblem = 'No heart rate arrived at the end of the two minutes. '
            'The watch may have lost skin contact.';
      });
      return;
    }
    setState(() {
      _postBpm = bpm;
      _hrrProblem = null;
    });
  }

  void _resetHrr() {
    setState(() {
      _restBpm = null;
      _postBpm = null;
      _hrrProblem = null;
    });
  }

  void _recordWorkout(Duration elapsed) {
    final double? kg = _profileWeight;
    final double met = _metFor(_activity);
    final double? kcal = kg == null || elapsed.inSeconds <= 0
        ? null
        : met * 3.5 * kg / 200 * (elapsed.inSeconds / 60);
    setState(() {
      _lastWorkout = (
        activity: _activity,
        elapsed: elapsed,
        kcal: kcal,
      );
    });
  }

  Future<void> _saveRpe() async {
    final int value = _rpe.round();
    await DailyLog.setCounter(DailyLog.rpe, value);
    await DailyLog.setEntry(DailyLog.rpeNote, _rpeNote.text);
    if (!mounted) return;
    setState(() => _savedRpe = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved today: RPE $value/10.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness tools')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DsPage(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_loadError != null) ...<Widget>[
          DsCard(
            child: Text(
              'Your saved entries could not be read: $_loadError',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
        _medicationSection(context),
        const SizedBox(height: Space.xl),
        _hrrSection(context),
        const SizedBox(height: Space.xl),
        _workoutSection(context),
        const SizedBox(height: Space.xl),
        _zonesSection(context),
        const SizedBox(height: Space.xl),
        _rpeSection(context),
        const SizedBox(height: Space.xxl),
        const DsSection(
          title: 'About these tools',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'The recovery test uses two live heart rates from the watch. '
                  'The workout timer counts real seconds. Zones come from '
                  '220 minus your age. Every calorie and zone number is an '
                  'estimate, and none of it is a diagnosis.',
                ),
                SizedBox(height: Space.sm),
                Text(
                  'The medication card is a list you keep, not a reminder: the '
                  'watch has no alarm API and this app sends no medication '
                  'notifications. There is no weather, find-my-watch, paging, '
                  'vibration pattern or smart-wake control here because the '
                  'watch cannot be told to do any of those things.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _medicationSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = AppColors.of(
      AppColors.sleepPurple,
      AppColors.darkSleep,
      context,
    );

    return DsSection(
      title: 'Medications and supplements',
      subtitle: 'A list you keep on this phone. No reminders and no schedule.',
      child: _medications.isEmpty
          ? DsCard(
              child: DsEmptyState(
                icon: Icons.medication_outlined,
                title: 'Nothing on the list yet',
                message: 'Add what you take and the dose if you want it '
                    'written down. The list stays on this phone.',
                action: FilledButton.icon(
                  onPressed: () => _editMedication(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add one'),
                ),
              ),
            )
          : DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < _medications.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(
                        height: Space.xl,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.medication_outlined,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _medications[i].name,
                                style: theme.textTheme.titleSmall,
                              ),
                              if (_medications[i].dose.isNotEmpty)
                                Text(
                                  _medications[i].dose,
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit ${_medications[i].name}',
                          onPressed: () => _editMedication(index: i),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Remove ${_medications[i].name}',
                          onPressed: () => _removeMedication(i),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    onPressed: () => _editMedication(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add another'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _hrrSection(BuildContext context) {
    final BleService ble = context.watch<BleService>();
    final ThemeData theme = Theme.of(context);
    final int live = ble.heartRate.bpm;

    return DsSection(
      title: 'Heart rate recovery',
      subtitle: 'Two heart rates two minutes apart. The difference is shown; '
          'no recovery grade is invented.',
      child: !ble.isConnected
          ? const DsCard(
              child: DsEmptyState(
                icon: Icons.watch_off_outlined,
                title: 'No watch connected',
                message: 'This test needs a live heart rate at the start and '
                    'again two minutes later. Pair the watch in Settings, wear '
                    'it, then open this screen again.',
              ),
            )
          : _hrrBody(context, ble: ble, live: live, theme: theme),
    );
  }

  Widget _hrrBody(
    BuildContext context, {
    required BleService ble,
    required int live,
    required ThemeData theme,
  }) {
    final int? rest = _restBpm;
    final int? post = _postBpm;

    if (rest == null) {
      return DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 18,
                  color: AppColors.of(
                    AppColors.heartRed,
                    AppColors.darkHeart,
                    context,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    hasHeartRate(live)
                        ? 'Live: $live bpm'
                        : 'Waiting for a heart rate',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (hasHeartRate(live))
                  DsStatusPill(
                    label: 'Live',
                    color: theme.colorScheme.secondary,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Sit still for a few minutes, then record the rate the watch is '
              'showing. Two minutes later the app reads the rate again and '
              'shows the change.',
              style: theme.textTheme.bodySmall,
            ),
            if (ble.demoMode) ...<Widget>[
              const SizedBox(height: Space.xs),
              Text(
                'Demo mode is on, so these heart rates are generated by the '
                'app rather than measured.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: hasHeartRate(live) ? _recordRestingRate : null,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Record resting rate'),
            ),
            if (!hasHeartRate(live)) ...<Widget>[
              const SizedBox(height: Space.xs),
              Text(
                'The button becomes available when the watch reports a rate.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    if (post != null) {
      final int difference = rest - post;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsGrid(
            minTileWidth: 160,
            children: <Widget>[
              DsMetricTile(
                label: 'Resting',
                value: '$rest',
                unit: 'bpm',
                accent: AppColors.of(
                  AppColors.heartRed,
                  AppColors.darkHeart,
                  context,
                ),
                icon: Icons.favorite_border_rounded,
              ),
              DsMetricTile(
                label: 'Two minutes later',
                value: '$post',
                unit: 'bpm',
                accent: AppColors.of(
                  AppColors.heartRed,
                  AppColors.darkHeart,
                  context,
                ),
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  difference >= 0
                      ? 'A drop of $difference bpm over two minutes.'
                      : 'The second reading was ${-difference} bpm higher.',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Both numbers came from the watch. A single pair of readings '
                  'moves with breathing, talking, temperature and how still you '
                  'sat, so this is not a clinical recovery score.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.md),
                OutlinedButton.icon(
                  onPressed: _resetHrr,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Start a new test'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_hrrProblem != null) {
      return DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_hrrProblem!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: _resetHrr,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DsCard(
          child: Text(
            'Resting rate recorded: $rest bpm. Sit still for two minutes. When '
            'the countdown ends the app reads the rate the watch is showing.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: Space.md),
        DsCountdown(
          key: ValueKey<int>(_hrrRun),
          title: 'Two-minute wait',
          icon: Icons.timer_outlined,
          duration: const Duration(minutes: 2),
          description: 'Keep the watch on and stay still. The second reading '
              'is taken when this reaches zero.',
          finishedLabel: 'Measure now',
          onFinished: _finishHrr,
        ),
        const SizedBox(height: Space.sm),
        TextButton(
          onPressed: _resetHrr,
          child: const Text('Cancel test'),
        ),
      ],
    );
  }

  Widget _workoutSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? kg = _profileWeight;
    final ({String activity, Duration elapsed, double? kcal})? last =
        _lastWorkout;
    final Color accent = AppColors.of(
      AppColors.oxyGreen,
      AppColors.darkOxy,
      context,
    );

    return DsSection(
      title: 'Workout timer',
      subtitle: 'Counts while this screen is open. Energy is an estimate from '
          'your weight and a rough MET value.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const DsLabel('Activity'),
                const SizedBox(height: Space.xs),
                DsSegmented<String>(
                  value: _activity,
                  options: <DsSegment<String>>[
                    for (final ({String label, double met}) activity
                        in _activities)
                      DsSegment<String>(
                        value: activity.label,
                        label: activity.label,
                      ),
                  ],
                  onChanged: (String value) =>
                      setState(() => _activity = value),
                ),
                const SizedBox(height: Space.md),
                Text(
                  kg == null
                      ? 'No weight is saved in your profile, so no calorie '
                          'estimate is shown. The timer still works.'
                      : 'The estimate uses ${_formatNumber(kg)} kg from your '
                          'profile and ${_formatNumber(_metFor(_activity))} MET '
                          'for ${_activity.toLowerCase()}. Both are rough.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          DsStopwatch(
            title: 'Session',
            icon: Icons.directions_run_outlined,
            description: 'Elapsed time, counted by the app. Pause stops the '
                'count; saving records it below.',
            recordLabel: 'Save session',
            onRecord: _recordWorkout,
          ),
          if (last != null) ...<Widget>[
            const SizedBox(height: Space.md),
            DsCard(
              borderColor: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DsLabel(
                    'Last saved session',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    '${last.activity} · ${_formatDuration(last.elapsed)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    last.kcal == null
                        ? 'No weight saved, so no energy estimate.'
                        : 'About ${last.kcal!.round()} kcal, estimated from '
                            'the time above and your stored weight. This is not '
                            'a measurement.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _zonesSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BleService ble = context.watch<BleService>();
    final int? age = _profileAge;
    final int live = ble.heartRate.bpm;
    final bool hasLive = hasHeartRate(live);

    return DsSection(
      title: 'Heart rate zones',
      subtitle: 'Bands are 50 to 100 percent of 220 minus age. That maximum is '
          'a formula, not a measurement.',
      child: age == null
          ? const DsCard(
              child: DsEmptyState(
                icon: Icons.person_outline,
                title: 'No age saved',
                message: 'The 220 − age estimate needs your age. Add it to your '
                    'profile in Settings; this screen does not guess one, so no '
                    'bands are shown.',
              ),
            )
          : _zonesBody(
              context,
              theme: theme,
              age: age,
              live: hasLive ? live : null,
              demo: ble.demoMode,
            ),
    );
  }

  Widget _zonesBody(
    BuildContext context, {
    required ThemeData theme,
    required int age,
    required int? live,
    required bool demo,
  }) {
    final int maxHr = 220 - age;
    final int? active = live == null ? null : _zoneFor(live, maxHr);
    final String liveLabel = switch (active) {
      -1 => 'Below zone 1',
      0 => 'Zone 1',
      1 => 'Zone 2',
      2 => 'Zone 3',
      3 => 'Zone 4',
      4 => 'Zone 5',
      5 => 'Above zone 5',
      _ => 'No rate',
    };
    final Color accent = AppColors.of(
      AppColors.heartRed,
      AppColors.darkHeart,
      context,
    );

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Estimated maximum: $maxHr bpm',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              DsStatusPill(
                label: 'Estimate',
                color: theme.colorScheme.onSurfaceVariant,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            '220 − $age years = $maxHr bpm. The formula is a population '
            'average and can be wrong for one person by a wide margin.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          if (live != null) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.favorite_rounded, size: 16, color: accent),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'Live: $live bpm',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                DsStatusPill(
                  label: liveLabel,
                  color: accent,
                  dense: true,
                ),
              ],
            ),
            if (demo) ...<Widget>[
              const SizedBox(height: Space.xxs),
              Text(
                'Demo mode is on, so this rate is generated by the app.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: Space.md),
          ] else ...<Widget>[
            Text(
              'No live heart rate, so no band is marked. The bands are shown '
              'on their own.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Space.md),
          ],
          for (int i = 0; i < _zoneBands.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: Space.sm),
            _ZoneRow(
              label: 'Zone ${_zoneBands[i].zone}',
              detail: '${(maxHr * _zoneBands[i].low).round()}–'
                  '${(maxHr * _zoneBands[i].high).round()} bpm',
              percent: '${(_zoneBands[i].low * 100).round()}–'
                  '${(_zoneBands[i].high * 100).round()}%',
              active: active == i,
              accent: accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _rpeSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int? saved = _savedRpe;

    return DsSection(
      title: 'Effort (RPE)',
      subtitle: 'How hard the session felt, 1 to 10. Stored with today.',
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'RPE ${_rpe.round()} / 10',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  saved == null
                      ? 'Nothing saved today'
                      : 'Saved today: $saved / 10',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: _rpe,
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_rpe.round()}',
              onChanged: (double value) =>
                  setState(() => _rpe = value),
            ),
            const DsLabel('Words about the session (optional)'),
            const SizedBox(height: Space.xs),
            TextField(
              controller: _rpeNote,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'For example, steady until the last ten minutes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _saveRpe,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save today\'s rating'),
            ),
            const SizedBox(height: Space.xs),
            Text(
              '1 is very easy, 10 is the hardest effort you could sustain. '
              'This is your own rating, not something the watch measured.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// The zone a rate falls in, as an index into [_zoneBands], -1 below the
  /// first band and 5 above the last.
  static int _zoneFor(int bpm, int maxHr) {
    final int firstLow = (maxHr * _zoneBands.first.low).round();
    if (bpm < firstLow) return -1;
    if (bpm > maxHr) return _zoneBands.length;
    for (int i = 0; i < _zoneBands.length; i++) {
      final int low = (maxHr * _zoneBands[i].low).round();
      final int high = (maxHr * _zoneBands[i].high).round();
      if (bpm >= low &&
          (bpm < high ||
              (bpm == high && i == _zoneBands.length - 1))) {
        return i;
      }
    }
    return _zoneBands.length - 1;
  }

  static double _metFor(String label) {
    for (final ({String label, double met}) activity in _activities) {
      if (activity.label == label) return activity.met;
    }
    return _activities.first.met;
  }

  static String _formatDuration(Duration value) {
    final int total = value.inSeconds.clamp(0, 359999);
    final int hours = total ~/ 3600;
    final int minutes = (total % 3600) ~/ 60;
    final int seconds = total % 60;
    final String mmss =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return hours > 0 ? '$hours:$mmss' : mmss;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toStringAsFixed(1);
  }
}

/// The add/edit dialog, owning its text controllers for the life of the route.
///
/// Disposing controllers as soon as `showDialog` returns is too early: the
/// route's exit animation still builds the fields, and a disposed controller
/// throws from that rebuild. A small StatefulWidget disposes them when the route
/// is actually gone.
class _MedicationDialog extends StatefulWidget {
  const _MedicationDialog({this.existing});

  final Medication? existing;

  @override
  State<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<_MedicationDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _dose =
      TextEditingController(text: widget.existing?.dose ?? '');

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  void _save() {
    final String trimmed = _name.text.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(
      context,
      Medication(name: trimmed, dose: _dose.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add medication' : 'Edit medication',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'For example, Vitamin D3',
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _dose,
              decoration: const InputDecoration(
                labelText: 'Dose or note (optional)',
                hintText: 'For example, 2000 IU',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// One band in the zone table, marked when the live rate falls inside it.
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.label,
    required this.detail,
    required this.percent,
    required this.active,
    required this.accent,
  });

  final String label;
  final String detail;
  final String percent;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: active ? accent : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: active ? accent : null,
                ),
              ),
              Text(percent, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(detail, style: theme.textTheme.bodySmall),
        if (active) ...<Widget>[
          const SizedBox(width: Space.sm),
          Icon(Icons.my_location_rounded, size: 16, color: accent),
        ],
      ],
    );
  }
}
