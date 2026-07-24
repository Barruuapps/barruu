import 'dart:convert';

import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:flutter/material.dart';

class StemJsonReaderBlock extends StatelessWidget {
  final Block block;

  const StemJsonReaderBlock({super.key, required this.block});

  String _titleForType(BlockType type) {
    switch (type) {
      case BlockType.learningObjective:
        return 'Learning Objective';
      case BlockType.conceptSummary:
        return 'Concept Summary';
      case BlockType.numericalQuestion:
        return 'Numerical Question';
      case BlockType.parametricGraph:
        return 'Parametric Graph';
      case BlockType.keyPoint:
        return 'Key Point';
      default:
        return type.name
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (match) => ' ${match.group(1)}',
            )
            .trimLeft()
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  Color _accentForType(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (block.type) {
      case BlockType.theorem:
        return scheme.primary;
      case BlockType.proof:
        return scheme.secondary;
      case BlockType.definition:
        return scheme.tertiary;
      case BlockType.example:
        return Colors.teal;
      case BlockType.learningObjective:
        return Colors.green;
      case BlockType.conceptSummary:
        return Colors.indigo;
      case BlockType.numericalQuestion:
        return Colors.blue;
      case BlockType.glossary:
        return Colors.deepPurple;
      case BlockType.parametricGraph:
        return Colors.cyan;
      case BlockType.citation:
        return Colors.blueGrey;
      case BlockType.toc:
        return Colors.orange;
      case BlockType.faq:
        return Colors.amber.shade800;
      case BlockType.keyPoint:
        return Colors.pink.shade400;
      default:
        return scheme.primary;
    }
  }

  Widget _body(BuildContext context, Map<String, dynamic> map) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium;
    String v(String key, [String fallback = '']) =>
        (map[key] as String?) ?? fallback;

    switch (block.type) {
      case BlockType.theorem:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('title').isNotEmpty)
              Text(
                v('title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (v('statement').isNotEmpty) ...[
              if (v('title').isNotEmpty) const SizedBox(height: 8),
              Text(v('statement'), style: bodyStyle),
            ],
          ],
        );
      case BlockType.proof:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('proofOf').isNotEmpty)
              Text(
                'Proof of ${v('proofOf')}',
                style: theme.textTheme.titleSmall,
              ),
            if (v('strategy').isNotEmpty) ...[
              if (v('proofOf').isNotEmpty) const SizedBox(height: 8),
              Text(v('strategy'), style: bodyStyle),
            ],
          ],
        );
      case BlockType.definition:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('term').isNotEmpty)
              Text(
                v('term'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (v('formalDefinition').isNotEmpty) ...[
              if (v('term').isNotEmpty) const SizedBox(height: 8),
              Text(v('formalDefinition'), style: bodyStyle),
            ],
            if (v('informalSummary').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                v('informalSummary'),
                style: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        );
      case BlockType.example:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('title').isNotEmpty)
              Text(
                v('title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (v('problem').isNotEmpty) ...[
              if (v('title').isNotEmpty) const SizedBox(height: 8),
              Text(v('problem'), style: bodyStyle),
            ],
            if (v('finalAnswer').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Answer: ${v('finalAnswer')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      case BlockType.learningObjective:
        final objectives = (map['objectives'] as List?) ?? const [];
        final first = objectives.isNotEmpty && objectives.first is Map
            ? Map<String, dynamic>.from(objectives.first as Map)
            : <String, dynamic>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('sectionScope').isNotEmpty)
              Text(v('sectionScope'), style: theme.textTheme.titleSmall),
            if ((first['statement'] as String?)?.isNotEmpty ?? false) ...[
              if (v('sectionScope').isNotEmpty) const SizedBox(height: 8),
              Text((first['statement'] as String?) ?? '', style: bodyStyle),
            ],
          ],
        );
      case BlockType.conceptSummary:
        final points =
            (map['keyPoints'] as List?)
                ?.map((entry) => '$entry')
                .where((entry) => entry.isNotEmpty)
                .toList() ??
            const <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('sectionTitle').isNotEmpty)
              Text(v('sectionTitle'), style: theme.textTheme.titleSmall),
            if (points.isNotEmpty) const SizedBox(height: 8),
            ...points
                .take(4)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $entry', style: bodyStyle),
                  ),
                ),
          ],
        );
      case BlockType.numericalQuestion:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('question').isNotEmpty) Text(v('question'), style: bodyStyle),
            const SizedBox(height: 8),
            Text(
              'Correct value: ${map['correctValue'] ?? 0} ${v('unit')}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case BlockType.glossary:
        return Text('Scope: ${v('scope', 'document')}', style: bodyStyle);
      case BlockType.parametricGraph:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('expression').isNotEmpty)
              Text(
                v('expression'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (v('caption').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(v('caption'), style: bodyStyle),
            ],
          ],
        );
      case BlockType.citation:
        final authors =
            (map['authors'] as List?)?.map((entry) => '$entry').join(', ') ??
            '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('title').isNotEmpty) Text(v('title'), style: bodyStyle),
            if (authors.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(authors, style: theme.textTheme.bodySmall),
            ],
            if (map['year'] != null) ...[
              const SizedBox(height: 6),
              Text('${map['year']}', style: theme.textTheme.bodySmall),
            ],
          ],
        );
      case BlockType.toc:
        return Text(v('title', 'Contents'), style: bodyStyle);
      case BlockType.faq:
        final items = (map['items'] as List?) ?? const [];
        final first = items.isNotEmpty && items.first is Map
            ? Map<String, dynamic>.from(items.first as Map)
            : <String, dynamic>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('header').isNotEmpty)
              Text(v('header'), style: theme.textTheme.titleSmall),
            if ((first['question'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Q: ${(first['question'] as String?) ?? ''}',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if ((first['answer'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(
                'A: ${(first['answer'] as String?) ?? ''}',
                style: bodyStyle,
              ),
            ],
          ],
        );
      case BlockType.keyPoint:
        final items = (map['items'] as List?) ?? const [];
        final first = items.isNotEmpty && items.first is Map
            ? Map<String, dynamic>.from(items.first as Map)
            : <String, dynamic>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v('header').isNotEmpty)
              Text(v('header'), style: theme.textTheme.titleSmall),
            if ((first['title'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                (first['title'] as String?) ?? '',
                style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if ((first['description'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text((first['description'] as String?) ?? '', style: bodyStyle),
            ],
          ],
        );
      default:
        return Text(
          const JsonEncoder.withIndent('  ').convert(map),
          style: bodyStyle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentForType(context);
    Map<String, dynamic> map = <String, dynamic>{};

    try {
      final decoded = jsonDecode(block.content);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(block.type.icon, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _titleForType(block.type),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _body(context, map),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
