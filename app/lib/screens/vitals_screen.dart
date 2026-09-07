import 'package:flutter/material.dart';
import 'bp_screen.dart';
import 'heart_screen.dart';

class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vitals'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite_outline), text: 'Heart'),
              Tab(icon: Icon(Icons.water_drop_outlined), text: 'Blood pressure'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [HeartScreen(), BpScreen()],
        ),
      ),
    );
  }
}
