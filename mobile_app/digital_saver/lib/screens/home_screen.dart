import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/services/emergency_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';
import 'package:digital_saver/widgets/health_card.dart';
import 'package:digital_saver/widgets/connection_status.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer3<BleService, StorageService, EmergencyService>(
        builder: (context, ble, storage, emergency, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status Card
                ConnectionStatusWidget(
                  isConnected: ble.isConnected,
                  deviceName: ble.connectedDevice?.platformName ?? 'Digital Saver Watch',
                ),
                
                const SizedBox(height: 20),
                
                // Heart Rate Card
                HealthCard(
                  title: l10n.heartRate,
                  value: ble.latestHealthData?.heartRate.toString() ?? '--',
                  unit: l10n.bpm,
                  icon: Icons.favorite,
                  color: Colors.red,
                  status: ble.latestHealthData?.status ?? HealthStatus.normal,
                ),
                
                const SizedBox(height: 12),
                
                // Blood Pressure Card
                HealthCard(
                  title: l10n.bloodPressure,
                  value: ble.latestBpData?.displayString ?? '--/--',
                  unit: l10n.mmhg,
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  status: _getBpStatus(ble.latestBpData),
                ),
                
                const SizedBox(height: 12),
                
                // SpO2 Card
                HealthCard(
                  title: l10n.oxygen,
                  value: ble.latestHealthData?.spO2?.toString() ?? '--',
                  unit: l10n.percent,
                  icon: Icons.air,
                  color: Colors.cyan,
                  status: _getSpO2Status(ble.latestHealthData?.spO2),
                ),
                
                const SizedBox(height: 20),
                
                // Emergency Button
                if (emergency.emergencyActive)
                  _buildEmergencyActive(context, emergency)
                else
                  _buildEmergencyButton(context),
                
                const SizedBox(height: 20),
                
                // Emergency Contacts Quick Access
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.contacts, color: Colors.orange),
                    title: Text(l10n.emergencyContacts),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/contacts'),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Medical Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.medicalDisclaimer,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showEmergencyDialog(context),
      icon: const Icon(Icons.emergency),
      label: Text(AppLocalizations.of(context)!.callEmergency),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmergencyActive(BuildContext context, EmergencyService emergency) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.warning_amber, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.emergencyAlert,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.emergencyMessage),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => emergency.callEmergencyServices(),
                  icon: const Icon(Icons.phone),
                  label: Text(AppLocalizations.of(context)!.callEmergency),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                OutlinedButton.icon(
                  onPressed: () => emergency.cancelEmergency(),
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context)!.cancelAlert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = Provider.of<StorageService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.emergencyAlert),
          ],
        ),
        content: Text(l10n.areYouOkay),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final emergency = Provider.of<EmergencyService>(context, listen: false);
              final alert = AlertData(
                type: AlertType.fall,
                severity: AlertSeverity.critical,
                timestamp: DateTime.now(),
              );
              emergency.triggerEmergency(alert, storage.emergencyContacts);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.sendAlert),
          ),
        ],
      ),
    );
  }

  HealthStatus _getBpStatus(BloodPressureData? bp) {
    if (bp == null) return HealthStatus.normal;
    if (bp.systolic > 180 || bp.diastolic > 120) return HealthStatus.alert;
    if (bp.systolic > 140 || bp.diastolic > 90) return HealthStatus.warning;
    return HealthStatus.normal;
  }

  HealthStatus _getSpO2Status(int? spO2) {
    if (spO2 == null) return HealthStatus.normal;
    if (spO2 < 90) return HealthStatus.alert;
    if (spO2 < 95) return HealthStatus.warning;
    return HealthStatus.normal;
  }
}
