import 'dart:async';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/learning/presentation/providers/learning_progress_provider.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'question_feedback_widgets.dart';

/// Type of reconstruction exercise
enum ReconstructorType {
  sentence('Sentence'),
  math('Math steps');

  const ReconstructorType(this.displayName);
  final String displayName;
}

enum OrderingExerciseVariant { wordOrder, mathWorkpad }

class WordOrderReaderBlock extends OrderingExerciseReaderBlock {
  const WordOrderReaderBlock({
    super.key,
    required super.block,
    required super.docDir,
  }) : super(variant: OrderingExerciseVariant.wordOrder);
}

class OrderingExerciseReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;
  final OrderingExerciseVariant variant;

  const OrderingExerciseReaderBlock({
    super.key,
    required this.block,
    required this.docDir,
    required this.variant,
  });

  @override
  ConsumerState<OrderingExerciseReaderBlock> createState() =>
      _OrderingExerciseReaderState();
}

class _OrderingExerciseReaderState
    extends ConsumerState<OrderingExerciseReaderBlock> {
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late final TextEditingController _contentController;
  late final TextEditingController _translationController;
  late Map<String, dynamic> _content;
  Timer? _saveDebounce;

  // Student interaction state
  final List<WordCard> _availableWords = [];
  final List<WordCard> _selectedWords = [];
  bool _isSubmitted = false;
  bool _isCorrect = false;
  String _feedback = '';
  bool _showTranslation = false;
  late ReconstructorType _type;
  late bool _isBilingual;
  late String _mathDifficulty;
  String? _savedAiExplanation;

  // Static RegExp for LaTeX detection (compiled once for performance)
  static final _latexPattern = RegExp(
    r'[\$\\^_{}]|\\(frac|sqrt|sum|int|lim|text|sin|cos|tan|log|ln|alpha|beta|gamma|delta|theta|pi|infty|partial|nabla)',
  );

  bool get _isMathWorkpad =>
      widget.variant == OrderingExerciseVariant.mathWorkpad;

  bool get _isWordOrder => widget.variant == OrderingExerciseVariant.wordOrder;

  @override
  void initState() {
    super.initState();
    _initializeContent();
    _initializeControllers();
    _initializeChallenge();
  }

  void _initializeContent() {
    try {
      if (widget.block.content.isNotEmpty) {
        final parsed = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
        _content = _normalizeIncomingContent(parsed);

        // Load saved student state if available
        _isSubmitted = _content['isSubmitted'] == true;
        _isCorrect = _content['isCorrect'] == true;
        _feedback = _content['feedback']?.toString() ?? '';
        _showTranslation = _content['showTranslation'] == true;
        _savedAiExplanation = _content['_aiExplanation'] as String?;

        _type = _isMathWorkpad
            ? ReconstructorType.math
            : ReconstructorType.sentence;
        _isBilingual = _isWordOrder && _content['isBilingual'] == true;
        _mathDifficulty = _content['mathDifficulty']?.toString() ?? 'easy';
      } else {
        _content = _getDefaultContent();
        _type = _isMathWorkpad
            ? ReconstructorType.math
            : ReconstructorType.sentence;
        _isBilingual = _isWordOrder && _content['isBilingual'] == true;
        _mathDifficulty = 'easy';
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse block content',
        error: e,
        stackTrace: stackTrace,
      );
      _content = _getDefaultContent();
      _type = _isMathWorkpad
          ? ReconstructorType.math
          : ReconstructorType.sentence;
      _isBilingual = _isWordOrder && _content['isBilingual'] == true;
      _mathDifficulty = 'easy';
    }
  }

  Map<String, dynamic> _normalizeIncomingContent(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);
    final steps =
        (normalized['steps'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final hasMathWorkpadShape =
        _isMathWorkpad || normalized.containsKey('mode') || steps.isNotEmpty;

    if (hasMathWorkpadShape) {
      final joinedSteps = steps.join('\n');
      if ((normalized['content']?.toString() ?? '').trim().isEmpty &&
          joinedSteps.isNotEmpty) {
        normalized['content'] = joinedSteps;
      }
      normalized['type'] = _isMathWorkpad
          ? ReconstructorType.math.name
          : (normalized['type']?.toString() ?? ReconstructorType.sentence.name);
      normalized['question'] =
          (normalized['question']?.toString().trim().isNotEmpty ?? false)
          ? normalized['question']
          : 'Arrange the solution steps in the correct order:';
      normalized['marksPerQuestion'] =
          (normalized['marksPerQuestion'] ?? normalized['points'] ?? 1.0);
      normalized['mode'] = 'line_order';
    }

    normalized['question'] = normalized['question']?.toString() ?? '';
    normalized['content'] = normalized['content']?.toString() ?? '';
    normalized['type'] = _isMathWorkpad
        ? ReconstructorType.math.name
        : ReconstructorType.sentence.name;
    normalized['isBilingual'] =
        _isWordOrder && normalized['isBilingual'] == true;
    normalized['translation'] = normalized['translation']?.toString() ?? '';
    normalized['explanation'] = normalized['explanation']?.toString() ?? '';
    normalized['marksPerQuestion'] =
        (normalized['marksPerQuestion'] ?? 1.0) is num
        ? normalized['marksPerQuestion']
        : double.tryParse(normalized['marksPerQuestion'].toString()) ?? 1.0;
    normalized['mathDifficulty'] =
        normalized['mathDifficulty']?.toString() ?? 'easy';
    return normalized;
  }

  Map<String, dynamic> _getDefaultContent() {
    final isMath = _isMathWorkpad;
    return {
      'question': isMath
          ? 'Arrange the solution steps to solve the problem correctly.'
          : 'Arrange the words to build a natural, correct sentence.',
      'content': isMath
          ? '3x - 6 = 9\n3x = 15\nx = 5'
          : 'She studies every morning',
      'type': isMath
          ? ReconstructorType.math.name
          : ReconstructorType.sentence.name,
      'isBilingual': false,
      'translation': '',
      'explanation': isMath
          ? 'Move constants first, then isolate the variable.'
          : 'Use the correct English word order: subject + verb + time phrase.',
      'answerOnce': false,
      'showFeedbackInstantly': true,
      'marksPerQuestion': 1.0,
      'mathDifficulty': 'easy',
    };
  }

  void _initializeControllers() {
    _questionController = TextEditingController(
      text: _content['question']?.toString() ?? '',
    );
    _explanationController = TextEditingController(
      text: _content['explanation']?.toString() ?? '',
    );
    _contentController = TextEditingController(
      text: _content['content']?.toString() ?? '',
    );
    _translationController = TextEditingController(
      text: _content['translation']?.toString() ?? '',
    );
  }

  void _initializeChallenge() {
    _availableWords.clear();
    _selectedWords.clear();

    final content = _contentController.text.trim();
    List<String> parts = [];

    if (_type == ReconstructorType.sentence) {
      // Split sentence by spaces for word-by-word reconstruction
      parts = content
          .split(' ')
          .where((word) => word.trim().isNotEmpty)
          .toList();
    } else {
      // Math mode
      // Split by newline (full lines)
      final lines = content
          .split('\n')
          .where((step) => step.trim().isNotEmpty)
          .toList();

      // If hard mode, pair parts from equations split by '='
      if (_mathDifficulty == 'hard') {
        final hardParts = <String>[];
        for (final line in lines) {
          final lineParts = line
              .split('=')
              .where((part) => part.trim().isNotEmpty)
              .map((p) => p.trim())
              .toList();

          // Pair consecutive parts as "part1 = part2"
          for (int i = 0; i < lineParts.length; i += 2) {
            if (i + 1 < lineParts.length) {
              hardParts.add('${lineParts[i]} = ${lineParts[i + 1]}');
            } else {
              // If odd number of parts, add the last one alone
              hardParts.add(lineParts[i]);
            }
          }
        }
        parts = hardParts;
      } else {
        // Easy mode: use full lines
        parts = lines;
      }
    }

    // Create word cards and shuffle
    _availableWords.addAll(
      parts.map((part) => WordCard(text: part.trim())).toList(),
    );
    _availableWords.shuffle();

    // Load saved state if available
    if (_content.containsKey('selectedWords') &&
        _content['selectedWords'] is List) {
      final savedSelected = (_content['selectedWords'] as List).cast<String>();
      for (final text in savedSelected) {
        final index = _availableWords.indexWhere((word) => word.text == text);
        if (index != -1) {
          final word = _availableWords.removeAt(index);
          _selectedWords.add(word);
        }
      }
    }

    setState(() {});
  }

  void _onWordSelected(WordCard word) {
    setState(() {
      _availableWords.remove(word);
      _selectedWords.add(word);
    });
    _checkCompletion();
    _saveCurrentState();
  }

  void _onWordDeselected(int index) {
    if (index >= 0 && index < _selectedWords.length) {
      setState(() {
        final word = _selectedWords.removeAt(index);
        _availableWords.add(word);
      });
      _checkCompletion();
      _saveCurrentState();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedWords.removeAt(oldIndex);
      _selectedWords.insert(newIndex, item);
    });
    _checkCompletion();
    _saveCurrentState();
  }

  void _checkCompletion() {
    final originalText = _contentController.text.trim();

    // Different comparison logic for sentence vs math mode
    String reconstructedText;
    String normalizedOriginal;
    String normalizedReconstructed;

    if (_type == ReconstructorType.sentence) {
      // For sentences: join with spaces and normalize whitespace
      reconstructedText = _selectedWords.map((w) => w.text).join(' ');
      normalizedOriginal = originalText.replaceAll(RegExp(r'\s+'), ' ').trim();
      normalizedReconstructed = reconstructedText
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } else {
      // For math
      if (_mathDifficulty == 'hard') {
        // Hard mode: reconstruct from pairs "part1 = part2"
        reconstructedText = _selectedWords.map((w) => w.text.trim()).join('\n');

        // Normalize original by pairing parts
        final lines = originalText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        final pairedParts = <String>[];
        for (final line in lines) {
          final lineParts = line
              .split('=')
              .where((part) => part.trim().isNotEmpty)
              .map((p) => p.trim())
              .toList();

          // Pair consecutive parts as "part1 = part2"
          for (int i = 0; i < lineParts.length; i += 2) {
            if (i + 1 < lineParts.length) {
              pairedParts.add('${lineParts[i]} = ${lineParts[i + 1]}');
            } else {
              pairedParts.add(lineParts[i]);
            }
          }
        }
        normalizedOriginal = pairedParts.join('\n');
        normalizedReconstructed = reconstructedText;
      } else {
        // Easy mode: join with newlines and normalize whitespace
        reconstructedText = _selectedWords.map((w) => w.text.trim()).join('\n');
        normalizedOriginal = originalText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .join('\n');
        normalizedReconstructed = reconstructedText;
      }
    }

    setState(() {
      _isCorrect = normalizedOriginal == normalizedReconstructed;
    });
  }

  Future<void> _submitAnswer() async {
    // Check if at least one word/step is selected
    if (_selectedWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == ReconstructorType.sentence
                ? 'Please select at least one word before submitting'
                : 'Please select at least one step before submitting',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
      _feedback = _isCorrect
          ? '🎉 Perfect! You arranged the ${_type == ReconstructorType.sentence ? 'sentence' : 'steps'} correctly!'
          : '📝 Not quite right. Review and try again.';
    });
    _saveCurrentState();
    // Record attempt for learning progress tracking.
    ref
        .read(learningProgressProvider(widget.docDir.path).notifier)
        .recordAttempt(
          blockId: widget.block.id ?? widget.block.position.toString(),
          blockType: _isMathWorkpad ? 'mathWorkpad' : 'wordOrder',
          isCorrect: _isCorrect,
        );
    if (mounted) {
      final question = _questionController.text.trim();
      final explanation = _explanationController.text.trim();
      final styleUtils = ref.read(styleUtilsProvider);
      final shouldRetry = await showDuolingoFeedbackSheet(
        context: context,
        isCorrect: _isCorrect,
        correctAnswer: _contentController.text.trim(),
        explanation: explanation,
        showExplanation: explanation.isNotEmpty,
        question: question,
        studentAnswer: _selectedWords.map((w) => w.text).join(' '),
        questionType: _type == ReconstructorType.sentence
            ? 'sentence ordering'
            : 'math step ordering',
        baseStyle: styleUtils.applyStyle(widget.block.style),
        savedAiExplanation: _savedAiExplanation,
        onAiExplanationGenerated: (ai) {
          setState(() => _savedAiExplanation = ai);
          _saveCurrentState();
        },
      );
      if (shouldRetry && mounted) _resetChallenge();
    }
  }

  void _resetChallenge() {
    setState(() {
      _isSubmitted = false;
      _isCorrect = false;
      _feedback = '';
      // Clear saved state
      _content.remove('selectedWords');
      _content.remove('isSubmitted');
      _content.remove('isCorrect');
      _content.remove('feedback');
    });
    _initializeChallenge();
    _saveCurrentState();
  }

  void _toggleTranslation() {
    setState(() {
      _showTranslation = !_showTranslation;
    });
    _saveCurrentState();
  }

  void _saveCurrentState() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      try {
        final updatedContent = Map<String, dynamic>.from(_content);
        updatedContent['selectedWords'] = _selectedWords
            .map((w) => w.text)
            .toList();
        updatedContent['isSubmitted'] = _isSubmitted;
        updatedContent['isCorrect'] = _isCorrect;
        updatedContent['feedback'] = _feedback;
        updatedContent['showTranslation'] = _showTranslation;
        if (_type == ReconstructorType.math) {
          final steps = _contentController.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          updatedContent['mode'] = 'line_order';
          updatedContent['steps'] = steps;
          updatedContent['correctOrder'] = List<int>.generate(
            steps.length,
            (index) => index,
          );
          updatedContent['points'] = updatedContent['marksPerQuestion'];
        } else {
          updatedContent.remove('mode');
          updatedContent.remove('steps');
          updatedContent.remove('correctOrder');
          updatedContent.remove('points');
        }
        if (_savedAiExplanation != null) {
          updatedContent['_aiExplanation'] = _savedAiExplanation;
        }

        final updatedBlock = widget.block.copyWith(
          content: JsonStringConverter().convertToJsonString(updatedContent),
        );

        ref
            .read(editDocumentControllerProvider(widget.docDir).notifier)
            .saveBlock(updatedBlock);
        _content = updatedContent;
      } catch (e, stackTrace) {
        logger.e(
          'Failed to save reconstructor state',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _contentController.dispose();
    _translationController.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questionController.text.trim();
    final styleUtils = ref.read(styleUtilsProvider);
    final explanation = _explanationController.text.trim();
    final translation = _translationController.text.trim();
    final template = widget.block.style.questionTemplate ?? 'default';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isMathWorkpad
                    ? Icons.functions_rounded
                    : Icons.reorder_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _isMathWorkpad ? 'Math Workpad' : 'Word Order',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (question.isNotEmpty) ...[
            _buildMathText(
              text: question,
              style: styleUtils.applyStyle(widget.block.style),
              context: context,
            ),
            const SizedBox(height: 16),
          ],

          // Translation Toggle - only for sentence/language mode
          if (_isWordOrder && _isBilingual && translation.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.translate,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Translation',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showTranslation,
                  onChanged: (value) => _toggleTranslation(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (_showTranslation) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  translation,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Reconstruction Area
          _selectedWords.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _type == ReconstructorType.sentence
                          ? 'Tap words below to build your sentence'
                          : 'Tap steps below to arrange in order',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              : _type == ReconstructorType.sentence
              ? _buildSentenceReconstructionArea(theme, template: template)
              : _buildMathStepsReconstructionArea(theme, template: template),

          const SizedBox(height: 16),

          // Available Words
          if (_availableWords.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableWords
                  .map(
                    (word) => _buildAvailableWordItem(
                      word,
                      theme,
                      template: template,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Action Button (before submission)
          if (!_isSubmitted && _selectedWords.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _submitAnswer,
                child: const Text('Check Answer'),
              ),
            )
          else if (_isSubmitted) ...[
            // Post-submit actions: [↩ Try Again]  [✨ Explain ▾]  on one row
            PostSubmitActions(
              isCorrect: _isCorrect,
              onRetry: _resetChallenge,
              explanation: explanation,
              question: question,
              correctAnswer: _contentController.text.trim(),
              studentAnswer: _selectedWords.map((w) => w.text).join(' '),
              questionType: _type == ReconstructorType.sentence
                  ? 'sentence ordering'
                  : 'math step ordering',
              baseStyle: styleUtils.applyStyle(widget.block.style),
              savedAiExplanation: _savedAiExplanation,
              onAiExplanationGenerated: (ai) {
                setState(() => _savedAiExplanation = ai);
                _saveCurrentState();
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Build sentence reconstruction area using Wrap for natural word flow
  Widget _buildSentenceReconstructionArea(
    ThemeData theme, {
    String template = 'default',
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedWords.asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        return GestureDetector(
          onTap: () => _onWordDeselected(index),
          child: _buildSelectedWordChip(
            word.text,
            theme,
            template: template,
            index: index,
          ),
        );
      }).toList(),
    );
  }

  /// Build a selected word chip with template-specific styling.
  Widget _buildSelectedWordChip(
    String text,
    ThemeData theme, {
    String template = 'default',
    int index = 0,
  }) {
    // After submission the chip reflects the result: green = correct, red = wrong.
    final Color chipColor;
    if (_isSubmitted) {
      chipColor = _isCorrect
          ? const Color(0xFF2E7D32)
          : theme.colorScheme.error;
    } else {
      chipColor = theme.colorScheme.primary;
    }
    final primary = chipColor;
    switch (template) {
      case 'card':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 'bubble':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 'tile':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primary, width: 2),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'numbered':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      case 'minimal':
        // Plain inline text – no box, no border, no underline
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 'highlight':
        // Marker-highlight style: coloured background, no border
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      default: // 'default'
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
          ),
        );
    }
  }

  /// Build math steps reconstruction area — words flow inline like a sentence.
  Widget _buildMathStepsReconstructionArea(
    ThemeData theme, {
    String template = 'default',
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedWords.asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        return GestureDetector(
          onTap: () => _onWordDeselected(index),
          child: _buildSelectedWordChip(
            word.text,
            theme,
            template: template,
            index: index,
          ),
        );
      }).toList(),
    );
  }

  /// Build a math step item with template-specific styling
  Widget _buildMathStepItem(
    int index,
    ThemeData theme, {
    String template = 'default',
  }) {
    final word = _selectedWords[index];
    final primary = theme.colorScheme.primary;

    Widget buildContent() {
      final stepLabel = _mathDifficulty != 'hard'
          ? Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: template == 'numbered'
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: template != 'numbered'
                    ? BorderRadius.circular(4)
                    : null,
                color: primary,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();

      final mathWidget = Expanded(
        child: _buildMathText(
          text: word.text,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
          context: context,
        ),
      );

      final dragHandle = Icon(
        Icons.drag_handle,
        size: 20,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      );

      return Row(
        children: [
          if (_mathDifficulty != 'hard') stepLabel,
          mathWidget,
          const SizedBox(width: 8),
          dragHandle,
        ],
      );
    }

    BoxDecoration decoration;
    EdgeInsets padding;

    switch (template) {
      case 'card':
        decoration = BoxDecoration(
          color: primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
        padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 12);
        break;
      case 'bubble':
        decoration = BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
        );
        padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 16);
        break;
      case 'tile':
        decoration = BoxDecoration(
          color: primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: primary, width: 2),
        );
        padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 12);
        break;
      case 'numbered':
        decoration = BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
            width: 1,
          ),
        );
        padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 12);
        break;
      case 'minimal':
        // Plain row with only a bottom separator – no card
        decoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(color: primary.withValues(alpha: 0.2), width: 1),
          ),
        );
        padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 4);
        break;
      case 'highlight':
        // Left-accent coloured bar with tinted background
        decoration = BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          border: Border(left: BorderSide(color: primary, width: 3)),
        );
        padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 12);
        break;
      default: // 'default'
        decoration = const BoxDecoration();
        padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 4);
    }

    return InkWell(
      key: Key('selected_${word.text}_$index'),
      onTap: () => _onWordDeselected(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: padding,
        decoration: decoration,
        child: buildContent(),
      ),
    );
  }

  Widget _buildAvailableWordItem(
    WordCard word,
    ThemeData theme, {
    String template = 'default',
  }) {
    final outline = theme.colorScheme.outline.withValues(alpha: 0.25);
    final surface = theme.colorScheme.surfaceContainerHighest;

    BoxDecoration decoration;
    EdgeInsets padding;
    TextStyle textStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 15,
    );

    switch (template) {
      case 'card':
        decoration = BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        break;
      case 'bubble':
        decoration = BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
        );
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
        break;
      case 'tile':
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: outline, width: 1.5),
        );
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
        break;
      case 'numbered':
        decoration = BoxDecoration(
          color: surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outline, width: 1),
        );
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        break;
      case 'minimal':
        // No box – plain text, no underline
        decoration = const BoxDecoration();
        padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 6);
        textStyle = TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          fontSize: 15,
        );
        break;
      case 'highlight':
        // Marker-highlight style for available words
        decoration = BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        );
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        break;
      default: // 'default'
        decoration = BoxDecoration(
          border: Border.all(color: outline),
          borderRadius: BorderRadius.circular(8),
        );
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }

    final double chipRadius;
    switch (template) {
      case 'bubble':
        chipRadius = 20;
        break;
      case 'tile':
        chipRadius = 4;
        break;
      case 'minimal':
        chipRadius = 0;
        break;
      default:
        chipRadius = 8;
    }

    return InkWell(
      onTap: () => _onWordSelected(word),
      borderRadius: BorderRadius.circular(chipRadius),
      child: Container(
        padding: padding,
        decoration: decoration,
        child: _buildMathText(
          text: word.text,
          style: textStyle,
          context: context,
        ),
      ),
    );
  }

  Widget _buildMathText({
    required String text,
    required TextStyle style,
    required BuildContext context,
  }) {
    // Use static RegExp for efficient LaTeX detection
    final hasLatex = _latexPattern.hasMatch(text);

    if (hasLatex) {
      try {
        return Math.tex(
          text,
          textStyle: style,
          mathStyle: MathStyle.text,
          onErrorFallback: (FlutterMathException e) => Text(text, style: style),
        );
      } catch (e) {
        return Text(text, style: style);
      }
    } else {
      return Text(text, style: style);
    }
  }
}

class WordCard {
  final String text;

  const WordCard({required this.text});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordCard &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}
