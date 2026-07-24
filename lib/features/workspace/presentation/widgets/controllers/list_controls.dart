

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/list_template_selector.dart';
import 'package:barruu/features/workspace/utils/style_constants.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Controls for list type and custom icon selection
class ListControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const ListControls({
    super.key,
    required this.controller,
    required this.block,
  });

  void _showEmojiPicker(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pick an Emoji'),
          content: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: StyleConstants.commonListEmojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    controller.updateStyle(
                      block,
                      block.style.copyWith(
                        listType: ListType.custom.value,
                        customIcon: StyleConstants.commonListEmojis[index],
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        StyleConstants.commonListEmojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = block.style;
    final controls = [
      PopupMenuButton<String>(
        icon:  Icon(Icons.list, color: theme.colorScheme.primary),
        tooltip: 'List Type',
        itemBuilder: (_) => StyleConstants.listTypes
            .map((type) => PopupMenuItem(
          value: type.value,
          child: Text(
            type.displayName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ))
            .toList(),
        onSelected: (type) =>
            controller.updateStyle(block, block.style.copyWith(listType: type)),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ];

    if (style.listType == ListType.custom.value) {
      controls.add(
        PopupMenuButton<String>(
          tooltip: 'Custom Icon/Emoji - Type any emoji directly',
          icon: Icon(Icons.emoji_emotions, color: theme.colorScheme.primary),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type any emoji or character:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: style.customIcon ?? '😀',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: const OutlineInputBorder(),
                        helperText: 'Use keyboard emoji picker',
                        helperStyle: const TextStyle(fontSize: 10),
                      ),
                      onChanged: (icon) {
                        if (icon.isNotEmpty) {
                          controller.updateStyle(block, block.style.copyWith(customIcon: icon));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEmojiPicker(context, theme);
                      },
                      icon: const Icon(Icons.grid_view, size: 16),
                      label: const Text('Or pick from grid'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return Row(children: [
      ...controls,
      IconButton(
        icon: Icon(IconsaxPlusLinear.gallery, color: theme.colorScheme.primary),
        tooltip: 'Select List Template',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => ListTemplateSelector(
              selectedTemplate: block.style.listTemplate ?? 'default',
              onTemplateSelected: (template) async {
                try {
                  await controller.updateStyle(
                    block,
                    block.style.copyWith(listTemplate: template),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e, stackTrace) {
                  logger.e('Failed to update list template', error: e, stackTrace: stackTrace);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating list template: $e')),
                    );
                  }
                }
              },
              theme: theme,
            ),
          );
        },
      ),
    ]);
  }
}