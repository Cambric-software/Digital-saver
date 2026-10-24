/// Milestones counted from the watch history stored on this phone.
///
/// The previous version was a fixed set of eight badges with hard-coded
/// `isLocked` and `isNew` flags, "+100 XP" values that nothing awarded, and a
/// header that read "3/8 Unlocked" from those literals. Two of the badges
/// described data the app cannot measure: "Sleep Well" (8+ hours of sleep for
/// five nights - this watch reports no sleep at all) and "Health Hero" (a
/// health score above 90 for 30 days - that score is computed from live
/// readings and never stored). "First Sync" was unlocked unconditionally,
/// including for someone who had never paired a watch, and "Week Warrior" was
/// marked new regardless of use. Every badge also floated on a looping
/// animation with a coloured shadow.
///
/// This version computes milestones from [WatchSample]s that are actually
/// stored: how many exist, which days they fall on, whether a run of days is
/// consecutive, and whether any sample records 10,000 steps, an oxygen reading,
/// heart-rate variability or a reading before 07:00. With no history it says
/// that nothing has been counted instead of showing a pre-filled badge case.
library;

import 'package:flutter/material.dart';

import '../../../core/services/local_store.dart';
import '../../../core/services/veyro_protocol.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';

/// Distinct local calendar days that contain at least one sample.
///
/// Days are returned as UTC midnight so that a daylight-saving change cannot
/// turn a 23-hour day into a non-consecutive one.
List<DateTime> recordingDays(List<WatchSample> samples) {
  final Set<DateTime> days = <DateTime>{
    for (final WatchSample sample in samples) _dayOf(sample.at),
  };
  final List<DateTime> sorted = days.toList()..sort();
  return sorted;
}

/// The longest run of consecutive days in [days].
int longestDayStreak(Iterable<DateTime> days) {
  final List<DateTime> sorted = _sortedDays(days);
  var longest = 0;
  var run = 0;
  DateTime? previous;

  for (final DateTime day in sorted) {
    run = previous != null && day.difference(previous).inDays == 1 ? run + 1 : 1;
    if (run > longest) longest = run;
    previous = day;
  }
  return longest;
}

/// The run of consecutive days ending today or yesterday, or 0.
///
/// Ending yesterday still counts: a person who has not synced yet today has not
/// broken the run. A run that ended two days ago is over.
int currentDayStreak(Iterable<DateTime> days, {DateTime? asOf}) {
  final List<DateTime> sorted = _sortedDays(days);
  if (sorted.isEmpty) return 0;

  final DateTime today = _dayOf(asOf ?? DateTime.now());
  final int gap = today.difference(sorted.last).inDays;
  if (gap < 0 || gap > 1) return 0;

  var streak = 1;
  for (var i = sorted.length - 1; i > 0; i--) {
    if (sorted[i].difference(sorted[i - 1]).inDays != 1) break;
    streak++;
  }
  return streak;
}

/// One milestone and the count that decides it.
class Milestone {
  /// Create a milestone.
  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.progress,
  });

  /// Stable identifier, used by tests.
  final String id;

  /// Short name.
  final String title;

  /// What has to be stored for this to count, in plain words.
  final String description;

  /// Icon for the milestone.
  final IconData icon;

  /// The count needed. Always at least one.
  final int target;

  /// The count reached so far. May exceed [target].
  final int progress;

  /// Whether the count has reached [target].
  bool get earned => progress >= target;

  /// Progress as a fraction, clamped for a progress bar.
  double get fraction => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  /// Progress as it should be shown: never more than the target.
  int get shownProgress => progress > target ? target : progress;
}

/// Every milestone, computed from stored samples.
List<Milestone> milestonesFor(List<WatchSample> samples) {
  final List<DateTime> days = recordingDays(samples);
  final int longest = longestDayStreak(days);
  final bool beforeSeven = samples.any(
    (WatchSample sample) => sample.hr > 0 && sample.at.hour < 7,
  );
  final bool hasOxygen = samples.any(
    (WatchSample sample) => sample.spo2 > 0,
  );
  final bool hasHrv = samples.any(
    (WatchSample sample) => sample.hrv > 0,
  );
  final bool tenThousandSteps = samples.any(
    (WatchSample sample) => sample.steps >= 10000,
  );

  return <Milestone>[
    Milestone(
      id: 'first_reading',
      title: 'First reading',
      description: 'At least one sample stored from the watch.',
      icon: Icons.looks_one_rounded,
      target: 1,
      progress: samples.isEmpty ? 0 : 1,
    ),
    Milestone(
      id: 'hundred_readings',
      title: 'One hundred readings',
      description: '100 samples stored. The watch writes about one a minute '
          'while it sees a pulse or steps.',
      icon: Icons.auto_stories_outlined,
      target: 100,
      progress: samples.length,
    ),
    Milestone(
      id: 'seven_days',
      title: 'Seven recorded days',
      description: 'Samples on 7 different days.',
      icon: Icons.calendar_month_outlined,
      target: 7,
      progress: days.length,
    ),
    Milestone(
      id: 'thirty_days',
      title: 'Thirty recorded days',
      description: 'Samples on 30 different days.',
      icon: Icons.calendar_view_month_outlined,
      target: 30,
      progress: days.length,
    ),
    Milestone(
      id: 'three_day_streak',
      title: 'Three days in a row',
      description: 'Samples on 3 consecutive days.',
      icon: Icons.local_fire_department_outlined,
      target: 3,
      progress: longest,
    ),
    Milestone(
      id: 'seven_day_streak',
      title: 'A full week',
      description: 'Samples on 7 consecutive days.',
      icon: Icons.whatshot_rounded,
      target: 7,
      progress: longest,
    ),
    Milestone(
      id: 'early_reading',
      title: 'Before seven',
      description: 'A stored heart-rate reading taken before 07:00.',
      icon: Icons.wb_twilight_rounded,
      target: 1,
      progress: beforeSeven ? 1 : 0,
    ),
    Milestone(
      id: 'oxygen_reading',
      title: 'Oxygen recorded',
      description: 'A stored sample that carries an oxygen saturation.',
      icon: Icons.air_rounded,
      target: 1,
      progress: hasOxygen ? 1 : 0,
    ),
    Milestone(
      id: 'step_ten_thousand',
      title: 'Ten thousand steps',
      description: 'A stored sample reporting 10,000 steps or more. The watch '
          'resets its counter when it reboots.',
      icon: Icons.directions_walk_rounded,
      target: 1,
      progress: tenThousandSteps ? 1 : 0,
    ),
    Milestone(
      id: 'hrv_reading',
      title: 'Variability recorded',
      description: 'A stored sample that carries heart-rate variability.',
      icon: Icons.monitor_heart_outlined,
      target: 1,
      progress: hasHrv ? 1 : 0,
    ),
  ];
}

DateTime _dayOf(DateTime time) => DateTime.utc(time.year, time.month, time.day);

List<DateTime> _sortedDays(Iterable<DateTime> days) {
  final Set<DateTime> unique = <DateTime>{
    for (final DateTime day in days) _dayOf(day),
  };
  final List<DateTime> sorted = unique.toList()..sort();
  return sorted;
}

/// Milestones, counted from stored history.
class AchievementsScreen extends StatefulWidget {
  /// Create the progress view.
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
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
    final ThemeData theme = Theme.of(context);
    final List<Milestone> milestones = milestonesFor(_samples);
    final int earned =
        milestones.where((Milestone milestone) => milestone.earned).length;
    final int streak = currentDayStreak(recordingDays(_samples));

    return DsSection(
      title: 'Milestones',
      subtitle: 'Counted from the watch history stored on this phone',
      trailing: IconButton(
        tooltip: 'Reload stored history',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: _loading
          ? const _LoadingCard(label: 'Counting stored samples…')
          : _error != null
              ? _UnreadableHistory(error: _error!)
              : _samples.isEmpty
                  ? const _NothingCountedYet()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DsCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(Space.sm),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius:
                                      BorderRadius.circular(Radii.md),
                                ),
                                child: Icon(
                                  Icons.emoji_events_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: Space.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '$earned of ${milestones.length} reached',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: Space.xxs),
                                    Text(
                                      _samples.length == 1
                                          ? '1 stored sample. Live readings '
                                              'count once the watch stores them.'
                                          : '${_samples.length} stored samples. '
                                              'Live readings count once the '
                                              'watch stores them.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (streak > 0) ...<Widget>[
                                      const SizedBox(height: Space.xxs),
                                      Text(
                                        'Current recording streak: '
                                        '${streak == 1 ? '1 day' : '$streak days'}.',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.xl),
                        DsGrid(
                          minTileWidth: 280,
                          children: <Widget>[
                            for (final Milestone milestone in milestones)
                              _MilestoneCard(milestone: milestone),
                          ],
                        ),
                        const SizedBox(height: Space.xl),
                        DsCard(
                          color: theme.colorScheme.surfaceContainerLow,
                          child: Text(
                            'Every count on this page comes from samples '
                            'stored by the watch. Nothing is awarded for '
                            'opening the app, and no milestone claims a medical '
                            'outcome. History older than '
                            '${VeyroProtocol.retainDays} days is deleted, so '
                            'the longest streak and the largest day count can '
                            'fall over time.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
    );
  }
}

/// One milestone card.
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool earned = milestone.earned;

    return DsCard(
      color: earned ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: earned
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(
                  milestone.icon,
                  size: 20,
                  color: earned
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(milestone.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: Space.xxs),
                    Text(
                      earned ? 'Reached' : 'Not yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: earned
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(milestone.description, style: theme.textTheme.bodySmall),
          if (milestone.target > 1) ...<Widget>[
            const SizedBox(height: Space.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: milestone.fraction,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  earned
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              '${milestone.shownProgress} of ${milestone.target}',
              style: theme.textTheme.labelMedium,
            ),
          ],
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
            '($error). No milestone is shown rather than marking one reached '
            'without evidence.',
      ),
    );
  }
}

/// Nothing has been stored, so nothing is counted.
class _NothingCountedYet extends StatelessWidget {
  const _NothingCountedYet();

  @override
  Widget build(BuildContext context) {
    return const DsCard(
      child: DsEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Nothing counted yet',
        message: 'Milestones are counted from the samples the watch stores. '
            'Pair the watch and let its memory sync, then come back. Nothing '
            'here is filled in ahead of your data.',
      ),
    );
  }
}
