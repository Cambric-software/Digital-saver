import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/local_store.dart';
import '../services/memory_analyzer.dart';
import '../services/veyro_protocol.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  MemoryReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final samples = await LocalStore.loadAll();
    if (!mounted) return;
    setState(() {
      _report = MemoryAnalyzer.analyze(samples);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final r = _report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch memory'),
        actions: [
          IconButton(
            onPressed: ble.isConnected ? () async {
              await ble.startMemorySync();
              await Future<void>.delayed(const Duration(seconds: 2));
              await _load();
            } : null,
            icon: const Icon(Icons.sync),
            tooltip: 'Pull from Veyro',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (ble.syncingMemory)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Copying watch log… ${ble.memoryRows} rows'),
                  ),
                Text(
                  'Veyro keeps ${VeyroProtocol.retainDays} days on flash. Older days are deleted so the chip does not fill up.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (ble.watchInfo.fw.isNotEmpty)
                  Text('Firmware ${ble.watchInfo.fw} · ${ble.watchInfo.samples} samples on watch · ${ble.watchInfo.freeKb} KB free'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Samples', '${r?.samples ?? 0}'),
                    _chip('Avg HR', r?.avgHr == 0 ? '—' : '${r!.avgHr}'),
                    _chip('Rest HR', r?.restHr == 0 ? '—' : '${r!.restHr}'),
                    _chip('SpO2', r?.avgSpo2 == 0 ? '—' : '${r!.avgSpo2}%'),
                    _chip('Falls', '${r?.falls ?? 0}'),
                  ],
                ),
                const SizedBox(height: 20),
                ...?r?.notes.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(n),
                  ),
                ),
                if (r?.first != null)
                  Text(
                    'Oldest sample will drop around ${r!.deletesAfter.toLocal().toString().split(' ').first}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
    );
  }

  Widget _chip(String k, String v) => Chip(label: Text('$k  $v'));
}
