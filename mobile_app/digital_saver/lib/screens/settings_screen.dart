import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = Provider.of<StorageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Language Setting
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(storage.locale.languageCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          
          const Divider(),
          
          // Dark Mode
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text(l10n.darkMode),
            value: storage.isDarkMode,
            onChanged: (value) => storage.setDarkMode(value),
          ),
          
          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(l10n.notifications),
            value: storage.notificationsEnabled,
            onChanged: (value) => storage.setNotificationsEnabled(value),
          ),
          
          const Divider(),
          
          // Heart Rate Threshold
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text(l10n.heartRateThreshold),
            subtitle: Slider(
              value: storage.heartRateThreshold.toDouble(),
              min: 80,
              max: 140,
              divisions: 12,
              label: '${storage.heartRateThreshold} ${l10n.bpm}',
              onChanged: (value) => storage.setHeartRateThreshold(value.toInt()),
            ),
            trailing: Text('${storage.heartRateThreshold}'),
          ),
          
          // BP Threshold
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: Text(l10n.bpThreshold),
            subtitle: Slider(
              value: storage.systolicThreshold.toDouble(),
              min: 120,
              max: 180,
              divisions: 12,
              label: '${storage.systolicThreshold} ${l10n.mmhg}',
              onChanged: (value) => storage.setSystolicThreshold(value.toInt()),
            ),
            trailing: Text('${storage.systolicThreshold}'),
          ),
          
          const Divider(),
          
          // Emergency Contacts
          ListTile(
            leading: const Icon(Icons.contacts, color: Colors.orange),
            title: Text(l10n.emergencyContacts),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/contacts'),
          ),
          
          const Divider(),
          
          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Digital Saver v1.0.0'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = Provider.of<StorageService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildLanguageTile(context, 'en', 'English', storage),
              _buildLanguageTile(context, 'ar', 'العربية', storage),
              _buildLanguageTile(context, 'es', 'Español', storage),
              _buildLanguageTile(context, 'fr', 'Français', storage),
              _buildLanguageTile(context, 'de', 'Deutsch', storage),
              _buildLanguageTile(context, 'zh', '中文', storage),
              _buildLanguageTile(context, 'ja', '日本語', storage),
              _buildLanguageTile(context, 'ru', 'Русский', storage),
              _buildLanguageTile(context, 'pt', 'Português', storage),
              _buildLanguageTile(context, 'hi', 'हिन्दी', storage),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String code,
    String name,
    StorageService storage,
  ) {
    return ListTile(
      title: Text(name),
      leading: Radio<String>(
        value: code,
        groupValue: storage.locale.languageCode,
        onChanged: (value) {
          if (value != null) {
            storage.setLocale(Locale(value));
            Navigator.pop(context);
          }
        },
      ),
      onTap: () {
        storage.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  String _getLanguageName(String code) {
    final names = {
      'en': 'English',
      'ar': 'العربية',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'zh': '中文',
      'ja': '日本語',
      'ru': 'Русский',
      'pt': 'Português',
      'hi': 'हिन्दी',
    };
    return names[code] ?? code;
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Digital Saver',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.favorite,
        color: Colors.red,
        size: 48,
      ),
      children: [
        const Text(
          'A smartwatch health monitoring app with emergency alerts.',
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.medicalDisclaimer,
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
