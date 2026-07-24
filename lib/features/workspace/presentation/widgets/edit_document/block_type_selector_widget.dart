import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/core/utils/responsive_utils.dart';

/// A widget that displays a selector for different block types.
///
/// This widget provides a horizontal scrollable list on mobile devices
/// and a vertical sidebar on desktop devices. Users can tap block type
/// buttons to add new blocks to their document.
///
/// The layout automatically adapts based on screen size using [ResponsiveUtils].
class BlockTypeSelectorWidget extends StatelessWidget {
  /// The theme data for styling the widget.
  final ThemeData theme;

  /// Callback function invoked when a block type button is tapped.
  ///
  /// The callback receives the selected [BlockType] and a boolean indicating
  /// whether the button was tapped from the sidebar (true) or horizontal list (false).
  final Function(BlockType type, bool isSidebar) onBlockTypeSelected;

  /// The maximum width available for the widget.
  final double maxWidth;

  /// Creates a block type selector widget.
  ///
  /// [theme] provides the styling for the widget.
  /// [onBlockTypeSelected] is called when a user selects a block type.
  /// [maxWidth] is the available width for layout calculations.
  const BlockTypeSelectorWidget({
    super.key,
    required this.theme,
    required this.onBlockTypeSelected,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Use the sidebar layout only on desktop (≥ 900px), where the parent
    // edit_document_screen uses a Row with crossAxisAlignment.stretch that
    // provides a bounded height.  On tablets and mobile the widget is placed
    // at the bottom of an unbounded Column, so we use the horizontal bar to
    // avoid the "RenderFlex children have non-zero flex but incoming height
    // constraints are unbounded" error.
    final showSidebar = ResponsiveUtils.isDesktop(context);
    final sidebarWidth = ResponsiveUtils.getSidebarWidth(context);

    if (!showSidebar) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: BlockType.values
                .where((t) => t != BlockType.unsupported)
                .map((t) => _buildBlockButton(context, t, false))
                .toList(),
          ),
        ),
      );
    }

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: BlockType.values
                  .where((t) => t != BlockType.unsupported)
                  .map((t) => _buildBlockButton(context, t, true))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds an individual block type button.
  ///
  /// [context] is the build context.
  /// [type] is the block type this button represents.
  /// [isSidebar] indicates whether this button is in the sidebar (true) or horizontal list (false).
  Widget _buildBlockButton(
    BuildContext context,
    BlockType type,
    bool isSidebar,
  ) {
    final isMobileOrTablet = !ResponsiveUtils.isDesktop(context);
    // Enhanced icon sizes for better visibility on mobile/tablet
    final iconSize = ResponsiveUtils.getIconSize(
      context,
      baseSize: isSidebar ? 30.0 : (isMobileOrTablet ? 28.0 : 26.0),
    );

    return Padding(
      padding: isSidebar
          ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
          : EdgeInsets.symmetric(horizontal: isMobileOrTablet ? 5 : 6),
      child: Tooltip(
        message: type.displayName,
        preferBelow: !isSidebar,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onBlockTypeSelected(type, isSidebar),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // Increased padding for better touch targets on mobile/tablet
              padding: EdgeInsets.all(isMobileOrTablet ? 14.0 : 12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context),
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                type.icon,
                color: theme.colorScheme.primary,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
