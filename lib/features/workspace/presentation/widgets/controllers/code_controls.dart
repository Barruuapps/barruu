import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/code_template_selector.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// Toolbar controls for code blocks — shows a template-selector gallery button.
class CodeControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const CodeControls({
    super.key,
    required this.controller,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTemplate = block.style.codeTemplate ?? 'minimal';

    return IconButton(
      icon: Icon(IconsaxPlusLinear.gallery, color: theme.colorScheme.primary),
      tooltip: 'Select Code Template',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => CodeTemplateSelector(
            selectedTemplate: currentTemplate,
            onTemplateSelected: (template) async {
              try {
                await controller.updateStyle(
                  block,
                  block.style.copyWith(codeTemplate: template),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e, stackTrace) {
                logger.e('Failed to update code template', error: e, stackTrace: stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating code template: $e')),
                  );
                }
              }
            },
            theme: theme,
          ),
        );
      },
    );
  }
}
