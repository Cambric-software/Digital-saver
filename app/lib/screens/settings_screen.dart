/// Settings: the one place the app's choices are changed.
///
/// Rebuilt. The previous version was a 715-line [Scaffold] with an [AppBar]
/// inside the shared shell, so Settings drew a page frame inside a page frame.
/// It read and wrote every preference through shared_preferences by hand, with
/// the key string and the default spelled out separately on the load side and
/// the save side; a typo in either produced a switch that appeared to save and
/// reverted on the next open. It also loaded the profile and emergency contacts
/// and never showed them, kept a PIN controller it never used, and carried
/// three imports - url_launcher, app_lock and emergency_service - that did
/// nothing.
///
/// What is here now:
///   * a [DsPage] with no frame of its own;
///   * every stored preference goes through [StorageService], so a key and its
///     default exist once;
///   * the profile and emergency contacts are editable and save through
///     [LocalStore];
///   * the app-lock PIN sets, verifies and clears through [AppLock], with the
///     wrong-PIN and too-short-PIN failures shown in the dialog;
///   * controls that only store a value say so, rather than claiming to change
///     the watch when this build has no command for them;
///   * no save-everything button. Each control saves itself, so the snackbar
///     can only appear when the write actually succeeded.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/health_models.dart';
import '../services/app_lock.dart';
import '../services/auto_update_service.dart';
import '../services/ble_service.dart';
import '../services/dynamic_theme_service.dart';
import '../services/local_store.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';

/// Appearance, the watch, alerts, records and the release.
class SettingsScreen extends StatefulWidget {
  /// Create the screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _watchFaces = <String>[
    'Face 1: Minimal Sport',
    'Face 2: Health Rings',
    'Face 3: Cyberpunk Pixel',
    'Face 4: Classic Analog Dial',
    'Face 5: Detailed Telemetry',
  ];

  static const List<String> _complicationChoices = <String>[
    'Steps',
    'Heart Rate',
    'Battery Level',
    'Calories Burned',
    'Distance (km)',
    'None',
  ];

  static const List<String> _languages = <String>['English', 'العربية'];

  bool _loading = true;
  String? _loadError;

  // Profile and contacts are the two records the screen owns. They stay in
  // LocalStore; the settings above them stay in StorageService.
  UserProfile _profile = UserProfile();
  List<EmergencyContact> _contacts = <EmergencyContact>[];
  bool _savingProfile = false;
  String? _profileError;
  bool _savingContact = false;
  String? _contactError;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _contactRelation = TextEditingController();

  bool _demoMode = StorageService.defaultDemoMode;
  int _watchFace = StorageService.defaultWatchFace;
  bool _autoSync = StorageService.defaultAutoSyncHistory;
  double _highHr = StorageService.defaultHighHrThreshold;
  double _lowSpo2 = StorageService.defaultLowSpo2Threshold;
  String _complicationTop = StorageService.defaultComplicationTop;
  String _complicationBottom = StorageService.defaultComplicationBottom;
  List<String> _quickReplies =
      List<String>.of(StorageService.defaultQuickReplies);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _contactRelation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Captured before the first await: this State may be gone afterwards.
      final AppLock lock = context.read<AppLock>();

      final UserProfile profile = await LocalStore.loadProfile();
      final List<EmergencyContact> contacts = await LocalStore.loadContacts();
      final bool demoMode = await StorageService.demoMode();
      final int watchFace = await StorageService.watchFace();
      final bool autoSync = await StorageService.autoSyncHistory();
      final double highHr = await StorageService.highHrThreshold();
      final double lowSpo2 = await StorageService.lowSpo2Threshold();
      final String complicationTop = await StorageService.complicationTop();
      final String complicationBottom =
          await StorageService.complicationBottom();
      final List<String> quickReplies = await StorageService.quickReplies();

      if (!lock.ready) await lock.load();
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _contacts = contacts;
        _name.text = profile.name;
        _age.text = '${profile.age}';
        _weight.text = _formatNumber(profile.weightKg);
        _demoMode = demoMode;
        _watchFace = watchFace >= 0 && watchFace < _watchFaces.length
            ? watchFace
            : StorageService.defaultWatchFace;
        _autoSync = autoSync;
        _highHr = highHr;
        _lowSpo2 = lowSpo2;
        _complicationTop = _complicationChoices.contains(complicationTop)
            ? complicationTop
            : StorageService.defaultComplicationTop;
        _complicationBottom = _complicationChoices.contains(complicationBottom)
            ? complicationBottom
            : StorageService.defaultComplicationBottom;
        _quickReplies = List<String>.of(quickReplies);
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

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _load();
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toString();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── Stored settings ─────────────────────────────────────────────────

  Future<void> _setDemoMode(bool value) async {
    setState(() => _demoMode = value);
    try {
      await StorageService.setDemoMode(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _demoMode = !value);
      _snack('Demo mode could not be saved: $error');
    }
  }

  Future<void> _setAutoSync(bool value) async {
    setState(() => _autoSync = value);
    try {
      await StorageService.setAutoSyncHistory(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _autoSync = !value);
      _snack('The auto-sync preference could not be saved: $error');
    }
  }

  Future<void> _setWatchFace(int value, BleService ble) async {
    final int previous = _watchFace;
    setState(() => _watchFace = value);
    try {
      await StorageService.setWatchFace(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _watchFace = previous);
      _snack('The watch face could not be saved: $error');
      return;
    }

    if (!ble.isConnected) return;
    try {
      await ble.setWatchFace(value);
      _snack('Face ${value + 1} saved and sent to the watch.');
    } catch (error) {
      _snack('The choice was saved, but the watch did not accept it: $error');
    }
  }

  Future<void> _setHighHr(double value) async {
    setState(() => _highHr = value);
    try {
      await StorageService.setHighHrThreshold(value);
    } catch (error) {
      _snack('The high heart-rate threshold could not be saved: $error');
    }
  }

  Future<void> _setLowSpo2(double value) async {
    setState(() => _lowSpo2 = value);
    try {
      await StorageService.setLowSpo2Threshold(value);
    } catch (error) {
      _snack('The low oxygen threshold could not be saved: $error');
    }
  }

  Future<void> _setComplicationTop(String value) async {
    final String previous = _complicationTop;
    setState(() => _complicationTop = value);
    try {
      await StorageService.setComplicationTop(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _complicationTop = previous);
      _snack('The top slot could not be saved: $error');
    }
  }

  Future<void> _setComplicationBottom(String value) async {
    final String previous = _complicationBottom;
    setState(() => _complicationBottom = value);
    try {
      await StorageService.setComplicationBottom(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _complicationBottom = previous);
      _snack('The bottom slot could not be saved: $error');
    }
  }

  // ── Quick replies ───────────────────────────────────────────────────

  Future<void> _addQuickReply() async {
    final String? text = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _TextPromptDialog(
        title: 'Add a quick reply',
        hint: 'On my way!',
        confirmLabel: 'Add',
        fieldLabel: 'Reply text',
      ),
    );
    if (text == null || !mounted) return;
    await _saveQuickReplies(
      <String>[..._quickReplies, text],
      'Quick reply added to this phone.',
    );
  }

  Future<void> _removeQuickReply(int index) async {
    if (index < 0 || index >= _quickReplies.length) return;
    final List<String> next = List<String>.of(_quickReplies)..removeAt(index);
    await _saveQuickReplies(next, 'Quick reply removed.');
  }

  Future<void> _saveQuickReplies(List<String> next, String message) async {
    try {
      await StorageService.setQuickReplies(next);
      if (!mounted) return;
      setState(() => _quickReplies = List<String>.of(next));
      _snack(message);
    } catch (error) {
      _snack('The quick replies could not be saved: $error');
    }
  }

  // ── Profile ─────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    final String name = _name.text.trim();
    final int? age = int.tryParse(_age.text.trim());
    final double? weight = double.tryParse(_weight.text.trim());

    String? error;
    if (name.isEmpty) {
      error = 'Enter a name, or leave the field blank and save; a blank name '
          'is allowed but the emergency alert will not name you.';
    } else if (age == null || age < 1 || age > 120) {
      error = 'Age must be a whole number from 1 to 120.';
    } else if (weight == null || weight < 20 || weight > 300) {
      error = 'Weight must be a number from 20 to 300 kg.';
    }
    if (error != null) {
      setState(() => _profileError = error);
      return;
    }

    setState(() {
      _savingProfile = true;
      _profileError = null;
    });

    final UserProfile next = _profile.copyWith(
      name: name,
      age: age,
      weightKg: weight,
    );

    try {
      await LocalStore.saveProfile(next);
      if (!mounted) return;
      setState(() {
        _profile = next;
        _savingProfile = false;
      });
      _snack('Profile saved on this phone.');
    } catch (saveError) {
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _profileError = 'The profile could not be saved: $saveError';
      });
    }
  }

  // ── Emergency contacts ──────────────────────────────────────────────

  Future<void> _addContact() async {
    final String name = _contactName.text.trim();
    final String phone = _contactPhone.text.trim();
    final String relation = _contactRelation.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(
        () => _contactError = 'A contact needs a name and a phone number.',
      );
      return;
    }

    final List<EmergencyContact> next = <EmergencyContact>[
      ..._contacts,
      EmergencyContact(name: name, phone: phone, relation: relation),
    ];
    final bool saved = await _saveContacts(
      next,
      'Contact added. It is stored on this phone.',
    );
    if (!saved || !mounted) return;
    setState(() {
      _contactName.clear();
      _contactPhone.clear();
      _contactRelation.clear();
      _contactError = null;
    });
  }

  Future<void> _removeContact(int index) async {
    if (index < 0 || index >= _contacts.length) return;
    final List<EmergencyContact> next = List<EmergencyContact>.of(_contacts)
      ..removeAt(index);
    await _saveContacts(next, 'Contact removed.');
  }

  Future<bool> _saveContacts(
    List<EmergencyContact> next,
    String message,
  ) async {
    setState(() {
      _savingContact = true;
      _contactError = null;
    });
    try {
      await LocalStore.saveContacts(next);
      if (!mounted) return false;
      setState(() {
        _contacts = next;
        _savingContact = false;
      });
      _snack(message);
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _savingContact = false;
        _contactError = 'The contacts could not be saved: $error';
      });
      return false;
    }
  }

  // ── App lock ────────────────────────────────────────────────────────

  Future<void> _openPinDialog(AppLock lock, _PinMode mode) async {
    final bool? changed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _PinDialog(mode: mode, lock: lock),
    );
    if (changed != true || !mounted) return;
    final String message = switch (mode) {
      _PinMode.set =>
        'PIN set. Changing or removing it will ask for this PIN first.',
      _PinMode.change => 'PIN changed.',
      _PinMode.remove => 'PIN removed. No app lock is set.',
    };
    _snack(message);
  }

  // ── Scan and export ─────────────────────────────────────────────────

  Future<void> _scan() async {
    final BleService ble = context.read<BleService>();
    if (ble.state == BleState.scanning) return;
    try {
      await ble.startScan();
      if (!mounted) return;
      if (ble.state == BleState.scanning) {
        _snack('Searching for Veyro. Keep the watch nearby.');
      } else if (ble.state == BleState.error) {
        _snack(
          ble.errorMessage.isEmpty
              ? 'The scan could not start.'
              : ble.errorMessage,
        );
      }
    } catch (error) {
      _snack('The scan could not start: $error');
    }
  }

  Future<void> _showStoredSamples({required bool json}) async {
    try {
      final List<WatchSample> samples = await LocalStore.loadAll();
      if (!mounted) return;

      if (samples.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Nothing stored yet'),
            content: const Text(
              'No watch samples are saved on this phone. Pair the watch and '
              'pull once from the Watch screen, then come back.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }

      final String body = json
          ? jsonEncode(
              samples
                  .map(
                    (WatchSample sample) => <String, Object>{
                      'unix': sample.unix,
                      'hr': sample.hr,
                      'spo2': sample.spo2,
                      'bps': sample.bps,
                      'bpd': sample.bpd,
                      'hrv': sample.hrv,
                      'steps': sample.steps,
                      'fall': sample.fall,
                      'battery': sample.bat,
                    },
                  )
                  .toList(),
            )
          : 'unix,hr,spo2,bps,bpd,hrv,steps,fall,bat\n'
              '${samples.map((WatchSample sample) => sample.toCsv()).join('\n')}';

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            json
                ? '${samples.length} samples as JSON'
                : '${samples.length} samples as CSV',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(body),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      _snack('Stored samples could not be read: $error');
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return DsPage(
        title: 'Settings',
        child: DsCard(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: Space.lg),
                  Text(
                    'Reading the stored preferences and records…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return DsPage(
        title: 'Settings',
        child: DsCard(
          borderColor: Theme.of(context).colorScheme.error,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Settings could not be loaded',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(_loadError!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: Space.lg),
              OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ThemeService themeService = context.watch<ThemeService>();
    final LocaleService locale = context.watch<LocaleService>();
    final BleService ble = context.watch<BleService>();
    final AutoUpdateService updates = context.watch<AutoUpdateService>();
    final AppLock lock = context.watch<AppLock>();

    final bool dark = themeService.themeModeType == AppThemeMode.dark;
    final String language = _languages.contains(locale.currentLanguage)
        ? locale.currentLanguage
        : 'English';

    return DsPage(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'Changes save as you make them. The profile and contact '
                    'forms have their own save buttons, so a half-typed entry '
                    'is never stored.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Appearance & language',
            subtitle: 'How the app looks and which language it asks for',
            child: DsCard(
              child: Column(
                children: <Widget>[
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        dark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                      ),
                      title: const Text('Dark theme'),
                      subtitle: Text(
                        dark
                            ? 'Dark surfaces and lifted text colours.'
                            : 'Light surfaces for daytime use.',
                      ),
                      value: dark,
                      onChanged: (bool value) => themeService.setTheme(
                        value ? AppThemeMode.dark : AppThemeMode.light,
                      ),
                    ),
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        themeService.isDimmed
                            ? Icons.nights_stay_outlined
                            : Icons.brightness_4_outlined,
                      ),
                      title: const Text('Dim after dark'),
                      subtitle: Text(
                        themeService.dimAfterDark
                            ? 'On. The dark theme is used from '
                                '${DynamicThemeService.dimStartHour}:00 to '
                                '${DynamicThemeService.dimEndHour.toString().padLeft(2, '0')}:00. '
                                '${themeService.isDimmed ? 'It is after dark now, so the dark theme is active.' : 'It is daytime now, so the theme you picked is used.'}'
                            : 'Off. The theme you picked is used all day. When '
                                'on, the dark theme is used from '
                                '${DynamicThemeService.dimStartHour}:00 to '
                                '${DynamicThemeService.dimEndHour.toString().padLeft(2, '0')}:00.',
                      ),
                      value: themeService.dimAfterDark,
                      onChanged: (bool value) =>
                          themeService.setDimAfterDark(value),
                    ),
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: Space.md),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    isExpanded: true,
                    decoration: _fieldDecoration('App language'),
                    items: <DropdownMenuItem<String>>[
                      for (final String option in _languages)
                        DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option == 'English'
                                ? 'English (US / UK)'
                                : 'العربية (مصر / الفصحى)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (String? value) async {
                      if (value == null) return;
                      await locale.setLanguage(value);
                    },
                  ),
                  const SizedBox(height: Space.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'The language choice is stored by LocaleService and '
                      'survives a restart.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Watch & sync',
            subtitle: 'The connection, the face and what a sync does',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: <Widget>[
                      DsStatusPill(
                        label: ble.isConnected
                            ? 'Watch connected'
                            : 'No watch connected',
                        icon: ble.isConnected
                            ? Icons.bluetooth_connected_rounded
                            : Icons.bluetooth_disabled_rounded,
                        color: ble.isConnected
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      Text(
                        ble.batteryLevel > 0
                            ? '${ble.batteryLevel}% battery'
                            : 'Battery --',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Space.md,
                    runSpacing: Space.sm,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed:
                            ble.state == BleState.scanning ? null : _scan,
                        icon: ble.state == BleState.scanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bluetooth_searching, size: 18),
                        label: Text(
                          ble.state == BleState.scanning
                              ? 'Searching…'
                              : 'Scan for Veyro',
                        ),
                      ),
                      if (ble.state == BleState.error &&
                          ble.errorMessage.isNotEmpty)
                        Text(
                          ble.errorMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Scanning asks for Bluetooth and nearby-device permission. '
                    'Pairing needs the six digits shown on the watch face.',
                    style: theme.textTheme.bodySmall,
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.sync_outlined),
                      title: const Text('Remember auto-sync choice'),
                      subtitle: const Text(
                        'Saved on this phone. This build starts a log sync on '
                        'its own when the watch connects.',
                      ),
                      value: _autoSync,
                      onChanged: _setAutoSync,
                    ),
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: Space.md),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.science_outlined),
                      title: const Text('Demo mode'),
                      subtitle: const Text(
                        'Saved on this phone. Sleep history reads this setting; '
                        'live readings come from the watch when one is '
                        'connected.',
                      ),
                      value: _demoMode,
                      onChanged: _setDemoMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Watch face & complications',
            subtitle: 'What the watch shows, and what is stored for its slots',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DropdownButtonFormField<int>(
                    initialValue: _watchFace,
                    isExpanded: true,
                    decoration: _fieldDecoration('Active watch face'),
                    items: <DropdownMenuItem<int>>[
                      for (int i = 0; i < _watchFaces.length; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            _watchFaces[i],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (int? value) {
                      if (value == null) return;
                      _setWatchFace(value, ble);
                    },
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Saved on this phone. If a watch is connected, the face is '
                    'applied immediately.',
                    style: theme.textTheme.bodySmall,
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: Space.md),
                  Text('Complication slots', style: theme.textTheme.titleSmall),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Saved on this phone. This build does not send the slot '
                    'choice to the watch.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.md),
                  DropdownButtonFormField<String>(
                    initialValue: _complicationTop,
                    isExpanded: true,
                    decoration: _fieldDecoration('Top slot'),
                    items: <DropdownMenuItem<String>>[
                      for (final String choice in _complicationChoices)
                        DropdownMenuItem<String>(
                          value: choice,
                          child: Text(
                            choice,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      _setComplicationTop(value);
                    },
                  ),
                  const SizedBox(height: Space.md),
                  DropdownButtonFormField<String>(
                    initialValue: _complicationBottom,
                    isExpanded: true,
                    decoration: _fieldDecoration('Bottom slot'),
                    items: <DropdownMenuItem<String>>[
                      for (final String choice in _complicationChoices)
                        DropdownMenuItem<String>(
                          value: choice,
                          child: Text(
                            choice,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      _setComplicationBottom(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Health alerts',
            subtitle: 'The values this app remembers for flagging a reading',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'High heart-rate threshold',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Saved at ${_highHr.toInt()} BPM or above.',
                    style: theme.textTheme.bodySmall,
                  ),
                  Slider(
                    value: _highHr,
                    min: 80,
                    max: 180,
                    divisions: 20,
                    label: '${_highHr.toInt()} BPM',
                    onChanged: (double value) =>
                        setState(() => _highHr = value),
                    onChangeEnd: _setHighHr,
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  Text(
                    'Low oxygen threshold',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Saved at ${_lowSpo2.toInt()}% or below.',
                    style: theme.textTheme.bodySmall,
                  ),
                  Slider(
                    value: _lowSpo2,
                    min: 80,
                    max: 95,
                    divisions: 15,
                    label: '${_lowSpo2.toInt()}%',
                    onChanged: (double value) =>
                        setState(() => _lowSpo2 = value),
                    onChangeEnd: _setLowSpo2,
                  ),
                  Text(
                    'These values are stored on this phone. This build does '
                    'not raise an alert from them yet; it does not pretend '
                    'that it does.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Quick replies',
            subtitle: 'Replies kept for answering from the watch',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Stored on this phone. This build does not send the list '
                    'to the watch.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.md),
                  if (_quickReplies.isEmpty)
                    Text(
                      'No replies saved.',
                      style: theme.textTheme.bodySmall,
                    ),
                  for (int i = 0; i < _quickReplies.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.short_text_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(
                              _quickReplies[i],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: _quickReplies.length <= 1
                                ? 'Keep at least one reply'
                                : 'Remove this reply',
                            onPressed: _quickReplies.length <= 1
                                ? null
                                : () => _removeQuickReply(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  if (_quickReplies.length <= 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Text(
                        'One reply is kept, so there is always something to '
                        'send from the watch.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _addQuickReply,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add a reply'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Profile',
            subtitle: 'Used for the emergency alert and the health context',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration('Name'),
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _age,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('Age'),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: TextField(
                          controller: _weight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _fieldDecoration('Weight (kg)'),
                        ),
                      ),
                    ],
                  ),
                  if (_profileError != null) ...<Widget>[
                    const SizedBox(height: Space.md),
                    Text(
                      _profileError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _savingProfile ? null : _saveProfile,
                      icon: _savingProfile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _savingProfile ? 'Saving…' : 'Save profile',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Emergency contacts',
            subtitle: 'The people the alert offers to call',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Stored on this phone by LocalStore. Nothing here is '
                    'uploaded.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.md),
                  if (_contacts.isEmpty)
                    Text(
                      'No emergency contacts yet. Add one below; an alert '
                      'without a contact has nobody to offer.',
                      style: theme.textTheme.bodySmall,
                    ),
                  for (int i = 0; i < _contacts.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _contacts[i].name,
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (_contacts[i].relation.isNotEmpty)
                                  Text(
                                    _contacts[i].relation,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                Text(
                                  _contacts[i].phone,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove ${_contacts[i].name}',
                            onPressed:
                                _savingContact ? null : () => _removeContact(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: Space.md),
                  Text('Add a contact', style: theme.textTheme.titleSmall),
                  const SizedBox(height: Space.md),
                  TextField(
                    controller: _contactName,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration('Name'),
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _contactPhone,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration('Phone'),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: TextField(
                          controller: _contactRelation,
                          decoration: _fieldDecoration('Relation'),
                        ),
                      ),
                    ],
                  ),
                  if (_contactError != null) ...<Widget>[
                    const SizedBox(height: Space.md),
                    Text(
                      _contactError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _savingContact ? null : _addContact,
                      icon: _savingContact
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded,
                              size: 18),
                      label: Text(
                        _savingContact ? 'Saving…' : 'Add contact',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'App lock',
            subtitle: 'A six-digit PIN checked by AppLock on this device',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!lock.ready)
                    Text(
                      'Checking whether a PIN is stored…',
                      style: theme.textTheme.bodySmall,
                    )
                  else if (!lock.hasLock) ...<Widget>[
                    Text(
                      'No PIN is set. The app opens without asking for one.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'A PIN is stored as a salted hash on this device and is '
                      'never sent anywhere.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: Space.lg),
                    FilledButton.icon(
                      onPressed: () => _openPinDialog(lock, _PinMode.set),
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text('Set a 6-digit PIN'),
                    ),
                  ] else ...<Widget>[
                    DsStatusPill(
                      label: 'PIN set',
                      icon: Icons.lock_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'The PIN is asked for when the app opens and again after '
                      'it has been in the background. Changing or removing it '
                      'asks for the current one first. Five wrong tries make '
                      'the lock wait 30 seconds.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: Space.lg),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.sm,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openPinDialog(lock, _PinMode.change),
                          icon: const Icon(Icons.password_rounded, size: 18),
                          label: const Text('Change PIN'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => lock.lockNow(),
                          icon: const Icon(Icons.lock_clock_rounded, size: 18),
                          label: const Text('Lock now'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _openPinDialog(lock, _PinMode.remove),
                          icon: const Icon(Icons.lock_open_rounded, size: 18),
                          label: const Text('Remove PIN'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'Your data',
            subtitle: 'A selectable copy of what is already stored',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Nothing is uploaded. The buttons below read the samples '
                    'saved on this phone; they do not pull from the watch.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.lg),
                  Wrap(
                    spacing: Space.md,
                    runSpacing: Space.sm,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => _showStoredSamples(json: false),
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                        ),
                        label: const Text('View CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showStoredSamples(json: true),
                        icon: const Icon(Icons.data_object_rounded, size: 18),
                        label: const Text('View JSON'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          DsSection(
            title: 'About & updates',
            subtitle: 'The build, the release feed and the check',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(Space.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child: Icon(
                          Icons.monitor_heart_rounded,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppVersion.displayName,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'Version ${AppVersion.display} '
                              '(build ${AppVersion.buildNumber})',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              AppVersion.publisher,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  Text(
                    _updateStatus(updates),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (updates.error != null) ...<Widget>[
                    const SizedBox(height: Space.xs),
                    Text(
                      'The check did not complete. Nothing was installed or '
                      'changed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  if (updates.lastChecked != null) ...<Widget>[
                    const SizedBox(height: Space.xs),
                    Text(
                      'Last checked ${_stamp(updates.lastChecked!)}.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  FilledButton.tonalIcon(
                    onPressed: updates.isChecking
                        ? null
                        : () => updates.checkForUpdates(),
                    icon: updates.isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.system_update_alt_rounded, size: 18),
                    label: Text(
                      updates.isChecking ? 'Checking…' : 'Check for updates',
                    ),
                  ),
                  if (updates.latestUpdate != null &&
                      updates.latestUpdate!.isNewer) ...<Widget>[
                    const SizedBox(height: Space.lg),
                    Text(
                      _installAvailability(updates.latestUpdate!),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (updates.isAutoUpdating) ...<Widget>[
                      const SizedBox(height: Space.sm),
                      LinearProgressIndicator(
                        value: updates.downloadProgress > 0
                            ? updates.downloadProgress
                            : null,
                      ),
                    ],
                    if (updates.autoUpdateMessage != null) ...<Widget>[
                      const SizedBox(height: Space.sm),
                      Text(
                        updates.autoUpdateMessage!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: Space.md),
                    FilledButton.icon(
                      onPressed: updates.isAutoUpdating ||
                              !updates.latestUpdate!.canVerify
                          ? null
                          : () => updates.installUpdate(),
                      icon: updates.isAutoUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined, size: 18),
                      label: Text(
                        updates.isAutoUpdating
                            ? 'Downloading and verifying…'
                            : 'Download and verify update',
                      ),
                    ),
                    if (updates.latestUpdate!.asset != null &&
                        !updates.latestUpdate!.canVerify) ...<Widget>[
                      const SizedBox(height: Space.xs),
                      Text(
                        'This build will not install a package that has no '
                        'published checksum.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          const DsSection(
            title: 'Licence',
            subtitle: 'Proprietary, and not a medical device',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Copyright (c) 2026 Cambric Software. All rights reserved.',
                  ),
                  SizedBox(height: Space.sm),
                  Text(
                    'Digital Saver is proprietary software. You may install '
                    'and run it on devices you control. Redistribution, '
                    'modification and reverse engineering are not licensed; '
                    'the source is published for inspection, not for reuse.',
                  ),
                  SizedBox(height: Space.sm),
                  Text(
                    'It is a consumer wellness product, not a certified '
                    'medical device. Sensor readings are estimates and can be '
                    'wrong. Do not use them for diagnosis or treatment, or as '
                    'the only way help would be called.',
                  ),
                  SizedBox(height: Space.sm),
                  Text(
                    'The full agreement ships with the project as LICENSE.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _installAvailability(UpdateInfo update) {
    final asset = update.asset;
    if (asset == null) {
      return 'This release did not publish a package for this platform, so '
          'there is nothing this build can verify or apply.';
    }
    if (!update.canVerify) {
      return 'The release does not publish a SHA-256 for ${asset.name}, so '
          'this build will not download it.';
    }
    return 'The release publishes a SHA-256 for ${asset.name}. The download '
        'is checked before anything is opened or staged.';
  }

  static String _updateStatus(AutoUpdateService updates) {
    if (updates.isChecking) {
      return 'Checking the GitHub releases feed…';
    }
    final String? error = updates.error;
    if (error != null) return error;
    final UpdateInfo? latest = updates.latestUpdate;
    if (latest == null) return 'Not checked yet in this session.';
    if (latest.isNewer) {
      return 'Version ${latest.version} is available. This copy is '
          '${AppVersion.current}.';
    }
    return 'Up to date. The newest published release is ${latest.version}.';
  }

  static String _stamp(DateTime value) {
    final DateTime local = value.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  static InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.md,
      ),
    );
  }
}

/// Which PIN flow the dialog is running.
enum _PinMode { set, change, remove }

/// A dialog that sets, changes or removes the app PIN.
///
/// The controllers live here rather than in the screen so a dialog that is
/// dismissed mid-animation cannot leave a disposed controller in the tree.
class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.mode, required this.lock});

  final _PinMode mode;
  final AppLock lock;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _newPin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _needsCurrent =>
      widget.mode == _PinMode.change || widget.mode == _PinMode.remove;

  bool get _needsNew =>
      widget.mode == _PinMode.set || widget.mode == _PinMode.change;

  String get _title => switch (widget.mode) {
        _PinMode.set => 'Set a PIN',
        _PinMode.change => 'Change the PIN',
        _PinMode.remove => 'Remove the PIN',
      };

  String get _confirmLabel => switch (widget.mode) {
        _PinMode.set => 'Set PIN',
        _PinMode.change => 'Change PIN',
        _PinMode.remove => 'Remove',
      };

  Future<void> _submit() async {
    final String newPin = _newPin.text;
    final String current = _current.text;

    if (_needsNew) {
      if (newPin.length != 6 || int.tryParse(newPin) == null) {
        setState(() => _error = 'Use exactly 6 digits, 0 to 9.');
        return;
      }
      if (newPin != _confirm.text) {
        setState(() => _error = 'The two new PINs do not match.');
        return;
      }
    }
    if (_needsCurrent && current.length != 6) {
      setState(() => _error = 'Enter the current 6-digit PIN.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_needsCurrent) {
        final bool correct = await widget.lock.unlock(current);
        if (!mounted) return;
        if (!correct) {
          setState(() {
            _busy = false;
            _error = 'That PIN is not correct. After five wrong tries the '
                'lock waits 30 seconds.';
          });
          return;
        }
      }

      if (widget.mode == _PinMode.remove) {
        await widget.lock.clearPin();
      } else {
        await widget.lock.setPin(newPin);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'The PIN could not be saved: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_needsCurrent) ...<Widget>[
              TextField(
                controller: _current,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _SettingsScreenState._fieldDecoration(
                  'Current PIN',
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: Space.md),
            ],
            if (_needsNew) ...<Widget>[
              TextField(
                controller: _newPin,
                autofocus: widget.mode == _PinMode.set,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _SettingsScreenState._fieldDecoration(
                  'New 6-digit PIN',
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _confirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _SettingsScreenState._fieldDecoration(
                  'Confirm the new PIN',
                ).copyWith(counterText: ''),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: Space.md),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (widget.mode == _PinMode.remove) ...<Widget>[
              const SizedBox(height: Space.md),
              Text(
                'Removing the PIN deletes the stored hash. The profile, '
                'contacts and samples are not touched.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_confirmLabel),
        ),
      ],
    );
  }
}

/// A one-field dialog that returns the trimmed text, or null on cancel.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.fieldLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String fieldLabel;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write something first.');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 80,
            decoration: _SettingsScreenState._fieldDecoration(
              widget.fieldLabel,
            ).copyWith(
              hintText: widget.hint,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
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
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
