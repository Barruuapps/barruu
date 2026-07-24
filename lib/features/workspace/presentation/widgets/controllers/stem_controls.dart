import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';

class StemControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;

  const StemControls({
    super.key,
    required this.controller,
    required this.block,
  });

  Future<void> _applyPreset(String preset) async {
    BlockStyle next = block.style;
    switch (preset) {
      case 'academic':
        next = block.style.copyWith(
          fontFamily: 'Times New Roman',
          fontSize: 18,
          bold: false,
          italic: false,
        );
        break;
      case 'highlighted':
        next = block.style.copyWith(
          fontFamily: 'Times New Roman',
          fontSize: 18,
          bold: true,
          italic: false,
          background: '#f5f3ff',
        );
        break;
      case 'compact':
        next = block.style.copyWith(
          fontFamily: 'Arial',
          fontSize: 16,
          bold: false,
          italic: false,
        );
        break;
    }
    await controller.updateStyle(block, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'STEM Style Preset',
      onSelected: (preset) => _applyPreset(preset),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'academic', child: Text('Academic')),
        PopupMenuItem(value: 'highlighted', child: Text('Highlighted')),
        PopupMenuItem(value: 'compact', child: Text('Compact')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'STEM',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
