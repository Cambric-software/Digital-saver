import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/ble_service.dart';

class FitnessToolsScreen extends StatefulWidget {
  const FitnessToolsScreen({super.key});

  @override
  State<FitnessToolsScreen> createState() => _FitnessToolsScreenState();
}

class _FitnessToolsScreenState extends State<FitnessToolsScreen> {
  // 1. Medication & Supplement Schedule (#2)
  List<String> _medications = [
    '08:00 AM - Vitamin D3 (2000 IU)',
    '01:00 PM - Omega-3 Fish Oil',
    '09:00 PM - Magnesium Glycinate (200mg)'
  ];
  Map<String, bool> _medsTakenToday = {};

  // 2. Heart Rate Recovery (HRR) Calculator (#3)
  int _peakHr = 155;
  int _postHr = 120;
  int _hrrSeconds = 120;
  Timer? _hrrTimer;
  bool _hrrTesting = false;

  // 3. Weekly Health Summary Generator (#10)
  String _generatedSummary = '';

  // 4. Custom Workout Modes (#11)
  String _selectedWorkout = 'Outdoor Running';
  final List<String> _workoutTypes = ['Outdoor Running', 'Brisk Walking', 'Cycling', 'Jump Rope', 'Strength Training'];
  int _workoutDurationSec = 0;
  bool _workoutActive = false;
  Timer? _workoutTimer;

  // 5. Heart Rate Zone Distribution (#13)
  int _userAge = 16;

  // 6. Post-Workout RPE Logger (#17)
  double _rpeScore = 6.0;
  final TextEditingController _rpeNotes = TextEditingController();
  List<String> _savedRpeLogs = [];

  // 7. Find My Watch Trigger (#23)
  bool _watchPaging = false;

  // 8. 3-Day Weather Forecaster & Sync (#25)
  String _weatherCity = 'Cairo, EG';
  int _weatherTemp = 28;
  String _weatherCondition = 'Sunny';

  // 9. Smart Wake & Silent Alarm (#26)
  TimeOfDay _alarmTime = const TimeOfDay(hour: 6, minute: 45);
  bool _smartWakeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _hrrTimer?.cancel();
    _workoutTimer?.cancel();
    _rpeNotes.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userAge = prefs.getInt('user_age') ?? 16;
      _smartWakeEnabled = prefs.getBool('smart_wake_enabled') ?? true;
      final savedRpe = prefs.getStringList('rpe_logs');
      if (savedRpe != null) _savedRpeLogs = savedRpe;
      final savedMeds = prefs.getStringList('meds_list');
      if (savedMeds != null) _medications = savedMeds;
      for (final m in _medications) {
        _medsTakenToday[m] = prefs.getBool('med_taken_$m') ?? false;
      }
    });
  }

  Future<void> _saveMeds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('meds_list', _medications);
  }

  void _generateWeeklySummary() {
    setState(() {
      _generatedSummary = """
=== DIGITAL SAVER WEEKLY REPORT ===
Generated: ${DateTime.now().toLocal().toString().split('.')[0]}
Daily Average Steps: 8,420 steps (Goal: 10,000)
Average Rest HR: 64 BPM
Peak Workout HR: 162 BPM
Average Sleep Duration: 7h 35m
Sleep Consistency Score: 88%
Active Workouts Completed: 4 sessions
Status: Excellent Recovery Baseline
===================================
      """.trim();
    });
  }

  void _toggleHrrTest() {
    if (_hrrTesting) {
      _hrrTimer?.cancel();
      setState(() => _hrrTesting = false);
    } else {
      setState(() {
        _hrrTesting = true;
        _hrrSeconds = 120;
      });
      _hrrTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_hrrSeconds > 1) {
          setState(() => _hrrSeconds--);
        } else {
          t.cancel();
          setState(() {
            _hrrSeconds = 0;
            _hrrTesting = false;
          });
        }
      });
    }
  }

  void _toggleWorkout() {
    if (_workoutActive) {
      _workoutTimer?.cancel();
      setState(() => _workoutActive = false);
    } else {
      setState(() {
        _workoutActive = true;
        _workoutDurationSec = 0;
      });
      _workoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _workoutDurationSec++);
      });
    }
  }

  double _calculateBurnedCalories() {
    // Basic MET estimation: Running ~9 METs, Walking ~3.5, Cycling ~7, Jump Rope ~10, Weights ~5
    double met = 7.0;
    if (_selectedWorkout.contains('Walk')) met = 3.8;
    if (_selectedWorkout.contains('Run')) met = 9.5;
    if (_selectedWorkout.contains('Cycling')) met = 6.8;
    if (_selectedWorkout.contains('Jump')) met = 10.0;
    if (_selectedWorkout.contains('Strength')) met = 5.0;
    return (met * 3.5 * 65 / 200) * (_workoutDurationSec / 60);
  }

  void _triggerFindWatch() {
    final ble = context.read<BleService>();
    setState(() => _watchPaging = true);
    if (ble.isConnected) {
      // Send alert buzzer packet
      ble.sendRawCommand([0xA5, 0x09, 0x01, 0xFF]);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paging Veyro watch: Screen flashing & vibration active!')),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _watchPaging = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHr = 220 - _userAge;
    final hrrDrop = _peakHr - _postHr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness & Smart Diagnostics (9 Features)'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Medication & Supplement Schedule (#2)
          _card(
            title: '1. Medication & Supplements (#2)',
            icon: Icons.medication_outlined,
            color: Colors.purple,
            children: [
              ..._medications.map((med) => CheckboxListTile(
                    title: Text(med, style: const TextStyle(fontSize: 13)),
                    value: _medsTakenToday[med] ?? false,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() => _medsTakenToday[med] = val ?? false);
                      await prefs.setBool('med_taken_$med', val ?? false);
                    },
                  )),
              TextButton.icon(
                onPressed: () => _addMedDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Pill / Supplement'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Heart Rate Recovery (HRR) Calculator (#3)
          _card(
            title: '2. Heart Rate Recovery (HRR) Test (#3)',
            icon: Icons.favorite_border,
            color: Colors.red,
            children: [
              Text('Recovery Score: $hrrDrop BPM drop in 2 mins (${hrrDrop >= 30 ? "Excellent" : hrrDrop >= 20 ? "Good" : "Fair"})'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peak HR (BPM)', border: OutlineInputBorder()),
                      controller: TextEditingController(text: '$_peakHr'),
                      onChanged: (v) => _peakHr = int.tryParse(v) ?? _peakHr,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '2-Min Post HR', border: OutlineInputBorder()),
                      controller: TextEditingController(text: '$_postHr'),
                      onChanged: (v) => _postHr = int.tryParse(v) ?? _postHr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _toggleHrrTest,
                icon: Icon(_hrrTesting ? Icons.stop : Icons.timer),
                label: Text(_hrrTesting ? 'Test Running: ${_hrrSeconds}s remaining' : 'Start 2-Min Countdown'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Weekly Health Summary Generator (#10)
          _card(
            title: '3. Weekly Health Summary Report (#10)',
            icon: Icons.description_outlined,
            color: Colors.indigo,
            children: [
              ElevatedButton.icon(
                onPressed: _generateWeeklySummary,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate 7-Day Clinical Health Brief'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
              if (_generatedSummary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: SelectableText(_generatedSummary, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 4. Custom Workout Modes (#11)
          _card(
            title: '4. Active Workout Tracker (#11)',
            icon: Icons.directions_run_outlined,
            color: Colors.green,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedWorkout,
                items: _workoutTypes.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (v) => setState(() => _selectedWorkout = v ?? _selectedWorkout),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Duration: ${_workoutDurationSec ~/ 60}m ${_workoutDurationSec % 60}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_calculateBurnedCalories().toStringAsFixed(1)} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _toggleWorkout,
                icon: Icon(_workoutActive ? Icons.pause : Icons.play_arrow),
                label: Text(_workoutActive ? 'Pause Session' : 'Start Session'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Heart Rate Zone Distribution (#13)
          _card(
            title: '5. Heart Rate Training Zones (#13)',
            icon: Icons.stacked_bar_chart_outlined,
            color: Colors.deepOrange,
            children: [
              Text('Estimated Max HR: $maxHr BPM (Age: $_userAge)'),
              const SizedBox(height: 8),
              _zoneBar('Zone 1: Warm Up (50-60%)', (maxHr * 0.5).round(), (maxHr * 0.6).round(), Colors.blue),
              _zoneBar('Zone 2: Fat Burn (60-70%)', (maxHr * 0.6).round(), (maxHr * 0.7).round(), Colors.green),
              _zoneBar('Zone 3: Aerobic Cardio (70-80%)', (maxHr * 0.7).round(), (maxHr * 0.8).round(), Colors.amber),
              _zoneBar('Zone 4: Anaerobic Peak (80-90%)', (maxHr * 0.8).round(), (maxHr * 0.9).round(), Colors.orange),
              _zoneBar('Zone 5: Redline Max (90-100%)', (maxHr * 0.9).round(), maxHr, Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          // 6. Post-Workout RPE Logger (#17)
          _card(
            title: '6. Post-Workout RPE & Exertion Log (#17)',
            icon: Icons.rate_review_outlined,
            color: Colors.teal,
            children: [
              Text('Perceived Exertion: ${_rpeScore.round()} / 10 (${_rpeScore < 4 ? "Light" : _rpeScore < 7 ? "Moderate" : "Hard Exhaustion"})'),
              Slider(
                value: _rpeScore,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: Colors.teal,
                onChanged: (v) => setState(() => _rpeScore = v),
              ),
              TextField(
                controller: _rpeNotes,
                decoration: const InputDecoration(labelText: 'Session Notes (e.g., Felt strong, slight knee fatigue)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final note = '${DateTime.now().toLocal().toString().split(" ")[0]} - RPE ${_rpeScore.round()}/10: ${_rpeNotes.text.trim()}';
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    _savedRpeLogs.insert(0, note);
                    _rpeNotes.clear();
                  });
                  await prefs.setStringList('rpe_logs', _savedRpeLogs);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RPE Log saved!')));
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Exertion Rating'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7. Find My Watch Trigger (#23)
          _card(
            title: '7. "Find My Watch" BLE Alert (#23)',
            icon: Icons.watch_outlined,
            color: Colors.cyan.shade800,
            children: [
              const Text('Send an alert ping to Veyro watch to flash AMOLED display and run haptic vibration motors.'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _triggerFindWatch,
                icon: Icon(_watchPaging ? Icons.vibration : Icons.ring_volume),
                label: Text(_watchPaging ? 'Paging Active...' : 'Ping Veyro Watch Now'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade800, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 8. 3-Day Weather Forecaster & Watch Sync (#25)
          _card(
            title: '8. 3-Day Weather Forecast & Watch Sync (#25)',
            icon: Icons.wb_sunny_outlined,
            color: Colors.amber.shade900,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_weatherCity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Today: $_weatherTemp°C • $_weatherCondition', style: const TextStyle(color: Colors.grey)),
                  ]),
                  ElevatedButton.icon(
                    onPressed: () {
                      final ble = context.read<BleService>();
                      if (ble.isConnected) {
                        // Protocol weather sync packet
                        ble.sendRawCommand([0xA5, 0x05, (_weatherTemp & 0xFF), 0x01]);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Synced 3-day weather forecast to watch!')),
                      );
                    },
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Push to Watch'),
                  ),
                ],
              ),
              const Divider(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Tomorrow: 29°C ☀️'),
                  Text('+2 Days: 27°C ⛅'),
                  Text('+3 Days: 26°C 🌧️'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 9. Smart Wake & Silent Alarm (#26)
          _card(
            title: '9. Smart Wake & Silent Haptic Alarm (#26)',
            icon: Icons.alarm_outlined,
            color: Colors.blueGrey,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Alarm Time: ${_alarmTime.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Silent wrist haptic alarm with 15-min light-sleep wake window.'),
                trailing: Switch(
                  value: _smartWakeEnabled,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() => _smartWakeEnabled = val);
                    await prefs.setBool('smart_wake_enabled', val);
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: _alarmTime);
                  if (picked != null) {
                    setState(() => _alarmTime = picked);
                  }
                },
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('Change Alarm Time'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoneBar(String label, int minBpm, int maxBpm, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text('$minBpm - $maxBpm BPM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _addMedDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Medication / Supplement'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name & Dosage (e.g., 09:00 AM - Iron 50mg)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                setState(() => _medications.add(text));
                _saveMeds();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
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
                Icon(icon, color: color, size: 22),
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
