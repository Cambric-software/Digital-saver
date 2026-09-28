import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/health_models.dart';
import '../services/app_lock.dart';
import '../services/auto_update_service.dart';
import '../services/ble_service.dart';
import '../services/emergency_service.dart';
import '../services/local_store.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

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
  final _weight = TextEditingController();
  final _pin = TextEditingController();
  final _watchPin = TextEditingController();

  // Settings state
  String _selectedLanguage = 'English';
  bool _demoMode = false;
  int _selectedWatchFace = 0;
  bool _autoSyncHistory = true;

  final List<String> _watchFaces = [
    'Face 1: Minimal Sport',
    'Face 2: Health Rings (Apple-like)',
    'Face 3: Cyberpunk Pixel',
    'Face 4: Classic Analog Dial',
    'Face 5: Detailed Telemetry'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    final c = await LocalStore.loadContacts();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _profile = p;
      _contacts = c;
      _name.text = p.name;
      _age.text = '${p.age}';
      _weight.text = '${p.weightKg.round()}';
      _selectedLanguage = prefs.getString('app_language') ?? 'English';
      _demoMode = prefs.getBool('demo_mode') ?? false;
      _selectedWatchFace = prefs.getInt('selected_watch_face') ?? 0;
      _autoSyncHistory = prefs.getBool('auto_sync_history') ?? true;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _pin.dispose();
    _watchPin.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLanguage);
    await prefs.setBool('demo_mode', _demoMode);
    await prefs.setInt('selected_watch_face', _selectedWatchFace);
    await prefs.setBool('auto_sync_history', _autoSyncHistory);

    final nextProfile = UserProfile(
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? 16,
      weightKg: double.tryParse(_weight.text) ?? 65.0,
      gender: _profile.gender,
      heightCm: _profile.heightCm,
    );
    await LocalStore.saveProfile(nextProfile);

    // If BLE is connected, send watchface switch
    final ble = context.read<BleService>();
    if (ble.isConnected) {
      await ble.setWatchFace(_selectedWatchFace);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _triggerBleScan() {
    final ble = context.read<BleService>();
    if (ble.state != BleState.scanning) {
      ble.startScan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scanning for Veyro smartwatch nearby...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ble = context.watch<BleService>();
    final themeService = context.watch<ThemeService>();
    final updateService = context.watch<AutoUpdateService>();
    final isArabic = _selectedLanguage == 'العربية';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'الإعدادات والتحكم' : 'Settings & Preferences'),
          elevation: 0,
          backgroundColor: AppColors.surface,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined, color: AppColors.primary),
              tooltip: isArabic ? 'حفظ' : 'Save',
              onPressed: _saveSettings,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Language & Display Card
            _buildCard(
              title: isArabic ? 'اللغة والمظهر' : 'Language & Display',
              icon: Icons.language_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'لغة التطبيق' : 'App Language',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English (US / UK)')),
                    DropdownMenuItem(value: 'العربية', child: Text('العربية (مصر / الفصحى)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedLanguage = v);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isArabic ? 'الوضع الليلي (Dark Mode)' : 'Dark Theme Mode'),
                  subtitle: Text(isArabic ? 'تفعيل الوضع الداكن الموفر للطاقة' : 'Reduce eye strain and conserve battery'),
                  value: themeService.themeMode == ThemeMode.dark,
                  onChanged: (dark) {
                    themeService.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Hardware Watch & Demo Mode Card
            _buildCard(
              title: isArabic ? 'تحكم ساعة فيرو (Veyro Control)' : 'Veyro Watch & Telemetry',
              icon: Icons.watch_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ble.isConnected ? (isArabic ? 'الساعة متصلة عبر BLE' : 'Watch Connected via BLE') : (isArabic ? 'غير متصلة' : 'Disconnected'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ble.isConnected ? Colors.green : Colors.grey,
                            ),
                          ),
                          Text(
                            isArabic ? 'البطارية: ${ble.batteryLevel}%' : 'Battery: ${ble.batteryLevel}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _triggerBleScan,
                      icon: const Icon(Icons.bluetooth_searching, size: 16),
                      label: Text(isArabic ? 'بحث عن الساعة' : 'Scan BLE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                DropdownButtonFormField<int>(
                  value: _selectedWatchFace,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'واجهة الساعة (Watch Face)' : 'Active Watch Face',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(_watchFaces.length, (i) => DropdownMenuItem(value: i, child: Text(_watchFaces[i], style: const TextStyle(fontSize: 13)))),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedWatchFace = v);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isArabic ? 'وضع العرض التجريبي (Demo Mode)' : 'Demo Simulation Mode'),
                  subtitle: Text(isArabic ? 'إيقاف محاكاة الحساسات وقراءة الحساسات الحقيقية فقط' : 'Toggle between simulated data and real watch BLE sensor feeds'),
                  value: _demoMode,
                  onChanged: (v) => setState(() => _demoMode = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. User Profile Card
            _buildCard(
              title: isArabic ? 'الملف الشخصي والأهداف' : 'Personal Health Profile',
              icon: Icons.person_outline,
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الاسم' : 'Name',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'العمر' : 'Age',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Updates & About Cambric
            _buildCard(
              title: isArabic ? 'عن كمبريك والتحديثات' : 'About Cambric & Releases',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Digital Saver Suite', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isArabic ? 'الإصدار 1.0.2 • صنع بواسطة كمبريك (مصر)' : 'Version 1.0.2 • Built by Cambric (Egypt)'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Production', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => updateService.checkForUpdates(),
                  icon: const Icon(Icons.system_update_alt, size: 16),
                  label: Text(isArabic ? 'التحقق من التحديثات' : 'Check for GitHub Releases'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(isArabic ? 'حفظ كافة التغييرات' : 'Save All Preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}
