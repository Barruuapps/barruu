
import 'package:barruu/features/workspace/constants/block_styles_constants.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_template_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Icon options for page blocks
const List<Map<String, dynamic>> pageIconOptions = [
  {'name': 'document', 'icon': IconsaxPlusLinear.document_text},
  {'name': 'folder', 'icon': IconsaxPlusLinear.folder_open},
  {'name': 'book', 'icon': IconsaxPlusLinear.book_1},
  {'name': 'note', 'icon': IconsaxPlusLinear.note_1},
  {'name': 'clipboard', 'icon': IconsaxPlusLinear.clipboard_text},
  {'name': 'archive', 'icon': IconsaxPlusLinear.archive_book},
  {'name': 'task', 'icon': IconsaxPlusLinear.task_square},
  {'name': 'category', 'icon': IconsaxPlusLinear.category},
  {'name': 'element', 'icon': IconsaxPlusLinear.element_3},
];

/// Controls for page block display styles
class PageControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const PageControls({
    super.key,
    required this.controller,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentStyle = block.style.displayStyle ?? 'card';
    final showIcon = block.style.showIcon;
    final customIcon = block.style.customIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Template Selector
        IconButton(
          icon: Icon(IconsaxPlusLinear.gallery, color: theme.colorScheme.onSurface, size: 20),
          tooltip: 'Choose Template',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => PageTemplateSelector(
                selectedTemplate: currentStyle,
                onTemplateSelected: (style) {
                  controller.saveBlock(
                    block.copyWith(style: block.style.copyWith(displayStyle: style)),
                  );
                  Navigator.of(context).pop();
                },
                theme: theme,
              ),
            );
          },
        ),
        // Display Style Selector
        Tooltip(
          message: 'Display Style',
          waitDuration: const Duration(milliseconds: 500),
          child: PopupMenuButton<String>(
            icon: Icon(
              _getIconForStyle(currentStyle),
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            onSelected: (style) {
              final updatedStyle = block.style.copyWith(displayStyle: style);
              final updatedBlock = block.copyWith(style: updatedStyle);
              controller.saveBlock(updatedBlock);
            },
            itemBuilder: (context) => BlockStylesConstants.pageDisplayStyleValues
                .map(
                  (style) => PopupMenuItem<String>(
                    value: style,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForStyle(style),
                          size: 18,
                          color: style == currentStyle
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStyleLabel(style),
                          style: TextStyle(
                            color: style == currentStyle
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: style == currentStyle
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        // Custom Icon Selector
        if (showIcon)
          Tooltip(
            message: 'Change Icon',
            waitDuration: const Duration(milliseconds: 500),
            child: PopupMenuButton<String>(
              icon: Icon(
                _getCustomIcon(customIcon),
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onSelected: (iconName) {
                final updatedStyle = block.style.copyWith(customIcon: iconName);
                final updatedBlock = block.copyWith(style: updatedStyle);
                controller.saveBlock(updatedBlock);
              },
              itemBuilder: (context) => pageIconOptions
                  .map(
                    (iconOption) => PopupMenuItem<String>(
                      value: iconOption['name'] as String,
                      child: Row(
                        children: [
                          Icon(
                            iconOption['icon'] as IconData,
                            size: 18,
                            color: (iconOption['name'] == customIcon || 
                                   (customIcon == null && iconOption['name'] == 'document'))
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _capitalize(iconOption['name'] as String),
                            style: TextStyle(
                              color: (iconOption['name'] == customIcon || 
                                     (customIcon == null && iconOption['name'] == 'document'))
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: (iconOption['name'] == customIcon || 
                                          (customIcon == null && iconOption['name'] == 'document'))
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(width: 8),
        // Show/Hide Icon Toggle
        Tooltip(
          message: showIcon ? 'Hide Icon' : 'Show Icon',
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final updatedStyle = block.style.copyWith(showIcon: !showIcon);
                final updatedBlock = block.copyWith(style: updatedStyle);
                controller.saveBlock(updatedBlock);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: showIcon
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  showIcon ? IconsaxPlusLinear.eye : IconsaxPlusLinear.eye_slash,
                  color: showIcon
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForStyle(String style) {
    switch (style) {
      case 'button':
        return IconsaxPlusLinear.menu_board;
      case 'compact':
        return IconsaxPlusLinear.row_horizontal;
      case 'minimal':
        return IconsaxPlusLinear.minus_cirlce; // Note: 'cirlce' typo exists in the iconsax_plus package itself
      case 'banner':
        return IconsaxPlusLinear.flag;
      case 'sidebar':
        return IconsaxPlusLinear.align_left;
      case 'floating':
        return IconsaxPlusLinear.box;
      case 'gradient':
        return IconsaxPlusLinear.colorfilter;
      case 'outlined':
        return IconsaxPlusLinear.element_3;
      case 'hero':
        return IconsaxPlusLinear.star;
      case 'card':
      default:
        return IconsaxPlusLinear.card;
    }
  }

  String _getStyleLabel(String style) {
    switch (style) {
      case 'button':
        return 'Button';
      case 'compact':
        return 'Compact';
      case 'minimal':
        return 'Minimal';
      case 'banner':
        return 'Banner';
      case 'sidebar':
        return 'Sidebar';
      case 'floating':
        return 'Floating';
      case 'gradient':
        return 'Gradient';
      case 'outlined':
        return 'Outlined';
      case 'hero':
        return 'Hero';
      case 'card':
      default:
        return 'Card';
    }
  }

  IconData _getCustomIcon(String? iconName) {
    if (iconName == null) return IconsaxPlusLinear.document_text;
    
    final iconOption = pageIconOptions.firstWhere(
      (option) => option['name'] == iconName,
      orElse: () => pageIconOptions[0],
    );
    return iconOption['icon'] as IconData;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
