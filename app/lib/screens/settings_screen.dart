import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/health_models.dart';
import '../services/app_lock.dart';
import '../services/auto_update_service.dart';
import '../services/ble_service.dart';
import '../services/emergency_service.dart';
import '../services/local_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile _profile = UserProfile();
  List<EmergencyContact> _contacts = [];
  bool _loading = true;
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _pin = TextEditingController();
  final _watchPin = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    final c = await LocalStore.loadContacts();
    setState(() {
      _profile = p;
      _contacts = c;
      _name.text = p.name;
      _age.text = '${p.age}';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _pin.dispose();
    _watchPin.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final next = UserProfile(
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? 16,
      weightKg: _profile.weightKg,
      heightCm: _profile.heightCm,
      emergencyContactName: _contacts.isNotEmpty ? _contacts.first.name : null,
      emergencyContactPhone: _contacts.isNotEmpty ? _contacts.first.phone : null,
    );
    await LocalStore.saveProfile(next);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved on this phone only')));
  }

  Future<void> _clearLocalHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local health history?'),
        content: const Text('This permanently deletes saved watch readings from this device. Your profile and watch remain unchanged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete history'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocalStore.clearHealthHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local health history deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final lock = context.watch<AppLock>();
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('No accounts. No cloud. Profile stays in this phone.'),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Your name')),
          TextField(controller: _age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          FilledButton(onPressed: _saveProfile, child: const Text('Save profile')),
          const Divider(height: 32),
          Text('Veyro', style: Theme.of(context).textTheme.titleMedium),
          Text(ble.isConnected ? 'Connected · ${ble.batteryLevel}% · fw ${ble.watchInfo.fw}' : 'Not connected'),
          if (ble.isConnected && !ble.watchInfo.paired) ...[
            const Text('Type the 6-digit PIN shown on the watch.'),
            TextField(controller: _watchPin, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Watch PIN')),
            FilledButton(onPressed: () => ble.pairWithPin(_watchPin.text.trim()), child: const Text('Pair')),
          ],
          OutlinedButton(
            onPressed: ble.isConnected ? ble.disconnect : ble.startScan,
            child: Text(ble.isConnected ? 'Disconnect' : 'Scan for Veyro'),
          ),
          if (ble.isConnected)
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Watch home screen'),
              initialValue: 0,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Clock')),
                DropdownMenuItem(value: 1, child: Text('Vitals estimate')),
                DropdownMenuItem(value: 2, child: Text('Activity')),
                DropdownMenuItem(value: 3, child: Text('Motion')),
                DropdownMenuItem(value: 4, child: Text('Battery')),
                DropdownMenuItem(value: 5, child: Text('Storage')),
                DropdownMenuItem(value: 6, child: Text('Connection')),
                DropdownMenuItem(value: 7, child: Text('Device info')),
              ],
              onChanged: (value) {
                if (value != null) ble.setWatchFace(value);
              },
            ),
          if (!ble.isConnected)
            TextButton(onPressed: ble.startDemo, child: const Text('Use demo numbers (no watch)')),
          const Divider(height: 32),
          Text('App lock', style: Theme.of(context).textTheme.titleMedium),
          Text(lock.hasLock ? 'PIN lock is on' : 'Off — anyone with the phone can open Veyro'),
          TextField(controller: _pin, obscureText: true, maxLength: 6, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '6-digit PIN')),
          Row(children: [
            FilledButton(onPressed: () => lock.setPin(_pin.text.trim()), child: const Text('Set lock')),
            const SizedBox(width: 8),
            TextButton(onPressed: lock.clearPin, child: const Text('Remove lock')),
          ]),
          const Divider(height: 32),
          Text('Emergency (Egypt: ambulance 123)', style: Theme.of(context).textTheme.titleMedium),
          ..._contacts.map((c) => ListTile(
                title: Text(c.name),
                subtitle: Text('${c.phone} · ${c.relation}'),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => EmergencyService.callContact(c),
                ),
              )),
          TextButton(
            onPressed: () async {
              await LocalStore.saveContacts([
                ..._contacts,
                EmergencyContact(name: 'Family', phone: '', relation: 'family'),
              ]);
              await _load();
            },
            child: const Text('Add contact slot — edit in a later build from this list'),
          ),
          FilledButton.tonal(onPressed: EmergencyService.callEmergency, child: const Text('Call 123')),
          const Divider(height: 32),
          Text('App ${AppVersion.current} · Cambric · local build'),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://github.com/Cambric-software/Digital-saver/releases')),
            child: const Text('Optional GitHub update page'),
          ),
          const Divider(height: 32),
          Text('Local data', style: Theme.of(context).textTheme.titleMedium),
          const Text('Health readings stay on this device unless you export or share them yourself.'),
          OutlinedButton.icon(
            onPressed: _clearLocalHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear local health history'),
          ),
        ],
      ),
    );
  }
}
