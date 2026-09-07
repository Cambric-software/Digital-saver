import 'package:flutter/material.dart';
import 'achievements_screen.dart';
import 'health_tips_screen.dart';
import 'health_trends_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
              Tab(icon: Icon(Icons.lightbulb_outline), text: 'Guidance'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Progress'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HealthTrendsScreen(),
            HealthTipsScreen(),
            AchievementsScreen(),
          ],
        ),
      ),
    );
  }
}
