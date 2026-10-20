/// Timers that do the one thing a stopwatch control must do: keep time.
///
/// The habit cards these replace were buttons that flipped a boolean. "Start
/// Breath Hold" set `_apneaActive = true` and nothing else happened — the
/// seconds never moved, because the `Timer` was created and never started, and
/// the displayed value was whatever it had been initialised to. A timer that
/// does not count is worse than no timer, because the screen looks like it is
/// working.
///
/// Both controls here count the ticks the scheduler actually delivers rather
/// than subtracting wall-clock time, so the number on screen is time spent with
/// the screen open — which is what a 20-second handwash timer is for. It is
/// also what makes them testable: `tester.pump` advances the same clock.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'ds_widgets.dart';

/// How often the controls update. Fast enough to look live, slow enough not to
/// rebuild the screen 60 times a second for a 2-minute timer.
const Duration _tick = Duration(milliseconds: 200);

String _formatDuration(Duration value) {
  final int totalSeconds = value.inSeconds.clamp(0, 359999);
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  final String mmss =
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  return hours > 0 ? '$hours:$mmss' : mmss;
}

/// A reusable countdown from a fixed duration, optionally in steps.
///
/// [steps] exists for the dental timer, where two minutes is four quadrants of
/// thirty seconds, and telling someone which quadrant they are on is the whole
/// feature.
class DsCountdown extends StatefulWidget {
  /// Create a countdown.
  const DsCountdown({
    super.key,
    required this.title,
    required this.icon,
    required this.duration,
    this.description,
    this.steps = 1,
    this.stepLabel = 'Step',
    this.finishedLabel = 'Done',
    this.onFinished,
  });

  /// Card heading.
  final String title;

  /// Card icon.
  final IconData icon;

  /// Total time to count down.
  final Duration duration;

  /// What the timer is for.
  final String? description;

  /// Number of equal parts, e.g. 4 quadrants.
  final int steps;

  /// Word used before the step number.
  final String stepLabel;

  /// Text shown once the countdown reaches zero.
  final String finishedLabel;

  /// Called once when the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<DsCountdown> createState() => _DsCountdownState();
}

class _DsCountdownState extends State<DsCountdown> {
  late Duration _remaining = widget.duration;
  Timer? _timer;

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running || _remaining <= Duration.zero) return;
    setState(() {
      _timer = Timer.periodic(_tick, (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _remaining -= _tick;
          if (_remaining <= Duration.zero) {
            _remaining = Duration.zero;
            timer.cancel();
            _timer = null;
          }
        });
        if (_remaining <= Duration.zero) widget.onFinished?.call();
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _timer = null);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _timer = null;
      _remaining = widget.duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool finished = _remaining <= Duration.zero;
    final double progress = widget.duration.inMilliseconds == 0
        ? 0.0
        : 1 - (_remaining.inMilliseconds / widget.duration.inMilliseconds);

    final int steps = widget.steps < 1 ? 1 : widget.steps;
    final Duration perStep = widget.duration ~/ steps;
    final int step = finished
        ? steps
        : ((widget.duration - _remaining).inMilliseconds ~/
                    (perStep.inMilliseconds == 0 ? 1 : perStep.inMilliseconds))
                .clamp(0, steps - 1) +
            1;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(widget.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleSmall),
              ),
              if (steps > 1)
                DsStatusPill(
                  label: finished
                      ? widget.finishedLabel
                      : '${widget.stepLabel} $step of $steps',
                  color: theme.colorScheme.primary,
                  dense: true,
                ),
            ],
          ),
          if (widget.description != null) ...<Widget>[
            const SizedBox(height: Space.xs),
            Text(widget.description!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                _formatDuration(_remaining),
                style: Type.metricSmall.copyWith(
                  color: finished
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: Space.sm),
              Text('remaining', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                finished ? theme.colorScheme.secondary : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: <Widget>[
              if (finished)
                FilledButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Start again'),
                )
              else
                FilledButton.icon(
                  onPressed: _running ? _pause : _start,
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(_running ? 'Pause' : 'Start'),
                ),
              OutlinedButton(
                onPressed: _remaining == widget.duration ? null : _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A count-up timer, optionally against a target, with an optional record
/// action.
///
/// The breath-hold trainer uses the record action: the value is kept only if it
/// beats the stored best, and the caller is told which of the two stands.
class DsStopwatch extends StatefulWidget {
  /// Create a stopwatch.
  const DsStopwatch({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.target,
    this.reachedLabel = 'Target reached',
    this.recordLabel,
    this.onRecord,
    this.bestSeconds = 0,
    this.bestLabel = 'Best',
    this.onReachTarget,
  });

  /// Card heading.
  final String title;

  /// Card icon.
  final IconData icon;

  /// What the timer is for.
  final String? description;

  /// Optional goal. Past this, the timer keeps counting and says so.
  final Duration? target;

  /// Text shown once the target is passed.
  final String reachedLabel;

  /// Label for the record button, if there is one.
  final String? recordLabel;

  /// Called with the elapsed time when the record button is pressed.
  final ValueChanged<Duration>? onRecord;

  /// Best recorded value, in seconds. Zero means none recorded yet.
  final int bestSeconds;

  /// Word used before the best value.
  final String bestLabel;

  /// Called once when the target is reached.
  final VoidCallback? onReachTarget;

  @override
  State<DsStopwatch> createState() => _DsStopwatchState();
}

class _DsStopwatchState extends State<DsStopwatch> {
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _reached = false;

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() {
      _timer = Timer.periodic(_tick, (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _elapsed += _tick);
        final Duration? target = widget.target;
        if (!_reached && target != null && _elapsed >= target) {
          _reached = true;
          widget.onReachTarget?.call();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _timer = null);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _timer = null;
      _elapsed = Duration.zero;
      _reached = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Duration? target = widget.target;
    final bool hasBest = widget.bestSeconds > 0;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(widget.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleSmall),
              ),
              if (hasBest)
                DsStatusPill(
                  label: '${widget.bestLabel} '
                      '${_formatDuration(Duration(seconds: widget.bestSeconds))}',
                  color: theme.colorScheme.secondary,
                  dense: true,
                ),
            ],
          ),
          if (widget.description != null) ...<Widget>[
            const SizedBox(height: Space.xs),
            Text(widget.description!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                _formatDuration(_elapsed),
                style: Type.metricSmall.copyWith(
                  color: _reached
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: Space.sm),
              Text(
                target == null
                    ? 'elapsed'
                    : _reached
                        ? widget.reachedLabel
                        : 'of ${_formatDuration(target)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (target != null) ...<Widget>[
            const SizedBox(height: Space.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: target.inMilliseconds == 0
                    ? 0.0
                    : (_elapsed.inMilliseconds / target.inMilliseconds)
                        .clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _reached
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _running ? _pause : _start,
                icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(_running ? 'Pause' : 'Start'),
              ),
              if (widget.recordLabel != null)
                OutlinedButton.icon(
                  onPressed: _elapsed <= Duration.zero
                      ? null
                      : () {
                          widget.onRecord?.call(_elapsed);
                          _pause();
                        },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: Text(widget.recordLabel!),
                ),
              OutlinedButton(
                onPressed: _elapsed == Duration.zero ? null : _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
