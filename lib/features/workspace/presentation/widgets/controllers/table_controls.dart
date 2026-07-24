
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/table_template_selector.dart';
import 'package:barruu/core/utils/app_logger.dart';

class TableControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const TableControls({
    super.key,
    required this.controller,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFirstRowHeader = block.style.headerStyle == 'first_row';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.table_rows,
            color: theme.colorScheme.primary,
            semanticLabel: 'Table header options',
          ),
          tooltip: 'Table Header Options',
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'none',
              child: Row(
                children: [
                  Icon(
                    isFirstRowHeader ? Icons.radio_button_unchecked : Icons.radio_button_checked,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('No Header', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'first_row',
              child: Row(
                children: [
                  Icon(
                    isFirstRowHeader ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('First Row as Header', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            try {
              final newHeaderStyle = value == 'first_row' ? 'first_row' : null;
              await controller.updateStyle(
                block,
                block.style.copyWith(headerStyle: newHeaderStyle),
              );
            } catch (e, stackTrace) {
              logger.e('Failed to update table header style', error: e, stackTrace: stackTrace);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating table header: $e')),
                );
              }
            }
          },
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        IconButton(
          icon: Icon(IconsaxPlusLinear.gallery, color: theme.colorScheme.primary),
          tooltip: 'Select Table Template',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => TableTemplateSelector(
                selectedTemplate: block.style.tableTemplate ?? 'default',
                onTemplateSelected: (template) async {
                  try {
                    await controller.updateStyle(
                      block,
                      block.style.copyWith(tableTemplate: template),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e, stackTrace) {
                    logger.e('Failed to update table template', error: e, stackTrace: stackTrace);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating table template: $e')),
                      );
                    }
                  }
                },
                theme: theme,
              ),
            );
          },
        ),
      ],
    );
  }
}
