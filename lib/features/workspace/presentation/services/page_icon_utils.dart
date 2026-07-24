import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

/// Available page icon options with their display names.
final List<Map<String, dynamic>> pageIconOptions = [
  {'name': 'document', 'icon': IconsaxPlusLinear.document_text},
  {'name': 'folder', 'icon': IconsaxPlusLinear.folder_2},
  {'name': 'note', 'icon': IconsaxPlusLinear.note},
  {'name': 'bookmark', 'icon': IconsaxPlusLinear.bookmark},
  {'name': 'clipboard', 'icon': IconsaxPlusLinear.clipboard_text},
  {'name': 'archive', 'icon': IconsaxPlusLinear.archive_book},
  {'name': 'star', 'icon': IconsaxPlusLinear.star},
  {'name': 'heart', 'icon': IconsaxPlusLinear.heart},
  {'name': 'category', 'icon': IconsaxPlusLinear.category},
  {'name': 'tag', 'icon': IconsaxPlusLinear.tag},
];

/// Gets the icon for a page block based on customIcon setting.
///
/// Returns [IconsaxPlusLinear.document_text] as the default icon if no custom icon is specified.
IconData getPageIcon(String? customIcon) {
  if (customIcon == null) return IconsaxPlusLinear.document_text;
  
  final iconOption = pageIconOptions.firstWhere(
    (option) => option['name'] == customIcon,
    orElse: () => pageIconOptions[0],
  );
  return iconOption['icon'] as IconData;
}
