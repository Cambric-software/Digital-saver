/// The medication list, its schedule and today's doses.
///
/// The stored model used to be a name and a dose, with a comment saying there
/// was no schedule, no reminder and no interval. This screen is where a schedule
/// is written down and where a dose is ticked off, and the times entered here
/// are the same ones the notification scheduler turns into reminders.
///
/// It deliberately does not calculate a next dose, a maximum daily dose or an
/// interaction. The app has no pharmacological data, so it shows the times the
/// person entered and says plainly that the list is theirs, not a prescription.
library;

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';

import '../../../core/models/reminder.dart';
import '../../../core/services/daily_log.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';

/// The medication list and today's doses.
class MedicationsScreen extends StatefulWidget {
  /// Create the screen.
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  bool _loading = true;
  String? _loadError;
  List<Medication> _medications = <Medication>[];
  Map<String, DateTime?> _taken = <String, DateTime?>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Medication> stored = await StorageService.medications();
      final DateTime now = DateTime.now();
      final Map<String, DateTime?> taken = <String, DateTime?>{};
      for (final Medication medication in stored) {
        if (!medication.appliesOn(now.weekday)) continue;
        for (final String time in medication.times) {
          final String key = _doseKey(medication, time);
          taken[key] = await DailyLog.time(key);
        }
      }
      if (!mounted) return;
      setState(() {
        _medications = stored;
        _taken = taken;
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

  static String _doseKey(Medication medication, String time) =>
      'med_${medication.id}_$time';

  Future<void> _store(List<Medication> next) async {
    await StorageService.setMedications(next);
    if (!mounted) return;
    setState(() => _medications = List<Medication>.unmodifiable(next));
    await NotificationService.instance.syncFromStorage();
    await _load();
  }

  Future<void> _markTaken(
    Medication medication,
    String time, {
    required bool taken,
  }) async {
    final String key = _doseKey(medication, time);
    final DateTime? now = taken ? DateTime.now() : null;
    await DailyLog.setTime(key, now);
    if (!mounted) return;
    setState(() {
      final Map<String, DateTime?> next = Map<String, DateTime?>.of(_taken);
      next[key] = now;
      _taken = next;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          taken
              ? '${medication.name} at $time marked taken.'
              : '${medication.name} at $time is no longer marked taken.',
        ),
      ),
    );
  }

  Future<void> _edit([Medication? existing]) async {
    final Medication? result = await showDialog<Medication>(
      context: context,
      builder: (BuildContext context) => _MedicationDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    final List<Medication> next = List<Medication>.of(_medications);
    final int index =
        next.indexWhere((Medication entry) => entry.id == result.id);
    if (index >= 0) {
      next[index] = result;
    } else {
      next.add(result);
    }
    await _store(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isScheduled
              ? '${result.name} saved with ${result.times.length} '
                  'time${result.times.length == 1 ? '' : 's'}.'
              : '${result.name} saved without a time, so no reminder is '
                  'scheduled.',
        ),
      ),
    );
  }

  Future<void> _delete(Medication medication) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove this medication?'),
        content: Text(
          '${medication.name} and its schedule will be removed. Doses already '
          'marked today are kept in today\'s log.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store(
      _medications
          .where((Medication entry) => entry.id != medication.id)
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add',
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DsPage(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final List<_Dose> doses = _dosesFor(now);
    final int dueSoFar =
        doses.where((_Dose dose) => !dose.at.isAfter(now)).length;
    final int takenSoFar = doses
        .where((_Dose dose) =>
            !dose.at.isAfter(now) &&
            _taken[_doseKey(dose.medication, dose.time)] != null)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_loadError != null) ...<Widget>[
          DsCard(
            child: Text(
              'Your medication list could not be read: $_loadError',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
        DsSection(
          title: 'Today\'s doses',
          subtitle: 'Times you entered, in the order they fall. Nothing is '
              'calculated for you.',
          trailing: doses.isEmpty
              ? null
              : Text(
                  '$takenSoFar of $dueSoFar due so far',
                  style: theme.textTheme.bodySmall,
                ),
          child: doses.isEmpty
              ? DsCard(
                  child: DsEmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No doses scheduled for today',
                    message: _medications.isEmpty
                        ? 'Add a medication and the times you take it. Those '
                            'times become reminders on this phone.'
                        : 'None of your medications has a time that applies '
                            'today. Add a time to one to see it here.',
                    action: FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add a medication'),
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    for (final _Dose dose in doses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: _DoseTile(
                          dose: dose,
                          taken: _taken[_doseKey(dose.medication, dose.time)],
                          now: now,
                          onTaken: (bool taken) => _markTaken(
                            dose.medication,
                            dose.time,
                            taken: taken,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Your list',
          subtitle: '${_medications.length} '
              '${_medications.length == 1 ? 'entry' : 'entries'}',
          trailing: OutlinedButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
          child: _medications.isEmpty
              ? DsCard(
                  child: DsEmptyState(
                    icon: Icons.playlist_add_outlined,
                    title: 'Your list is empty',
                    message:
                        'Add only what you actually take. The app does not '
                        'suggest products or doses.',
                    action: FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add the first one'),
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    for (final Medication medication in _medications)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: _MedicationTile(
                          medication: medication,
                          onEdit: () => _edit(medication),
                          onDelete: () => _delete(medication),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Space.xxl),
        DsSection(
          title: 'Please read',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'This is your own list, not a prescription. Digital Saver '
                  'does not check doses, interactions or missed doses, and it '
                  'does not tell you what to take.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Follow the instructions from your clinician or pharmacist. '
                  'If a dose is missed, follow their advice rather than a '
                  'number on this screen.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Reminders are delivered by the phone and can arrive a few '
                  'minutes late. The watch does not receive this list.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_Dose> _dosesFor(DateTime day) {
    final List<_Dose> doses = <_Dose>[];
    for (final Medication medication in _medications) {
      for (final DateTime at in medication.dueOn(day)) {
        final String time = '${at.hour.toString().padLeft(2, '0')}:'
            '${at.minute.toString().padLeft(2, '0')}';
        doses.add(_Dose(medication: medication, time: time, at: at));
      }
    }
    doses.sort((_Dose a, _Dose b) => a.at.compareTo(b.at));
    return doses;
  }
}

/// One scheduled dose.
class _Dose {
  const _Dose({
    required this.medication,
    required this.time,
    required this.at,
  });

  final Medication medication;
  final String time;
  final DateTime at;
}

/// A dose row with its taken state.
class _DoseTile extends StatelessWidget {
  const _DoseTile({
    required this.dose,
    required this.taken,
    required this.now,
    required this.onTaken,
  });

  final _Dose dose;
  final DateTime? taken;
  final DateTime now;
  final ValueChanged<bool> onTaken;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isTaken = taken != null;
    final bool isPast = !dose.at.isAfter(now);
    final Color statusColor = isTaken
        ? theme.colorScheme.secondary
        : isPast
            ? theme.colorScheme.tertiary
            : theme.colorScheme.onSurfaceVariant;
    final String status;
    if (isTaken) {
      status = 'Taken at ${_hhmm(taken!)}';
    } else if (isPast) {
      status = 'Due at ${dose.time}';
    } else {
      status = 'Later at ${dose.time}';
    }

    return DsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isTaken
                ? Icons.check_circle_outline_rounded
                : Icons.medication_outlined,
            size: 22,
            color: statusColor,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      dose.time,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        dose.medication.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (dose.medication.dose.trim().isNotEmpty)
                  Text(
                    dose.medication.dose,
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: Space.xxs),
                Text(
                  status,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          isTaken
              ? TextButton(
                  onPressed: () => onTaken(false),
                  child: const Text('Undo'),
                )
              : FilledButton(
                  onPressed: () => onTaken(true),
                  child: const Text('Taken'),
                ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

/// One entry in the medication list.
class _MedicationTile extends StatelessWidget {
  const _MedicationTile({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
  });

  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            medication.isScheduled
                ? Icons.alarm_on_outlined
                : Icons.alarm_off_outlined,
            size: 22,
            color: medication.isScheduled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(medication.name, style: theme.textTheme.titleMedium),
                if (medication.dose.trim().isNotEmpty)
                  Text(medication.dose, style: theme.textTheme.bodySmall),
                const SizedBox(height: Space.xxs),
                Text(
                  medication.isScheduled
                      ? '${medication.timesLabel} آ· ${medication.repeatLabel}'
                      : 'No times set â€” no reminder is scheduled.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: medication.isScheduled
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (medication.notes.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: Space.xxs),
                  Text(medication.notes, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Medication actions',
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              PopupMenuItem<String>(value: 'delete', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}

/// The add/edit form.
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
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  late List<String> _times =
      List<String>.of(widget.existing?.times ?? <String>[]);
  late String _repeat;
  late Set<int> _days;
  String? _error;

  @override
  void initState() {
    super.initState();
    final Medication? existing = widget.existing;
    _days = <int>{...?existing?.days};
    if (existing == null || existing.days.isEmpty) {
      _repeat = 'daily';
      _days = <int>{1, 2, 3, 4, 5, 6, 7};
    } else if (_days.length == 7) {
      _repeat = 'daily';
    } else if (_days.length == 5 &&
        _days.containsAll(const <int>[1, 2, 3, 4, 5])) {
      _repeat = 'weekdays';
    } else if (_days.length == 2 && _days.containsAll(const <int>[6, 7])) {
      _repeat = 'weekends';
    } else {
      _repeat = 'custom';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final TimeOfDay? chosen = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Time to take it',
    );
    if (chosen == null) return;
    final String value = '${chosen.hour.toString().padLeft(2, '0')}:'
        '${chosen.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_times.contains(value)) {
        _times = <String>[..._times, value]..sort();
      }
    });
  }

  void _changeRepeat(String? value) {
    if (value == null) return;
    setState(() {
      _repeat = value;
      switch (value) {
        case 'daily':
          _days = <int>{1, 2, 3, 4, 5, 6, 7};
          break;
        case 'weekdays':
          _days = <int>{1, 2, 3, 4, 5};
          break;
        case 'weekends':
          _days = <int>{6, 7};
          break;
        case 'custom':
          if (_days.isEmpty) _days = <int>{1, 2, 3, 4, 5, 6, 7};
          break;
      }
    });
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the medication a name.');
      return;
    }
    if (_repeat == 'custom' && _days.isEmpty) {
      setState(() => _error = 'Choose at least one day.');
      return;
    }
    final List<int> days = _days.toList()..sort();
    final Medication medication = Medication(
      id: widget.existing?.id ?? Medication.newId(),
      name: name,
      dose: _dose.text.trim(),
      notes: _notes.text.trim(),
      times: List<String>.unmodifiable(_times..sort()),
      days: days.length == 7 ? const <int>[] : List<int>.unmodifiable(days),
    );
    Navigator.pop(context, medication);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add a medication' : 'Edit medication',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'What you actually take',
                ),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _dose,
                decoration: const InputDecoration(
                  labelText: 'Dose or strength (optional)',
                  hintText: 'For example, 500 mg or 1 tablet',
                ),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'With food, before bed',
                ),
              ),
              const SizedBox(height: Space.lg),
              DsLabel('Times', color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: Space.xs),
              if (_times.isEmpty)
                Text(
                  'No times yet. Without a time, this is a note and no '
                  'reminder is scheduled.',
                  style: theme.textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: <Widget>[
                    for (final String time in _times)
                      InputChip(
                        label: Text(time),
                        onDeleted: () => setState(() => _times.remove(time)),
                      ),
                  ],
                ),
              const SizedBox(height: Space.xs),
              OutlinedButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add_alarm_outlined, size: 18),
                label: const Text('Add a time'),
              ),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String>(
                initialValue: _repeat,
                decoration: const InputDecoration(labelText: 'Applies on'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'daily',
                    child: Text('Every day'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'weekdays',
                    child: Text('Weekdays'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'weekends',
                    child: Text('Weekends'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'custom',
                    child: Text('Choose days'),
                  ),
                ],
                onChanged: _changeRepeat,
              ),
              if (_repeat == 'custom') ...<Widget>[
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: <Widget>[
                    for (int day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(shortDayName(day)),
                        selected: _days.contains(day),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _days.add(day);
                            } else {
                              _days.remove(day);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: Space.sm),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
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
