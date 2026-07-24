import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/stem_json_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StemJsonBlock extends BaseEditableBlock {
  const StemJsonBlock({
    super.key,
    required super.block,
    required super.isEditing,
    required super.docDir,
  });

  @override
  ConsumerState<StemJsonBlock> createState() => _StemJsonBlockState();
}

class _StemJsonBlockState extends BaseEditableBlockState<StemJsonBlock> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, FocusNode> _focusNodes = <String, FocusNode>{};
  late Debouncer _saveDebouncer;

  @override
  Map<String, dynamic> getDefaultContent() => {'content': ''};

  @override
  void initializeBlockSpecifics() {
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 450));
  }

  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
  }

  @override
  void onContentChanged() {
    for (final field in _fieldsForType()) {
      final controller = _controllers[field.id];
      final focusNode = _focusNodes[field.id];
      if (controller == null || (focusNode?.hasFocus ?? false)) {
        continue;
      }

      final nextValue = field.read(content);
      if (controller.text == nextValue) continue;

      final selectionIndex = controller.selection.baseOffset.clamp(
        0,
        nextValue.length,
      );
      controller.value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    }
  }

  TextEditingController _controllerFor(_StemFieldConfig field) {
    return _controllers.putIfAbsent(
      field.id,
      () => TextEditingController(text: field.read(content)),
    );
  }

  FocusNode _focusNodeFor(_StemFieldConfig field) {
    return _focusNodes.putIfAbsent(field.id, () {
      final node = FocusNode(debugLabel: field.id);
      node.addListener(() {
        if (!node.hasFocus) {
          _persistContent(immediate: true);
        }
      });
      return node;
    });
  }

  void _persistContent({bool immediate = false}) {
    for (final field in _fieldsForType()) {
      final controller = _controllers[field.id];
      if (controller != null) {
        field.write(content, controller.text);
      }
    }

    if (immediate) {
      saveContent();
    } else {
      _saveDebouncer.call(() => saveContent());
    }
  }

  List<_StemFieldConfig> _fieldsForType() {
    switch (widget.block.type) {
      case BlockType.theorem:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'statementType',
            label: 'Statement type',
            hintText: 'theorem, lemma, corollary...',
            read: (map) => (map['statementType'] as String?) ?? 'theorem',
            write: (map, value) => map['statementType'] = value.trim().isEmpty
                ? 'theorem'
                : value.trim(),
          ),
          _StemFieldConfig(
            id: 'title',
            label: 'Title',
            hintText: 'Optional short title',
            read: (map) => (map['title'] as String?) ?? '',
            write: (map, value) => map['title'] = value,
          ),
          _StemFieldConfig(
            id: 'statement',
            label: 'Statement',
            hintText: 'Write the full theorem statement',
            minLines: 4,
            maxLines: 10,
            read: (map) => (map['statement'] as String?) ?? '',
            write: (map, value) => map['statement'] = value,
          ),
        ];
      case BlockType.proof:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'proofOf',
            label: 'Proof of',
            hintText: 'What is this proof for?',
            read: (map) => (map['proofOf'] as String?) ?? '',
            write: (map, value) => map['proofOf'] = value,
          ),
          _StemFieldConfig(
            id: 'strategy',
            label: 'Strategy',
            hintText: 'Outline the proof idea or approach',
            minLines: 3,
            maxLines: 8,
            read: (map) => (map['strategy'] as String?) ?? '',
            write: (map, value) => map['strategy'] = value,
          ),
        ];
      case BlockType.definition:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'term',
            label: 'Term',
            hintText: 'Defined concept or term',
            read: (map) => (map['term'] as String?) ?? '',
            write: (map, value) => map['term'] = value,
          ),
          _StemFieldConfig(
            id: 'formalDefinition',
            label: 'Formal definition',
            hintText: 'Precise definition',
            minLines: 3,
            maxLines: 8,
            read: (map) => (map['formalDefinition'] as String?) ?? '',
            write: (map, value) => map['formalDefinition'] = value,
          ),
          _StemFieldConfig(
            id: 'informalSummary',
            label: 'Informal summary',
            hintText: 'Plain-language explanation',
            minLines: 2,
            maxLines: 6,
            read: (map) => (map['informalSummary'] as String?) ?? '',
            write: (map, value) => map['informalSummary'] = value,
          ),
        ];
      case BlockType.example:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'title',
            label: 'Title',
            hintText: 'Worked example title',
            read: (map) => (map['title'] as String?) ?? '',
            write: (map, value) => map['title'] = value,
          ),
          _StemFieldConfig(
            id: 'problem',
            label: 'Problem',
            hintText: 'Problem statement',
            minLines: 4,
            maxLines: 10,
            read: (map) => (map['problem'] as String?) ?? '',
            write: (map, value) => map['problem'] = value,
          ),
          _StemFieldConfig(
            id: 'finalAnswer',
            label: 'Final answer',
            hintText: 'Short final answer',
            read: (map) => (map['finalAnswer'] as String?) ?? '',
            write: (map, value) => map['finalAnswer'] = value,
          ),
        ];
      case BlockType.learningObjective:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'sectionScope',
            label: 'Section scope',
            hintText: 'Section or topic scope',
            read: (map) => (map['sectionScope'] as String?) ?? '',
            write: (map, value) => map['sectionScope'] = value,
          ),
          _StemFieldConfig(
            id: 'objectives.0.statement',
            label: 'Objective',
            hintText: 'What should the learner achieve?',
            minLines: 3,
            maxLines: 7,
            read: (map) {
              final firstObjective = _firstMap(
                map['objectives'],
                fallback: <String, dynamic>{'statement': ''},
              );
              return (firstObjective['statement'] as String?) ?? '';
            },
            write: (map, value) {
              final firstObjective = _firstMap(
                map['objectives'],
                fallback: <String, dynamic>{'statement': ''},
              );
              firstObjective['statement'] = value;
              map['objectives'] = <Map<String, dynamic>>[firstObjective];
            },
          ),
        ];
      case BlockType.conceptSummary:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'sectionTitle',
            label: 'Section title',
            hintText: 'Summary heading',
            read: (map) => (map['sectionTitle'] as String?) ?? '',
            write: (map, value) => map['sectionTitle'] = value,
          ),
          _StemFieldConfig(
            id: 'keyPoints',
            label: 'Key points',
            hintText: 'One point per line',
            minLines: 4,
            maxLines: 10,
            read: (map) {
              final points =
                  (map['keyPoints'] as List?)
                      ?.map((entry) => '$entry')
                      .toList() ??
                  <String>[];
              return points.join('\n');
            },
            write: (map, value) {
              map['keyPoints'] = value
                  .split('\n')
                  .map((entry) => entry.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList();
            },
          ),
        ];
      case BlockType.numericalQuestion:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'question',
            label: 'Question',
            hintText: 'Numerical question prompt',
            minLines: 3,
            maxLines: 7,
            read: (map) => (map['question'] as String?) ?? '',
            write: (map, value) => map['question'] = value,
          ),
          _StemFieldConfig(
            id: 'correctValue',
            label: 'Correct value',
            hintText: 'e.g. 9.81',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            read: (map) => '${map['correctValue'] ?? 0}',
            write: (map, value) => map['correctValue'] =
                num.tryParse(value) ?? map['correctValue'] ?? 0,
          ),
          _StemFieldConfig(
            id: 'unit',
            label: 'Unit',
            hintText: 'e.g. m/s²',
            read: (map) => (map['unit'] as String?) ?? '',
            write: (map, value) => map['unit'] = value,
          ),
        ];
      case BlockType.glossary:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'scope',
            label: 'Scope',
            hintText: 'document, section, custom...',
            read: (map) => (map['scope'] as String?) ?? 'document',
            write: (map, value) =>
                map['scope'] = value.trim().isEmpty ? 'document' : value.trim(),
          ),
        ];
      case BlockType.parametricGraph:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'expression',
            label: 'Expression',
            hintText: 'Graph expression',
            read: (map) => (map['expression'] as String?) ?? '',
            write: (map, value) => map['expression'] = value,
          ),
          _StemFieldConfig(
            id: 'caption',
            label: 'Caption',
            hintText: 'Optional caption',
            read: (map) => (map['caption'] as String?) ?? '',
            write: (map, value) => map['caption'] = value,
          ),
        ];
      case BlockType.citation:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'title',
            label: 'Title',
            hintText: 'Citation title',
            read: (map) => (map['title'] as String?) ?? '',
            write: (map, value) => map['title'] = value,
          ),
          _StemFieldConfig(
            id: 'authors',
            label: 'Authors',
            hintText: 'Comma-separated authors',
            read: (map) =>
                (map['authors'] as List?)
                    ?.map((entry) => '$entry')
                    .join(', ') ??
                '',
            write: (map, value) {
              map['authors'] = value
                  .split(',')
                  .map((entry) => entry.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList();
            },
          ),
          _StemFieldConfig(
            id: 'year',
            label: 'Year',
            hintText: '${DateTime.now().year}',
            keyboardType: TextInputType.number,
            read: (map) => '${map['year'] ?? DateTime.now().year}',
            write: (map, value) => map['year'] =
                int.tryParse(value) ?? map['year'] ?? DateTime.now().year,
          ),
        ];
      case BlockType.toc:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'title',
            label: 'TOC title',
            hintText: 'Contents',
            read: (map) => (map['title'] as String?) ?? 'Contents',
            write: (map, value) =>
                map['title'] = value.trim().isEmpty ? 'Contents' : value,
          ),
        ];
      case BlockType.faq:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'header',
            label: 'Header',
            hintText: 'FAQ heading',
            read: (map) => (map['header'] as String?) ?? '',
            write: (map, value) => map['header'] = value,
          ),
          _StemFieldConfig(
            id: 'items.0.question',
            label: 'Question',
            hintText: 'First FAQ question',
            read: (map) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{'question': '', 'answer': ''},
              );
              return (firstItem['question'] as String?) ?? '';
            },
            write: (map, value) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{'question': '', 'answer': ''},
              );
              firstItem['question'] = value;
              map['items'] = <Map<String, dynamic>>[firstItem];
            },
          ),
          _StemFieldConfig(
            id: 'items.0.answer',
            label: 'Answer',
            hintText: 'First FAQ answer',
            minLines: 3,
            maxLines: 8,
            read: (map) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{'question': '', 'answer': ''},
              );
              return (firstItem['answer'] as String?) ?? '';
            },
            write: (map, value) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{'question': '', 'answer': ''},
              );
              firstItem['answer'] = value;
              map['items'] = <Map<String, dynamic>>[firstItem];
            },
          ),
        ];
      case BlockType.keyPoint:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'header',
            label: 'Header',
            hintText: 'Section heading',
            read: (map) => (map['header'] as String?) ?? '',
            write: (map, value) => map['header'] = value,
          ),
          _StemFieldConfig(
            id: 'items.0.title',
            label: 'Key point title',
            hintText: 'Short key point title',
            read: (map) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{
                  'icon': '💡',
                  'title': '',
                  'description': '',
                },
              );
              return (firstItem['title'] as String?) ?? '';
            },
            write: (map, value) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{
                  'icon': '💡',
                  'title': '',
                  'description': '',
                },
              );
              firstItem['title'] = value;
              map['items'] = <Map<String, dynamic>>[firstItem];
            },
          ),
          _StemFieldConfig(
            id: 'items.0.description',
            label: 'Description',
            hintText: 'Explain the key point',
            minLines: 3,
            maxLines: 8,
            read: (map) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{
                  'icon': '💡',
                  'title': '',
                  'description': '',
                },
              );
              return (firstItem['description'] as String?) ?? '';
            },
            write: (map, value) {
              final firstItem = _firstMap(
                map['items'],
                fallback: <String, dynamic>{
                  'icon': '💡',
                  'title': '',
                  'description': '',
                },
              );
              firstItem['description'] = value;
              map['items'] = <Map<String, dynamic>>[firstItem];
            },
          ),
        ];
      default:
        return <_StemFieldConfig>[
          _StemFieldConfig(
            id: 'content',
            label: 'Content',
            hintText: 'Add content',
            minLines: 3,
            maxLines: 8,
            read: (map) => (map['content'] as String?) ?? '',
            write: (map, value) => map['content'] = value,
          ),
        ];
    }
  }

  Widget _buildFieldCard(
    BuildContext context,
    _StemFieldConfig field,
    StyleUtils styleUtils,
    ThemeData theme,
  ) {
    final controller = _controllerFor(field);
    final focusNode = _focusNodeFor(field);
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final lineHeight = ResponsiveUtils.getLineHeight(context, baseHeight: 1.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: field.minLines,
            maxLines: field.maxLines,
            keyboardType: field.keyboardType,
            textAlign: textAlign,
            style: styleUtils
                .applyStyle(widget.block.style)
                .copyWith(
                  fontSize: widget.block.style.fontSize * textMultiplier,
                  color:
                      styleUtils.parseHex(widget.block.style.color) ??
                      theme.colorScheme.onSurface,
                  height: lineHeight,
                ),
            decoration: InputDecoration(
              hintText: field.hintText,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
            onChanged: (_) => _persistContent(),
          ),
        ],
      ),
    );
  }

  String get _blockTitle {
    switch (widget.block.type) {
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
        return widget.block.type.name
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

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surfaceContainerLow,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.block.type.icon,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _blockTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Structured STEM content with shared Flutter/web fields',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._fieldsForType().map(
                (field) => _buildFieldCard(context, field, styleUtils, theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildReader(BuildContext context) =>
      StemJsonReaderBlock(block: widget.block);
}

Map<String, dynamic> _firstMap(
  Object? rawValue, {
  required Map<String, dynamic> fallback,
}) {
  if (rawValue is List && rawValue.isNotEmpty && rawValue.first is Map) {
    return Map<String, dynamic>.from(rawValue.first as Map);
  }
  return Map<String, dynamic>.from(fallback);
}

class _StemFieldConfig {
  const _StemFieldConfig({
    required this.id,
    required this.label,
    required this.read,
    required this.write,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String id;
  final String label;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final String Function(Map<String, dynamic> map) read;
  final void Function(Map<String, dynamic> map, String value) write;
}
