import 'dart:math' as math;
import 'package:flutter/material.dart';

// Achievement badges screen
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Achievement> _achievements = [
    Achievement(
      id: 'first_sync',
      title: 'First Sync',
      description: 'Connected to your watch for the first time',
      icon: Icons.bluetooth_connected,
      color: const Color(0xFF3B82F6),
      xp: 100,
    ),
    Achievement(
      id: 'heart_health',
      title: 'Heart Guardian',
      description: 'Monitored your heart rate for 7 consecutive days',
      icon: Icons.favorite,
      color: Colors.red,
      xp: 250,
      isLocked: true,
    ),
    Achievement(
      id: 'step_master',
      title: 'Step Master',
      description: 'Reached 10,000 steps in a single day',
      icon: Icons.directions_walk,
      color: const Color(0xFF10B981),
      xp: 200,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Logged health data before 7 AM',
      icon: Icons.wb_sunny,
      color: Colors.amber,
      xp: 150,
      isLocked: true,
    ),
    Achievement(
      id: 'sleep_well',
      title: 'Sleep Well',
      description: 'Achieved 8+ hours of sleep for 5 nights',
      icon: Icons.bedtime,
      color: const Color(0xFF8B5CF6),
      xp: 300,
      isLocked: true,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Used the app for 7 days in a row',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      xp: 400,
      isNew: true,
    ),
    Achievement(
      id: 'health_hero',
      title: 'Health Hero',
      description: 'Maintained a health score above 90 for 30 days',
      icon: Icons.shield,
      color: const Color(0xFFEC4899),
      xp: 500,
      isLocked: true,
    ),
    Achievement(
      id: 'data_master',
      title: 'Data Master',
      description: 'Logged all health metrics for 14 days',
      icon: Icons.analytics,
      color: const Color(0xFF06B6D4),
      xp: 350,
      isLocked: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F172A),
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E3A5F).withOpacity(0.8),
                      const Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_achievements.where((a) => !a.isLocked).length}/${_achievements.length} Unlocked',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _AchievementCard(
                  achievement: _achievements[index],
                  controller: _controller,
                  index: index,
                ),
                childCount: _achievements.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xp;
  final bool isLocked;
  final bool isNew;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xp,
    this.isLocked = false,
    this.isNew = false,
  });
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AnimationController controller;
  final int index;

  const _AchievementCard({
    required this.achievement,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final floatOffset = math.sin(controller.value * 2 * math.pi + index * 0.5) * 5;

        return Transform.translate(
          offset: Offset(0, achievement.isLocked ? 0 : floatOffset),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(achievement.isLocked ? 0.03 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: achievement.isLocked
                    ? Colors.white.withOpacity(0.1)
                    : achievement.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: achievement.isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: achievement.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: achievement.isLocked
                              ? Colors.grey.withOpacity(0.2)
                              : achievement.color.withOpacity(0.2),
                          border: Border.all(
                            color: achievement.isLocked
                                ? Colors.grey.withOpacity(0.3)
                                : achievement.color.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          achievement.isLocked ? Icons.lock : achievement.icon,
                          color: achievement.isLocked ? Colors.grey : achievement.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        achievement.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: achievement.isLocked ? Colors.grey : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(achievement.isLocked ? 0.3 : 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: achievement.isLocked
                              ? Colors.grey.withOpacity(0.1)
                              : achievement.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${achievement.xp} XP',
                          style: TextStyle(
                            color: achievement.isLocked ? Colors.grey : achievement.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (achievement.isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
