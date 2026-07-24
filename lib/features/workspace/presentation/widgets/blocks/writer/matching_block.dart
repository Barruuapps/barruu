import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/matching_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';

/// Matching question block for creating pair-matching questions.
/// 
/// Content format:
/// ```json
/// {
///   "questionType": "matching",
///   "instruction": "Match each programming language with its primary use case:",
///   "leftColumn": [
///     {"id": "l1", "text": "Python"},
///     {"id": "l2", "text": "JavaScript"}
///   ],
///   "rightColumn": [
///     {"id": "r1", "text": "Web interactivity"},
///     {"id": "r2", "text": "Data science"}
///   ],
///   "correctPairs": [
///     {"left": "l1", "right": "r2"},
///     {"left": "l2", "right": "r1"}
///   ],
///   "shuffleItems": true,
///   "allowPartialCredit": true,
///   "explanation": "Python excels in data science. JavaScript powers web interactivity.",
///   "points": 2,
///   "tags": ["programming"],
///   "difficulty": "medium"
/// }
/// ```
class MatchingBlock extends BaseEditableBlock {
  const MatchingBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<MatchingBlock> createState() => _MatchingBlockState();
}

class _MatchingBlockState extends BaseEditableBlockState<MatchingBlock> {
  late TextEditingController _instructionController;
  late TextEditingController _explanationController;
  late FocusNode _instructionFocusNode;
  late FocusNode _explanationFocusNode;
  late Debouncer _debouncer;
  List<Map<String, dynamic>> _leftColumn = [];
  List<Map<String, dynamic>> _rightColumn = [];
  List<Map<String, dynamic>> _correctPairs = [];

  @override
  Map<String, dynamic> getDefaultContent() => {
    'questionType': 'matching',
    'instruction': 'Match the items on the left with the correct items on the right:',
    'leftColumn': [
      {'id': 'l1', 'text': ''},
      {'id': 'l2', 'text': ''},
    ],
    'rightColumn': [
      {'id': 'r1', 'text': ''},
      {'id': 'r2', 'text': ''},
    ],
    'correctPairs': [
      {'left': 'l1', 'right': 'r1'},
      {'left': 'l2', 'right': 'r2'},
    ],
    'shuffleItems': true,
    'allowPartialCredit': true,
    'explanation': 'Explain the correct matches here.',
    'showExplanation': true,
    'points': 2,
    'tags': [],
    'difficulty': 'medium',
  };

  @override
  void initializeBlockSpecifics() {
    _instructionController = TextEditingController(text: content['instruction'] ?? '');
    _explanationController = TextEditingController(text: content['explanation'] ?? '');
    _instructionFocusNode = FocusNode();
    _explanationFocusNode = FocusNode();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

    _leftColumn = List<Map<String, dynamic>>.from(content['leftColumn'] ?? []);
    _rightColumn = List<Map<String, dynamic>>.from(content['rightColumn'] ?? []);
    _correctPairs = List<Map<String, dynamic>>.from(content['correctPairs'] ?? []);

    if (_leftColumn.isEmpty || _rightColumn.isEmpty) {
      final defaults = getDefaultContent();
      _leftColumn = List<Map<String, dynamic>>.from(defaults['leftColumn'] as List);
      _rightColumn = List<Map<String, dynamic>>.from(defaults['rightColumn'] as List);
      _correctPairs = List<Map<String, dynamic>>.from(defaults['correctPairs'] as List);
    }
  }

  @override
  void onContentChanged() {
    if (_instructionController.text != content['instruction']) {
      _instructionController.text = content['instruction'] ?? '';
    }
    if (_explanationController.text != content['explanation']) {
      _explanationController.text = content['explanation'] ?? '';
    }
    _leftColumn = List<Map<String, dynamic>>.from(content['leftColumn'] ?? []);
    _rightColumn = List<Map<String, dynamic>>.from(content['rightColumn'] ?? []);
    _correctPairs = List<Map<String, dynamic>>.from(content['correctPairs'] ?? []);
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _instructionController.dispose();
    _explanationController.dispose();
    _instructionFocusNode.dispose();
    _explanationFocusNode.dispose();
  }

  void _saveContentLocal() {
    content['instruction'] = _instructionController.text;
    content['explanation'] = _explanationController.text;
    content['leftColumn'] = _leftColumn;
    content['rightColumn'] = _rightColumn;
    content['correctPairs'] = _correctPairs;
    saveContent();
  }

  void _addPair() {
    setState(() {
      final leftId = 'l${_leftColumn.length + 1}';
      final rightId = 'r${_rightColumn.length + 1}';
      _leftColumn.add({'id': leftId, 'text': ''});
      _rightColumn.add({'id': rightId, 'text': ''});
      _correctPairs.add({'left': leftId, 'right': rightId});
    });
    _debouncer.call(_saveContentLocal);
  }

  void _removePair(int index) {
    if (_leftColumn.length > 2) {
      setState(() {
        final leftId = _leftColumn[index]['id'];
        final rightId = _rightColumn[index]['id'];
        _leftColumn.removeAt(index);
        _rightColumn.removeAt(index);
        _correctPairs.removeWhere(
          (pair) => pair['left'] == leftId || pair['right'] == rightId,
        );
      });
      _debouncer.call(_saveContentLocal);
    }
  }

  void _movePair(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _leftColumn.length) return;
    setState(() {
      final leftItem = _leftColumn.removeAt(index);
      _leftColumn.insert(newIndex, leftItem);
      final rightItem = _rightColumn.removeAt(index);
      _rightColumn.insert(newIndex, rightItem);
    });
    _debouncer.call(_saveContentLocal);
  }

  void _updateLeftItem(int index, String text) {
    _leftColumn[index]['text'] = text;
    _debouncer.call(_saveContentLocal);
  }

  void _updateRightItem(int index, String text) {
    _rightColumn[index]['text'] = text;
    _debouncer.call(_saveContentLocal);
  }

  @override
  Widget buildReader(BuildContext context) {
    return MatchingReaderBlock(
      block: widget.block,
      docDir: widget.docDir,
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(IconsaxPlusBold.link_21, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Matching',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Instruction
              TextField(
                controller: _instructionController,
                focusNode: _instructionFocusNode,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Instruction (e.g. Match each term with its definition)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (_) => _debouncer.call(_saveContentLocal),
              ),
              const SizedBox(height: 10),

              // Column headers
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Left header
                    Expanded(
                      child: Text(
                        'LEFT',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28), // space for arrow icon
                    // Right header
                    Expanded(
                      child: Text(
                        'RIGHT',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // Spacer for action buttons column
                    const SizedBox(width: 56),
                  ],
                ),
              ),

              // Pairs
              ...List.generate(_leftColumn.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left input
                      Expanded(
                        child: TextFormField(
                          initialValue: _leftColumn[index]['text'],
                          minLines: 1,
                          maxLines: 2,
                          style: theme.textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'Item ${index + 1}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            isDense: true,
                            contentPadding: const EdgeInsets.all(8),
                          ),
                          onChanged: (text) => _updateLeftItem(index, text),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      // Right input
                      Expanded(
                        child: TextFormField(
                          initialValue: _rightColumn[index]['text'],
                          minLines: 1,
                          maxLines: 2,
                          style: theme.textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'Match ${index + 1}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            isDense: true,
                            contentPadding: const EdgeInsets.all(8),
                          ),
                          onChanged: (text) => _updateRightItem(index, text),
                        ),
                      ),
                      // Action buttons
                      const SizedBox(width: 4),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Move up
                          if (index > 0)
                            _actionIconButton(
                              icon: Icons.keyboard_arrow_up_rounded,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              onTap: () => _movePair(index, -1),
                            )
                          else
                            const SizedBox(width: 22, height: 22),
                          // Move down
                          if (index < _leftColumn.length - 1)
                            _actionIconButton(
                              icon: Icons.keyboard_arrow_down_rounded,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              onTap: () => _movePair(index, 1),
                            )
                          else
                            const SizedBox(width: 22, height: 22),
                        ],
                      ),
                      // Delete button
                      if (_leftColumn.length > 2)
                        _actionIconButton(
                          icon: IconsaxPlusBold.minus,
                          color: theme.colorScheme.error.withOpacity(0.7),
                          onTap: () => _removePair(index),
                        )
                      else
                        const SizedBox(width: 22),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 4),

              // Add button & settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addPair,
                    icon: const Icon(IconsaxPlusBold.add, size: 14),
                    label: const Text('Add Pair', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  Flexible(
                    child: Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.end,
                    children: [
                      FilterChip(
                        label: const Text('Shuffle', style: TextStyle(fontSize: 11)),
                        selected: content['shuffleItems'] ?? true,
                        onSelected: (value) {
                          setState(() => content['shuffleItems'] = value);
                          _debouncer.call(_saveContentLocal);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      FilterChip(
                        label: const Text('Partial', style: TextStyle(fontSize: 11)),
                        selected: content['allowPartialCredit'] ?? true,
                        onSelected: (value) {
                          setState(() => content['allowPartialCredit'] = value);
                          _debouncer.call(_saveContentLocal);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      FilterChip(
                        label: const Text('Explanation', style: TextStyle(fontSize: 11)),
                        selected: content['showExplanation'] as bool? ?? true,
                        onSelected: (value) {
                          setState(() => content['showExplanation'] = value);
                          _debouncer.call(_saveContentLocal);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      FilterChip(
                        label: const Text('Instant Check', style: TextStyle(fontSize: 11)),
                        selected: content['evaluateOnMatch'] as bool? ?? false,
                        onSelected: (value) {
                          setState(() => content['evaluateOnMatch'] = value);
                          _debouncer.call(_saveContentLocal);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Explanation
              if (content['showExplanation'] as bool? ?? true)
                TextField(
                  controller: _explanationController,
                  focusNode: _explanationFocusNode,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Explanation (shown after answering)',
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

  Widget _actionIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
