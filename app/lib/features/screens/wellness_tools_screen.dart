/// Wellness tools, rebuilt onto the design system and stripped of invented data.
///
/// The previous version read as a feature list rather than a screen: headings
/// were numbered from "1. Daily Hydration Logger (#1)" to "(#20)", and the
/// numbers behind them were mostly decoration. The water count started at three
/// glasses nobody had drunk, the coffee count at one, the step streak at five
/// days, and two badges were permanently "unlocked" beside a card that claimed a
/// distance no one had walked. The emergency card opened pre-filled with a blood
/// type, an allergy list and a phone number that had never been entered.
///
/// Persistence was half done. Water, coffee, stride and the streak were written
/// to `shared_preferences` under one global key each, so yesterday's glasses
/// were still counted today; the ICE details and everything else vanished when
/// the screen closed.
///
/// What is here now: counts that start at zero and are stored per day, an
/// emergency card that stays empty until someone fills it in, box breathing
/// that paces four real four-second phases, a rest countdown that counts, and a
/// stride that is saved and actually used to estimate distance from the watch's
/// step count. The streak and badge card is gone: there is no step history to
/// earn it from.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/ble_service.dart';
import '../../../core/services/daily_log.dart';
import 'package:cambric_design/cambric_design.dart';
import '../../../features/widgets/ds_timers.dart';

/// Everyday wellness habits that are logged, not measured.
class WellnessToolsScreen extends StatefulWidget {
  /// Create the screen.
  const WellnessToolsScreen({super.key});

  @override
  State<WellnessToolsScreen> createState() => _WellnessToolsScreenState();
}

class _WellnessToolsScreenState extends State<WellnessToolsScreen> {
  static const int _goalGlasses = 8;
  static const int _glassMl = 250;

  bool _loading = true;
  String? _loadError;

  int _glasses = 0;
  int _coffees = 0;
  DateTime? _lastCoffee;
  double? _strideCm;
  _IceDetails _ice = const _IceDetails();

  int _restSeconds = 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final int glasses =
          await DailyLog.counter(DailyLog.hydrationGlasses);
      final int coffees = await DailyLog.counter(DailyLog.coffees);
      final DateTime? lastCoffee = await DailyLog.time(DailyLog.lastCoffee);
      final double? stride = await DailyLog.strideCm();
      final _IceDetails ice = await _IceDetails.load();
      if (!mounted) return;
      setState(() {
        _glasses = glasses;
        _coffees = coffees;
        _lastCoffee = lastCoffee;
        _strideCm = stride;
        _ice = ice;
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

  Future<void> _addGlass() async {
    final int next = _glasses + 1;
    setState(() => _glasses = next);
    await DailyLog.setCounter(DailyLog.hydrationGlasses, next);
  }

  Future<void> _removeGlass() async {
    if (_glasses <= 0) return;
    final int next = _glasses - 1;
    setState(() => _glasses = next);
    await DailyLog.setCounter(DailyLog.hydrationGlasses, next);
  }

  Future<void> _resetWater() async {
    setState(() => _glasses = 0);
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 0);
  }

  Future<void> _logCoffee() async {
    final DateTime now = DateTime.now();
    final int next = _coffees + 1;
    setState(() {
      _coffees = next;
      _lastCoffee = now;
    });
    await DailyLog.setCounter(DailyLog.coffees, next);
    await DailyLog.setTime(DailyLog.lastCoffee, now);
  }

  Future<void> _resetCoffee() async {
    setState(() {
      _coffees = 0;
      _lastCoffee = null;
    });
    await DailyLog.setCounter(DailyLog.coffees, 0);
    await DailyLog.setTime(DailyLog.lastCoffee, null);
  }

  Future<void> _setStride(double value) async {
    setState(() => _strideCm = value);
    await DailyLog.setStrideCm(value);
  }

  Future<void> _editIce() async {
    final _IceDetails? next = await showDialog<_IceDetails>(
      context: context,
      builder: (BuildContext ctx) => _IceDialog(existing: _ice),
    );

    if (next == null) return;
    await next.save();
    if (!mounted) return;
    setState(() => _ice = next);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency card saved on this phone.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness tools')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DsPage(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BleService ble = context.watch<BleService>();
    final int steps = ble.activity.steps;
    final double? stride = _strideCm;
    final double? distanceKm =
        stride != null && steps > 0 ? steps * stride / 100000 : null;
    final Color water = AppColors.of(
      AppColors.bpBlue,
      AppColors.darkBp,
      context,
    );
    final Color coffee = AppColors.of(
      AppColors.stepAmber,
      AppColors.darkStep,
      context,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_loadError != null) ...<Widget>[
          DsCard(
            child: Text(
              'Today\'s counts could not be read: $_loadError',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
        DsSection(
          title: 'Hydration today',
          subtitle: '250 ml a glass. The eight-glass line is a general guide, '
              'not a target derived from your data.',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.water_drop_outlined, size: 18, color: water),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        '$_glasses of $_goalGlasses glasses',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${_glasses * _glassMl} ml',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: (_glasses / _goalGlasses).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(water),
                  ),
                ),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _addGlass,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add a glass'),
                    ),
                    OutlinedButton(
                      onPressed: _glasses == 0 ? null : _removeGlass,
                      child: const Text('Remove one'),
                    ),
                    TextButton(
                      onPressed: _glasses == 0 ? null : _resetWater,
                      child: const Text('Reset today'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Emergency card',
          subtitle: 'Only what you enter here. Nothing is sent anywhere.',
          child: _ice.isEmpty
              ? DsCard(
                  child: DsEmptyState(
                    icon: Icons.medical_information_outlined,
                    title: 'No emergency details yet',
                    message: 'Blood type, allergies, a contact and any notes '
                        'worth having to hand. They stay on this phone.',
                    action: FilledButton.icon(
                      onPressed: _editIce,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Add details'),
                    ),
                  ),
                )
              : DsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _IceRow(label: 'Blood type', value: _ice.bloodType),
                      _IceRow(
                        label: 'Emergency contact',
                        value: _ice.contact,
                      ),
                      _IceRow(label: 'Allergies', value: _ice.allergies),
                      _IceRow(label: 'Medical notes', value: _ice.notes),
                      const SizedBox(height: Space.sm),
                      OutlinedButton.icon(
                        onPressed: _editIce,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit details'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: Space.xl),
        const DsSection(
          title: 'Box breathing',
          subtitle: 'Four equal phases: in, hold, out, hold.',
          child: DsCountdown(
            title: 'Box breathing cycle',
            icon: Icons.self_improvement_outlined,
            duration: Duration(seconds: 16),
            steps: 4,
            stepLabel: 'Phase',
            description: 'Four seconds in, four hold, four out, four hold. '
                'Start again for another cycle.',
            finishedLabel: 'Cycle done',
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Caffeine today',
          subtitle: 'A count of what you log. Clearance varies between people, '
              'so no time-to-clear figure is shown.',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.coffee_outlined, size: 18, color: coffee),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        _coffees == 1
                            ? '1 coffee or tea'
                            : '$_coffees coffees and teas',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _lastCoffee == null
                          ? 'None logged'
                          : 'Last at ${_formatTime(_lastCoffee!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _logCoffee,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Log one'),
                    ),
                    TextButton(
                      onPressed: _coffees == 0 ? null : _resetCoffee,
                      child: const Text('Reset today'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Rest between sets',
          subtitle: 'Counts down while this screen is open.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DsSegmented<int>(
                value: _restSeconds,
                options: const <DsSegment<int>>[
                  DsSegment<int>(value: 30, label: '30 s'),
                  DsSegment<int>(value: 60, label: '60 s'),
                  DsSegment<int>(value: 90, label: '90 s'),
                  DsSegment<int>(value: 120, label: '2 min'),
                ],
                onChanged: (int value) =>
                    setState(() => _restSeconds = value),
              ),
              const SizedBox(height: Space.md),
              DsCountdown(
                key: ValueKey<int>(_restSeconds),
                title: 'Rest timer',
                icon: Icons.timer_outlined,
                duration: Duration(seconds: _restSeconds),
                description: 'Change the length above to start a different '
                    'rest. Reset returns to the chosen length.',
                finishedLabel: 'Rest over',
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        DsSection(
          title: 'Walking stride',
          subtitle: 'Used only to turn steps into a distance estimate.',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.straighten_outlined,
                      size: 18,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        stride == null
                            ? 'No stride saved'
                            : '${stride.round()} cm per step',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Steps come from the watch. The distance below is '
                  'steps multiplied by this stride, so it is an estimate.',
                  style: theme.textTheme.bodySmall,
                ),
                Slider(
                  value: stride ?? 70,
                  min: 40,
                  max: 120,
                  divisions: 80,
                  label: '${(stride ?? 70).round()} cm',
                  onChanged: (double value) =>
                      setState(() => _strideCm = value),
                  onChangeEnd: _setStride,
                ),
                if (stride == null)
                  Text(
                    'Move the slider to set it; it is saved when you let go.',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: Space.md),
                Text(
                  steps > 0
                      ? '${_formatCount(steps)} steps today'
                      : 'No step count yet. The watch reports steps while it '
                          'is connected.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (distanceKm != null) ...<Widget>[
                  const SizedBox(height: Space.xxs),
                  Text(
                    'About ${distanceKm.toStringAsFixed(2)} km at that stride.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xxl),
        const DsSection(
          title: 'About these tools',
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'These are habit counters and timers. They do not measure '
                  'your body: the numbers are what you entered, plus the step '
                  'count the watch reports.',
                ),
                SizedBox(height: Space.sm),
                Text(
                  'The breathing and rest timers count while this screen is '
                  'open, and stop when you leave. Nothing here is a treatment '
                  'plan or a diagnosis.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatCount(int value) {
    final String digits = value.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}

/// One labelled line on the emergency card.
class _IceRow extends StatelessWidget {
  const _IceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsLabel(label, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: Space.xxs),
          Text(
            empty ? 'Not recorded' : value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: empty ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The emergency-card form, owning its text controllers for the life of the
/// route.
///
/// Disposing them as soon as `showDialog` returns is too early: the route's exit
/// animation still builds the fields, and a disposed controller throws from that
/// rebuild ("A TextEditingController was used after being disposed"). A small
/// StatefulWidget disposes them when the route is actually gone.
class _IceDialog extends StatefulWidget {
  const _IceDialog({required this.existing});

  final _IceDetails existing;

  @override
  State<_IceDialog> createState() => _IceDialogState();
}

class _IceDialogState extends State<_IceDialog> {
  late final TextEditingController _blood =
      TextEditingController(text: widget.existing.bloodType);
  late final TextEditingController _contact =
      TextEditingController(text: widget.existing.contact);
  late final TextEditingController _allergies =
      TextEditingController(text: widget.existing.allergies);
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing.notes);

  @override
  void dispose() {
    _blood.dispose();
    _contact.dispose();
    _allergies.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      _IceDetails(
        bloodType: _blood.text.trim(),
        contact: _contact.text.trim(),
        allergies: _allergies.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergency card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _blood,
              decoration: const InputDecoration(
                labelText: 'Blood type',
                hintText: 'For example, O+',
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency contact',
                hintText: 'Phone number',
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _allergies,
              decoration: const InputDecoration(
                labelText: 'Allergies',
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Medical notes',
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

/// The emergency card fields, stored on this phone.
///
/// These keep the keys the previous version used, so a card someone already
/// filled in survives the rebuild. They deliberately have no defaults: the old
/// screen opened showing a blood type, an allergy list and a phone number that
/// nobody had entered, which is worse than an empty card.
class _IceDetails {
  const _IceDetails({
    this.bloodType = '',
    this.contact = '',
    this.allergies = '',
    this.notes = '',
  });

  final String bloodType;
  final String contact;
  final String allergies;
  final String notes;

  static const String _keyBloodType = 'ice_blood_type';
  static const String _keyContact = 'ice_emergency_contact';
  static const String _keyAllergies = 'ice_allergies';
  static const String _keyNotes = 'ice_medical_notes';

  bool get isEmpty =>
      bloodType.trim().isEmpty &&
      contact.trim().isEmpty &&
      allergies.trim().isEmpty &&
      notes.trim().isEmpty;

  static Future<_IceDetails> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _IceDetails(
      bloodType: prefs.getString(_keyBloodType) ?? '',
      contact: prefs.getString(_keyContact) ?? '',
      allergies: prefs.getString(_keyAllergies) ?? '',
      notes: prefs.getString(_keyNotes) ?? '',
    );
  }

  Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBloodType, bloodType.trim());
    await prefs.setString(_keyContact, contact.trim());
    await prefs.setString(_keyAllergies, allergies.trim());
    await prefs.setString(_keyNotes, notes.trim());
  }
}
