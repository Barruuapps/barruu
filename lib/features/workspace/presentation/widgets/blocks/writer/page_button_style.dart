import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/services/page_icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Builds the button display style for a page block.
///
/// Renders the page as a prominent button with optional icon.
Widget buildPageBlockButtonStyle({
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

  final titleStyle = TextStyle(
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    decoration: decoration,
  );

  final bgColor = styleUtils.parseHex(blockStyle.background) ?? theme.colorScheme.primary;
  final fgColor = styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onPrimary;

  if (!isEditing) {
    // Reader / non-editing: show a proper clickable button that navigates
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasPage ? onNavigate : null,
        icon: showIcon
            ? Icon(getPageIcon(blockStyle.customIcon), size: 20)
            : const SizedBox.shrink(),
        label: Text(title, style: titleStyle.copyWith(color: fgColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withOpacity(0.6),
          disabledForegroundColor: fgColor.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // Edit mode: show button-styled container with inline title editing + action buttons
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (showIcon) ...[
              Icon(getPageIcon(blockStyle.customIcon), size: 20, color: fgColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: TextField(
                controller: titleController,
                onChanged: onTitleChanged,
                style: titleStyle.copyWith(color: fgColor),
                textAlign: styleUtils.textAlignFromStyle(blockStyle),
                decoration: InputDecoration(
                  hintText: 'Untitled',
                  hintStyle: TextStyle(color: fgColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Icon(IconsaxPlusLinear.arrow_right_3, size: 18, color: fgColor.withOpacity(0.7)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16),
              label: const Text('Go to Page'),
              onPressed: hasPage ? onNavigate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(IconsaxPlusLinear.link, size: 16),
              label: const Text('Link Page'),
              onPressed: onLinkPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

