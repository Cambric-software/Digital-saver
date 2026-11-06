/// Guided breathing with patterns that actually pace themselves.
///
/// The old box-breathing card ran a single 16-second countdown and printed a
/// phase number derived from the remaining time. It never named the phase, never
/// showed the seconds left in it, and the cycle simply stopped after one round.
///
/// This screen uses [BreathingPattern] for the rhythm, counts the ticks the
/// scheduler really delivers, shows which phase is active and how much of it is
/// left, and records the seconds practised for today. It is a relaxation
/// exercise, not a treatment, and it says so.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';

import '../../../core/models/breathing_pattern.dart';
import '../../../core/services/daily_log.dart';

/// The breathing and relaxation screen.
class BreathingScreen extends StatefulWidget {
  /// Create the screen.
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  static const Duration _tick = Duration(milliseconds: 200);

  BreathingPattern _pattern = BreathingPattern.all.first;
  int _minutes = 3;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _running = false;
  int _todaySeconds = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadToday() async {
    int seconds = 0;
    try {
      seconds = await DailyLog.counter(DailyLog.breathingSeconds);
    } catch (_) {
      seconds = 0;
    }
    if (!mounted) return;
    setState(() {
      _todaySeconds = seconds;
      _loading = false;
    });
  }

  Duration get _sessionLength => Duration(minutes: _minutes);

  void _start() {
    if (_running) return;
    if (_elapsed >= _sessionLength) _elapsed = Duration.zero;
    setState(() => _running = true);
    _timer = Timer.periodic(_tick, (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      bool completed = false;
      setState(() {
        _elapsed += _tick;
        if (_elapsed >= _sessionLength) {
          _elapsed = _sessionLength;
          _running = false;
          completed = true;
        }
      });
      if (completed) {
        timer.cancel();
        _timer = null;
        unawaited(_saveSession());
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _running = false);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _timer = null;
    setState(() => _running = false);
    await _saveSession();
  }

  void _discard() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _elapsed = Duration.zero;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session discarded. Nothing was recorded.')),
    );
  }

  Future<void> _saveSession() async {
    final int seconds = _elapsed.inSeconds;
    if (seconds <= 0) return;
    final int next = _todaySeconds + seconds;
    await DailyLog.setCounter(DailyLog.breathingSeconds, next);
    if (!mounted) return;
    setState(() {
      _todaySeconds = next;
      _elapsed = Duration.zero;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recorded ${_formatDuration(Duration(seconds: seconds))} of breathing.',
        ),
      ),
    );
  }

  void _choosePattern(BreathingPattern pattern) {
    if (_running) _pause();
    setState(() {
      _pattern = pattern;
      _elapsed = Duration.zero;
    });
  }

  void _chooseMinutes(int minutes) {
    if (_running) _pause();
    setState(() {
      _minutes = minutes;
      _elapsed = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breathing & relaxation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DsPage(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BreathMoment moment = _pattern.momentAt(_elapsed);
    final int remainingPhase =
        (moment.remainingInPhase.inMilliseconds / 1000).ceil();
    final double sessionProgress =
        (_elapsed.inMilliseconds / _sessionLength.inMilliseconds)
            .clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DsSection(
          title: 'Choose a rhythm',
          subtitle: 'Each pattern repeats until the session ends.',
          child: DsCard(
            child: Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                for (final BreathingPattern pattern in BreathingPattern.all)
                  ChoiceChip(
                    label: Text(pattern.name),
                    selected: pattern.id == _pattern.id,
                    onSelected: (bool selected) {
                      if (selected) _choosePattern(pattern);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: _pattern.name,
          subtitle: _pattern.description,
          child: DsCard(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 250,
                  child: Center(
                    child: AnimatedContainer(
                      duration: _tick,
                      width: _circleSize(moment),
                      height: _circleSize(moment),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            theme.colorScheme.primary.withValues(alpha: 0.85),
                            theme.colorScheme.primary.withValues(alpha: 0.35),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              moment.phase.kind.label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              '$remainingPhase',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (moment.phase.note.isNotEmpty)
                  Text(
                    moment.phase.note,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: Space.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Cycle ${moment.cycle + 1}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(width: Space.md),
                    Text(
                      '${_formatDuration(_elapsed)} of '
                      '${_formatDuration(_sessionLength)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: sessionProgress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _running ? _pause : _start,
                      icon: Icon(
                        _running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      label: Text(_running ? 'Pause' : 'Start'),
                    ),
                    OutlinedButton(
                      onPressed: _elapsed.inSeconds == 0 ? null : _finish,
                      child: const Text('Finish & save'),
                    ),
                    TextButton(
                      onPressed: _elapsed.inSeconds == 0 ? null : _discard,
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Session length',
          subtitle: 'The timer stops itself at the chosen length.',
          child: DsSegmented<int>(
            value: _minutes,
            options: const <DsSegment<int>>[
              DsSegment<int>(value: 1, label: '1 min'),
              DsSegment<int>(value: 3, label: '3 min'),
              DsSegment<int>(value: 5, label: '5 min'),
              DsSegment<int>(value: 10, label: '10 min'),
            ],
            onChanged: _chooseMinutes,
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Practised today',
          subtitle: 'Seconds recorded on this phone.',
          child: DsCard(
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.self_improvement_outlined,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    _todaySeconds == 0
                        ? 'Nothing recorded yet today.'
                        : '${_formatDuration(Duration(seconds: _todaySeconds))} '
                            'recorded today.',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xxl),
        DsSection(
          title: 'Before you start',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Sit comfortably and breathe through your nose unless the '
                  'pattern says otherwise. Stop if you feel dizzy, light-headed '
                  'or short of breath.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'This is a relaxation exercise, not a treatment for a '
                  'condition. It does not measure your breathing or your '
                  'oxygen level.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'The timer counts while this screen is open and stops when '
                  'you leave it. Only sessions you finish or save are added to '
                  'today\'s total.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static double _circleSize(BreathMoment moment) {
    const double small = 130;
    const double large = 230;
    return switch (moment.phase.kind) {
      BreathPhaseKind.inhale => small + (large - small) * moment.progress,
      BreathPhaseKind.exhale => large - (large - small) * moment.progress,
      BreathPhaseKind.hold => 180,
    };
  }

  static String _formatDuration(Duration value) {
    final int total = value.inSeconds;
    final int minutes = total ~/ 60;
    final int seconds = total % 60;
    if (minutes == 0) return '${seconds}s';
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }
}
