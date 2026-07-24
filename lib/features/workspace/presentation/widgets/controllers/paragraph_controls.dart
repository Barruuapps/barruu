import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/paragraph_template_selector.dart';
import 'package:barruu/features/workspace/presentation/widgets/dialogs/add_link_dialog.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Controls for paragraph block specific features
class ParagraphControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final TextEditingController? textController;

  const ParagraphControls({
    super.key,
    required this.controller,
    required this.block,
    this.textController,
  });

  Future<void> _showAddLinkDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const AddLinkDialog(),
    );

    if (result != null && textController != null) {
      // Insert the markdown link at cursor position
      final currentText = textController!.text;
      final selection = textController!.selection;

      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        result,
      );

      textController!.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + result.length,
        ),
      );
    }
  }

  void _showTemplateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final currentTemplate = block.style.paragraphTemplate ?? 'default';

    showDialog(
      context: context,
      builder: (context) => ParagraphTemplateSelector(
        selectedTemplate: currentTemplate,
        onTemplateSelected: (template) async {
          try {
            await controller.updateStyle(
              block,
              block.style.copyWith(paragraphTemplate: template),
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } catch (e, stackTrace) {
            logger.e(
              'Failed to update paragraph template',
              error: e,
              stackTrace: stackTrace,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating paragraph template: $e'),
                ),
              );
            }
          }
        },
        theme: theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Template selector button
        Tooltip(
          message: 'Paragraph Template',
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showTemplateSelector(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconsaxPlusLinear.gallery,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Template',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Link button
        Tooltip(
          message: 'Add Link',
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showAddLinkDialog(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Link',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
