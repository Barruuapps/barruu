import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/services/page_icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Builds the minimal display style for a page block.
///
/// The most compact style with just an underlined link and small action buttons.
Widget buildPageBlockMinimalStyle({
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
  // Build decoration: always underline for minimal style, combine with strikethrough if needed
  TextDecoration decoration;
  if (blockStyle.strikethrough) {
    decoration = TextDecoration.combine(
        [TextDecoration.underline, TextDecoration.lineThrough]);
  } else {
    decoration = TextDecoration.underline;
  }

  final titleStyle = theme.textTheme.bodyMedium?.copyWith(
    color: styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.primary,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w500,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: decoration,
  );

  final contentWidget = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (showIcon) ...[
            Icon(
              getPageIcon(blockStyle.customIcon),
              color: styleUtils.parseHex(blockStyle.color) ??
                  theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: isEditing
                ? TextField(
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
                : Text(title, style: titleStyle, textAlign: styleUtils.textAlignFromStyle(blockStyle)),
          ),
          if (!isEditing && hasPage)
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              color: styleUtils.parseHex(blockStyle.color) ??
                  theme.colorScheme.primary,
              size: 14,
            ),
        ],
      ),
      if (isEditing) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 12),
              label: const Text('Go', style: TextStyle(fontSize: 12)),
              onPressed: hasPage ? onNavigate : null,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              icon: const Icon(IconsaxPlusLinear.link, size: 12),
              label: const Text('Link', style: TextStyle(fontSize: 12)),
              onPressed: onLinkPage,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    ],
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: contentWidget,
        ),
      ),
    );
  }
  return contentWidget;
}

