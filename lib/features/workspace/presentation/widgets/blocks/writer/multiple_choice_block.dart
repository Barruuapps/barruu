import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/multiple_choice_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';

/// Multiple choice question block for creating interactive questions.
/// 
/// Content format:
/// ```json
/// {
///   "questionType": "multipleChoice",
///   "question": "What is the capital of France?",
///   "options": [
///     {"id": "a", "text": "London", "isCorrect": false},
///     {"id": "b", "text": "Paris", "isCorrect": true}
///   ],
///   "allowMultiple": false,
///   "shuffleOptions": true,
///   "explanation": "Paris has been the capital of France since the 12th century.",
///   "points": 1,
///   "tags": ["geography", "europe"],
///   "difficulty": "easy"
/// }
/// ```
class MultipleChoiceBlock extends BaseEditableBlock {
  const MultipleChoiceBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<MultipleChoiceBlock> createState() => _MultipleChoiceBlockState();
}

class _MultipleChoiceBlockState extends BaseEditableBlockState<MultipleChoiceBlock> {
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late FocusNode _questionFocusNode;
  late FocusNode _explanationFocusNode;
  late Debouncer _debouncer;
  List<Map<String, dynamic>> _options = [];

  @override
  Map<String, dynamic> getDefaultContent() => {
    'questionType': 'multipleChoice',
    'question': 'Enter your question here',
    'options': [
      {'id': 'a', 'text': ' ', 'isCorrect': false},
      {'id': 'b', 'text': ' ', 'isCorrect': true},
      {'id': 'c', 'text': '', 'isCorrect': false},
      {'id': 'd', 'text': '', 'isCorrect': false},
    ],
    'allowMultiple': false,
    'shuffleOptions': true,
    'showExplanation': true,
    'explanation': 'Explain the correct answer here.',
    'points': 1,
    'tags': [],
    'difficulty': 'medium',
  };

  @override
  void initializeBlockSpecifics() {
    _questionController = TextEditingController(text: content['question'] ?? '');
    _explanationController = TextEditingController(text: content['explanation'] ?? '');
    _questionFocusNode = FocusNode();
    _explanationFocusNode = FocusNode();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    
    // Initialize options
    _options = List<Map<String, dynamic>>.from(content['options'] ?? []);
    if (_options.isEmpty) {
      _options = List<Map<String, dynamic>>.from(getDefaultContent()['options'] as List);
    }
  }

  @override
  void onContentChanged() {
    if (_questionController.text != content['question']) {
      _questionController.text = content['question'] ?? '';
    }
    if (_explanationController.text != content['explanation']) {
      _explanationController.text = content['explanation'] ?? '';
    }
    _options = List<Map<String, dynamic>>.from(content['options'] ?? []);
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _questionController.dispose();
    _explanationController.dispose();
    _questionFocusNode.dispose();
    _explanationFocusNode.dispose();
  }

  void _saveContentLocal() {
    content['question'] = _questionController.text;
    content['explanation'] = _explanationController.text;
    content['options'] = _options;
    saveContent();
  }

  void _addOption() {
    setState(() {
      final newId = String.fromCharCode(97 + _options.length); // a, b, c, d...
      _options.add({
        'id': newId,
        'text': 'Option ${newId.toUpperCase()}',
        'isCorrect': false,
      });
    });
    _debouncer.call(_saveContentLocal);
  }

  void _removeOption(int index) {
    if (_options.length > 2) {
      setState(() {
        _options.removeAt(index);
      });
      _debouncer.call(_saveContentLocal);
    }
  }

  void _toggleCorrect(int index) {
    setState(() {
      final allowMultiple = content['allowMultiple'] ?? false;
      if (!allowMultiple) {
        // Single choice: uncheck all others
        for (var option in _options) {
          option['isCorrect'] = false;
        }
      }
      _options[index]['isCorrect'] = !(_options[index]['isCorrect'] ?? false);
    });
    _debouncer.call(_saveContentLocal);
  }

  void _updateOptionText(int index, String text) {
    _options[index]['text'] = text;
    _debouncer.call(_saveContentLocal);
  }

  @override
  Widget buildReader(BuildContext context) {
    return MultipleChoiceReaderBlock(
      block: widget.block,
      docDir: widget.docDir,
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final allowMultiple = content['allowMultiple'] ?? false;

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
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(IconsaxPlusBold.task_square, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Multiple Choice',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Question
              TextField(
                controller: _questionController,
                focusNode: _questionFocusNode,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Question',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (_) => _debouncer.call(_saveContentLocal),
              ),
              const SizedBox(height: 8),
              
              ...List.generate(_options.length, (index) {
                final option = _options[index];
                final isCorrect = option['isCorrect'] ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleCorrect(index),
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: isCorrect
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Option text
                      Expanded(
                        child: TextFormField(
                          maxLines: 2,
                          minLines: 1,
                          initialValue: option['text'],
                          style: theme.textTheme.bodySmall,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Option',
                            isDense: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (text) => _updateOptionText(index, text),
                        ),
                      ),
                      // Delete button
                      if (_options.length > 2)
                        IconButton(
                          icon: const Icon(IconsaxPlusBold.minus, size: 16, color: Colors.red),
                          onPressed: () => _removeOption(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 16,
                        ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 6),
              
              // Add option button & settings in one row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  OutlinedButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(IconsaxPlusBold.add, size: 16, fontWeight: FontWeight.bold,),
                    label: const Text('Add', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                        FilterChip(
                          label: const Text('Multi', style: TextStyle(fontSize: 11)),
                          selected: allowMultiple,
                          onSelected: (value) {
                            setState(() {
                              content['allowMultiple'] = value;
                            });
                            _debouncer.call(_saveContentLocal);
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        FilterChip(
                          label: const Text('Shuffle', style: TextStyle(fontSize: 11)),
                          selected: content['shuffleOptions'] ?? true,
                          onSelected: (value) {
                            setState(() {
                              content['shuffleOptions'] = value;
                            });
                            _debouncer.call(_saveContentLocal);
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        FilterChip(
                          label: const Text('Explanation', style: TextStyle(fontSize: 11)),
                          selected: content['showExplanation'] ?? true,
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
              const SizedBox(height: 8),
              
              // Explanation
              TextField(
                controller: _explanationController,
                focusNode: _explanationFocusNode,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Explanation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
