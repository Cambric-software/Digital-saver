import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final storage = Provider.of<StorageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Profile',
                        style: AppTheme.titleLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure your health profile',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appearance
          _buildSectionTitle('Appearance'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: t.darkMode,
                  trailing: Switch(
                    value: storage.isDarkMode,
                    onChanged: (value) => storage.setDarkMode(value),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: t.language,
                  subtitle: _getLanguageName(storage.locale.languageCode),
                  onTap: () => _showLanguageDialog(context, storage),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notifications
          _buildSectionTitle('Notifications'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.notifications_rounded,
                  title: t.notifications,
                  trailing: Switch(
                    value: storage.notificationsEnabled,
                    onChanged: (value) => storage.setNotificationsEnabled(value),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.favorite_rounded,
                  title: 'Heart Rate Alerts',
                  subtitle: 'Alert when abnormal HR detected',
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.water_drop_rounded,
                  title: 'Blood Pressure Alerts',
                  subtitle: 'Alert when BP is elevated',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Health Thresholds
          _buildSectionTitle('Health Thresholds'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildThresholdSlider(
                  title: t.heartRateThreshold,
                  value: storage.heartRateThreshold.toDouble(),
                  min: 80,
                  max: 140,
                  unit: t.bpm,
                  onChanged: (value) => storage.setHeartRateThreshold(value.toInt()),
                ),
                const SizedBox(height: 20),
                _buildThresholdSlider(
                  title: t.bpThreshold,
                  value: storage.systolicThreshold.toDouble(),
                  min: 120,
                  max: 180,
                  unit: t.mmhg,
                  onChanged: (value) => storage.setSystolicThreshold(value.toInt()),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Emergency Contacts
          _buildSectionTitle('Emergency Contacts'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.contacts_rounded,
                  title: 'Manage Contacts',
                  subtitle: '${storage.emergencyContacts.length} contacts saved',
                  onTap: () => Navigator.pushNamed(context, '/contacts'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.local_hospital_rounded,
                  title: 'Emergency Services',
                  subtitle: 'Call 123 (Egypt)',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Watch
          _buildSectionTitle('Watch'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.watch_rounded,
                  title: 'Watch Settings',
                  subtitle: 'Configure watch preferences',
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.sync_rounded,
                  title: 'Sync Data',
                  subtitle: 'Last sync: 5 minutes ago',
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.firmware_rounded,
                  title: 'Firmware Update',
                  subtitle: 'Current: v1.0.0',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.healthyGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Up to date',
                      style: TextStyle(
                        color: AppTheme.healthyGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About
          _buildSectionTitle('About'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.info_rounded,
                  title: 'About',
                  subtitle: 'Version 2.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.description_rounded,
                  title: 'Terms of Service',
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.help_rounded,
                  title: 'Help & Support',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.titleMedium);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: AppTheme.titleMedium),
      subtitle: subtitle != null ? Text(subtitle, style: AppTheme.bodySmall) : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildThresholdSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${value.toInt()} $unit',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
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

  void _showLanguageDialog(BuildContext context, StorageService storage) {
    final t = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(t.selectLanguage, style: AppTheme.headlineSmall),
            const SizedBox(height: 16),
            ...['en', 'ar', 'es', 'fr', 'de', 'zh', 'ja', 'ru', 'pt', 'hi']
                .map((code) => ListTile(
                      title: Text(_getLanguageName(code)),
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
                    )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Digital Saver',
      applicationVersion: '2.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.favorite, color: AppTheme.primaryColor, size: 48),
      ),
      children: [
        Text(
          'A professional health monitoring app with advanced features for heart rate, blood pressure, and emergency alerts.',
        ),
        const SizedBox(height: 16),
        Text(
          '⚠️ This app provides wellness estimates and is not a medical device.',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
