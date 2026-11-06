/// Alarms and reminders the person sets, stored and scheduled by the phone.
///
/// The app had no alarm screen. The watch firmware describes an alarm
/// characteristic, but nothing in the phone app ever wrote to it, and there was
/// no reminder model at all. This screen adds the missing part in the place it
/// can actually work: the phone's own notification system.
///
/// It is honest about two limits. Timing is approximate on modern Android,
/// because exact alarms need a restricted permission the app does not request.
/// And a desktop build has no notification implementation in the plugin, so the
/// screen says the schedule is saved but nothing will alert there.
library;

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';

import '../../../core/models/reminder.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';

/// The alarm and reminder list.
class RemindersScreen extends StatefulWidget {
  /// Create the screen.
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _loading = true;
  String? _loadError;
  List<Reminder> _reminders = <Reminder>[];
  bool? _permission;
  NotificationSyncResult? _lastSync;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Reminder> stored = await StorageService.reminders();
      final bool? allowed =
          await NotificationService.instance.notificationsEnabled();
      if (!mounted) return;
      setState(() {
        _reminders = stored;
        _permission = allowed;
        _loading = false;
        _loadError = null;
      });
      await _sync(quiet: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _sync({bool quiet = false}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final NotificationSyncResult result =
        await NotificationService.instance.syncFromStorage();
    if (!mounted) return;
    setState(() {
      _lastSync = result;
      _syncing = false;
    });
    if (!quiet) {
      final String message;
      if (result.busy) {
        message = 'A schedule update is already running.';
      } else if (result.error != null) {
        message = result.error!;
      } else if (!result.supported) {
        message = 'Saved. This platform cannot show scheduled notifications.';
      } else {
        message = '${result.scheduled} upcoming alert'
            '${result.scheduled == 1 ? '' : 's'} scheduled.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _requestPermission() async {
    final bool granted =
        await NotificationService.instance.requestPermissions();
    final bool? allowed =
        await NotificationService.instance.notificationsEnabled();
    if (!mounted) return;
    setState(() => _permission = allowed ?? granted);
    if (granted) await _sync(quiet: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Notifications allowed. The schedule is up to date.'
              : 'Notifications are still blocked. You can allow them in the '
                  'phone settings.',
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    final bool shown = await NotificationService.instance.showPreview();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? 'Sent. Check the notification shade.'
              : 'The test notification could not be sent on this device.',
        ),
      ),
    );
  }

  Future<void> _store(List<Reminder> next) async {
    await StorageService.setReminders(next);
    if (!mounted) return;
    setState(() => _reminders = List<Reminder>.unmodifiable(next));
    await _sync(quiet: true);
  }

  Future<void> _addPreset(Reminder preset) async {
    await _store(<Reminder>[..._reminders, preset]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${preset.title} added at ${preset.timeLabel}.')),
    );
  }

  Future<void> _edit([Reminder? existing]) async {
    final Reminder? result = await showDialog<Reminder>(
      context: context,
      builder: (BuildContext context) => _ReminderDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    final List<Reminder> next = List<Reminder>.of(_reminders);
    final int index =
        next.indexWhere((Reminder entry) => entry.id == result.id);
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
          '${result.title} saved for ${result.timeLabel} (${result.repeatLabel}).',
        ),
      ),
    );
  }

  Future<void> _toggle(Reminder reminder, bool enabled) async {
    final List<Reminder> next = _reminders
        .map(
          (Reminder entry) => entry.id == reminder.id
              ? entry.copyWith(enabled: enabled)
              : entry,
        )
        .toList(growable: false);
    await _store(next);
  }

  Future<void> _delete(Reminder reminder) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this reminder?'),
        content: Text(
          '${reminder.title} at ${reminder.timeLabel} will be removed and its '
          'scheduled notification cancelled.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store(
      _reminders
          .where((Reminder entry) => entry.id != reminder.id)
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms & reminders'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add',
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_alarm_outlined),
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
    final List<({Reminder reminder, DateTime? next})> rows =
        _reminders.map((Reminder reminder) {
      return (reminder: reminder, next: reminder.nextOccurrence(now));
    }).toList();
    rows.sort((({Reminder reminder, DateTime? next}) a,
        ({Reminder reminder, DateTime? next}) b) {
      if (a.reminder.enabled != b.reminder.enabled) {
        return a.reminder.enabled ? -1 : 1;
      }
      final DateTime aTime = a.next ?? DateTime(9999);
      final DateTime bTime = b.next ?? DateTime(9999);
      final int byTime = aTime.compareTo(bTime);
      return byTime != 0
          ? byTime
          : a.reminder.title.compareTo(b.reminder.title);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_loadError != null) ...<Widget>[
          DsCard(
            child: Text(
              'Your reminders could not be read: $_loadError',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
        _DeliveryCard(
          permission: _permission,
          lastSync: _lastSync,
          syncing: _syncing,
          onRequest: _requestPermission,
          onTest: _testNotification,
          onSync: () => _sync(),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Your reminders',
          subtitle: 'Sorted by what happens next. Switches save immediately.',
          trailing: _syncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          child: rows.isEmpty
              ? DsCard(
                  child: DsEmptyState(
                    icon: Icons.alarm_outlined,
                    title: 'No alarms or reminders yet',
                    message: 'Set a wake-up alarm, a water prompt or a break. '
                        'Each one is stored on this phone and scheduled with '
                        'the phone\'s notification system.',
                    action: FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add a reminder'),
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    for (final ({Reminder reminder, DateTime? next}) row
                        in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: _ReminderTile(
                          reminder: row.reminder,
                          next: row.next,
                          onToggle: (bool value) =>
                              _toggle(row.reminder, value),
                          onEdit: () => _edit(row.reminder),
                          onDelete: () => _delete(row.reminder),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Add quickly',
          subtitle: 'Presets you can change afterwards.',
          child: DsCard(
            child: Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                ActionChip(
                  avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                  label: const Text('Wake-up alarm'),
                  onPressed: () => _addPreset(
                    Reminder(
                      id: Reminder.newId(),
                      title: 'Wake up',
                      hour: 7,
                      minute: 0,
                      days: const <int>[1, 2, 3, 4, 5, 6, 7],
                      kind: ReminderKind.alarm,
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.water_drop_outlined, size: 18),
                  label: const Text('Drink water'),
                  onPressed: () => _addPreset(
                    Reminder(
                      id: Reminder.newId(),
                      title: 'Drink water',
                      hour: 10,
                      minute: 0,
                      days: const <int>[1, 2, 3, 4, 5, 6, 7],
                      kind: ReminderKind.hydration,
                      body: 'Time for a glass of water.',
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.self_improvement_outlined, size: 18),
                  label: const Text('Stretch break'),
                  onPressed: () => _addPreset(
                    Reminder(
                      id: Reminder.newId(),
                      title: 'Stretch break',
                      hour: 15,
                      minute: 0,
                      days: const <int>[1, 2, 3, 4, 5],
                      kind: ReminderKind.reminder,
                      body: 'Stand up and move for a minute.',
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.nightlight_outlined, size: 18),
                  label: const Text('Wind down'),
                  onPressed: () => _addPreset(
                    Reminder(
                      id: Reminder.newId(),
                      title: 'Wind down',
                      hour: 21,
                      minute: 30,
                      days: const <int>[1, 2, 3, 4, 5, 6, 7],
                      kind: ReminderKind.reminder,
                      body: 'Start getting ready for sleep.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xxl),
        DsSection(
          title: 'About timing',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Reminders are delivered by this phone, not by the watch. '
                  'They are scheduled for the next few weeks and rebuilt '
                  'whenever you open the app or change a time.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Android may deliver a reminder a few minutes late. The app '
                  'asks for normal, battery-friendly scheduling rather than '
                  'the restricted exact-alarm permission.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'This screen does not send anything to a server, and no '
                  'reminder is shared with anyone.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The delivery status and permission controls.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.permission,
    required this.lastSync,
    required this.syncing,
    required this.onRequest,
    required this.onTest,
    required this.onSync,
  });

  final bool? permission;
  final NotificationSyncResult? lastSync;
  final bool syncing;
  final VoidCallback onRequest;
  final VoidCallback onTest;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool supported = NotificationService.platformSupported;

    final Color color;
    final String label;
    final String message;
    if (!supported) {
      color = theme.colorScheme.onSurfaceVariant;
      label = 'Not available here';
      message = 'This platform has no system notification support in the app. '
          'Reminders are saved, but nothing will alert you on this device. '
          'Open Digital Saver on an Android phone or iPhone to use them.';
    } else if (permission == true) {
      color = theme.colorScheme.secondary;
      label = 'Allowed';
      message = 'The phone can show your reminders.';
    } else if (permission == false) {
      color = theme.colorScheme.error;
      label = 'Blocked';
      message = 'Notifications are blocked for Digital Saver. Allow them in '
          'the phone settings, then come back and refresh.';
    } else {
      color = theme.colorScheme.tertiary;
      label = 'Not asked yet';
      message = 'The app needs permission to show notifications. It asks only '
          'when you press the button.';
    }

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DsStatusPill(
                label: label,
                color: color,
                icon: supported
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              const Spacer(),
              if (syncing)
                Text('Updating...', style: theme.textTheme.bodySmall)
              else if (lastSync != null && lastSync!.supported)
                Text(
                  '${lastSync!.scheduled} scheduled',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(message, style: theme.textTheme.bodyMedium),
          if (lastSync?.error != null) ...<Widget>[
            const SizedBox(height: Space.sm),
            Text(
              lastSync!.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (supported) ...<Widget>[
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: <Widget>[
                if (permission != true)
                  FilledButton.icon(
                    onPressed: onRequest,
                    icon: const Icon(Icons.notifications_active_outlined,
                        size: 18),
                    label: const Text('Allow notifications'),
                  ),
                if (permission == true)
                  OutlinedButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Send a test'),
                  ),
                TextButton(
                  onPressed: syncing ? null : onSync,
                  child: const Text('Update schedule'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One reminder row.
class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.next,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Reminder reminder;
  final DateTime? next;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final IconData icon = switch (reminder.kind) {
      ReminderKind.alarm => Icons.alarm_rounded,
      ReminderKind.hydration => Icons.water_drop_outlined,
      ReminderKind.reminder => Icons.notifications_outlined,
    };

    return DsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 22,
              color: reminder.enabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
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
                      reminder.timeLabel,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: reminder.enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  reminder.repeatLabel,
                  style: theme.textTheme.bodySmall,
                ),
                if (reminder.body.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: Space.xxs),
                  Text(
                    reminder.body,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: Space.xxs),
                Text(
                  _nextLabel(reminder, next),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: reminder.enabled
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Column(
            children: <Widget>[
              Switch(
                value: reminder.enabled,
                onChanged: onToggle,
              ),
              PopupMenuButton<String>(
                tooltip: 'Reminder actions',
                onSelected: (String value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _nextLabel(Reminder reminder, DateTime? next) {
    if (!reminder.enabled) return 'Paused';
    if (next == null) {
      return reminder.repeats ? 'No upcoming time' : 'This one has passed';
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(next.year, next.month, next.day);
    final int difference = day.difference(today).inDays;
    final String time = '${next.hour.toString().padLeft(2, '0')}:'
        '${next.minute.toString().padLeft(2, '0')}';
    if (difference == 0) return 'Next today at $time';
    if (difference == 1) return 'Next tomorrow at $time';
    return 'Next ${formatDay(next)} at $time';
  }
}

/// The add/edit form.
class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({this.existing});

  final Reminder? existing;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.existing?.body ?? '');
  late TimeOfDay _time;
  late ReminderKind _kind;
  late String _repeat;
  late Set<int> _days;
  late DateTime _date;
  late bool _vibrate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final Reminder? existing = widget.existing;
    final DateTime now = DateTime.now();
    _time = existing == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: existing.hour, minute: existing.minute);
    _kind = existing?.kind ?? ReminderKind.alarm;
    _vibrate = existing?.vibrate ?? true;
    _days = <int>{...?existing?.days};
    _date = existing?.onceDate ?? now;
    if (existing == null) {
      _repeat = 'daily';
      _days = <int>{1, 2, 3, 4, 5, 6, 7};
    } else if (existing.days.isEmpty) {
      _repeat = 'once';
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
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? chosen = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Reminder time',
    );
    if (chosen != null) setState(() => _time = chosen);
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Reminder date',
    );
    if (chosen != null) setState(() => _date = chosen);
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
        case 'once':
          _days = <int>{};
          break;
      }
    });
  }

  void _save() {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the reminder a name.');
      return;
    }
    if (_repeat == 'custom' && _days.isEmpty) {
      setState(() => _error = 'Choose at least one day.');
      return;
    }
    final List<int> days =
        _repeat == 'once' ? <int>[] : (_days.toList()..sort());
    final DateTime now = DateTime.now();
    if (_repeat == 'once' &&
        !DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute)
            .isAfter(now)) {
      setState(() => _error = 'That time has already passed. Choose a later '
          'date or time.');
      return;
    }
    final String month = _date.month.toString().padLeft(2, '0');
    final String day = _date.day.toString().padLeft(2, '0');
    final Reminder reminder = Reminder(
      id: widget.existing?.id ?? Reminder.newId(),
      title: title,
      hour: _time.hour,
      minute: _time.minute,
      days: days,
      date: _repeat == 'once' ? '${_date.year}-$month-$day' : '',
      kind: _kind,
      body: _body.text.trim(),
      enabled: widget.existing?.enabled ?? true,
      vibrate: _vibrate,
    );
    Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? 'New reminder' : 'Edit reminder'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _title,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Wake up, take a walk, call home',
                ),
              ),
              const SizedBox(height: Space.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_outlined, size: 18),
                      label: Text(
                        '${_time.hour.toString().padLeft(2, '0')}:'
                        '${_time.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: DropdownButtonFormField<ReminderKind>(
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: <DropdownMenuItem<ReminderKind>>[
                        for (final ReminderKind kind in ReminderKind.values)
                          DropdownMenuItem<ReminderKind>(
                            value: kind,
                            child: Text(kind.label),
                          ),
                      ],
                      onChanged: (ReminderKind? value) {
                        if (value != null) setState(() => _kind = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String>(
                initialValue: _repeat,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'once', child: Text('Once')),
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
              if (_repeat == 'once') ...<Widget>[
                const SizedBox(height: Space.md),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(formatDay(_date)),
                ),
              ],
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
              const SizedBox(height: Space.md),
              TextField(
                controller: _body,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'What should the notification say?',
                ),
              ),
              const SizedBox(height: Space.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _vibrate,
                onChanged: (bool value) => setState(() => _vibrate = value),
                title: const Text('Vibrate'),
              ),
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
