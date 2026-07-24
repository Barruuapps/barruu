import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/true_false_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';

/// True/False question block for creating binary choice questions.
///
/// Content format:
/// ```json
/// {
///   "questionType": "trueFalse",
///   "statement": "The Earth orbits around the Sun.",
///   "correctAnswer": true,
///   "explanation": "The Earth takes approximately 365.25 days to complete one orbit.",
///   "points": 1,
///   "tags": ["astronomy", "science"],
///   "difficulty": "easy"
/// }
/// ```
class TrueFalseBlock extends BaseEditableBlock {
  const TrueFalseBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<TrueFalseBlock> createState() => _TrueFalseBlockState();
}

class _TrueFalseBlockState extends BaseEditableBlockState<TrueFalseBlock> {
  late TextEditingController _statementController;
  late TextEditingController _explanationController;
  late FocusNode _statementFocusNode;
  late FocusNode _explanationFocusNode;
  late Debouncer _debouncer;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'questionType': 'trueFalse',
    'statement': 'Enter your true/false statement here',
    'correctAnswer': true,
    'explanation': 'Explain the correct answer here.',
    'showExplanation': true,
    'points': 1,
    'tags': [],
    'difficulty': 'easy',
  };

  @override
  void initializeBlockSpecifics() {
    _statementController = TextEditingController(
      text: (content['statement'] as String?) ?? '',
    );
    _explanationController = TextEditingController(
      text: (content['explanation'] as String?) ?? '',
    );
    _statementFocusNode = FocusNode();
    _explanationFocusNode = FocusNode();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  }

  @override
  void onContentChanged() {
    if (_statementController.text != content['statement']) {
      _statementController.text = (content['statement'] as String?) ?? '';
    }
    if (_explanationController.text != content['explanation']) {
      _explanationController.text = (content['explanation'] as String?) ?? '';
    }
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _statementController.dispose();
    _explanationController.dispose();
    _statementFocusNode.dispose();
    _explanationFocusNode.dispose();
  }

  void _saveContentLocal() {
    content['statement'] = _statementController.text;
    content['explanation'] = _explanationController.text;
    saveContent();
  }

  @override
  Widget buildReader(BuildContext context) {
    return TrueFalseReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final correctAnswer = (content['correctAnswer'] as bool?) ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    IconsaxPlusBold.tick_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'True/False',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Statement
              TextField(
                controller: _statementController,
                focusNode: _statementFocusNode,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Statement',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                onChanged: (_) => _debouncer.call(_saveContentLocal),
              ),
              const SizedBox(height: 8),

              // Correct Answer
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            content['correctAnswer'] = true;
                          });
                          _debouncer.call(_saveContentLocal);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: correctAnswer
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: correctAnswer
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'TRUE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: correctAnswer
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            content['correctAnswer'] = false;
                          });
                          _debouncer.call(_saveContentLocal);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !correctAnswer
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel,
                                size: 16,
                                color: !correctAnswer
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FALSE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: !correctAnswer
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Show Explanation toggle + Explanation field
              Row(
                children: [
                  FilterChip(
                    label: const Text(
                      'Explanation',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: content['showExplanation'] as bool? ?? true,
                    onSelected: (value) {
                      setState(() {
                        content['showExplanation'] = value;
                      });
                      _debouncer.call(_saveContentLocal);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (content['showExplanation'] as bool? ?? true)
                TextField(
                  controller: _explanationController,
                  focusNode: _explanationFocusNode,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Explanation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (_) => _debouncer.call(_saveContentLocal),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
