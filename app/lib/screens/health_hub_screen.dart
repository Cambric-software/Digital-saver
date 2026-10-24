/// The Health hub: the door to every tool suite, plus the daily timers that are
/// used standing up.
///
/// Rebuilt. The previous screen called itself "Cambric 50-Feature Health Hub"
/// and said "50/50 Features Active", which counted features that did not do
/// anything: six of the nine timers created a [Timer] that was never started, so
/// "Start Breath Hold" flipped a boolean and the seconds never moved. It also
/// displayed movement rings filled with hard-coded numbers (380 kcal, 24 min,
/// 8 hours) as if they had been measured, next to a personal best of 48 seconds
/// that nobody had recorded.
///
/// What is here now: the suites, which were previously unreachable because
/// nothing opened this screen; the everyday timers, which actually count; and a
/// reflection log, which is stored and shows what was written on which day.
library;

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'package:cambric_design/cambric_design.dart';
import '../widgets/ds_timers.dart';
import 'package:cambric_design/cambric_design.dart';
import 'bp_screen.dart';
import 'device_diagnostics_screen.dart';
import 'fitness_tools_screen.dart';
import 'lifestyle_tools_screen.dart';
import 'watch_simulator_screen.dart';
import 'wellness_tools_screen.dart';

/// The hub.
class HealthHubScreen extends StatefulWidget {
  /// Create the hub.
  const HealthHubScreen({super.key});

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen> {
  final TextEditingController _reflection = TextEditingController();

  Reflection? _today;
  List<Reflection> _recent = <Reflection>[];
  int _breathHoldBest = 0;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Reflection? today = await StorageService.todayReflection();
      final List<Reflection> recent = await StorageService.reflections();
      final int best = await StorageService.breathHoldBest();
      if (!mounted) return;
      setState(() {
        _today = today;
        _recent = recent;
        _breathHoldBest = best;
        _reflection.text = today?.text ?? '';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _saveReflection() async {
    await StorageService.saveReflection(_reflection.text);
    final Reflection? today = await StorageService.todayReflection();
    final List<Reflection> recent = await StorageService.reflections();
    if (!mounted) return;
    setState(() {
      _today = today;
      _recent = recent;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reflection saved')),
    );
  }

  Future<void> _recordBreathHold(Duration held) async {
    final int seconds = held.inSeconds;
    final int best = await StorageService.recordBreathHold(seconds);
    if (!mounted) return;
    setState(() => _breathHoldBest = best);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          best == seconds && seconds > 0
              ? 'New longest hold: ${best}s'
              : 'Held ${seconds}s. Best stays at ${best}s.',
        ),
      ),
    );
  }

  void _announce(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: 'Health hub',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_loadError != null) ...<Widget>[
            DsCard(
              child: Text(
                'Your saved notes and records could not be read: $_loadError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: Space.xl),
          ],
          DsSection(
            title: 'Tool suites',
            subtitle: 'Each one opens its own screen',
            child: DsGrid(
              minTileWidth: 280,
              children: <Widget>[
                _SuiteCard(
                  title: 'Wellness',
                  subtitle: 'Breathing, hydration, caffeine and a rest timer',
                  icon: Icons.spa_outlined,
                  onTap: () => _open(const WellnessToolsScreen()),
                ),
                _SuiteCard(
                  title: 'Fitness',
                  subtitle: 'Training, targets and how hard a session felt',
                  icon: Icons.fitness_center_outlined,
                  onTap: () => _open(const FitnessToolsScreen()),
                ),
                _SuiteCard(
                  title: 'Lifestyle',
                  subtitle: 'Fasting, mood, movement breaks and a BMR estimate',
                  icon: Icons.self_improvement_outlined,
                  onTap: () => _open(const LifestyleToolsScreen()),
                ),
                _SuiteCard(
                  title: 'Device & sensors',
                  subtitle: 'Connection, firmware, storage and the commands it accepts',
                  icon: Icons.tune_outlined,
                  onTap: () => _open(const DeviceDiagnosticsScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Measurements',
            subtitle: 'Readings that deserve their own screen',
            child: DsGrid(
              minTileWidth: 280,
              children: <Widget>[
                _SuiteCard(
                  title: 'Blood pressure',
                  subtitle: 'Systolic and diastolic, with the AHA categories',
                  icon: Icons.bloodtype_outlined,
                  onTap: () => _open(const BpScreen()),
                ),
                _SuiteCard(
                  title: 'Watch simulator',
                  subtitle: 'See how a watch face renders before you pair one',
                  icon: Icons.watch_outlined,
                  onTap: () => _open(const WatchSimulatorScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Everyday timers',
            subtitle: 'Habit timers, run while this screen is open',
            child: DsGrid(
              minTileWidth: 320,
              children: <Widget>[
                DsCountdown(
                  title: 'Wash your hands',
                  icon: Icons.clean_hands_outlined,
                  duration: const Duration(seconds: 20),
                  description:
                      'Twenty seconds of scrubbing, the length the WHO advises.',
                  finishedLabel: 'Clean',
                  onFinished: () => _announce('Twenty seconds done.'),
                ),
                DsCountdown(
                  title: 'Brush your teeth',
                  icon: Icons.sentiment_very_satisfied_outlined,
                  duration: const Duration(minutes: 2),
                  steps: 4,
                  stepLabel: 'Quadrant',
                  description:
                      'Two minutes, thirty seconds per quadrant of your mouth.',
                  finishedLabel: 'Clean',
                  onFinished: () => _announce('Two minutes done, all four '
                      'quadrants.'),
                ),
                DsCountdown(
                  title: 'Eye break (20-20-20)',
                  icon: Icons.remove_red_eye_outlined,
                  duration: const Duration(seconds: 20),
                  description: 'Look at something about 6 metres away.',
                  finishedLabel: 'Rest',
                  onFinished: () =>
                      _announce('Eyes rested. Back to the screen.'),
                ),
                DsCountdown(
                  title: 'Focused work',
                  icon: Icons.timer_outlined,
                  duration: const Duration(minutes: 25),
                  description:
                      'Twenty-five minutes on one task, then take a break.',
                  finishedLabel: 'Break',
                  onFinished: () =>
                      _announce('Twenty-five minutes. Stand up and move.'),
                ),
                DsStopwatch(
                  title: 'Morning light',
                  icon: Icons.wb_sunny_outlined,
                  target: const Duration(minutes: 15),
                  reachedLabel: 'Target reached',
                  description:
                      'Daylight in the first hour of the day supports sleep at '
                      'night.',
                  onReachTarget: () =>
                      _announce('Fifteen minutes of daylight. Good start.'),
                ),
                DsStopwatch(
                  title: 'Cold exposure',
                  icon: Icons.ac_unit_outlined,
                  description:
                      'Counts how long the cold lasts. Build up slowly, and '
                      'stop if you feel unwell.',
                ),
                DsStopwatch(
                  title: 'Breath hold',
                  icon: Icons.air_outlined,
                  description:
                      'Sit down and never do this in or near water. Records the '
                      'longest hold.',
                  bestSeconds: _breathHoldBest,
                  recordLabel: 'Record',
                  onRecord: _recordBreathHold,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Daily reflection',
            subtitle: _loading
                ? 'Loading what you wrote before'
                : _today == null
                    ? 'Nothing written today yet'
                    : 'Written today',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _reflection,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'What went well today?',
                    hintText: 'One sentence is enough. It is only for you.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: Space.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _saveReflection,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save'),
                  ),
                ),
                if (_recent.length > 1) ...<Widget>[
                  const SizedBox(height: Space.lg),
                  DsLabel('Earlier entries',
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: Space.sm),
                  for (final Reflection entry in _recent.skip(1).take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 96,
                            child: Text(
                              entry.date,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.text,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),
          const DsSection(
            title: 'What this is',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'These are habit timers and a private note pad. They are '
                        'not a treatment plan, and none of them measures your '
                        'body. Timings are counted while this screen is open.',
                      ),
                      SizedBox(height: Space.sm),
                      Text(
                        'Nothing here is sent anywhere: the reflection log and '
                        'your longest breath hold are stored on this device.',
                      ),
                    ],
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

/// One tappable card that opens another screen.
class _SuiteCard extends StatelessWidget {
  const _SuiteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DsCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: Space.xxs),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
