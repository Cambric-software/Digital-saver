import 'dart:math' as math;
import 'package:flutter/material.dart';

// Daily health tips screen
class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentTipIndex = 0;

  final List<HealthTip> _tips = [
    HealthTip(
      category: 'Heart Health',
      icon: Icons.favorite,
      color: Colors.red,
      title: 'Monitor Your Heart Rate',
      content: 'A normal resting heart rate for adults ranges from 60 to 100 beats per minute. Athletes may have lower rates. Track yours regularly to notice patterns.',
      actionable: 'Check your heart rate now',
    ),
    HealthTip(
      category: 'Sleep',
      icon: Icons.bedtime,
      color: Color(0xFF8B5CF6),
      title: 'Consistent Sleep Schedule',
      content: 'Going to bed and waking up at the same time every day helps regulate your body\'s internal clock. Aim for 7-9 hours of quality sleep.',
      actionable: 'Set a bedtime reminder',
    ),
    HealthTip(
      category: 'Activity',
      icon: Icons.directions_walk,
      color: Color(0xFF10B981),
      title: 'Take the Stairs',
      content: 'Just 2 minutes of stair climbing can improve heart health, burn calories, and boost energy levels. Small activities add up throughout the day.',
      actionable: 'Log your activity',
    ),
    HealthTip(
      category: 'Hydration',
      icon: Icons.water_drop,
      color: Color(0xFF3B82F6),
      title: 'Stay Hydrated',
      content: 'Drink at least 8 glasses of water daily. Your body needs water for every cell function, temperature regulation, and toxin removal.',
      actionable: 'Set a hydration reminder',
    ),
    HealthTip(
      category: 'SpO2',
      icon: Icons.air,
      color: Color(0xFF06B6D4),
      title: 'Understanding SpO2',
      content: 'Blood oxygen saturation (SpO2) measures how much oxygen your red blood cells carry. Normal levels are 95-100%. Low levels may indicate breathing issues.',
      actionable: 'Check your SpO2 level',
    ),
    HealthTip(
      category: 'Stress',
      icon: Icons.self_improvement,
      color: Color(0xFFEC4899),
      title: 'Take Deep Breaths',
      content: 'Practice deep breathing for 5 minutes daily. It activates your parasympathetic nervous system, reducing stress hormones and promoting relaxation.',
      actionable: 'Start a breathing exercise',
    ),
    HealthTip(
      category: 'Nutrition',
      icon: Icons.restaurant,
      color: Colors.orange,
      title: 'Colorful Plates',
      content: 'Eat a variety of colorful fruits and vegetables. Different colors provide different nutrients your body needs for optimal health.',
      actionable: 'Track your meals',
    ),
    HealthTip(
      category: 'Posture',
      icon: Icons.accessibility_new,
      color: Color(0xFF14B8A6),
      title: 'Check Your Posture',
      content: 'Good posture reduces strain on muscles and joints, prevents back pain, and even boosts confidence. Sit up straight and take regular breaks.',
      actionable: 'Set a posture reminder',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _currentTipIndex = DateTime.now().hour % _tips.length;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextTip() {
    _controller.reverse().then((_) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
      });
      _controller.forward();
    });
  }

  void _previousTip() {
    _controller.reverse().then((_) {
      setState(() {
        _currentTipIndex = (_currentTipIndex - 1 + _tips.length) % _tips.length;
      });
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_currentTipIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F172A),
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      tip.color.withOpacity(0.3),
                      const Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(tip.icon, color: tip.color, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Daily Health Tips',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Swipe to see more tips',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: tip.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tip.color.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tip.category,
                      style: TextStyle(
                        color: tip.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Main tip card
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (_controller.value * 0.2),
                        child: Opacity(
                          opacity: _controller.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tip.color.withOpacity(0.15),
                            tip.color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: tip.color.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tip.color.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: tip.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(tip.icon, color: tip.color, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  tip.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            tip.content,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: tip.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tip.color.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: tip.color, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip.actionable,
                                    style: TextStyle(
                                      color: tip.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavButton(
                        icon: Icons.arrow_back_ios,
                        onTap: _previousTip,
                      ),
                      const SizedBox(width: 20),
                      _buildIndicator(),
                      const SizedBox(width: 20),
                      _buildNavButton(
                        icon: Icons.arrow_forward_ios,
                        onTap: _nextTip,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // All tips preview
                  const Text(
                    'All Tips',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tips grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _tips.length,
                    itemBuilder: (context, index) {
                      final t = _tips[index];
                      return GestureDetector(
                        onTap: () {
                          _controller.reverse().then((_) {
                            setState(() {
                              _currentTipIndex = index;
                            });
                            _controller.forward();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _currentTipIndex == index
                                ? t.color.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _currentTipIndex == index
                                  ? t.color.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(t.icon, color: t.color, size: 24),
                              const Spacer(),
                              Text(
                                t.category,
                                style: TextStyle(
                                  color: _currentTipIndex == index ? t.color : Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_tips.length, (index) {
        final isActive = index == _currentTipIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _tips[index].color : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class HealthTip {
  final String category;
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  final String actionable;

  HealthTip({
    required this.category,
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
    required this.actionable,
  });
}
