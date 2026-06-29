import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/emergency_service.dart';
import '../services/storage_service.dart';
import '../models/health_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile _profile = UserProfile();
  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await StorageService.loadProfile();
    final c = await StorageService.loadContacts();
    setState(() {
      _profile = p;
      _contacts = c;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ble = context.watch<BleService>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e3a5f),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(profile: _profile, onEdit: _editProfile),
          const SizedBox(height: 16),
          _DeviceCard(ble: ble),
          const SizedBox(height: 16),
          _EmergencyCard(
            contacts: _contacts,
            ble: ble,
            profile: _profile,
            onAdd: _addContact,
            onDelete: _deleteContact,
          ),
          const SizedBox(height: 16),
          _LanguageCard(current: _profile.language, onChanged: _changeLanguage),
          const SizedBox(height: 16),
          _AboutCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _profile.name);
    final ageCtrl = TextEditingController(text: '${_profile.age}');
    final weightCtrl = TextEditingController(text: '${_profile.weightKg.round()}');
    final heightCtrl = TextEditingController(text: '${_profile.heightCm.round()}');
    String gender = _profile.gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                      items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => ss(() => gender = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final updated = UserProfile(
                      name: nameCtrl.text,
                      age: int.tryParse(ageCtrl.text) ?? _profile.age,
                      weightKg: double.tryParse(weightCtrl.text) ?? _profile.weightKg,
                      heightCm: double.tryParse(heightCtrl.text) ?? _profile.heightCm,
                      gender: gender,
                      language: _profile.language,
                    );
                    await StorageService.saveProfile(updated);
                    setState(() => _profile = updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relation (e.g. Son, Doctor)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                  final contact = EmergencyContact(
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    relation: relCtrl.text,
                  );
                  final updated = [..._contacts, contact];
                  await StorageService.saveContacts(updated);
                  setState(() => _contacts = updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteContact(int index) async {
    final updated = [..._contacts]..removeAt(index);
    await StorageService.saveContacts(updated);
    setState(() => _contacts = updated);
  }

  Future<void> _changeLanguage(String lang) async {
    final updated = UserProfile(
      name: _profile.name,
      age: _profile.age,
      weightKg: _profile.weightKg,
      heightCm: _profile.heightCm,
      gender: _profile.gender,
      language: lang,
    );
    await StorageService.saveProfile(updated);
    setState(() => _profile = updated);
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  const _ProfileCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563eb), Color(0xFF7c3aed)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isNotEmpty ? profile.name : 'Set your name',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${profile.age} yrs · ${profile.gender} · ${profile.weightKg.round()} kg · ${profile.heightCm.round()} cm',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'BMI: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF2563eb)),
                onPressed: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final BleService ble;
  const _DeviceCard({required this.ble});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ble.isConnected
                      ? const Color(0xFF22C55E).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.watch,
                  color: ble.isConnected ? const Color(0xFF22C55E) : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ble.isConnected ? 'Digital Saver Watch' : 'No Device Connected',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ble.isConnected
                          ? (ble.demoMode ? 'Demo Mode active' : 'Connected via Bluetooth')
                          : 'Tap to scan for your watch',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!ble.isConnected)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: ble.startScan,
                  child: const Text('Scan', style: TextStyle(fontSize: 13)),
                )
              else
                TextButton(
                  onPressed: ble.disconnect,
                  child: const Text('Disconnect', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
          if (!ble.isConnected) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: ble.enableDemoMode,
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Try Demo Mode', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final BleService ble;
  final UserProfile profile;
  final VoidCallback onAdd;
  final Future<void> Function(int) onDelete;
  const _EmergencyCard({
    required this.contacts,
    required this.ble,
    required this.profile,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563eb)),
              ),
            ],
          ),
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No contacts added yet', style: TextStyle(color: Colors.grey[500])),
            )
          else
            ...contacts.asMap().entries.map((e) => _ContactTile(
              contact: e.value,
              profile: profile,
              ble: ble,
              onDelete: () => onDelete(e.key),
            )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: EmergencyService.callEmergency,
              icon: const Icon(Icons.emergency),
              label: const Text('Call Emergency (911)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final UserProfile profile;
  final BleService ble;
  final VoidCallback onDelete;
  const _ContactTile({required this.contact, required this.profile, required this.ble, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${contact.phone} · ${contact.relation}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF22C55E), size: 20),
            onPressed: () => EmergencyService.callContact(contact),
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Color(0xFF2563eb), size: 20),
            onPressed: () => EmergencyService.sendSmsAlert(
              contact: contact,
              message: EmergencyService.buildAlertMessage(
                userName: profile.name,
                hr: ble.heartRate,
                bp: ble.bloodPressure,
                o2: ble.oxygen,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String current;
  final Future<void> Function(String) onChanged;
  const _LanguageCard({required this.current, required this.onChanged});

  static const _langs = [
    {'code': 'en', 'label': 'English'},
    {'code': 'ar', 'label': 'العربية (Arabic)'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ja', 'label': '日本語'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentLang = _langs.firstWhere(
      (l) => l['code'] == current,
      orElse: () => _langs[0],
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: current,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.language, color: Color(0xFF2563eb)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _langs.map((l) => DropdownMenuItem(value: l['code'], child: Text(l['label']!))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563eb).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2563eb), size: 20),
              SizedBox(width: 8),
              Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563eb), fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          _AboutRow(label: 'App Version', value: '2.0.0'),
          _AboutRow(label: 'Project', value: 'Egyptian Government Health'),
          _AboutRow(label: 'Budget', value: '10,000 EGP'),
          _AboutRow(label: 'Hardware', value: 'ESP32 + MAX30102 + MPU6050'),
          const SizedBox(height: 8),
          const Text(
            '⚠️ For wellness purposes only. Not a certified medical device. Always consult healthcare professionals.',
            style: TextStyle(color: Color(0xFF1e3a5f), fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label, value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
