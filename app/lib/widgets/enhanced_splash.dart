/// The opening screen: the product mark, the medical disclosure and one route
/// into the app.
///
/// The previous version hand-painted its own background: a wave, 25 drifting
/// particles, two glow rings and a neon title, all in hard-coded hex values and
/// all outside the theme. It also carried two more animation controllers than
/// the screen used, so the splash kept repainting particles while the person
/// was reading the disclaimer.
///
/// The background is now the shared static [WaveBackdrop], coloured from the
/// active theme. There are no shadows and no separate palette, so the screen
/// follows light and dark mode like every other page. The animation that
/// remains is the entrance - fade, scale and text slide - and the small icon
/// breath; each controller is disposed.
library;

import 'package:flutter/material.dart';

import '../main.dart' show MainNav;
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'creative_effects.dart';

/// The app's opening screen.
class EnhancedSplashScreen extends StatefulWidget {
  /// Create the splash.
  const EnhancedSplashScreen({super.key});

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _iconController;
  late final AnimationController _textController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  bool _showDisclaimer = false;
  bool _disclaimerExpanded = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _mainController.forward();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _iconController.repeat(reverse: true);
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showDisclaimer = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _disclaimerExpanded = true);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _acceptAndContinue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNav()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = AppColors.of(
      AppColors.primary,
      AppColors.darkPrimary,
      context,
    );
    final Color second = AppColors.of(
      AppColors.sleepPurple,
      AppColors.darkSleep,
      context,
    );
    final Color warning = AppColors.of(
      AppColors.warning,
      AppColors.darkWarning,
      context,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: WaveBackdrop(
                color: accent,
                opacity: 0.18,
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (BuildContext context, Widget? child) => Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: Space.xxl),
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (BuildContext context, Widget? child) =>
                          Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[accent, second],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(Radii.xl),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _iconController,
                          builder: (BuildContext context, Widget? child) =>
                              Transform.scale(
                            scale: 1 + _iconController.value * 0.06,
                            child: child,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.xl),
                            child: Image.asset(
                              'assets/digital-saver-icon-transparent.png',
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.favorite_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.xxl),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (BuildContext context, Widget? child) => Opacity(
                        opacity: _textOpacity.value,
                        child: SlideTransition(
                          position: _textSlide,
                          child: child,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          ShaderMask(
                            shaderCallback: (Rect bounds) => LinearGradient(
                              colors: <Color>[
                                theme.colorScheme.onSurface,
                                accent,
                                theme.colorScheme.onSurface,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Digital Saver',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.sm),
                          Text(
                            'Health Monitoring System',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xl),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (BuildContext context, Widget? child) => Opacity(
                        opacity: _textOpacity.value,
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.xl,
                          vertical: Space.sm,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Radii.pill),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(Radii.sm),
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                color: accent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Text(
                              'Made by Cambric',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.xxl),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (BuildContext context, Widget? child) => Opacity(
                        opacity: _textOpacity.value,
                        child: child,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _buildStatItem(
                            theme,
                            Icons.favorite_rounded,
                            'Heart Rate',
                            'Real-time',
                          ),
                          _buildStatItem(
                            theme,
                            Icons.air_rounded,
                            'SpO2',
                            'Monitoring',
                          ),
                          _buildStatItem(
                            theme,
                            Icons.warning_amber_rounded,
                            'Fall Detection',
                            'Alert',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xxl),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _showDisclaimer
                          ? AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(Space.xl),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(Radii.xl),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.all(Space.sm),
                                        decoration: BoxDecoration(
                                          color:
                                              warning.withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(Radii.sm),
                                        ),
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: warning,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: Space.md),
                                      Expanded(
                                        child: Text(
                                          'Medical Disclaimer',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Space.lg),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Column(
                                      children: <Widget>[
                                        Text(
                                          'Digital Saver is for informational '
                                          'purposes only. Always consult a '
                                          'qualified healthcare professional '
                                          'for medical concerns.',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: Space.md),
                                        Container(
                                          padding:
                                              const EdgeInsets.all(Space.md),
                                          decoration: BoxDecoration(
                                            color:
                                                warning.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              Radii.md,
                                            ),
                                            border: Border.all(
                                              color: warning.withValues(
                                                  alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Icon(
                                                Icons.info_outline_rounded,
                                                color: warning,
                                                size: 18,
                                              ),
                                              const SizedBox(width: Space.sm),
                                              Expanded(
                                                child: Text(
                                                  'This app is NOT a certified '
                                                  'medical device.',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: warning,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: Space.xl),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton(
                                            onPressed: _acceptAndContinue,
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: Space.lg,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  'I Understand & Continue',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: Space.sm),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    crossFadeState: _disclaimerExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 400),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: <Widget>[
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(height: Space.lg),
                                Text(
                                  'Loading…',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: Space.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(height: Space.xs),
        Text(title, style: theme.textTheme.labelMedium),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
