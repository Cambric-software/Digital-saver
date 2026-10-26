/// Insights: trends, guidance and progress in one page.
///
/// The previous version was a 33-line wrapper around a [DefaultTabController]
/// and a [TabBar] inside its own [Scaffold]. The app shell already supplies the
/// page frame, so opening Insights nested a page inside a page; and the tab bar
/// was the only route to three screens that were themselves full pages with
/// their own app bars.
///
/// This version is one [DsPage] with a segmented control. The three bodies are
/// plain widgets with no scaffold of their own, so each can be shown here or
/// rendered on its own.
library;

import 'package:flutter/material.dart';

import 'package:cambric_design/cambric_design.dart';
import 'achievements_screen.dart';
import 'health_tips_screen.dart';
import 'health_trends_screen.dart';

/// The three views inside Insights.
enum _View { trends, guidance, progress }

/// Trends, guidance and progress.
class InsightsScreen extends StatefulWidget {
  /// Create the page.
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _View _view = _View.trends;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Three labels fit a phone without a TabBar's scroll behaviour, and
        // the icons keep each choice recognisable when the label is long.
        DsSegmented<_View>(
          value: _view,
          onChanged: (_View view) => setState(() => _view = view),
          options: const <DsSegment<_View>>[
            DsSegment<_View>(
              value: _View.trends,
              label: 'Trends',
              icon: Icons.show_chart_rounded,
            ),
            DsSegment<_View>(
              value: _View.guidance,
              label: 'Guidance',
              icon: Icons.lightbulb_outline_rounded,
            ),
            DsSegment<_View>(
              value: _View.progress,
              label: 'Progress',
              icon: Icons.emoji_events_outlined,
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        // Keyed so switching views rebuilds the body from scratch and one
        // view's loaded history cannot leak into the next.
        KeyedSubtree(
          key: ValueKey<_View>(_view),
          child: switch (_view) {
            _View.trends => const HealthTrendsScreen(),
            _View.guidance => const HealthTipsScreen(),
            _View.progress => const AchievementsScreen(),
          },
        ),
      ],
    );

    return DsPage(title: 'Insights', child: content);
  }
}
