/// Guided breathing patterns and the maths that drives them.
///
/// A breathing exercise is only useful if the phase on screen matches the
/// seconds actually spent. The previous app had a box-breathing card built on a
/// countdown that ran one 16-second timer and printed "Phase 1–4" from the
/// remaining time; it never said which phase you were in or how long was left
/// in it.
///
/// [BreathingPattern.phaseAt] answers exactly that: given time practised, it
/// returns the current phase, its index, how much of it is left and how far
/// through it is. It is pure and clock-free, so the widget and the tests agree
/// on the same seconds.
library;

/// What the body should be doing during a phase.
enum BreathPhaseKind {
  /// Breathe in through the nose.
  inhale('Breathe in'),

  /// Hold after an inhale, or after an exhale.
  hold('Hold'),

  /// Breathe out slowly.
  exhale('Breathe out');

  const BreathPhaseKind(this.label);

  /// Wording shown on screen.
  final String label;
}

/// One phase of a breathing cycle.
class BreathPhase {
  /// Create a phase.
  const BreathPhase(this.kind, this.seconds, {this.note = ''});

  /// In, hold or out.
  final BreathPhaseKind kind;

  /// How long the phase lasts.
  final int seconds;

  /// Optional coaching line, e.g. `Through the nose`.
  final String note;

  /// The phase as a duration.
  Duration get duration => Duration(seconds: seconds);
}

/// The state of a pattern at one moment.
class BreathMoment {
  /// Create a moment.
  const BreathMoment({
    required this.phase,
    required this.index,
    required this.elapsedInPhase,
    required this.remainingInPhase,
    required this.cycle,
    required this.cyclePosition,
  });

  /// The phase being practised.
  final BreathPhase phase;

  /// Zero-based index of [phase] within the cycle.
  final int index;

  /// Time already spent in this phase.
  final Duration elapsedInPhase;

  /// Time left in this phase.
  final Duration remainingInPhase;

  /// Number of completed cycles at this moment.
  final int cycle;

  /// Position within the current cycle.
  final Duration cyclePosition;

  /// How far through the phase, from 0 to 1.
  double get progress {
    final int total = phase.seconds * 1000;
    if (total <= 0) return 1;
    return (elapsedInPhase.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

/// A named sequence of phases that repeats.
class BreathingPattern {
  /// Create a pattern.
  const BreathingPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.phases,
  });

  /// Stable identifier used by the screen.
  final String id;

  /// Short name, e.g. `Box`.
  final String name;

  /// One line explaining the rhythm.
  final String description;

  /// The phases, in order.
  final List<BreathPhase> phases;

  /// One full cycle.
  Duration get cycleDuration => Duration(
        seconds:
            phases.fold<int>(0, (int sum, BreathPhase p) => sum + p.seconds),
      );

  /// The state at [elapsed] since the session started.
  BreathMoment momentAt(Duration elapsed) {
    final int cycleMs = cycleDuration.inMilliseconds;
    final int safeMs = elapsed.inMilliseconds < 0 ? 0 : elapsed.inMilliseconds;
    final int cycle = cycleMs <= 0 ? 0 : safeMs ~/ cycleMs;
    final int positionMs = cycleMs <= 0 ? 0 : safeMs % cycleMs;
    int consumed = 0;
    for (int i = 0; i < phases.length; i++) {
      final BreathPhase phase = phases[i];
      final int phaseMs = phase.seconds * 1000;
      if (positionMs < consumed + phaseMs || i == phases.length - 1) {
        final int inPhase = positionMs - consumed;
        final int clamped = inPhase.clamp(0, phaseMs);
        return BreathMoment(
          phase: phase,
          index: i,
          elapsedInPhase: Duration(milliseconds: clamped),
          remainingInPhase: Duration(milliseconds: phaseMs - clamped),
          cycle: cycle,
          cyclePosition: Duration(milliseconds: positionMs),
        );
      }
      consumed += phaseMs;
    }
    return BreathMoment(
      phase: phases.first,
      index: 0,
      elapsedInPhase: Duration.zero,
      remainingInPhase: phases.first.duration,
      cycle: cycle,
      cyclePosition: Duration.zero,
    );
  }

  /// The patterns offered by the app.
  ///
  /// These are common relaxation rhythms, not medical protocols. The screen says
  /// so, and says to stop if the person feels dizzy.
  static const List<BreathingPattern> all = <BreathingPattern>[
    BreathingPattern(
      id: 'box',
      name: 'Box',
      description: 'Four seconds in, four hold, four out, four hold.',
      phases: <BreathPhase>[
        BreathPhase(BreathPhaseKind.inhale, 4, note: 'Through the nose'),
        BreathPhase(BreathPhaseKind.hold, 4),
        BreathPhase(BreathPhaseKind.exhale, 4, note: 'Through the mouth'),
        BreathPhase(BreathPhaseKind.hold, 4),
      ],
    ),
    BreathingPattern(
      id: '478',
      name: '4-7-8',
      description: 'Four in, seven hold, eight out.',
      phases: <BreathPhase>[
        BreathPhase(BreathPhaseKind.inhale, 4, note: 'Through the nose'),
        BreathPhase(BreathPhaseKind.hold, 7),
        BreathPhase(BreathPhaseKind.exhale, 8, note: 'Slow and quiet'),
      ],
    ),
    BreathingPattern(
      id: 'coherent',
      name: 'Coherent',
      description: 'Five seconds in, five seconds out, no hold.',
      phases: <BreathPhase>[
        BreathPhase(BreathPhaseKind.inhale, 5, note: 'Through the nose'),
        BreathPhase(BreathPhaseKind.exhale, 5, note: 'Through the mouth'),
      ],
    ),
    BreathingPattern(
      id: 'calm',
      name: 'Calm',
      description: 'Four in, two hold, six out.',
      phases: <BreathPhase>[
        BreathPhase(BreathPhaseKind.inhale, 4, note: 'Through the nose'),
        BreathPhase(BreathPhaseKind.hold, 2),
        BreathPhase(BreathPhaseKind.exhale, 6, note: 'Longer than the inhale'),
      ],
    ),
    BreathingPattern(
      id: 'reset',
      name: 'Quick reset',
      description: 'Three in, one hold, three out.',
      phases: <BreathPhase>[
        BreathPhase(BreathPhaseKind.inhale, 3),
        BreathPhase(BreathPhaseKind.hold, 1),
        BreathPhase(BreathPhaseKind.exhale, 3),
      ],
    ),
  ];
}
