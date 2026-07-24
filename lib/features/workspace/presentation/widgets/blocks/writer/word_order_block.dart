import 'dart:async';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/math_workpad_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/word_order_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderingEditorVariant { wordOrder, mathWorkpad }

class WordOrderBlock extends OrderingExerciseBlock {
  const WordOrderBlock({
    required super.block,
    required super.docDir,
    required super.isEditing,
    super.key,
  }) : super(variant: OrderingEditorVariant.wordOrder);
}

class OrderingExerciseBlock extends BaseEditableBlock {
  final OrderingEditorVariant variant;

  const OrderingExerciseBlock({
    required super.block,
    required super.docDir,
    required super.isEditing,
    required this.variant,
    super.key,
  });

  @override
  ConsumerState<OrderingExerciseBlock> createState() =>
      _OrderingExerciseEditorState();
}

class _OrderingExerciseEditorState
    extends BaseEditableBlockState<OrderingExerciseBlock> {
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late TextEditingController _marksController;
  late TextEditingController _contentController;
  late TextEditingController _translationController;
  Timer? _saveDebounce;

  ReconstructorType _currentType = ReconstructorType.sentence;
  bool _isBilingual = false;
  String _mathDifficulty = 'easy'; // 'easy' or 'hard'

  bool get _isMathWorkpad =>
      widget.variant == OrderingEditorVariant.mathWorkpad;

  bool get _isWordOrder => widget.variant == OrderingEditorVariant.wordOrder;

  @override
  Map<String, dynamic> getDefaultContent() {
    if (_isMathWorkpad) {
      return {
        'question':
            'Arrange the solution steps to solve the problem correctly.',
        'content': '3x - 6 = 9\n3x = 15\nx = 5',
        'type': ReconstructorType.math.name,
        'isBilingual': false,
        'translation': '',
        'explanation': 'Move constants first, then isolate the variable.',
        'answerOnce': false,
        'showFeedbackInstantly': true,
        'marksPerQuestion': 1.0,
        'mathDifficulty': 'easy',
        'mode': 'line_order',
        'steps': ['3x - 6 = 9', '3x = 15', 'x = 5'],
        'correctOrder': [0, 1, 2],
        'points': 1.0,
      };
    }
    return {
      'question': 'Arrange the words to build a natural, correct sentence.',
      'content': 'She studies every morning',
      'type': ReconstructorType.sentence.name,
      'isBilingual': false,
      'translation': '',
      'explanation':
          'Use the correct English word order: subject + verb + time phrase.',
      'answerOnce': false,
      'showFeedbackInstantly': true,
      'marksPerQuestion': 1.0,
      'mathDifficulty': 'easy',
    };
  }

  @override
  void initializeBlockSpecifics() {
    if (_isMathWorkpad) {
      _normalizeImportedMathWorkpadContent();
    } else {
      _normalizeWordOrderContent();
    }

    _questionController = TextEditingController(
      text: content['question']?.toString() ?? '',
    );
    _explanationController = TextEditingController(
      text: content['explanation']?.toString() ?? '',
    );
    _contentController = TextEditingController(
      text: content['content']?.toString() ?? '',
    );
    _translationController = TextEditingController(
      text: content['translation']?.toString() ?? '',
    );
    _marksController = TextEditingController(
      text: (content['marksPerQuestion'] ?? 1.0).toString(),
    );

    _currentType = _isMathWorkpad
        ? ReconstructorType.math
        : ReconstructorType.sentence;
    _isBilingual = _isWordOrder && content['isBilingual'] == true;
    _mathDifficulty = content['mathDifficulty']?.toString() ?? 'easy';

    _questionController.addListener(_onContentChanged);
    _explanationController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
    _translationController.addListener(_onContentChanged);
    _marksController.addListener(() {
      final parsed =
          double.tryParse(_marksController.text) ??
          (content['marksPerQuestion'] ?? 1.0);
      content['marksPerQuestion'] = parsed;
      _onContentChanged();
    });
  }

  void _normalizeWordOrderContent() {
    content['type'] = ReconstructorType.sentence.name;
    content['question'] =
        (content['question']?.toString().trim().isNotEmpty ?? false)
        ? content['question']
        : 'Arrange the words to build a natural, correct sentence.';
    content['isBilingual'] = content['isBilingual'] == true;
    content['translation'] = content['translation']?.toString() ?? '';
    content['mathDifficulty'] = content['mathDifficulty']?.toString() ?? 'easy';
    content.remove('mode');
    content.remove('steps');
    content.remove('correctOrder');
    content.remove('points');
  }

  void _normalizeImportedMathWorkpadContent() {
    final steps =
        (content['steps'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final hasMathWorkpadShape = content.containsKey('mode') || steps.isNotEmpty;
    if (!hasMathWorkpadShape) return;

    if ((content['content']?.toString() ?? '').trim().isEmpty &&
        steps.isNotEmpty) {
      content['content'] = steps.join('\n');
    }
    content['type'] = ReconstructorType.math.name;
    content['question'] =
        (content['question']?.toString().trim().isNotEmpty ?? false)
        ? content['question']
        : 'Arrange the solution steps in the correct order:';
    content['explanation'] = content['explanation']?.toString() ?? '';
    content['marksPerQuestion'] =
        (content['marksPerQuestion'] ?? content['points'] ?? 1.0) as num;
    content['mathDifficulty'] = content['mathDifficulty']?.toString() ?? 'easy';
    content['mode'] = 'line_order';
  }

  @override
  void onContentChanged() {
    final newQuestion = content['question']?.toString() ?? '';
    if (_questionController.text != newQuestion)
      _questionController.text = newQuestion;

    final newExplanation = content['explanation']?.toString() ?? '';
    if (_explanationController.text != newExplanation)
      _explanationController.text = newExplanation;

    final newContentText = content['content']?.toString() ?? '';
    if (_contentController.text != newContentText)
      _contentController.text = newContentText;

    final newTranslation = content['translation']?.toString() ?? '';
    if (_translationController.text != newTranslation)
      _translationController.text = newTranslation;

    final newMarks = (content['marksPerQuestion'] ?? 1.0).toString();
    if (_marksController.text != newMarks) _marksController.text = newMarks;

    final newType = ReconstructorType.values.firstWhere(
      (e) => e.name == content['type'],
      orElse: () => ReconstructorType.sentence,
    );
    if (_currentType != newType) {
      setState(() {
        _currentType = newType;
      });
    }

    final newBilingual = content['isBilingual'] == true;
    if (_isBilingual != newBilingual) {
      setState(() {
        _isBilingual = newBilingual;
      });
    }

    final newDifficulty = content['mathDifficulty']?.toString() ?? 'easy';
    if (_mathDifficulty != newDifficulty) {
      setState(() {
        _mathDifficulty = newDifficulty;
      });
    }
  }

  @override
  void disposeBlockSpecifics() {
    _questionController.removeListener(_onContentChanged);
    _explanationController.removeListener(_onContentChanged);
    _contentController.removeListener(_onContentChanged);
    _translationController.removeListener(_onContentChanged);
    _questionController.dispose();
    _explanationController.dispose();
    _contentController.dispose();
    _translationController.dispose();
    _marksController.dispose();
    _saveDebounce?.cancel();
  }

  void _onContentChanged() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () {
      _saveContentLocal();
    });
  }

  void _saveContentLocal() {
    content['question'] = _questionController.text;
    content['content'] = _contentController.text;
    content['type'] = _isMathWorkpad
        ? ReconstructorType.math.name
        : ReconstructorType.sentence.name;
    content['isBilingual'] = _isBilingual;
    content['translation'] = _translationController.text;
    content['explanation'] = _explanationController.text;
    content['answerOnce'] = content['answerOnce'] ?? false;
    content['showFeedbackInstantly'] = content['showFeedbackInstantly'] ?? true;
    content['marksPerQuestion'] = content['marksPerQuestion'] ?? 1.0;
    content['mathDifficulty'] = _mathDifficulty;
    if (_isMathWorkpad) {
      final steps = _contentController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      content['mode'] = 'line_order';
      content['steps'] = steps;
      content['correctOrder'] = List<int>.generate(
        steps.length,
        (index) => index,
      );
      content['points'] = content['marksPerQuestion'];
    } else {
      content.remove('mode');
      content.remove('steps');
      content.remove('correctOrder');
      content.remove('points');
    }
    saveContent();
  }

  void _setBilingual(bool value) {
    setState(() {
      _isBilingual = value;
    });
    _onContentChanged();
  }

  void _setMathDifficulty(String? value) {
    if (value == null) return;
    setState(() {
      _mathDifficulty = value;
    });
    _onContentChanged();
  }

  @override
  Widget buildReader(BuildContext context) {
    return _isMathWorkpad
        ? MathWorkpadReaderBlock(block: widget.block, docDir: widget.docDir)
        : WordOrderReaderBlock(block: widget.block, docDir: widget.docDir);
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

        const SizedBox(height: 8),

        Row(
          children: [
            Icon(
              _isMathWorkpad ? Icons.functions_rounded : Icons.reorder_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _isMathWorkpad ? 'Math Workpad' : 'Word Order',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 1: Points
        Row(
          children: [
            SizedBox(
              width: 72,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                controller: _marksController,
                onSubmitted: (v) => _onContentChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Math difficulty (only for math type)
        if (_isMathWorkpad) ...[
          DropdownButtonFormField<String>(
            value: _mathDifficulty,
            onChanged: _setMathDifficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'easy',
                child: Text(
                  'Easy - full lines',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'hard',
                child: Text(
                  'Hard - split by =',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Row 3: Bilingual toggle
        if (_isWordOrder) ...[
          Row(
            children: [
              Icon(
                Icons.translate,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Bilingual hint',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isBilingual,
                onChanged: _setBilingual,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Question / instruction
        TextField(
          controller: _questionController,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Question',
            hintText: _isMathWorkpad
                ? 'e.g. Arrange the steps to solve 2x + 3 = 11'
                : 'e.g. Arrange the words to form a correct sentence',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),

        // Sentence / content to reconstruct
        TextField(
          controller: _contentController,
          minLines: _isMathWorkpad ? 2 : 1,
          maxLines: _isMathWorkpad ? 6 : 3,
          decoration: InputDecoration(
            labelText: _isMathWorkpad ? 'Steps' : 'Sentence',
            hintText: _isMathWorkpad
                ? 'One step per line'
                : 'The cat sat on the mat',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Translation (bilingual only)
        if (_isWordOrder && _isBilingual) ...[
          TextField(
            controller: _translationController,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Translation',
              hintText: 'Shown as a hint to the learner',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Explanation / answer rationale
        TextField(
          controller: _explanationController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Explanation',
            hintText: 'Shown after the learner submits',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }
}
