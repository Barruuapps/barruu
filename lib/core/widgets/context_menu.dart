import 'package:flutter/material.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// A single item in a context menu.
class ContextMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? shortcutLabel;
  final bool isDestructive;
  final bool isDivider;

  const ContextMenuItem({
    required this.label,
    this.icon,
    this.onTap,
    this.shortcutLabel,
    this.isDestructive = false,
    this.isDivider = false,
  });

  /// Create a divider item
  factory ContextMenuItem.divider() {
    return const ContextMenuItem(label: '', isDivider: true);
  }
}

/// A premium right-click context menu inspired by macOS Finder,
/// VS Code right-click menus, and Linear's context menus.
///
/// Features hover highlight, destructive styling, keyboard shortcuts,
/// and smooth entrance animation.
///
/// Usage:
/// ```dart
/// showContextMenu(
///   context: context,
///   position: details.globalPosition,
///   items: [
///     ContextMenuItem(label: 'Rename', icon: Icons.edit, onTap: () {}),
///     ContextMenuItem(label: 'Delete', icon: Icons.delete, isDestructive: true, onTap: () {}),
///   ],
/// );
/// ```
class ContextMenu extends StatelessWidget {
  final List<ContextMenuItem> items;
  final Offset position;
  final double maxWidth;
  final double maxHeight;

  const ContextMenu({
    super.key,
    required this.items,
    required this.position,
    this.maxWidth = 240,
    this.maxHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Calculate position so the menu doesn't overflow the screen
    double left = position.dx;
    double top = position.dy;

    if (left + maxWidth > screenSize.width) {
      left = screenSize.width - maxWidth - DesignTokens.spacing8;
    }
    if (top + maxHeight > screenSize.height - DesignTokens.spacing48) {
      top = screenSize.height - maxHeight - DesignTokens.spacing48;
    }

    return Stack(
      children: [
        // Backdrop to dismiss
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent),
        ),
        // Menu
        Positioned(
          left: left.clamp(0, screenSize.width),
          top: top.clamp(0, screenSize.height),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.0),
            duration: DesignTokens.durationFast,
            curve: DesignTokens.curveEmphasized,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: child,
              );
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: DesignTokens.durationFast,
              curve: DesignTokens.curveEmphasized,
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: maxWidth,
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow
                            .withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: theme.colorScheme.shadow
                            .withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusLarge),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spacing4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items.map((item) {
                          if (item.isDivider) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacing8,
                                vertical: DesignTokens.spacing4,
                              ),
                              child: Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                            );
                          }
                          return _ContextMenuTile(item: item);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuTile extends StatefulWidget {
  final ContextMenuItem item;
  const _ContextMenuTile({required this.item});

  @override
  State<_ContextMenuTile> createState() => _ContextMenuTileState();
}

class _ContextMenuTileState extends State<_ContextMenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.item.isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          widget.item.onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: DesignTokens.durationHover,
          margin: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing12,
            vertical: DesignTokens.spacing8,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          child: Row(
            children: [
              // Icon
              if (widget.item.icon != null) ...[
                SizedBox(
                  width: DesignTokens.iconCompact,
                  child: Icon(
                    widget.item.icon,
                    size: DesignTokens.iconSmall,
                    color: effectiveColor,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
              ],
              // Label
              Expanded(
                child: Text(
                  widget.item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: effectiveColor,
                    fontWeight: DesignTokens.weightMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Shortcut
              if (widget.item.shortcutLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing8,
                    vertical: DesignTokens.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSmall),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    widget.item.shortcutLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show a context menu at the given position.
///
/// Usage:
/// ```dart
/// GestureDetector(
///   onSecondaryTapUp: (details) {
///     showContextMenu(
///       context: context,
///       position: details.globalPosition,
///       items: [...],
///     );
///   },
///   child: ...,
/// )
/// ```
Future<void> showContextMenu({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuItem> items,
  double maxWidth = 240,
  double maxHeight = 400,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => ContextMenu(
      items: items,
      position: position,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    ),
  );
}