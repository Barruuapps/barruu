import 'package:flutter/material.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// A premium sidebar navigation item used in the left sidebar.
///
/// Features hover animation, active indicator, icon, label, and optional
/// badge for counts.
class SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final int? badgeCount;
  final String? shortcutLabel;
  final Widget? trailing;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.badgeCount,
    this.shortcutLabel,
    this.trailing,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: DesignTokens.durationHover,
          margin: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing4,
            vertical: DesignTokens.spacing2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing8,
            vertical: DesignTokens.spacing8,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : _isHovered
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          child: Row(
            children: [
              // Active indicator bar
              if (widget.isActive)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: DesignTokens.spacing8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              // Icon
              Icon(
                widget.icon,
                size: DesignTokens.iconCompact,
                color: widget.isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.spacing12),
              // Label
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: widget.isActive
                        ? DesignTokens.weightSemiBold
                        : DesignTokens.weightMedium,
                    color: widget.isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Badge
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing8,
                    vertical: DesignTokens.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.badgeCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: DesignTokens.weightSemiBold,
                      color: widget.isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              // Shortcut label
              if (widget.shortcutLabel != null && !_isHovered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing8,
                    vertical: DesignTokens.spacing2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    widget.shortcutLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// A collapsible sidebar section with a header and child items.
class SidebarSection extends StatefulWidget {
  final String? title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  const SidebarSection({
    super.key,
    this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.padding,
  });

  @override
  State<SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<SidebarSection> {
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        if (widget.title != null)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacing12,
                DesignTokens.spacing16,
                DesignTokens.spacing8,
                DesignTokens.spacing4,
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
                  const SizedBox(width: DesignTokens.spacing4),
                  Text(
                    widget.title!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: DesignTokens.weightSemiBold,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Children
        if (_expanded) ...widget.children,
      ],
    );
  }
}

/// The full left sidebar shell with workspace switcher, search, and nav sections.
///
/// Usage:
/// ```dart
/// SidebarShell(
///   workspaceName: 'My Workspace',
///   navItems: [
///     SidebarNavItem(...),
///   ],
/// )
/// ```
class SidebarShell extends StatelessWidget {
  final String workspaceName;
  final VoidCallback? onWorkspaceTap;
  final Widget? searchField;
  final List<Widget> children;
  final double width;
  final Color? backgroundColor;

  const SidebarShell({
    super.key,
    required this.workspaceName,
    this.onWorkspaceTap,
    this.searchField,
    required this.children,
    this.width = DesignTokens.sidebarExpandedWidth,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      color: backgroundColor ?? theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Workspace switcher header
          GestureDetector(
            onTap: onWorkspaceTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacing12,
                DesignTokens.spacing16,
                DesignTokens.spacing12,
                DesignTokens.spacing8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      Icons.workspaces_rounded,
                      size: DesignTokens.iconSmall,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing8),
                  Expanded(
                    child: Text(
                      workspaceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.weightSemiBold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onWorkspaceTap != null)
                    Icon(
                      Icons.expand_more_rounded,
                      size: DesignTokens.iconSmall,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          // Search
          if (searchField != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacing12,
                vertical: DesignTokens.spacing4,
              ),
              child: searchField!,
            ),
          ],
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing12,
            ),
            child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
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
