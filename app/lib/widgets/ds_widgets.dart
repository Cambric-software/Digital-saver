/// The component vocabulary for Digital Saver.
///
/// Screens compose these rather than assembling raw [Card]s and [Padding]
/// each time. Every one reads its colours and spacing from the theme and the
/// token files, so light and dark are handled once, here, instead of being
/// re-guessed in twenty screens.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// A titled group of content.
///
/// The standard top-level container: a title, optional trailing action, and the
/// body. Replaces the pattern where every screen invented its own header.
class DsSection extends StatelessWidget {
  /// Create a section.
  const DsSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(Space.lg),
  });

  /// Section heading.
  final String title;

  /// Supporting line under the heading.
  final String? subtitle;

  /// Optional action, such as "See all".
  final Widget? trailing;

  /// Body.
  final Widget child;

  /// Inner padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: Space.xxs),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: Space.md),
        child,
      ],
    );
  }
}

/// A small upper-case label used above groups of content.
class DsLabel extends StatelessWidget {
  /// Create a label.
  const DsLabel(this.text, {super.key, this.color});

  /// Label text, upper-cased in the widget so callers write it naturally.
  final String text;

  /// Optional override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(color: color),
    );
  }
}

/// A raised panel with a border and no shadow.
///
/// The default container for grouped content. Shadows are avoided because they
/// do not read well on a dark surface, and a hairline border is clearer.
class DsCard extends StatelessWidget {
  /// Create a card.
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.color,
    this.borderColor,
  });

  /// Card body.
  final Widget child;

  /// Inner padding.
  final EdgeInsets padding;

  /// Makes the card tappable, with a pressed state.
  final VoidCallback? onTap;

  /// Surface override.
  final Color? color;

  /// Border override.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: borderColor ?? theme.colorScheme.outline),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: content,
      ),
    );
  }
}

/// A single health reading: label, value, unit and status.
///
/// Tabular figures so a number does not jitter as it updates, which matters
/// when the value is ticking in real time.
class DsMetricTile extends StatelessWidget {
  /// Create a tile.
  const DsMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.unit,
    this.status,
    this.icon,
    this.onTap,
  });

  /// What the reading measures, e.g. "Heart rate".
  final String label;

  /// The reading itself, as text.
  final String value;

  /// Unit shown after the value.
  final String? unit;

  /// Domain colour, e.g. red for heart.
  final Color accent;

  /// Interpretation, carried by icon and label rather than colour alone.
  final HealthStatus? status;

  /// Optional leading icon.
  final IconData? icon;

  /// Makes the tile tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = status;
    final statusColor = _statusColor(theme, state);

    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: Space.sm),
              ],
              Expanded(
                child: DsLabel(label, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (state != null && state != HealthStatus.unknown)
                Icon(state.icon, size: 16, color: statusColor),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  style: Type.metricSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...<Widget>[
                const SizedBox(width: Space.xxs),
                Text(
                  unit!,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ],
          ),
          if (state != null && state != HealthStatus.unknown) ...<Widget>[
            const SizedBox(height: Space.xs),
            Text(
              state.label,
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            ),
          ],
        ],
      ),
    );
  }

  /// Colour for a status, resolved for the current brightness.
  ///
  /// Normal is the app's secondary (teal), escalation walks amber to red, and
  /// each is paired with an icon and a word elsewhere so hue is never the only
  /// carrier of meaning.
  static Color _statusColor(ThemeData theme, HealthStatus? status) {
    final scheme = theme.colorScheme;
    return switch (status) {
      HealthStatus.normal => scheme.secondary,
      HealthStatus.elevated => scheme.tertiary,
      HealthStatus.high => _amber(theme),
      HealthStatus.critical => scheme.error,
      HealthStatus.unknown || null => scheme.onSurfaceVariant,
    };
  }

  /// Amber for the "watch this" level, which is not an error state.
  static Color _amber(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.darkWarning
      : AppColors.warning;
}

/// A compact status pill, e.g. "Connected" or "Searching".
class DsStatusPill extends StatelessWidget {
  /// Create a pill.
  const DsStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  /// Text.
  final String label;

  /// Accent colour.
  final Color color;

  /// Optional icon.
  final IconData? icon;

  /// Tighter padding.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Space.sm : Space.md,
        vertical: dense ? Space.xxs + 1 : Space.xs - 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: Space.xs),
          ],
          Text(
            label,
            style: (dense ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// What to show when there is nothing to display.
///
/// An empty screen with no explanation reads as broken, so the absence of data
/// always says what would fill it and what to do about it.
class DsEmptyState extends StatelessWidget {
  /// Create an empty state.
  const DsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  /// Illustrative icon.
  final IconData icon;

  /// Short statement of what is missing.
  final String title;

  /// What would fill this and how.
  final String message;

  /// Optional call to action.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.lg),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: Space.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of choices, used for filters and segmented controls.
class DsSegmented<T> extends StatelessWidget {
  /// Create a segmented control.
  const DsSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// Currently selected value.
  final T value;

  /// Available choices.
  final List<DsSegment<T>> options;

  /// Called with the new value.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.xxs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.sm + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final option in options)
            _SegmentButton<T>(
              option: option,
              selected: option.value == value,
              onTap: () => onChanged(option.value),
            ),
        ],
      ),
    );
  }
}

/// One option in a [DsSegmented].
class DsSegment<T> {
  /// Create an option.
  const DsSegment({required this.value, required this.label, this.icon});

  /// Value this option represents.
  final T value;

  /// Text shown.
  final String label;

  /// Optional icon.
  final IconData? icon;
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DsSegment<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? theme.colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (option.icon != null) ...<Widget>[
                  Icon(
                    option.icon,
                    size: 16,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.xs),
                ],
                Text(
                  option.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page scaffold: consistent padding, max width and optional title bar.
///
/// Content is capped at a readable measure. A health dashboard stretched across
/// a 27-inch monitor is harder to scan, not easier.
class DsPage extends StatelessWidget {
  /// Create a page.
  const DsPage({
    super.key,
    required this.child,
    this.title,
    this.actions = const <Widget>[],
    this.maxWidth = 1180,
  });

  /// Page content.
  final Widget child;

  /// Optional page title shown above the content.
  final String? title;

  /// Trailing actions.
  final List<Widget> actions;

  /// Maximum content width.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: width < Breakpoints.compact ? Space.lg : Space.xl,
          vertical: Space.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null || actions.isNotEmpty) ...<Widget>[
                  Row(
                    children: <Widget>[
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: theme.textTheme.displaySmall,
                          ),
                        )
                      else
                        const Spacer(),
                      ...actions,
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/// A grid of equally sized children that sizes to its own content.
///
/// [GridView] cannot do this inside a scrolling page: it either needs a bounded
/// height, which breaks the page, or a shrink-wrap that is expensive and still
/// fights the scroll view. Every screen here wanted the same thing - a
/// responsive grid of tiles that flows with the page - so it is here once.
///
/// The column count follows the available width rather than a fixed number, so
/// a tile is never asked to be narrower than it can render.
class DsGrid extends StatelessWidget {
  /// Create a grid.
  const DsGrid({
    required this.children,
    this.minTileWidth = 260,
    this.spacing = Space.md,
    super.key,
  });

  /// The tiles, in reading order.
  final List<Widget> children;

  /// Below this, a tile becomes a single full-width column.
  final double minTileWidth;

  /// Gap between tiles, horizontally and vertically.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = (available / minTileWidth).floor().clamp(1, 4);

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        final width =
            (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// A card describing one piece of hardware, what it measures, and its state.
///
/// The previous version laid the icon, title and status out in a [Row], and the
/// status strings - "Active (I2C 0x57)", "Armed & Active" - are long enough that
/// the row overflowed at phone widths. It overflowed on every screen that used
/// it, which is only visible by rendering at a phone width.
///
/// Here the header is laid out by available width, and every text run is
/// allowed to wrap, so no combination of title and status can overflow.
class DsSensorCard extends StatelessWidget {
  /// Create a sensor card.
  const DsSensorCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.details,
    super.key,
  });

  /// Name of the component.
  final String title;

  /// What it measures.
  final String subtitle;

  /// Current state, shown as a pill.
  final String status;

  /// Icon identifying the component.
  final IconData icon;

  /// Bullet points describing the component.
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final stacked = constraints.maxWidth < 420;
              final heading = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: Space.xxs),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final pill = DsStatusPill(
                label: status,
                color: theme.colorScheme.primary,
                dense: true,
              );

              // Side by side only when there is room for both without
              // squeezing the heading.
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    heading,
                    const SizedBox(height: Space.md),
                    pill,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: heading),
                  const SizedBox(width: Space.md),
                  Flexible(child: pill),
                ],
              );
            },
          ),
          const SizedBox(height: Space.md),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: Space.md),
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(detail, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
