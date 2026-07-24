import 'package:flutter/material.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// A contextual right sidebar inspector panel that shows properties,
/// metadata, outline, and actions based on what's selected.
///
/// Inspired by Notion's right sidebar, Linear's issue panel, and
/// VS Code's properties panel.
///
/// Usage:
/// ```dart
/// InspectorPanel(
///   title: 'Document Info',
///   children: [
///     InspectorSection(title: 'Properties', children: [...]),
///     InspectorSection(title: 'Metadata', children: [...]),
///   ],
/// )
/// ```
class InspectorPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double width;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Widget? headerTrailing;
  final ScrollController? scrollController;

  const InspectorPanel({
    super.key,
    required this.title,
    required this.children,
    this.width = DesignTokens.rightSidebarWidth,
    this.padding,
    this.backgroundColor,
    this.headerTrailing,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      color: backgroundColor ?? theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacing16,
              DesignTokens.spacing16,
              DesignTokens.spacing12,
              DesignTokens.spacing12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: DesignTokens.weightSemiBold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
              ],
            ),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing16,
            ),
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: padding ??
                  const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacing8,
                  ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A collapsible section within the inspector panel.
class InspectorSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Widget? trailing;
  final IconData? icon;

  const InspectorSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.trailing,
    this.icon,
  });

  @override
  State<InspectorSection> createState() => _InspectorSectionState();
}

class _InspectorSectionState extends State<InspectorSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing16,
              vertical: DesignTokens.spacing8,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  duration: DesignTokens.duration200,
                  turns: _expanded ? 0.25 : 0.0,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: DesignTokens.iconSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: DesignTokens.spacing8),
                  Icon(
                    widget.icon,
                    size: DesignTokens.iconSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
                const SizedBox(width: DesignTokens.spacing8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: DesignTokens.weightSemiBold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
        // Children
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacing16,
              0,
              DesignTokens.spacing16,
              DesignTokens.spacing8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: DesignTokens.duration200,
        ),
      ],
    );
  }
}

/// A single property row in the inspector panel (label + value).
class InspectorPropertyRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  final VoidCallback? onTap;
  final IconData? leadingIcon;

  const InspectorPropertyRow({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
    this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.spacing4,
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: DesignTokens.iconSmall,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: DesignTokens.spacing8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.weightMedium,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing2),
                if (valueWidget != null)
                  valueWidget!
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: DesignTokens.weightMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        onTap: onTap,
        child: row,
      );
    }

    return row;
  }
}

/// A chip-style tag inside the inspector for metadata/tags.
class InspectorChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? color;

  const InspectorChip({
    super.key,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing12,
          vertical: DesignTokens.spacing4,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? effectiveColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: isActive
              ? Border.all(color: effectiveColor, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? effectiveColor : theme.colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.weightMedium,
          ),
        ),
      ),
    );
  }
}