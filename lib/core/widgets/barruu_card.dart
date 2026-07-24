import 'package:flutter/material.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// Premium card widget used throughout Barruu.
///
/// Provides consistent elevation, hover scale, border radius, and selection
/// styling that matches Linear/Notion-tier design quality.
enum BarruuCardVariant { elevated, outlined, flat }

class BarruuCard extends StatefulWidget {
  final Widget child;
  final BarruuCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool enableHover;
  final String? semanticLabel;

  const BarruuCard({
    super.key,
    required this.child,
    this.variant = BarruuCardVariant.elevated,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.padding,
    this.borderRadius,
    this.enableHover = true,
    this.semanticLabel,
  });

  @override
  State<BarruuCard> createState() => _BarruuCardState();
}

class _BarruuCardState extends State<BarruuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = widget.onTap != null || widget.onLongPress != null;
    final pad = widget.padding ??
        const EdgeInsets.all(DesignTokens.spacing16);
    final radius = widget.borderRadius ??
        BorderRadius.circular(DesignTokens.radiusXLarge);

    // Build card contents with decoration
    Widget cardContents = Container(
      width: double.infinity,
      padding: pad,
      decoration: _decoration(theme, radius),
      child: widget.child,
    );

    // Apply hover scale via AnimatedScale
    cardContents = AnimatedScale(
      duration: DesignTokens.durationHover,
      curve: DesignTokens.curveStandard,
      scale:
          _isHovered && widget.enableHover && isInteractive ? 1.02 : 1.0,
      child: cardContents,
    );

    // Selection indicator
    if (widget.isSelected) {
      cardContents = Stack(
        children: [
          cardContents,
          Positioned(
            top: DesignTokens.spacing8,
            right: DesignTokens.spacing8,
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Icon(
                Icons.check_rounded,
                size: DesignTokens.iconSmall,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with interactivity
    if (isInteractive) {
      cardContents = Semantics(
        label: widget.semanticLabel,
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            if (widget.enableHover) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (widget.enableHover) setState(() => _isHovered = false);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            behavior: HitTestBehavior.opaque,
            child: cardContents,
          ),
        ),
      );
    }

    return cardContents;
  }

  BoxDecoration _decoration(ThemeData theme, BorderRadiusGeometry radius) {
    final isDark = theme.brightness == Brightness.dark;
    switch (widget.variant) {
      case BarruuCardVariant.elevated:
        return BoxDecoration(
          color: _isHovered
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surfaceContainer,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(
                alpha: _isHovered ? 0.08 : (isDark ? 0.04 : 0.06),
              ),
              blurRadius: _isHovered ? 16 : 12,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case BarruuCardVariant.outlined:
        return BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: radius,
          border: Border.all(
            color: widget.isSelected
                ? theme.colorScheme.primary
                : _isHovered
                    ? theme.colorScheme.outline
                    : theme.colorScheme.outlineVariant,
            width: widget.isSelected ? 2.0 : 1.0,
          ),
        );
      case BarruuCardVariant.flat:
        return BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: radius,
        );
    }
  }
}

/// A compact, horizontally-oriented card for list items.
class BarruuListCard extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;

  const BarruuListCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.padding,
  });

  @override
  State<BarruuListCard> createState() => _BarruuListCardState();
}

class _BarruuListCardState extends State<BarruuListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing12,
          vertical: DesignTokens.spacing8,
        );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: DesignTokens.durationHover,
          curve: DesignTokens.curveStandard,
          padding: pad,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : _isHovered
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.transparent,
            borderRadius:
                BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: DesignTokens.spacing12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.title,
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: DesignTokens.spacing4),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: DesignTokens.spacing8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}