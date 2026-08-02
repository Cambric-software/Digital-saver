import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';

// Watch simulator screen for development/demo purposes
class WatchSimulatorScreen extends StatefulWidget {
  const WatchSimulatorScreen({super.key});

  @override
  State<WatchSimulatorScreen> createState() => _WatchSimulatorScreenState();
}

class _WatchSimulatorScreenState extends State<WatchSimulatorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _heartbeatController;
  
  // Simulated watch data
  double _heartRate = 72;
  double _spO2 = 98;
  double _temperature = 36.6;
  int _steps = 5420;
  int _battery = 85;
  bool _isConnected = true;
  
  // Random data generation
  final _random = math.Random();
  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _heartbeatController = AnimationController(
      duration: _heartbeatDuration(_heartRate),
      vsync: this,
    )..repeat();

    _startDataSimulation();
  }

  Duration _heartbeatDuration(double bpm) {
    final secondsPerBeat = 60 / bpm;
    return Duration(milliseconds: (secondsPerBeat * 1000).round());
  }

  void _startDataSimulation() {
    _dataTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      
      setState(() {
        // Add slight variations to simulate real data
        _heartRate = (_heartRate + (_random.nextDouble() - 0.5) * 4).clamp(55, 110);
        _spO2 = (_spO2 + (_random.nextDouble() - 0.5) * 2).clamp(94, 100);
        _temperature = (_temperature + (_random.nextDouble() - 0.5) * 0.3).clamp(35.5, 38.5);
        _steps += _random.nextInt(50);
        _battery = (_battery - (_random.nextDouble() * 0.1)).clamp(0, 100).toInt();
      });
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _heartbeatController.dispose();
    _dataTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Watch Simulator'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.blue : Colors.grey,
            ),
            onPressed: () => setState(() => _isConnected = !_isConnected),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Watch face simulation
            _buildWatchFace(),
            const SizedBox(height: 30),
            
            // Health metrics cards
            _buildMetricsGrid(),
            const SizedBox(height: 20),
            
            // Activity section
            _buildActivitySection(),
            const SizedBox(height: 20),
            
            // Device info
            _buildDeviceInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchFace() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
          border: Border.all(
            color: const Color(0xFF334155),
            width: 4,
          ),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Time
                  Text(
                    '12:34',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MON, AUG 02',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Heart rate with animation
                  AnimatedBuilder(
                    animation: _heartbeatController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_heartbeatController.value < 0.1 
                            ? (0.1 - _heartbeatController.value) * 3 
                            : 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red.withOpacity(0.5 + _heartbeatController.value * 0.5),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_heartRate.round()}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              ' BPM',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // SpO2 with breathing animation
                  AnimatedBuilder(
                    animation: _breathingController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.3 + _breathingController.value * 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.air,
                              color: const Color(0xFF3B82F6).withOpacity(0.5 + _breathingController.value * 0.5),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_spO2.round()}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              ' SpO2',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(
          icon: Icons.favorite,
          iconColor: Colors.red,
          value: '${_heartRate.round()}',
          unit: 'BPM',
          label: 'Heart Rate',
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(
          icon: Icons.air,
          iconColor: const Color(0xFF3B82F6),
          value: '${_spO2.round()}',
          unit: '%',
          label: 'SpO2',
        )),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Steps progress
          Row(
            children: [
              const Icon(Icons.directions_walk, color: Color(0xFF10B981), size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_steps',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '/ 10,000',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_steps / 10000).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Temperature and battery
          Row(
            children: [
              Expanded(
                child: _buildSmallMetric(
                  icon: Icons.thermostat,
                  value: _temperature.toStringAsFixed(1),
                  unit: '°C',
                  label: 'Temperature',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallMetric(
                  icon: Icons.battery_full,
                  value: '$_battery',
                  unit: '%',
                  label: 'Battery',
                  color: _battery > 20 ? const Color(0xFF10B981) : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow('Device', 'Onyx Watch (Simulated)'),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('Status', _isConnected ? 'Connected' : 'Disconnected', 
              valueColor: _isConnected ? const Color(0xFF10B981) : Colors.red),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('Firmware', 'v2.3.1'),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('Last Sync', 'Just now'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
