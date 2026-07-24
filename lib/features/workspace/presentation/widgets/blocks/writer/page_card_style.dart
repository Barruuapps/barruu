import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/services/page_icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Builds the card display style for a page block.
///
/// This is the default and most visually prominent style with gradient background,
/// shadows, and prominent action buttons.
Widget buildPageBlockCardStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  TextDecoration? decoration;
  if (blockStyle.underline && blockStyle.strikethrough) {
    decoration = TextDecoration.combine(
        [TextDecoration.underline, TextDecoration.lineThrough]);
  } else if (blockStyle.underline) {
    decoration = TextDecoration.underline;
  } else if (blockStyle.strikethrough) {
    decoration = TextDecoration.lineThrough;
  }

  final titleStyle = theme.textTheme.bodyLarge?.copyWith(
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    color: styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onSurface,
    fontSize: blockStyle.fontSize ?? 16,
    fontFamily: blockStyle.fontFamily,
    decoration: decoration,
  );

  // Use full opacity when the user explicitly sets a background color;
  // otherwise fall back to the default low-opacity gradient.
  final Color? explicitBg = styleUtils.parseHex(blockStyle.background);
  final Color gradientStart = explicitBg != null
      ? explicitBg.withOpacity(0.85)
      : theme.colorScheme.primaryContainer.withOpacity(0.2);
  final Color gradientEnd = explicitBg != null
      ? explicitBg.withOpacity(0.65)
      : theme.colorScheme.primaryContainer.withOpacity(0.05);

  final cardWidget = Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: styleUtils.parseHex(blockStyle.borderColor) ??
            theme.colorScheme.primary.withOpacity(0.4),
        width: 2,
      ),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getPageIcon(blockStyle.customIcon),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing)
                    Text(
                      'Linked Page',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (isEditing) const SizedBox(height: 2),
                  if (isEditing)
                    TextField(
                      controller: titleController,
                      onChanged: onTitleChanged,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                      decoration: const InputDecoration(
                        hintText: 'Untitled',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else
                    Text(
                      title,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                    ),
                ],
              ),
            ),
            // Show forward arrow to indicate it's tappable when not editing
            if (!isEditing && hasPage)
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
        // Action buttons only when actively editing
        if (isEditing) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 18),
                  label: const Text('Go to Page'),
                  onPressed: hasPage ? onNavigate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.link, size: 18),
                  label: const Text('Link Page'),
                  onPressed: onLinkPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  // When not actively editing, wrap with InkWell so tapping navigates to the page
  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(16),
        child: cardWidget,
      ),
    );
  }
  return cardWidget;
}

