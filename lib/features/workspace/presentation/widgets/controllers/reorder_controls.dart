import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/reorder_template_selector.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// Controls for the reorder (math equation order) question block – opens a
/// template-selector dialog to change the visual layout of the block.
class ReorderControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const ReorderControls({
    super.key,
    required this.controller,
    required this.block,
  });

  void _showTemplateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final currentTemplate = block.style.questionTemplate ?? 'default';

    showDialog(
      context: context,
      builder: (context) => ReorderTemplateSelector(
        selectedTemplate: currentTemplate,
        onTemplateSelected: (template) async {
          try {
            await controller.updateStyle(
              block,
              block.style.copyWith(questionTemplate: template),
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } catch (e, stackTrace) {
            logger.e('Failed to update reorder question template',
                error: e, stackTrace: stackTrace);
          }
        },
        theme: theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Question Template',
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
    );
  }
}
