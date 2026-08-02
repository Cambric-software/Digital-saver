import 'dart:math' as math;
import 'package:flutter/material.dart';

// Floating quick actions widget
class QuickActionsWidget extends StatefulWidget {
  final VoidCallback? onEmergency;
  final VoidCallback? onCallDoctor;
  final VoidCallback? onCheckVitals;
  final VoidCallback? onShareLocation;

  const QuickActionsWidget({
    super.key,
    this.onEmergency,
    this.onCallDoctor,
    this.onCheckVitals,
    this.onShareLocation,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded actions
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAction(
                    icon: Icons.location_on,
                    label: 'Share Location',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      _toggle();
                      widget.onShareLocation?.call();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildAction(
                    icon: Icons.monitor_heart,
                    label: 'Check Vitals',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      _toggle();
                      widget.onCheckVitals?.call();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildAction(
                    icon: Icons.phone,
                    label: 'Call Doctor',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      _toggle();
                      widget.onCallDoctor?.call();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildAction(
                    icon: Icons.emergency,
                    label: 'Emergency',
                    color: Colors.red,
                    isEmergency: true,
                    onTap: () {
                      _toggle();
                      widget.onEmergency?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Main button
          _buildMainButton(),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * math.pi / 4,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isExpanded ? Icons.close : Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isEmergency ? color : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isEmergency ? Colors.white : color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isEmergency ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

// Animated stat card
class AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
  final double? progress;
  final String? trend;
  final bool isPositive;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
    this.progress,
    this.trend,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Circular timer widget
class CircularTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;
  final Color? color;

  const CircularTimer({
    super.key,
    required this.seconds,
    this.onComplete,
    this.color,
  });

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    _controller = AnimationController(
      duration: Duration(seconds: widget.seconds),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.addListener(() {
      setState(() {
        _remainingSeconds = (widget.seconds * (1 - _controller.value)).ceil();
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF2563EB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: _TimerPainter(
                  progress: _controller.value,
                  color: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'remaining',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (1 - progress),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
