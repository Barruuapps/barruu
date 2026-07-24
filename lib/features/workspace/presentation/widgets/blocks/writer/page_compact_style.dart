import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/services/page_icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Builds the compact display style for a page block.
///
/// A space-efficient style with minimal padding and smaller buttons.
Widget buildPageBlockCompactStyle({
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

  final titleStyle = theme.textTheme.bodyMedium?.copyWith(
    color: styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onSurface,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w500,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: decoration,
  );

  final containerWidget = Container(
    decoration: BoxDecoration(
      color: styleUtils.parseHex(blockStyle.background) ??
          theme.colorScheme.primaryContainer.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: styleUtils.parseHex(blockStyle.borderColor) ??
            theme.colorScheme.primary.withOpacity(0.4),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showIcon) ...[
              Icon(
                getPageIcon(blockStyle.customIcon),
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
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
                color: theme.colorScheme.primary,
                size: 16,
              ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 14),
                  label: const Text('Go'),
                  onPressed: hasPage ? onNavigate : null,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(IconsaxPlusLinear.link, size: 14),
                  label: const Text('Link'),
                  onPressed: onLinkPage,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(8),
        child: containerWidget,
      ),
    );
  }
  return containerWidget;
}

