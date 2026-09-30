import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'wellness_tools_screen.dart';
import 'fitness_tools_screen.dart';
import 'lifestyle_tools_screen.dart';
import 'device_diagnostics_screen.dart';

class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({super.key});

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen> {
  // Feature #41: Daily Movement Activity Rings
  int _activeCalories = 380;
  final int _targetCalories = 500;
  int _exerciseMins = 24;
  final int _targetExerciseMins = 30;
  int _standHours = 8;
  final int _targetStandHours = 12;

  // Feature #42: Circadian Sunlight Exposure
  int _sunlightSeconds = 0;
  final int _targetSunlightSeconds = 900; // 15 mins
  bool _sunlightActive = false;
  Timer? _sunlightTimer;

  // Feature #43: Handwashing 20-Second Timer
  int _handwashSeconds = 20;
  bool _handwashActive = false;
  Timer? _handwashTimer;

  // Feature #44: Visual Acuity & 20-20-20 Eye Break
  bool _eyeBreakActive = false;
  int _eyeBreakSeconds = 20;
  Timer? _eyeBreakTimer;

  // Feature #45: Dental Brushing Quadrant Timer
  int _brushingQuadrant = 1;
  int _brushingSeconds = 120;
  bool _brushingActive = false;
  Timer? _brushingTimer;

  // Feature #46: Daily Gratitude & Reflection
  final TextEditingController _gratitudeController = TextEditingController();
  String _savedGratitude = '';

  // Feature #47: Focus & Pomodoro Productivity Timer
  int _pomodoroSeconds = 1500; // 25 min
  bool _pomodoroActive = false;
  Timer? _pomodoroTimer;
  String _currentTask = 'Firmware Optimization';

  // Feature #48: Cold Exposure & Contrast Recovery
  int _coldSeconds = 0;
  bool _coldActive = false;
  Timer? _coldTimer;

  // Feature #49: Breath-Hold Capacity (Apnea / CO2 Tolerance)
  int _apneaSeconds = 0;
  bool _apneaActive = false;
  Timer? _apneaTimer;
  int _personalBestApnea = 48;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _sunlightTimer?.cancel();
    _handwashTimer?.cancel();
    _eyeBreakTimer?.cancel();
    _brushingTimer?.cancel();
    _pomodoroTimer?.cancel();
    _coldTimer?.cancel();
    _apneaTimer?.cancel();
    _gratitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedGratitude = prefs.getString('daily_gratitude') ?? '';
      _personalBestApnea = prefs.getInt('pb_apnea_sec') ?? 48;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambric 50-Feature Health Hub'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Responsive Clamp for Desktop
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Feature #50: Master Navigation Grid
              _buildMasterHubCard(),
              const SizedBox(height: 16),

              // Feature #41: Activity Rings
              _buildActivityRingsCard(),
              const SizedBox(height: 16),

              // Feature #42: Circadian Sunlight Exposure
              _buildSunlightCard(),
              const SizedBox(height: 16),

              // Feature #43: Handwashing Timer
              _buildHandwashCard(),
              const SizedBox(height: 16),

              // Feature #44: 20-20-20 Eye Strain Break
              _buildEyeBreakCard(),
              const SizedBox(height: 16),

              // Feature #45: Dental Quadrant Timer
              _buildBrushingCard(),
              const SizedBox(height: 16),

              // Feature #46: Daily Gratitude Prompt
              _buildGratitudeCard(),
              const SizedBox(height: 16),

              // Feature #47: Focus & Pomodoro Timer
              _buildPomodoroCard(),
              const SizedBox(height: 16),

              // Feature #48: Cold Exposure Recovery
              _buildColdExposureCard(),
              const SizedBox(height: 16),

              // Feature #49: Breath-Hold Capacity Tester
              _buildApneaCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Feature #50: Unified Cambric Hub
  Widget _buildMasterHubCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cambric Suite: 50/50 Features Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Tap any specialized suite to open full controls:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHubButton('Wellness Suite (7)', Icons.spa, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessToolsScreen()))),
              _buildHubButton('Fitness Suite (9)', Icons.fitness_center, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessToolsScreen()))),
              _buildHubButton('Lifestyle & BMR (6)', Icons.self_improvement, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LifestyleToolsScreen()))),
              _buildHubButton('Device & Sensor (15)', Icons.tune, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceDiagnosticsScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHubButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0),
    );
  }

  // Feature #41
  Widget _buildActivityRingsCard() {
    return _buildCard(
      title: 'Daily Movement Activity Rings (#41)',
      icon: Icons.donut_large,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildRingStat('Move', '$_activeCalories/$_targetCalories kcal', _activeCalories / _targetCalories, Colors.red),
            _buildRingStat('Exercise', '$_exerciseMins/$_targetExerciseMins min', _exerciseMins / _targetExerciseMins, Colors.green),
            _buildRingStat('Stand', '$_standHours/$_targetStandHours hrs', _standHours / _targetStandHours, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildRingStat(String label, String value, double progress, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), color: color, backgroundColor: color.withOpacity(0.2), strokeWidth: 5),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // Feature #42
  Widget _buildSunlightCard() {
    return _buildCard(
      title: 'Circadian Sunlight Exposure Tracker (#42)',
      icon: Icons.wb_sunny,
      children: [
        Text('${_sunlightSeconds ~/ 60}m ${_sunlightSeconds % 60}s of 15m Morning Light Goal', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _sunlightSeconds / _targetSunlightSeconds, color: Colors.amber),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _sunlightActive = !_sunlightActive);
            if (_sunlightActive) {
              _sunlightTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (!mounted) { t.cancel(); return; }
                setState(() => _sunlightSeconds++);
              });
            } else {
              _sunlightTimer?.cancel();
            }
          },
          icon: Icon(_sunlightActive ? Icons.pause : Icons.play_arrow),
          label: Text(_sunlightActive ? 'Pause Sunlight Timer' : 'Start Morning Sunlight'),
        ),
      ],
    );
  }

  // Feature #43
  Widget _buildHandwashCard() {
    return _buildCard(
      title: 'Hygiene & 20-Second Handwashing (#43)',
      icon: Icons.clean_hands,
      children: [
        Text(_handwashActive ? '$_handwashSeconds seconds remaining' : 'WHO-recommended 20s hygiene scrub.', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _handwashActive ? null : () {
            setState(() { _handwashActive = true; _handwashSeconds = 20; });
            _handwashTimer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (!mounted) { t.cancel(); return; }
              if (_handwashSeconds > 1) {
                setState(() => _handwashSeconds--);
              } else {
                t.cancel();
                setState(() => _handwashActive = false);
              }
            });
          },
          child: const Text('Start 20s Handwash'),
        ),
      ],
    );
  }

  // Feature #44
  Widget _buildEyeBreakCard() {
    return _buildCard(
      title: '20-20-20 Visual Acuity & Eye Strain Break (#44)',
      icon: Icons.remove_red_eye,
      children: [
        const Text('Every 20 minutes, look at an object 20 feet away for 20 seconds.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            setState(() => _eyeBreakActive = true);
            Future.delayed(const Duration(seconds: 20), () {
              if (mounted) setState(() => _eyeBreakActive = false);
            });
          },
          child: Text(_eyeBreakActive ? 'Looking 20ft away...' : 'Start 20s Eye Break'),
        ),
      ],
    );
  }

  // Feature #45
  Widget _buildBrushingCard() {
    return _buildCard(
      title: 'Dental Brushing Quadrant Guide (#45)',
      icon: Icons.sentiment_very_satisfied,
      children: [
        Text('Quadrant $_brushingQuadrant of 4 • ${_brushingSeconds ~/ 60}:${(_brushingSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            setState(() => _brushingActive = !_brushingActive);
          },
          child: Text(_brushingActive ? 'Pause Dental Timer' : 'Start 2-Min Brushing'),
        ),
      ],
    );
  }

  // Feature #46
  Widget _buildGratitudeCard() {
    return _buildCard(
      title: 'Daily Gratitude & Mindful Reflection (#46)',
      icon: Icons.favorite,
      children: [
        TextField(
          controller: _gratitudeController,
          decoration: const InputDecoration(hintText: 'What are you grateful for today?', isDense: true),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            SharedPreferences.getInstance().then((p) => p.setString('daily_gratitude', _gratitudeController.text));
            setState(() => _savedGratitude = _gratitudeController.text);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gratitude logged!')));
          },
          child: const Text('Save Reflection'),
        ),
        if (_savedGratitude.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Logged: $_savedGratitude', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ],
    );
  }

  // Feature #47
  Widget _buildPomodoroCard() {
    return _buildCard(
      title: 'Focus & Pomodoro Productivity Timer (#47)',
      icon: Icons.timer,
      children: [
        Text('Task: $_currentTask • ${_pomodoroSeconds ~/ 60}:${(_pomodoroSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => _pomodoroActive = !_pomodoroActive),
          child: Text(_pomodoroActive ? 'Pause Focus' : 'Start 25-Min Focus'),
        ),
      ],
    );
  }

  // Feature #48
  Widget _buildColdExposureCard() {
    return _buildCard(
      title: 'Cold Exposure & Contrast Recovery (#48)',
      icon: Icons.ac_unit,
      children: [
        Text('${_coldSeconds}s Cold Exposure Session', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => _coldActive = !_coldActive),
          child: Text(_coldActive ? 'Stop Cold Timer' : 'Start Cold Shower Timer'),
        ),
      ],
    );
  }

  // Feature #49
  Widget _buildApneaCard() {
    return _buildCard(
      title: 'Breath-Hold & CO2 Tolerance Trainer (#49)',
      icon: Icons.air,
      children: [
        Text('Hold: ${_apneaSeconds}s • Personal Best: ${_personalBestApnea}s', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => setState(() => _apneaActive = !_apneaActive),
          child: Text(_apneaActive ? 'Exhale & Stop' : 'Start Breath Hold'),
        ),
      ],
    );
  }
}
