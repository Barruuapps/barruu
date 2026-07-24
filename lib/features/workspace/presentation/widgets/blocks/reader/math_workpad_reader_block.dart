import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/learning/presentation/providers/learning_progress_provider.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'question_feedback_widgets.dart';

class MathWorkpadReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const MathWorkpadReaderBlock({
    super.key,
    required this.block,
    required this.docDir,
  });

  @override
  ConsumerState<MathWorkpadReaderBlock> createState() =>
      _MathWorkpadReaderBlockState();
}

class _MathWorkpadReaderBlockState
    extends ConsumerState<MathWorkpadReaderBlock> {
  static const Color _kCorrectColor = Color(0xFF059669);
  static const Color _kErrorColor = Color(0xFFEF4444);

  late Map<String, dynamic> _content;

  List<String> _steps = [];
  List<int> _correctOrder = [];
  List<int> _shuffledStepIndices = [];
  List<int> _placedStepIndices = [];
  bool _isSubmitted = false;
  bool _isCorrect = false;
  String? _savedAiExplanation;

  final List<TextEditingController> _scratchControllers = [];
  final bool _showSolution = false;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void dispose() {
    for (final c in _scratchControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isLineOrderMode {
    final mode = _content['mode']?.toString() ?? '';
    return mode == 'line_order' && _steps.length >= 2;
  }

  void _parseContent() {
    try {
      _content = JsonStringConverter().convertFromJsonString(
        widget.block.content,
      );
    } catch (_) {
      _content = <String, dynamic>{};
    }

    _savedAiExplanation = _content['_aiExplanation'] as String?;

    final rawSteps =
        ((_content['steps'] as List?) ??
                (_content['referenceSteps'] as List?) ??
                const <dynamic>[])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
    _steps = rawSteps;

    final rawOrder = (_content['correctOrder'] as List?)
        ?.map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    _correctOrder = (rawOrder != null && rawOrder.length == _steps.length)
        ? rawOrder
        : List<int>.generate(_steps.length, (i) => i);

    if (_isLineOrderMode) {
      _isSubmitted = _content['isSubmitted'] == true;
      _isCorrect = _content['isCorrect'] == true;
      _placedStepIndices =
          ((_content['placedStepIndices'] as List?) ?? const <dynamic>[])
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .where((i) => i >= 0 && i < _solvableSteps.length)
              .toList();

      final persistedShuffle =
          ((_content['shuffledStepIndices'] as List?) ?? const <dynamic>[])
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .where((i) => i >= 0 && i < _solvableSteps.length)
              .toList();

      if (persistedShuffle.length == _solvableSteps.length) {
        _shuffledStepIndices = persistedShuffle;
      } else {
        _shuffledStepIndices = List<int>.generate(
          _solvableSteps.length,
          (i) => i,
        )..shuffle(Random());
      }
      return;
    }

    // Fallback parsing
    final studentSteps =
        ((_content['studentSteps'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();
    if (studentSteps.isEmpty) studentSteps.add('');

    for (final step in studentSteps) {
      final ctrl = TextEditingController(text: step);
      ctrl.addListener(_persistScratchpad);
      _scratchControllers.add(ctrl);
    }
  }

  String get _question => _content['question']?.toString().trim() ?? '';
  String get _explanation => _content['explanation']?.toString().trim() ?? '';
  bool get _showExplanation => _content['showExplanation'] as bool? ?? true;

  String get _givenStep => _steps.isNotEmpty ? _steps.first : '';
  List<String> get _solvableSteps =>
      _steps.length > 1 ? _steps.sublist(1) : const <String>[];

  List<int> get _solvableCorrectOrder {
    if (_correctOrder.length <= 1) {
      return List<int>.generate(_solvableSteps.length, (i) => i);
    }
    return _correctOrder.skip(1).map((idx) => idx - 1).toList();
  }

  List<int> get _bankStepIndices {
    final placed = _placedStepIndices.toSet();
    return _shuffledStepIndices.where((idx) => !placed.contains(idx)).toList();
  }

  void _persistLineOrder() {
    try {
      final updated = Map<String, dynamic>.from(_content);
      updated['mode'] = 'line_order';
      updated['steps'] = _steps;
      updated['correctOrder'] = _correctOrder;
      updated['shuffledStepIndices'] = _shuffledStepIndices;
      updated['placedStepIndices'] = _placedStepIndices;
      updated['isSubmitted'] = _isSubmitted;
      updated['isCorrect'] = _isCorrect;
      if (_savedAiExplanation != null) {
        updated['_aiExplanation'] = _savedAiExplanation;
      }

      final jsonStr = JsonStringConverter().convertToJsonString(updated);
      final updatedBlock = widget.block.copyWith(content: jsonStr);
      ref
          .read(editDocumentControllerProvider(widget.docDir).notifier)
          .saveBlock(updatedBlock);
      _content = updated;
    } catch (e, st) {
      logger.e('Math workpad persist failed', error: e, stackTrace: st);
    }
  }

  void _persistScratchpad() {
    try {
      final updated = Map<String, dynamic>.from(_content);
      updated['studentSteps'] = _scratchControllers.map((c) => c.text).toList();
      final jsonStr = JsonStringConverter().convertToJsonString(updated);
      final updatedBlock = widget.block.copyWith(content: jsonStr);
      ref
          .read(editDocumentControllerProvider(widget.docDir).notifier)
          .saveBlock(updatedBlock);
      _content = updated;
    } catch (e, st) {
      logger.e('Math scratchpad persist failed', error: e, stackTrace: st);
    }
  }

  void _tapBankStep(int stepIndex) {
    if (_isSubmitted) return;
    setState(() {
      _placedStepIndices.add(stepIndex);
    });
    _persistLineOrder();

    if (_placedStepIndices.length == _solvableSteps.length) {
      Future.delayed(const Duration(milliseconds: 400), _submitLineOrder);
    }
  }

  void _tapPlacedStep(int position) {
    if (_isSubmitted) return;
    if (position < 0 || position >= _placedStepIndices.length) return;
    setState(() {
      _placedStepIndices.removeAt(position);
    });
    _persistLineOrder();
  }

  Future<void> _submitLineOrder() async {
    if (_placedStepIndices.length != _solvableSteps.length) return;

    final correct =
        _placedStepIndices.length == _solvableCorrectOrder.length &&
        _placedStepIndices.asMap().entries.every(
          (e) => _solvableCorrectOrder[e.key] == e.value,
        );

    setState(() {
      _isSubmitted = true;
      _isCorrect = correct;
    });
    _persistLineOrder();

    ref
        .read(learningProgressProvider(widget.docDir.path).notifier)
        .recordAttempt(
          blockId: widget.block.id ?? widget.block.position.toString(),
          blockType: 'mathWorkpad',
          isCorrect: correct,
        );

    if (mounted) {
      final shouldRetry = await showDuolingoFeedbackSheet(
        context: context,
        isCorrect: correct,
        correctAnswer: _steps.join(' → '),
        explanation: _showExplanation ? _explanation : '',
        showExplanation: _showExplanation,
        question: _question,
        studentAnswer: [
          _givenStep,
          ..._placedStepIndices.map((i) => _solvableSteps[i]),
        ].where((e) => e.trim().isNotEmpty).join(' → '),
        questionType: 'math step ordering',
        savedAiExplanation: _savedAiExplanation,
        onAiExplanationGenerated: (ai) {
          setState(() => _savedAiExplanation = ai);
          _persistLineOrder();
        },
      );
      if (shouldRetry && mounted) {
        _retryLineOrder();
      }
    }
  }

  void _retryLineOrder() {
    setState(() {
      _isSubmitted = false;
      _isCorrect = false;
      _placedStepIndices.clear();
    });
    _persistLineOrder();
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);

    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;

    final baseStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(
          fontSize: fontSize * ResponsiveUtils.getTextSizeMultiplier(context),
          color: color,
        );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLineOrderMode
          ? _buildLineOrder(context, theme, baseStyle)
          : _buildScratchpad(context, theme, baseStyle),
    );
  }

  Widget _buildLineOrder(
    BuildContext context,
    ThemeData theme,
    TextStyle baseStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_question.isNotEmpty)
          Text(
            _question,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        if (_question.isNotEmpty) const SizedBox(height: 16),

        if (_givenStep.isNotEmpty) ...[
          Text(
            'GIVEN EQUATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          _buildMathText(
            _givenStep,
            theme,
            baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          'YOUR ANSWER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 64,
          ), // FIXED CONSTRAINT HERE
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _placedStepIndices.isNotEmpty
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _placedStepIndices.isNotEmpty
                  ? Colors.transparent
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: _placedStepIndices.isEmpty
              ? Center(
                  child: Text(
                    'Tap the steps below to build the correct solution order',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _placedStepIndices.asMap().entries.map((entry) {
                    final position = entry.key;
                    final idx = entry.value;
                    final stepText = _solvableSteps[idx];
                    final isCorrectAtPosition = _isSubmitted
                        ? (_solvableCorrectOrder[position] == idx)
                        : null;

                    return _buildChip(
                      text: stepText,
                      theme: theme,
                      baseStyle: baseStyle,
                      isPlaced: true,
                      isCorrect: isCorrectAtPosition,
                      onTap: () => _tapPlacedStep(position),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 20),

        if (!_isSubmitted) ...[
          Text(
            'AVAILABLE STEPS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_bankStepIndices.isEmpty &&
                  _placedStepIndices.length == _solvableSteps.length)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kCorrectColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kCorrectColor.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'All steps placed!',
                    style: TextStyle(
                      color: _kCorrectColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ..._bankStepIndices.map(
                (idx) => _buildChip(
                  text: _solvableSteps[idx],
                  theme: theme,
                  baseStyle: baseStyle,
                  isPlaced: false,
                  onTap: () => _tapBankStep(idx),
                ),
              ),
            ],
          ),
        ],

        if (_isSubmitted) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          PostSubmitActions(
            isCorrect: _isCorrect,
            onRetry: _retryLineOrder,
            explanation: _showExplanation ? _explanation : '',
            showExplanation: _showExplanation,
            question: _question,
            correctAnswer: _steps.join(' → '),
            studentAnswer: [
              _givenStep,
              ..._placedStepIndices.map((i) => _solvableSteps[i]),
            ].where((e) => e.trim().isNotEmpty).join(' → '),
            questionType: 'math step ordering',
            baseStyle: baseStyle,
            savedAiExplanation: _savedAiExplanation,
            onAiExplanationGenerated: (ai) {
              setState(() => _savedAiExplanation = ai);
              _persistLineOrder();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required String text,
    required ThemeData theme,
    required TextStyle baseStyle,
    required bool isPlaced,
    bool? isCorrect,
    required VoidCallback onTap,
  }) {
    Color bgColor = theme.colorScheme.surface;
    Color borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
    Color textColor = theme.colorScheme.onSurface;
    TextDecoration decoration = TextDecoration.none;

    if (isCorrect == true) {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = _kCorrectColor;
    } else if (isCorrect == false) {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = _kErrorColor;
      decoration = TextDecoration.lineThrough;
    } else if (isPlaced) {
      bgColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
    }

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      elevation: (isPlaced || isCorrect != null) ? 0 : 1,
      child: InkWell(
        onTap: _isSubmitted ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildMathText(
            text,
            theme,
            baseStyle.copyWith(
              color: textColor,
              decoration: decoration,
              fontWeight: isCorrect == true ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMathText(String text, ThemeData theme, TextStyle baseStyle) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    try {
      return Math.tex(
        text,
        textStyle: baseStyle.copyWith(color: baseStyle.color),
        onErrorFallback: (e) =>
            Text(text, style: baseStyle, overflow: TextOverflow.ellipsis),
      );
    } catch (_) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }
  }

  Widget _buildScratchpad(
    BuildContext context,
    ThemeData theme,
    TextStyle baseStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode not supported graphically',
          style: baseStyle.copyWith(color: theme.colorScheme.error),
        ),
      ],
    );
  }
}
