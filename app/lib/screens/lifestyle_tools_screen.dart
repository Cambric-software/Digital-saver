import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class LifestyleToolsScreen extends StatefulWidget {
  const LifestyleToolsScreen({super.key});

  @override
  State<LifestyleToolsScreen> createState() => _LifestyleToolsScreenState();
}

class _LifestyleToolsScreenState extends State<LifestyleToolsScreen> {
  // 1. Intermittent Fasting Tracker (#4)
  bool _isFasting = false;
  String _fastingPlan = '16:8';
  DateTime? _fastingStartTime;
  int _fastingDurationHours = 16;
  Timer? _fastingTimer;

  // 2. Sleep Debt & Recovery (#8)
  double _targetSleep = 8.0;
  double _actualSleepAvg = 6.4;
  double _sleepDebtHours = 11.2;

  // 3. Noise Exposure & Hearing Safety (#9)
  int _currentDbLevel = 62;
  String _hearingSafetyRating = 'Safe (Moderate)';

  // 4. Daily Mood & Energy Logger (#16)
  int _selectedMoodIndex = 1; // 0: Great, 1: Good, 2: Okay, 3: Tired, 4: Stressed
  final List<String> _moodLabels = ['Great', 'Good', 'Okay', 'Tired', 'Stressed'];
  final List<String> _moodIcons = ['😄', '🙂', '😐', '🥱', '😫'];
  double _energyLevel = 7.0; // 1-10
  final List<String> _selectedTags = [];
  final List<String> _availableTags = ['Deep Sleep', 'Post-Workout', 'Busy Day', 'Relaxed', 'Caffeine'];
  String _lastSavedMood = '';

  // 5. BMR & Daily Calorie Burn (#18)
  int _calcAge = 25;
  double _calcWeightKg = 72.0;
  double _calcHeightCm = 175.0;
  String _calcGender = 'Male';
  double _activityMultiplier = 1.375; // Lightly active
  double _bmrResult = 1705;
  double _tdeeResult = 2344;

  // 6. Posture & Sedentary Break Timer (#19)
  int _postureIntervalMinutes = 30;
  int _postureSecondsRemaining = 1800;
  bool _postureTimerActive = false;
  Timer? _postureTimer;
  int _breaksCompletedToday = 3;

  @override
  void initState() {
    super.initState();
    _loadStoredPreferences();
  }

  @override
  void dispose() {
    _fastingTimer?.cancel();
    _postureTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStoredPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFasting = prefs.getBool('fasting_active') ?? false;
      final startStr = prefs.getString('fasting_start_time');
      if (startStr != null) {
        _fastingStartTime = DateTime.tryParse(startStr);
      }
      _fastingPlan = prefs.getString('fasting_plan') ?? '16:8';
      _fastingDurationHours = int.tryParse(_fastingPlan.split(':').first) ?? 16;
      _lastSavedMood = prefs.getString('today_logged_mood') ?? 'Good (Energy: 7/10)';
      _breaksCompletedToday = prefs.getInt('posture_breaks_count') ?? 3;
    });

    if (_isFasting) {
      _startFastingTicker();
    }
    _recalcBmr();
  }

  void _startFastingTicker() {
    _fastingTimer?.cancel();
    _fastingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _toggleFasting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_isFasting) {
        _isFasting = false;
        _fastingStartTime = null;
        _fastingTimer?.cancel();
        prefs.remove('fasting_active');
        prefs.remove('fasting_start_time');
      } else {
        _isFasting = true;
        _fastingStartTime = DateTime.now();
        prefs.setBool('fasting_active', true);
        prefs.setString('fasting_start_time', _fastingStartTime!.toIso8601String());
        _startFastingTicker();
      }
    });
  }

  void _togglePostureTimer() {
    if (_postureTimerActive) {
      _postureTimer?.cancel();
      setState(() => _postureTimerActive = false);
    } else {
      setState(() {
        _postureTimerActive = true;
        _postureSecondsRemaining = _postureIntervalMinutes * 60;
      });
      _postureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_postureSecondsRemaining > 0) {
          setState(() => _postureSecondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _postureTimerActive = false;
            _breaksCompletedToday++;
          });
          SharedPreferences.getInstance().then((p) {
            p.setInt('posture_breaks_count', _breaksCompletedToday);
          });
          _showPostureAlert();
        }
      });
    }
  }

  void _showPostureAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.accessibility_new, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Posture & Movement Break!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time to stand up, roll your shoulders, and hydrate!'),
            SizedBox(height: 12),
            Text('• 10 Shoulder rolls back\n• 5 Neck side-stretches\n• Drink 1 glass of water\n• Look 20ft away for 20s'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Break Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _recalcBmr() {
    // Mifflin-St Jeor / Revised Harris-Benedict
    double bmr;
    if (_calcGender == 'Male') {
      bmr = (10 * _calcWeightKg) + (6.25 * _calcHeightCm) - (5 * _calcAge) + 5;
    } else {
      bmr = (10 * _calcWeightKg) + (6.25 * _calcHeightCm) - (5 * _calcAge) - 161;
    }
    setState(() {
      _bmrResult = bmr;
      _tdeeResult = bmr * _activityMultiplier;
    });
  }

  void _saveMoodEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final entry = '${_moodIcons[_selectedMoodIndex]} ${_moodLabels[_selectedMoodIndex]} (Energy: ${_energyLevel.toInt()}/10)';
    await prefs.setString('today_logged_mood', entry);
    setState(() => _lastSavedMood = entry);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily mood & energy logged successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifestyle & Health Tools'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.self_improvement, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily health routines, circadian tracking, and metabolic tools.',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Intermittent Fasting Tracker (#4)
          _buildFastingCard(),
          const SizedBox(height: 16),

          // 2. Sleep Debt & Recovery (#8)
          _buildSleepDebtCard(),
          const SizedBox(height: 16),

          // 3. Noise Exposure & Hearing Safety (#9)
          _buildNoiseSafetyCard(),
          const SizedBox(height: 16),

          // 4. Daily Mood & Energy Logger (#16)
          _buildMoodLoggerCard(),
          const SizedBox(height: 16),

          // 5. BMR & Calorie Burn Calculator (#18)
          _buildBmrCard(),
          const SizedBox(height: 16),

          // 6. Posture & Sedentary Break Timer (#19)
          _buildPostureCard(),
          const SizedBox(height: 24),
        ],
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Feature 1 (#4): Intermittent Fasting
  Widget _buildFastingCard() {
    int elapsedSec = 0;
    if (_isFasting && _fastingStartTime != null) {
      elapsedSec = DateTime.now().difference(_fastingStartTime!).inSeconds;
    }
    final targetSec = _fastingDurationHours * 3600;
    final progress = (elapsedSec / targetSec).clamp(0.0, 1.0);
    final hours = elapsedSec ~/ 3600;
    final mins = (elapsedSec % 3600) ~/ 60;
    final secs = elapsedSec % 60;

    String stage = 'Digestion Window';
    if (hours >= 12) stage = 'Ketosis & Fat-Burning';
    else if (hours >= 8) stage = 'Blood Sugar Normalizing';
    else if (hours >= 4) stage = 'Early Fasting Stage';

    return _buildCard(
      title: 'Intermittent Fasting Tracker (#4)',
      icon: Icons.timer_outlined,
      children: [
        Row(
          children: [
            const Text('Fasting Protocol: ', style: TextStyle(fontWeight: FontWeight.w500)),
            DropdownButton<String>(
              value: _fastingPlan,
              underline: const SizedBox(),
              items: ['14:10', '16:8', '18:6', '20:4'].map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: _isFasting ? null : (v) {
                if (v != null) {
                  setState(() {
                    _fastingPlan = v;
                    _fastingDurationHours = int.tryParse(v.split(':').first) ?? 16;
                  });
                }
              },
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isFasting ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isFasting ? 'FASTING ACTIVE' : 'EATING WINDOW',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: _isFasting ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isFasting
                  ? '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Elapsed'
                  : 'Fast not started',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Target: ${_fastingDurationHours}h',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Biological Status: $stage', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _toggleFasting,
            icon: Icon(_isFasting ? Icons.stop : Icons.play_arrow),
            label: Text(_isFasting ? 'End Fasting Session' : 'Start Fasting Timer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFasting ? Colors.red.shade600 : AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Feature 2 (#8): Sleep Debt & Recovery
  Widget _buildSleepDebtCard() {
    return _buildCard(
      title: 'Sleep Debt & Recovery (#8)',
      icon: Icons.bedtime_outlined,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-Day Avg Sleep', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${_actualSleepAvg.toStringAsFixed(1)} hrs/night', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Sleep Target', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${_targetSleep.toStringAsFixed(1)} hrs/night', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Accumulated Debt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '+${_sleepDebtHours.toStringAsFixed(1)} hrs',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catch-up strategy: Add 45-60 min sleep over the next 4 nights to clear debt without circadian shift.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Feature 3 (#9): Noise Exposure & Hearing Safety
  Widget _buildNoiseSafetyCard() {
    return _buildCard(
      title: 'Hearing Health & Sound Exposure (#9)',
      icon: Icons.hearing_outlined,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_currentDbLevel dB SPL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                Text(_hearingSafetyRating, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('WHO Limit: 85 dB (8h)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Ambient sound estimated via Veyro microphone sensor. Prolonged exposure above 85 dB can cause temporary threshold shifts.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // Feature 4 (#16): Daily Mood & Energy Logger
  Widget _buildMoodLoggerCard() {
    return _buildCard(
      title: 'Daily Mood & Energy Journal (#16)',
      icon: Icons.sentiment_satisfied_alt,
      children: [
        const Text('How are you feeling right now?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_moodIcons.length, (idx) {
            final isSelected = _selectedMoodIndex == idx;
            return GestureDetector(
              onTap: () => setState(() => _selectedMoodIndex = idx),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(_moodIcons[idx], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(_moodLabels[idx], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Energy Level:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${_energyLevel.toInt()} / 10', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: _energyLevel,
          min: 1,
          max: 10,
          divisions: 9,
          label: '${_energyLevel.toInt()}',
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _energyLevel = v),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: _availableTags.map((tag) {
            final isChosen = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag, style: TextStyle(fontSize: 11, color: isChosen ? Colors.white : Colors.black87)),
              selected: isChosen,
              selectedColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveMoodEntry,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Log Today\'s Mood'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
        if (_lastSavedMood.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Last Logged: $_lastSavedMood', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ],
    );
  }

  // Feature 5 (#18): BMR & Caloric Expenditure Calculator
  Widget _buildBmrCard() {
    return _buildCard(
      title: 'BMR & Caloric Burn Calculator (#18)',
      icon: Icons.local_fire_department_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Age', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  TextFormField(
                    initialValue: '$_calcAge',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) {
                      _calcAge = int.tryParse(v) ?? _calcAge;
                      _recalcBmr();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weight (kg)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  TextFormField(
                    initialValue: '${_calcWeightKg.toInt()}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) {
                      _calcWeightKg = double.tryParse(v) ?? _calcWeightKg;
                      _recalcBmr();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Height (cm)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  TextFormField(
                    initialValue: '${_calcHeightCm.toInt()}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) {
                      _calcHeightCm = double.tryParse(v) ?? _calcHeightCm;
                      _recalcBmr();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Basal Metabolic Rate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${_bmrResult.toInt()} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const Text('Calories burned at rest', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Est. Daily Burn (TDEE)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${_tdeeResult.toInt()} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                  const Text('With daily movement', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Feature 6 (#19): Posture & Sedentary Break Timer
  Widget _buildPostureCard() {
    final mins = _postureSecondsRemaining ~/ 60;
    final secs = _postureSecondsRemaining % 60;

    return _buildCard(
      title: 'Posture & Ergonomic Breaks (#19)',
      icon: Icons.accessibility_new_outlined,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: _postureTimerActive ? AppColors.primary : Colors.grey,
                  ),
                ),
                Text(
                  _postureTimerActive ? 'Active Desk Countdown' : 'Timer Paused',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$_breaksCompletedToday Completed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                const Text('Daily Goal: 6 breaks', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _togglePostureTimer,
            icon: Icon(_postureTimerActive ? Icons.pause : Icons.play_arrow),
            label: Text(_postureTimerActive ? 'Pause Break Timer' : 'Start 30-Min Posture Timer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _postureTimerActive ? Colors.orange : AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
