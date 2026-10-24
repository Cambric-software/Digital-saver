/// Watch face previews, separated from the hardware they used to claim.
///
/// The old screen was a simulator that could not simulate anything. It toggled
/// a bluetooth icon in the app bar and called itself connected while no BLE
/// call was made; it invented a heart rate, an SpO2 value, a temperature, a
/// step count and a battery level, then walked each of them with a random
/// number generator every three seconds; it printed a firmware version and
/// "Last Sync: Just now" as constants. The watch face showed "MON, AUG 02" and
/// 12:34 whatever the date and time were. One of its two animation controllers
/// threw on the second controller because the state used the single-ticker
/// mixin, which made the screen fail as soon as it opened.
///
/// What is here now: three faces drawn with Flutter widgets and painters, a
/// selector to look at them, and a plain statement that this is a preview. It
/// does not connect, pair, sync, set a face or read a sensor, and every number
/// in the drawing is labelled as a sample. There are no timers or animations,
/// because there is nothing live to animate.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';
import 'package:cambric_design/cambric_design.dart';

/// The three layouts the preview can draw.
enum _FaceStyle {
  analog('Analog'),
  digital('Digital'),
  rings('Rings');

  const _FaceStyle(this.label);

  final String label;
}

/// Face previews that make no claim to be the watch.
class WatchSimulatorScreen extends StatefulWidget {
  /// Create the screen.
  const WatchSimulatorScreen({super.key});

  @override
  State<WatchSimulatorScreen> createState() => _WatchSimulatorScreenState();
}

class _WatchSimulatorScreenState extends State<WatchSimulatorScreen> {
  _FaceStyle _face = _FaceStyle.analog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watch simulator')),
      body: DsPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DsSection(
              title: 'Preview only',
              subtitle: 'A drawing in this app, not the watch.',
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Nothing on this screen is connected to a watch. It does '
                      'not scan, pair, sync, change a face or read a sensor. '
                      'Every number in the drawings is a sample value placed '
                      'there to show the layout.',
                    ),
                    SizedBox(height: Space.sm),
                    Text(
                      'To see real readings, pair a watch in Settings. To send '
                      'a face index to a paired watch, use Settings or the '
                      'Device diagnostics screen.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            DsSection(
              title: 'Face preview',
              subtitle: 'Three layouts, drawn with the app\'s own widgets.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DsSegmented<_FaceStyle>(
                    value: _face,
                    options: <DsSegment<_FaceStyle>>[
                      for (final _FaceStyle style in _FaceStyle.values)
                        DsSegment<_FaceStyle>(
                          value: style,
                          label: style.label,
                        ),
                    ],
                    onChanged: (_FaceStyle value) =>
                        setState(() => _face = value),
                  ),
                  const SizedBox(height: Space.lg),
                  Center(child: _WatchPreview(style: _face)),
                  const SizedBox(height: Space.md),
                  Text(
                    'Roughly to scale at 260 logical pixels across. The real '
                    'watch draws its own faces; this is a layout sketch.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),
            const DsSection(
              title: 'What this preview cannot do',
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'It cannot show your live heart rate, oxygen, steps or '
                      'battery, because it has no connection to the watch. The '
                      'values drawn here stay the same while the screen is '
                      'open.',
                    ),
                    SizedBox(height: Space.sm),
                    Text(
                      'It cannot change anything on a watch. Sending a face is '
                      'a command on the command characteristic, and this screen '
                      'never writes to it.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A circular case containing the selected face layout.
class _WatchPreview extends StatelessWidget {
  const _WatchPreview({required this.style});

  final _FaceStyle style;

  static const double _diameter = 260;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color ink = theme.colorScheme.onSurface;
    final Color accent = theme.colorScheme.primary;
    final Color second = theme.colorScheme.tertiary;
    final Color third = AppColors.of(
      AppColors.heartRed,
      AppColors.darkHeart,
      context,
    );

    return Semantics(
      label: 'Watch face preview, ${style.label}',
      image: true,
      child: Container(
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outline, width: 6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: ClipOval(
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: switch (style) {
                _FaceStyle.analog => CustomPaint(
                    painter: _AnalogFacePainter(ink: ink, accent: accent),
                    child: const SizedBox.expand(),
                  ),
                _FaceStyle.digital => _DigitalFace(
                    ink: ink,
                    muted: theme.colorScheme.onSurfaceVariant,
                    accent: third,
                  ),
                _FaceStyle.rings => CustomPaint(
                    painter: _RingsFacePainter(
                      track: theme.colorScheme.surfaceContainerHigh,
                      first: accent,
                      second: second,
                      third: third,
                    ),
                    child: _RingsLabel(ink: ink, muted: theme.colorScheme.onSurfaceVariant),
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The digital layout, using only Text and Icon widgets.
class _DigitalFace extends StatelessWidget {
  const _DigitalFace({
    required this.ink,
    required this.muted,
    required this.accent,
  });

  final Color ink;
  final Color muted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '10:10',
            style: Type.metric.copyWith(color: ink),
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'TUE 20 OCT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: muted,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.favorite_rounded, size: 16, color: accent),
              const SizedBox(width: Space.xs),
              Text('72 bpm', style: TextStyle(color: ink)),
              const SizedBox(width: Space.md),
              Icon(Icons.directions_walk_rounded, size: 16, color: muted),
              const SizedBox(width: Space.xs),
              Text('8,420', style: TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(
            'SAMPLE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: muted,
                  letterSpacing: 2,
                ),
          ),
        ],
      ),
    );
  }
}

/// The centre of the rings layout.
class _RingsLabel extends StatelessWidget {
  const _RingsLabel({required this.ink, required this.muted});

  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '8,420',
            style: Type.metricSmall.copyWith(color: ink),
          ),
          Text(
            'steps · sample',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: muted,
                ),
          ),
        ],
      ),
    );
  }
}

/// An analog face at ten past ten, with sixty tick marks.
class _AnalogFacePainter extends CustomPainter {
  const _AnalogFacePainter({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;

    for (int i = 0; i < 60; i++) {
      final double angle = i * math.pi / 30;
      final bool major = i % 5 == 0;
      final double outer = radius - 4;
      final double inner = outer - (major ? 10 : 4);
      final Offset direction = Offset(math.sin(angle), -math.cos(angle));
      final Paint tick = Paint()
        ..color = ink.withValues(alpha: major ? 0.8 : 0.35)
        ..strokeWidth = major ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + direction * inner,
        center + direction * outer,
        tick,
      );
    }

    // Hour hand at 10:10, minute hand at 10, and a thin second hand.
    _hand(
      canvas,
      center: center,
      angle: (10 + 10 / 60) / 12 * 2 * math.pi,
      length: radius * 0.48,
      width: 6,
      color: ink,
    );
    _hand(
      canvas,
      center: center,
      angle: 10 / 60 * 2 * math.pi,
      length: radius * 0.72,
      width: 4,
      color: ink,
    );
    _hand(
      canvas,
      center: center,
      angle: 30 / 60 * 2 * math.pi,
      length: radius * 0.66,
      width: 1.5,
      color: accent,
    );
    canvas.drawCircle(center, 4, Paint()..color = accent);
  }

  static void _hand(
    Canvas canvas, {
    required Offset center,
    required double angle,
    required double length,
    required double width,
    required Color color,
  }) {
    final Offset direction = Offset(math.sin(angle), -math.cos(angle));
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + direction * length, paint);
  }

  @override
  bool shouldRepaint(_AnalogFacePainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.accent != accent;
}

/// Three concentric activity rings at fixed sample values.
class _RingsFacePainter extends CustomPainter {
  const _RingsFacePainter({
    required this.track,
    required this.first,
    required this.second,
    required this.third,
  });

  final Color track;
  final Color first;
  final Color second;
  final Color third;

  static const List<double> _values = <double>[0.78, 0.54, 0.32];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 16;
    final List<Color> colors = <Color>[first, second, third];

    for (int i = 0; i < colors.length; i++) {
      final double ringRadius = radius - i * 18;
      final Rect rect = Rect.fromCircle(center: center, radius: ringRadius);
      final Paint background = Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, background);

      final Paint arc = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * _values[i], false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingsFacePainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.first != first ||
      oldDelegate.second != second ||
      oldDelegate.third != third;
}
