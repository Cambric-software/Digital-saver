import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class WellnessToolsScreen extends StatefulWidget {
  const WellnessToolsScreen({super.key});

  @override
  State<WellnessToolsScreen> createState() => _WellnessToolsScreenState();
}

class _WellnessToolsScreenState extends State<WellnessToolsScreen> with SingleTickerProviderStateMixin {
  // 1. Hydration State
  int _waterGlasses = 0;
  final int _targetGlasses = 10; // 2.5L target (250ml per glass)

  // 2. Emergency ICE Card State
  String _bloodType = 'A+';
  String _emergencyContact = '+20 100 000 0000';
  String _allergies = 'Penicillin, Peanuts';
  String _medicalNotes = 'Carries EpiPen. No other chronic conditions.';

  // 3. Box Breathing State
  int _breathPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  int _breathSeconds = 4;
  Timer? _breathTimer;
  bool _breathingActive = false;
  final List<String> _phases = ['Inhale (4s)', 'Hold (4s)', 'Exhale (4s)', 'Hold (4s)'];

  // 4. Caffeine Curfew State
  int _coffeesLoggedToday = 1;
  DateTime _lastCoffeeTime = DateTime.now().subtract(const Duration(hours: 2));

  // 5. Rest Interval Timer State
  int _restSecondsRemaining = 60;
  int _restTotalSeconds = 60;
  Timer? _restTimer;
  bool _restActive = false;

  // 6. Stride Length Calibration State
  double _strideLengthCm = 76.0;

  // 7. Daily Step Streak State
  int _streakDays = 5;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterGlasses = prefs.getInt('wellness_water_glasses') ?? 3;
      _bloodType = prefs.getString('ice_blood_type') ?? 'A+';
      _emergencyContact = prefs.getString('ice_emergency_contact') ?? '+20 100 000 0000';
      _allergies = prefs.getString('ice_allergies') ?? 'None listed';
      _medicalNotes = prefs.getString('ice_medical_notes') ?? 'None';
      _coffeesLoggedToday = prefs.getInt('wellness_coffee_count') ?? 1;
      _strideLengthCm = prefs.getDouble('wellness_stride_cm') ?? 76.0;
      _streakDays = prefs.getInt('wellness_step_streak') ?? 5;
    });
  }

  Future<void> _savePreference(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is int) await prefs.setInt(key, val);
    if (val is double) await prefs.setDouble(key, val);
    if (val is String) await prefs.setString(key, val);
  }

  void _addWater() {
    setState(() {
      _waterGlasses++;
      _savePreference('wellness_water_glasses', _waterGlasses);
    });
  }

  void _toggleBreathing() {
    setState(() {
      _breathingActive = !_breathingActive;
    });

    if (_breathingActive) {
      _breathSeconds = 4;
      _breathPhase = 0;
      _breathTimer?.cancel();
      _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _breathSeconds--;
          if (_breathSeconds <= 0) {
            _breathPhase = (_breathPhase + 1) % 4;
            _breathSeconds = 4;
          }
        });
      });
    } else {
      _breathTimer?.cancel();
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restTotalSeconds = seconds;
      _restSecondsRemaining = seconds;
      _restActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSecondsRemaining > 1) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _restSecondsRemaining = 0;
          _restActive = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final caffeineElimination = _lastCoffeeTime.add(const Duration(hours: 10));
    final caffeineRemainingHrs = caffeineElimination.difference(DateTime.now()).inHours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Tools & Features'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tool 1: Hydration Tracker
          _buildCard(
            title: '1. Daily Hydration Logger (#1)',
            icon: Icons.water_drop_outlined,
            color: Colors.blueAccent,
            children: [
              Text('Progress: ${_waterGlasses * 250} ml / ${_targetGlasses * 250} ml (${_waterGlasses}/$_targetGlasses glasses)'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_waterGlasses / _targetGlasses).clamp(0.0, 1.0),
                backgroundColor: Colors.blue.withOpacity(0.1),
                color: Colors.blueAccent,
                minHeight: 10,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addWater,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+250ml Glass'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _waterGlasses = 0;
                        _savePreference('wellness_water_glasses', 0);
                      });
                    },
                    child: const Text('Reset Today'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tool 2: Emergency ICE Card
          _buildCard(
            title: '2. Emergency ICE Medical Card (#5)',
            icon: Icons.medical_information_outlined,
            color: Colors.redAccent,
            children: [
              _buildRow('Blood Type:', _bloodType),
              _buildRow('Emergency Contact:', _emergencyContact),
              _buildRow('Known Allergies:', _allergies),
              _buildRow('Medical Notes:', _medicalNotes),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _editIceDialog(),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit ICE Health Details'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tool 3: Box Breathing & Respiration
          _buildCard(
            title: '3. Guided Box Breathing (#6)',
            icon: Icons.self_improvement_outlined,
            color: Colors.teal,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _breathingActive ? Colors.teal.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        border: Border.all(color: _breathingActive ? Colors.teal : Colors.grey, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          _breathingActive ? '${_breathSeconds}s' : 'Ready',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _breathingActive ? Colors.teal : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _breathingActive ? _phases[_breathPhase] : 'Tap below to begin 4-4-4-4 cycle',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _toggleBreathing,
                      icon: Icon(_breathingActive ? Icons.stop : Icons.play_arrow),
                      label: Text(_breathingActive ? 'Stop Session' : 'Start Box Breathing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tool 4: Caffeine Curfew Tracker
          _buildCard(
            title: '4. Caffeine Curfew & Sleep Guard (#7)',
            icon: Icons.coffee_outlined,
            color: Colors.brown,
            children: [
              Text('Coffees logged today: $_coffeesLoggedToday'),
              const SizedBox(height: 4),
              Text(
                caffeineRemainingHrs > 0
                    ? 'Estimated $caffeineRemainingHrs hours until caffeine is fully cleared for sleep.'
                    : 'System clear of caffeine. Good sleep readiness.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _coffeesLoggedToday++;
                    _lastCoffeeTime = DateTime.now();
                    _savePreference('wellness_coffee_count', _coffeesLoggedToday);
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Coffee / Tea'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tool 5: Rest Interval Timer
          _buildCard(
            title: '5. Workout Rest Interval Timer (#12)',
            icon: Icons.timer_outlined,
            color: Colors.deepOrange,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time: ${_restSecondsRemaining}s remaining',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _restActive ? Colors.deepOrange : Colors.black87,
                    ),
                  ),
                  if (_restActive)
                    IconButton(
                      icon: const Icon(Icons.stop_circle, color: Colors.red),
                      onPressed: () {
                        _restTimer?.cancel();
                        setState(() => _restActive = false);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [30, 60, 90, 120].map((sec) {
                  return ActionChip(
                    label: Text('${sec}s'),
                    onPressed: () => _startRestTimer(sec),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tool 6: Stride Length Calibration
          _buildCard(
            title: '6. Stride Length Calibration (#14)',
            icon: Icons.straighten_outlined,
            color: Colors.indigo,
            children: [
              Text('Current Stride Length: ${_strideLengthCm.round()} cm'),
              Slider(
                value: _strideLengthCm,
                min: 40,
                max: 120,
                divisions: 80,
                activeColor: Colors.indigo,
                onChanged: (v) {
                  setState(() {
                    _strideLengthCm = v;
                    _savePreference('wellness_stride_cm', v);
                  });
                },
              ),
              const Text(
                'Fine-tunes step-to-distance conversion formula for outdoor walks and runs.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tool 7: Step Streak & Lifetime Milestones
          _buildCard(
            title: '7. Step Streak & Milestone Badges (#15, #20)',
            icon: Icons.emoji_events_outlined,
            color: Colors.amber.shade800,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '$_streakDays-Day Step Streak!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge('First 10K Steps', Icons.star, true),
                  _badge('7-Day Streak', Icons.flash_on, _streakDays >= 7),
                  _badge('Half-Marathon Dist', Icons.directions_run, true),
                  _badge('100K Steps Lifetime', Icons.military_tech, false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _badge(String title, IconData icon, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? Colors.amber : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: unlocked ? Colors.amber.shade800 : Colors.grey),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: unlocked ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _editIceDialog() {
    final contactCtrl = TextEditingController(text: _emergencyContact);
    final allergiesCtrl = TextEditingController(text: _allergies);
    final notesCtrl = TextEditingController(text: _medicalNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit ICE Health Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Emergency Contact Phone')),
              TextField(controller: allergiesCtrl, decoration: const InputDecoration(labelText: 'Known Allergies')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Medical Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emergencyContact = contactCtrl.text.trim();
                _allergies = allergiesCtrl.text.trim();
                _medicalNotes = notesCtrl.text.trim();
                _savePreference('ice_emergency_contact', _emergencyContact);
                _savePreference('ice_allergies', _allergies);
                _savePreference('ice_medical_notes', _medicalNotes);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
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
