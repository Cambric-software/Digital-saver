import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/models/health_data.dart';
import 'package:digital_saver/i18n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HealthData> _records = [];
  bool _isLoading = true;
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final storage = Provider.of<StorageService>(context, listen: false);
    final records = await storage.getHealthHistory();
    
    setState(() {
      _records = _filterByPeriod(records);
      _isLoading = false;
    });
  }

  List<HealthData> _filterByPeriod(List<HealthData> records) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    switch (_selectedPeriod) {
      case 'today':
        return records.where((r) => r.timestamp.isAfter(startOfDay)).toList();
      case 'week':
        return records.where((r) => r.timestamp.isAfter(startOfWeek)).toList();
      case 'month':
        return records.where((r) => r.timestamp.isAfter(startOfMonth)).toList();
      default:
        return records;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'today', label: Text(l10n.today)),
                ButtonSegment(value: 'week', label: Text(l10n.thisWeek)),
                ButtonSegment(value: 'month', label: Text(l10n.thisMonth)),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (selection) {
                setState(() => _selectedPeriod = selection.first);
                _loadHistory();
              },
            ),
          ),
          
          // Statistics Summary
          if (_records.isNotEmpty) _buildStatsSummary(l10n),
          
          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noRecentData,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return _buildRecordCard(record, l10n);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(AppLocalizations l10n) {
    final heartRates = _records.map((r) => r.heartRate).toList();
    final avgHr = (heartRates.reduce((a, b) => a + b) / heartRates.length).round();
    final minHr = heartRates.reduce((a, b) => a < b ? a : b);
    final maxHr = heartRates.reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heart Rate Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(l10n.minHeartRate, minHr.toString(), Colors.green),
                _buildStatItem(l10n.avgHeartRate, avgHr.toString(), Colors.blue),
                _buildStatItem(l10n.maxHeartRate, maxHr.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${_records.length} ${l10n.readings}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRecordCard(HealthData record, AppLocalizations l10n) {
    Color statusColor;
    switch (record.status) {
      case HealthStatus.alert:
        statusColor = Colors.red;
        break;
      case HealthStatus.warning:
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.favorite, color: statusColor),
        ),
        title: Text(
          '${record.heartRate} ${l10n.bpm}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.systolic != null)
              Text('${l10n.bloodPressure}: ${record.systolic}/${record.diastolic} ${l10n.mmhg}'),
            Text(
              _formatTime(record.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusLabel(record.status, l10n),
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - '
        '${dt.day}/${dt.month}/${dt.year}';
  }

  String _getStatusLabel(HealthStatus status, AppLocalizations l10n) {
    switch (status) {
      case HealthStatus.alert:
        return l10n.statusAlert;
      case HealthStatus.warning:
        return l10n.statusWarning;
      default:
        return l10n.statusNormal;
    }
  }
}
