
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/header_template_selector.dart';
import 'package:barruu/core/utils/app_logger.dart';

class HeaderControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const HeaderControls({
    super.key,
    required this.controller,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const headerLevels = [
      _HeaderLevel(name: 'H1', level: 1, fontSize: 32.0),
      _HeaderLevel(name: 'H2', level: 2, fontSize: 28.0),
      _HeaderLevel(name: 'H3', level: 3, fontSize: 24.0),
      _HeaderLevel(name: 'H4', level: 4, fontSize: 20.0),
      _HeaderLevel(name: 'H5', level: 5, fontSize: 16.0),
      _HeaderLevel(name: 'H6', level: 6, fontSize: 14.0),
    ];

    final currentStyle = block.style.headerStyle ?? 'normal';

    const borderWidths = [
      _BorderWidth(name: 'Thin', value: 1.0),
      _BorderWidth(name: 'Medium', value: 2.0),
      _BorderWidth(name: 'Thick', value: 3.0),
    ];

    List<PopupMenuItem<int>> buildHeaderLevelItems() {
      return headerLevels.map((level) {
        return PopupMenuItem<int>(
          value: level.level,
          child: Text(
            level.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      }).toList();
    }

    List<PopupMenuItem<double>> buildBorderWidthItems() {
      return borderWidths.map((width) {
        return PopupMenuItem<double>(
          value: width.value,
          child: Text(
            width.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      }).toList();
    }

    return Row(
      children: [
        PopupMenuButton<int>(
          icon: Icon(Icons.title, color: theme.colorScheme.primary, semanticLabel: 'Select header level'),
          tooltip: 'Select Header Level',
          itemBuilder: (context) => buildHeaderLevelItems(),
          onSelected: (level) async {
            try {
              final selectedLevel = headerLevels.firstWhere((h) => h.level == level);
              await controller.updateStyle(
                block,
                block.style.copyWith(fontSize: selectedLevel.fontSize),
              );
            } catch (e, stackTrace) {
              logger.e('Failed to update header level', error: e, stackTrace: stackTrace);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating header level: $e')),
                );
              }
            }
          },
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        IconButton(
          icon: Icon(IconsaxPlusLinear.gallery, color: theme.colorScheme.primary),
          tooltip: 'Select Header Template',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => HeaderTemplateSelector(
                selectedTemplate: currentStyle,
                onTemplateSelected: (styleValue) async {
                  try {
                    await controller.updateStyle(
                      block,
                      block.style.copyWith(headerStyle: styleValue),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e, stackTrace) {
                    logger.e('Failed to update header style', error: e, stackTrace: stackTrace);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating header style: $e')),
                      );
                    }
                  }
                },
                theme: theme,
              ),
            );
          },
        ),
        PopupMenuButton<double>(
          icon: Icon(Icons.line_weight, color: theme.colorScheme.primary, semanticLabel: 'Select border width'),
          tooltip: 'Select Border Width',
          itemBuilder: (context) => buildBorderWidthItems(),
          onSelected: (width) async {
            try {
              await controller.updateStyle(
                block,
                block.style.copyWith(borderWidth: width),
              );
            } catch (e, stackTrace) {
              logger.e('Failed to update border width', error: e, stackTrace: stackTrace);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating border width: $e')),
                );
              }
            }
          },
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ],
    );
  }
}

class _HeaderLevel {
  final String name;
  final int level;
  final double fontSize;

  const _HeaderLevel({
    required this.name,
    required this.level,
    required this.fontSize,
  });
}

class _BorderWidth {
  final String name;
  final double value;

  const _BorderWidth({
    required this.name,
    required this.value,
  });
}