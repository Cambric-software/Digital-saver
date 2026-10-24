/// Lifestyle tools, rebuilt onto the design system and stripped of claims.
///
/// The previous version sold itself with numbers it did not have. Sleep debt was
/// fixed at "+11.2 hrs" from a "7-day average" of 6.4 hours that was typed into
/// the source, and it followed that with a catch-up strategy. The hearing card
/// reported "62 dB SPL" as an ambient measurement "via Veyro microphone
/// sensor", which no stream in the app provides. The fasting card named
/// biological stages - "Ketosis & Fat-Burning", "Blood Sugar Normalizing" - as
/// if a timer could observe them, and the mood entry, the fasting start and the
/// break count were `setState` values that vanished on the way back to the hub.
/// BMR was calculated from three editable fields that were never saved, using a
/// formula its comment labelled both Mifflin-St Jeor and Harris-Benedict.
///
/// What is here now: a fast that records when it really started and shows only
/// elapsed time against the window the person chose; a mood and energy entry
/// stored per day; a movement-break countdown that counts when the break is
/// acknowledged; and a BMR/TDEE calculator that uses the stored profile, prints
/// the formula, and calls every result an estimate. The sleep-debt and hearing
/// cards are gone because nothing in the app measures either.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/health_models.dart';
import '../../../core/services/daily_log.dart';
import '../../../core/services/local_store.dart';
import 'package:cambric_design/cambric_design.dart';
import '../../../features/widgets/ds_timers.dart';
import 'package:cambric_design/cambric_design.dart';

/// Daily habits and two calculators, nothing diagnostic.
class LifestyleToolsScreen extends StatefulWidget {
  /// Create the screen.
  const LifestyleToolsScreen({super.key});

  @override
  State<LifestyleToolsScreen> createState() => _LifestyleToolsScreenState();
}

class _LifestyleToolsScreenState extends State<LifestyleToolsScreen> {
  static const List<String> _plans = <String>['14:10', '16:8', '18:6', '20:4'];
  static const List<String> _moods = <String>[
    'Great',
    'Good',
    'Okay',
    'Tired',
    'Stressed',
  ];
  static const List<String> _availableTags = <String>[
    'Slept well',
    'Post-workout',
    'Busy day',
    'Relaxed',
    'Caffeine',
  ];
  static const List<({String label, double factor})> _activityLevels =
      <({String label, double factor})>[
    (label: 'Sedentary', factor: 1.2),
    (label: 'Light', factor: 1.375),
    (label: 'Moderate', factor: 1.55),
    (label: 'Active', factor: 1.725),
  ];

  bool _loading = true;
  String? _loadError;

  DateTime? _fastingStart;
  String _plan = '16:8';
  Timer? _fastingTimer;

  String? _mood;
  int _energy = 5;
  final Set<String> _tags = <String>{};
  String? _savedSummary;

  int _breaks = 0;

  UserProfile _profile = UserProfile();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _height = TextEditingController();
  bool _femaleConstant = false;
  double _activityFactor = 1.375;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fastingTimer?.cancel();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final DateTime? start = await DailyLog.time(DailyLog.fastingStart);
      final String? storedPlan = await DailyLog.fastingPlan();
      final String? mood = await DailyLog.entry(DailyLog.mood);
      final int energy = await DailyLog.counter(DailyLog.energy);
      final String? tags = await DailyLog.entry(DailyLog.moodTags);
      final int breaks = await DailyLog.counter(DailyLog.breaks);
      final UserProfile profile = await LocalStore.loadProfile();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Loaded profiles have a stored JSON object; a missing one means the
      // person has not entered age, weight or height yet, so the fields are
      // left empty rather than filled with the model's defaults.
      final bool hasProfile = prefs.getString('veyro_profile') != null;

      final String? validMood =
          mood != null && _moods.contains(mood) ? mood : null;
      final int validEnergy = energy >= 1 && energy <= 10 ? energy : 5;
      final Set<String> chosenTags = <String>{
        for (final String tag in (tags ?? '').split(','))
          if (_availableTags.contains(tag.trim())) tag.trim(),
      };

      if (!mounted) return;
      setState(() {
        _fastingStart = start;
        _plan = storedPlan != null && _plans.contains(storedPlan)
            ? storedPlan
            : '16:8';
        _mood = validMood;
        _energy = validEnergy;
        _tags
          ..clear()
          ..addAll(chosenTags);
        _savedSummary = validMood == null
            ? null
            : 'Saved today: $validMood · energy $validEnergy/10';
        _breaks = breaks;
        _profile = profile;
        _femaleConstant = profile.gender.toLowerCase() == 'female';
        if (hasProfile) {
          _age.text = '${profile.age}';
          _weight.text = _formatNumber(profile.weightKg);
          _height.text = _formatNumber(profile.heightCm);
        }
        _loading = false;
        _loadError = null;
      });

      if (start != null) _startFastingTicker();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  void _startFastingTicker() {
    _fastingTimer?.cancel();
    _fastingTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggleFast() async {
    if (_fastingStart != null) {
      _fastingTimer?.cancel();
      _fastingTimer = null;
      setState(() => _fastingStart = null);
      await DailyLog.setTime(DailyLog.fastingStart, null);
      return;
    }

    final DateTime now = DateTime.now();
    setState(() => _fastingStart = now);
    await DailyLog.setTime(DailyLog.fastingStart, now);
    _startFastingTicker();
  }

  Future<void> _setPlan(String value) async {
    setState(() => _plan = value);
    await DailyLog.setFastingPlan(value);
  }

  Future<void> _saveMood() async {
    final String? mood = _mood;
    if (mood == null) return;
    final int energy = _energy;
    final List<String> tags = _tags.toList()..sort();
    await DailyLog.setEntry(DailyLog.mood, mood);
    await DailyLog.setCounter(DailyLog.energy, energy);
    await DailyLog.setEntry(DailyLog.moodTags, tags.join(', '));
    if (!mounted) return;
    setState(() {
      _savedSummary = 'Saved today: $mood · energy $energy/10';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Today\'s entry saved.')),
    );
  }

  Future<void> _onBreakFinished() async {
    final bool? acknowledged = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Time to move'),
          content: const Text(
            'Stand up, roll your shoulders, look across the room for twenty '
            'seconds, and take a few slow breaths.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
    if (acknowledged != true || !mounted) return;

    final int next = _breaks + 1;
    setState(() => _breaks = next);
    await DailyLog.setCounter(DailyLog.breaks, next);
  }

  Future<void> _saveProfileNumbers() async {
    final int? age = int.tryParse(_age.text.trim());
    final double? weight = double.tryParse(_weight.text.trim());
    final double? height = double.tryParse(_height.text.trim());
    if (age == null ||
        age < 1 ||
        age > 120 ||
        weight == null ||
        weight < 20 ||
        weight > 300 ||
        height == null ||
        height < 100 ||
        height > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter an age from 1 to 120, a weight from 20 to 300 kg and a '
            'height from 100 to 250 cm.',
          ),
        ),
      );
      return;
    }

    final UserProfile next = _profile.copyWith(
      age: age,
      weightKg: weight,
      heightCm: height,
    );
    try {
      await LocalStore.saveProfile(next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The profile could not be saved: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _profile = next);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your profile on this phone.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lifestyle tools')),
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
        _fastingSection(context),
        const SizedBox(height: Space.xl),
        _moodSection(context),
        const SizedBox(height: Space.xl),
        _bmrSection(context),
        const SizedBox(height: Space.xl),
        _breaksSection(context),
        const SizedBox(height: Space.xxl),
        const DsSection(
          title: 'About these tools',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'The fast counts time since you started it. It has no way '
                  'to observe metabolism, so it makes no claims about what '
                  'your body is doing beyond the clock.',
                ),
                SizedBox(height: Space.sm),
                Text(
                  'Mood, energy and breaks are what you record. BMR and TDEE '
                  'are estimates calculated from the numbers you enter, not '
                  'measurements, and no calorie target is suggested.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fastingSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool running = _fastingStart != null;
    final Duration elapsed = _elapsed;
    final int targetHours = _targetHours;
    final double progress = running && targetHours > 0
        ? (elapsed.inSeconds / (targetHours * 3600)).clamp(0.0, 1.0)
        : 0.0;

    return DsSection(
      title: 'Fasting timer',
      subtitle: 'Elapsed time against the window you chose. No stage claims.',
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DsLabel('Plan'),
            const SizedBox(height: Space.xs),
            DsSegmented<String>(
              value: _plan,
              options: <DsSegment<String>>[
                for (final String plan in _plans)
                  DsSegment<String>(value: plan, label: plan),
              ],
              onChanged: _setPlan,
            ),
            const SizedBox(height: Space.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    running ? _formatElapsed(elapsed) : '--:--:--',
                    style: Type.metricSmall.copyWith(
                      color: running
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                DsStatusPill(
                  label: running ? 'Running' : 'Not started',
                  color: running
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(
              running
                  ? 'Elapsed. Target: $targetHours hours.'
                  : 'Target: $targetHours hours.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Space.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _toggleFast,
              icon: Icon(
                running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 18,
              ),
              label: Text(running ? 'End fast' : 'Start fast'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DsSection(
      title: 'Mood and energy',
      subtitle: 'One entry a day. Saving again replaces today\'s.',
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DsLabel('How are you feeling?'),
            const SizedBox(height: Space.xs),
            DsSegmented<String?>(
              value: _mood,
              options: <DsSegment<String?>>[
                for (final String mood in _moods)
                  DsSegment<String?>(value: mood, label: mood),
              ],
              onChanged: (String? value) => setState(() => _mood = value),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: <Widget>[
                const Expanded(child: DsLabel('Energy')),
                Text('$_energy / 10', style: theme.textTheme.labelLarge),
              ],
            ),
            Slider(
              value: _energy.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_energy',
              onChanged: (double value) =>
                  setState(() => _energy = value.round()),
            ),
            const SizedBox(height: Space.sm),
            const DsLabel('What shaped it'),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                for (final String tag in _availableTags)
                  FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _mood == null ? null : _saveMood,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save today'),
            ),
            const SizedBox(height: Space.sm),
            Text(
              _savedSummary ?? 'Nothing saved for today yet.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bmrSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? bmr = _bmr;
    final double? tdee = bmr == null ? null : bmr * _activityFactor;

    return DsSection(
      title: 'Basal metabolic rate',
      subtitle: 'Mifflin-St Jeor, from the numbers below. Estimates, not '
          'measurements.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DsGrid(
                  minTileWidth: 170,
                  children: <Widget>[
                    _NumberField(
                      controller: _age,
                      label: 'Age',
                      suffix: 'years',
                      onChanged: () => setState(() {}),
                    ),
                    _NumberField(
                      controller: _weight,
                      label: 'Weight',
                      suffix: 'kg',
                      onChanged: () => setState(() {}),
                    ),
                    _NumberField(
                      controller: _height,
                      label: 'Height',
                      suffix: 'cm',
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                const DsLabel('Equation constant'),
                const SizedBox(height: Space.xs),
                DsSegmented<bool>(
                  value: _femaleConstant,
                  options: const <DsSegment<bool>>[
                    DsSegment<bool>(value: false, label: 'Male (+5)'),
                    DsSegment<bool>(value: true, label: 'Female (−161)'),
                  ],
                  onChanged: (bool value) =>
                      setState(() => _femaleConstant = value),
                ),
                const SizedBox(height: Space.md),
                const DsLabel('Daily activity'),
                const SizedBox(height: Space.xs),
                DsSegmented<double>(
                  value: _activityFactor,
                  options: <DsSegment<double>>[
                    for (final ({String label, double factor}) level
                        in _activityLevels)
                      DsSegment<double>(
                        value: level.factor,
                        label: level.label,
                      ),
                  ],
                  onChanged: (double value) =>
                      setState(() => _activityFactor = value),
                ),
                const SizedBox(height: Space.md),
                Text(
                  'Mifflin-St Jeor: 10 × weight (kg) + 6.25 × height (cm) '
                  '− 5 × age + the constant above. TDEE is that estimate '
                  'multiplied by the activity factor.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.md),
                OutlinedButton.icon(
                  onPressed: _saveProfileNumbers,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save these numbers to my profile'),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'These are the only numbers used. Nothing is inferred from '
                  'the watch.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          if (bmr == null || tdee == null)
            const DsCard(
              child: DsEmptyState(
                icon: Icons.calculate_outlined,
                title: 'No estimate yet',
                message: 'Enter an age, weight and height above. BMR is '
                    'calculated from them; it is never measured.',
              ),
            )
          else
            DsGrid(
              minTileWidth: 200,
              children: <Widget>[
                DsMetricTile(
                  label: 'BMR estimate',
                  value: _formatKcal(bmr),
                  unit: 'kcal/day',
                  accent: theme.colorScheme.primary,
                  icon: Icons.local_fire_department_outlined,
                ),
                DsMetricTile(
                  label: 'TDEE estimate',
                  value: _formatKcal(tdee),
                  unit: 'kcal/day',
                  accent: theme.colorScheme.tertiary,
                  icon: Icons.directions_walk_rounded,
                ),
              ],
            ),
          const SizedBox(height: Space.sm),
          Text(
            'An estimate of energy use, not a target. This screen gives no '
            'advice about how much to eat.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _breaksSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DsSection(
      title: 'Movement breaks',
      subtitle: 'A desk countdown. A break is logged when you acknowledge it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.accessibility_new_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    _breaks == 1
                        ? '1 break logged today'
                        : '$_breaks breaks logged today',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          DsCountdown(
            title: 'Stand up and move',
            icon: Icons.timer_outlined,
            duration: const Duration(minutes: 30),
            description: 'Thirty minutes at the desk, then a short movement '
                'list. The count is stored with today.',
            finishedLabel: 'Time to move',
            onFinished: _onBreakFinished,
          ),
        ],
      ),
    );
  }

  int get _targetHours {
    final String first = _plan.split(':').first;
    return int.tryParse(first) ?? 16;
  }

  Duration get _elapsed {
    final DateTime? start = _fastingStart;
    if (start == null) return Duration.zero;
    final Duration value = DateTime.now().difference(start);
    return value.isNegative ? Duration.zero : value;
  }

  /// Mifflin-St Jeor, or null until all three inputs are plausible.
  double? get _bmr {
    final int? age = int.tryParse(_age.text.trim());
    final double? weight = double.tryParse(_weight.text.trim());
    final double? height = double.tryParse(_height.text.trim());
    if (age == null || age < 1 || age > 120) return null;
    if (weight == null || weight < 20 || weight > 300) return null;
    if (height == null || height < 100 || height > 250) return null;
    final double base = 10 * weight + 6.25 * height - 5 * age;
    return base + (_femaleConstant ? -161 : 5);
  }

  static String _formatElapsed(Duration value) {
    final int total = value.inSeconds < 0 ? 0 : value.inSeconds;
    final String hours = (total ~/ 3600).toString().padLeft(2, '0');
    final String minutes = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final String seconds = (total % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String _formatKcal(double value) {
    final String digits = value.round().toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toString();
  }
}

/// A labelled numeric field for the calculator inputs.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (String value) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
