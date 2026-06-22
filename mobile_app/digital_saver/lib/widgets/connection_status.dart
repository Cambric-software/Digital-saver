import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/i18n/app_localizations.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final String deviceName;

  const ConnectionStatusWidget({
    super.key,
    required this.isConnected,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ble = Provider.of<BleService>(context);

    return Card(
      color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade100 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.watch,
                color: isConnected ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Connection Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? l10n.watchConnected : l10n.watchDisconnected,
                        style: TextStyle(
                          color: isConnected ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Connect/Disconnect Button
            if (isConnected)
              TextButton.icon(
                onPressed: () => ble.disconnect(),
                icon: const Icon(Icons.link_off, size: 18),
                label: Text(l10n.disconnect),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              )
            else
              ElevatedButton.icon(
                onPressed: ble.isScanning ? null : () => ble.startScan(),
                icon: ble.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching, size: 18),
                label: Text(ble.isScanning ? l10n.scanning : l10n.connect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
