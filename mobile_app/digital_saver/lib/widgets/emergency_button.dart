import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digital_saver/theme/app_theme.dart';

class EmergencyButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const EmergencyButton({super.key, this.onPressed});

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.heavyImpact();
    widget.onPressed?.call();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isPressed = true);
    HapticFeedback.mediumImpact();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleTap,
          onLongPressStart: _handleLongPressStart,
          onLongPressEnd: _handleLongPressEnd,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppTheme.dangerRed,
                  AppTheme.dangerRed.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.dangerRed.withOpacity(0.4 * _pulseAnimation.value),
                  blurRadius: 20 + (10 * _pulseAnimation.value),
                  spreadRadius: 2 * _pulseAnimation.value,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.98 : _scaleAnimation.value),
            transformAlignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulse animation indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3 + (0.7 * _pulseAnimation.value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'EMERGENCY',
                            style: AppTheme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hold for 3 seconds to alert contacts',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3 + (0.7 * _pulseAnimation.value)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
