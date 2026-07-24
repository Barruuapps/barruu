import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/learning/presentation/providers/learning_progress_provider.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/data/services/answer_validation_service.dart';
import 'question_feedback_widgets.dart';

/// Read-only display of true/false question block with answer submission.
class TrueFalseReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const TrueFalseReaderBlock({
    required this.block,
    required this.docDir,
    super.key,
  });

  @override
  ConsumerState<TrueFalseReaderBlock> createState() =>
      _TrueFalseReaderBlockState();
}

class _TrueFalseReaderBlockState extends ConsumerState<TrueFalseReaderBlock> {
  // Green used for correct-answer highlighting across all templates.
  static const Color _kCorrectColor = Color(0xFF2E7D32);

  late Map<String, dynamic> _content;
  bool? _selectedAnswer;
  bool _isSubmitted = false;
  ValidationResult? _result;
  String? _savedAiExplanation;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  void _parseContent() {
    final converter = JsonStringConverter();
    try {
      _content = converter.convertFromJsonString(widget.block.content);

      // Restore interactive state stored in the block's own JSON content.
      final submitted = _content['_isSubmitted'] as bool? ?? false;
      final answerVal = _content['_selectedAnswer'];
      final bool? savedAnswer = answerVal == null
          ? null
          : (answerVal == true || answerVal == 'true');

      // Restore persisted AI explanation.
      _savedAiExplanation = _content['_aiExplanation'] as String?;

      if (savedAnswer != null) _selectedAnswer = savedAnswer;
      if (submitted && savedAnswer != null) {
        _isSubmitted = true;
        final validator = AnswerValidationService();
        _result = validator.validateTrueFalse(
          userAnswer: savedAnswer,
          correctAnswer: _content['correctAnswer'] ?? true,
        );
      }
    } catch (e) {
      _content = {'statement': 'Error loading question', 'correctAnswer': true};
    }
  }

  void _persistState() {
    try {
      final updatedContent = Map<String, dynamic>.from(_content);
      updatedContent['_selectedAnswer'] = _selectedAnswer;
      updatedContent['_isSubmitted'] = _isSubmitted;
      if (_savedAiExplanation != null) {
        updatedContent['_aiExplanation'] = _savedAiExplanation;
      }
      if (_isSubmitted && _result != null) {
        final points = (updatedContent['points'] as num?)?.toDouble() ?? 1.0;
        updatedContent['_earnedMarks'] = _result!.score * points;
        updatedContent['_totalMarks'] = points;
      } else {
        updatedContent.remove('_earnedMarks');
        updatedContent.remove('_totalMarks');
      }
      final jsonString = JsonStringConverter().convertToJsonString(
        updatedContent,
      );
      final updatedBlock = widget.block.copyWith(content: jsonString);
      ref
          .read(editDocumentControllerProvider(widget.docDir).notifier)
          .saveBlock(updatedBlock);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to persist true/false state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _selectAnswer(bool answer) {
    if (_isSubmitted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAnswer = answer;
    });
    _persistState();
  }

  Future<void> _submit() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select True or False'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final validator = AnswerValidationService();
    final result = validator.validateTrueFalse(
      userAnswer: _selectedAnswer!,
      correctAnswer: _content['correctAnswer'] ?? true,
    );

    setState(() {
      _isSubmitted = true;
      _result = result;
    });
    _persistState();
    // Record attempt for learning progress tracking.
    ref
        .read(learningProgressProvider(widget.docDir.path).notifier)
        .recordAttempt(
          blockId: widget.block.id ?? widget.block.position.toString(),
          blockType: 'trueFalse',
          isCorrect: result.isCorrect,
        );
    if (mounted) {
      final shouldRetry = await showDuolingoFeedbackSheet(
        context: context,
        isCorrect: result.isCorrect,
        correctAnswer: (_content['correctAnswer'] as bool? ?? true)
            ? 'True'
            : 'False',
        explanation: (_content['showExplanation'] as bool? ?? true)
            ? (_content['explanation']?.toString() ?? '')
            : '',
        showExplanation: _content['showExplanation'] as bool? ?? true,
        question: _content['statement']?.toString() ?? '',
        studentAnswer: _selectedAnswer != null
            ? (_selectedAnswer! ? 'True' : 'False')
            : '',
        questionType: 'true/false',
        savedAiExplanation: _savedAiExplanation,
        onAiExplanationGenerated: (ai) {
          setState(() => _savedAiExplanation = ai);
          _persistState();
        },
      );
      if (shouldRetry && mounted) _retry();
    }
  }

  void _retry() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = null;
      _isSubmitted = false;
      _result = null;
    });
    _persistState();
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final statement =
        _content['statement']?.toString() ?? 'No statement provided';
    final explanation = _content['explanation']?.toString() ?? '';
    final showExplanation = _content['showExplanation'] as bool? ?? true;
    final correctAnswer = _content['correctAnswer'] as bool? ?? true;

    // Apply block styles
    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isWide = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isDesktop ? 24.0 : (isWide ? 16.0 : 0.0);
    final verticalPadding = isDesktop ? 14.0 : (isWide ? 10.0 : 2.0);
    final padding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);

    final baseStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(
          fontSize: fontSize * ResponsiveUtils.getTextSizeMultiplier(context),
          color: color,
        );

    return Padding(
      padding: padding.copyWith(
        top: padding.vertical / 2 + verticalMargin,
        bottom: padding.vertical / 2 + verticalMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'True / False',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Statement
          Text(
            statement,
            style: baseStyle.copyWith(fontWeight: FontWeight.w600),
          ),

          // Hint before submission
          if (!_isSubmitted) ...[
            const SizedBox(height: 6),
            Text(
              _selectedAnswer == null
                  ? 'Is this statement true or false?'
                  : 'Ready to check!',
              style: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 14) * 0.82,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // True/False buttons (template-driven)
          _buildAnswerButtons(
            template: widget.block.style.questionTemplate ?? 'default',
            baseStyle: baseStyle,
            theme: theme,
            correctAnswer: correctAnswer,
          ),

          // Post-submit actions: [↩ Try Again]  [✨ Explain ▾]  on one row
          if (_isSubmitted && _result != null) ...[
            const SizedBox(height: 10),
            PostSubmitActions(
              isCorrect: _result!.isCorrect,
              onRetry: _retry,
              explanation: showExplanation ? explanation : '',
              showExplanation: showExplanation,
              question: statement,
              correctAnswer: correctAnswer ? 'True' : 'False',
              studentAnswer: _selectedAnswer != null
                  ? (_selectedAnswer! ? 'True' : 'False')
                  : '',
              questionType: 'true/false',
              baseStyle: baseStyle,
              savedAiExplanation: _savedAiExplanation,
              onAiExplanationGenerated: (ai) {
                setState(() => _savedAiExplanation = ai);
                _persistState();
              },
            ),
          ],

          // Submit button (before submission)
          if (!_isSubmitted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedAnswer != null ? _submit : null,
                child: const Text('Check Answer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerButtons({
    required String template,
    required TextStyle baseStyle,
    required ThemeData theme,
    required bool correctAnswer,
  }) {
    switch (template) {
      case 'card':
        return _buildCardButtons(baseStyle, theme, correctAnswer);
      case 'banner':
        return _buildBannerButtons(baseStyle, theme, correctAnswer);
      case 'minimal':
        return _buildMinimalButtons(baseStyle, theme, correctAnswer);
      case 'toggle':
        return _buildToggleButtons(baseStyle, theme, correctAnswer);
      case 'spotlight':
        return _buildSpotlightButtons(baseStyle, theme, correctAnswer);
      default:
        return Row(
          children: [
            Expanded(
              child: _buildChoiceButton(
                theme: theme,
                baseStyle: baseStyle,
                value: true,
                label: 'TRUE',
                icon: Icons.check_circle_rounded,
                correctAnswer: correctAnswer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceButton(
                theme: theme,
                baseStyle: baseStyle,
                value: false,
                label: 'FALSE',
                icon: Icons.cancel_rounded,
                correctAnswer: correctAnswer,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCardButtons(
    TextStyle baseStyle,
    ThemeData theme,
    bool correctAnswer,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildCardButton(
            theme: theme,
            baseStyle: baseStyle,
            value: true,
            label: 'TRUE',
            icon: Icons.check_circle_outline_rounded,
            correctAnswer: correctAnswer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardButton(
            theme: theme,
            baseStyle: baseStyle,
            value: false,
            label: 'FALSE',
            icon: Icons.cancel_outlined,
            correctAnswer: correctAnswer,
          ),
        ),
      ],
    );
  }

  Widget _buildCardButton({
    required ThemeData theme,
    required TextStyle baseStyle,
    required bool value,
    required String label,
    required IconData icon,
    required bool correctAnswer,
  }) {
    final bool isSelected = _selectedAnswer == value;
    final bool isCorrectChoice = correctAnswer == value;
    final bool isWrongSelection =
        _isSubmitted && isSelected && !isCorrectChoice;

    final Color borderColor;
    final Color bgColor;
    final Color contentColor;

    if (_isSubmitted) {
      if (isCorrectChoice) {
        borderColor = _kCorrectColor;
        bgColor = _kCorrectColor.withValues(alpha: 0.08);
        contentColor = _kCorrectColor;
      } else if (isWrongSelection) {
        borderColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withValues(alpha: 0.06);
        contentColor = theme.colorScheme.error;
      } else {
        borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
        bgColor = Colors.transparent;
        contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.09);
      contentColor = theme.colorScheme.primary;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.4);
      bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: bgColor,
      child: InkWell(
        onTap: _isSubmitted ? null : () => _selectAnswer(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected || (_isSubmitted && isCorrectChoice) ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: contentColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: baseStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerButtons(
    TextStyle baseStyle,
    ThemeData theme,
    bool correctAnswer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBannerButton(
          theme: theme,
          baseStyle: baseStyle,
          value: true,
          label: 'TRUE',
          icon: Icons.check_circle_rounded,
          correctAnswer: correctAnswer,
        ),
        const SizedBox(height: 8),
        _buildBannerButton(
          theme: theme,
          baseStyle: baseStyle,
          value: false,
          label: 'FALSE',
          icon: Icons.cancel_rounded,
          correctAnswer: correctAnswer,
        ),
      ],
    );
  }

  Widget _buildBannerButton({
    required ThemeData theme,
    required TextStyle baseStyle,
    required bool value,
    required String label,
    required IconData icon,
    required bool correctAnswer,
  }) {
    final bool isSelected = _selectedAnswer == value;
    final bool isCorrectChoice = correctAnswer == value;
    final bool isWrongSelection =
        _isSubmitted && isSelected && !isCorrectChoice;

    final Color borderColor;
    final Color bgColor;
    final Color contentColor;

    if (_isSubmitted) {
      if (isCorrectChoice) {
        borderColor = _kCorrectColor;
        bgColor = _kCorrectColor.withValues(alpha: 0.1);
        contentColor = _kCorrectColor;
      } else if (isWrongSelection) {
        borderColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withValues(alpha: 0.08);
        contentColor = theme.colorScheme.error;
      } else {
        borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
        bgColor = Colors.transparent;
        contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.09);
      contentColor = theme.colorScheme.primary;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.4);
      bgColor = Colors.transparent;
      contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    }

    return InkWell(
      onTap: _isSubmitted ? null : () => _selectAnswer(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected || (_isSubmitted && isCorrectChoice) ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: contentColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: contentColor,
                fontSize: (baseStyle.fontSize ?? 14) * 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalButtons(
    TextStyle baseStyle,
    ThemeData theme,
    bool correctAnswer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [true, false].asMap().entries.map((entry) {
        final value = entry.value;
        final label = value ? 'True' : 'False';
        final bool isSelected = _selectedAnswer == value;
        final bool isCorrectChoice = correctAnswer == value;
        final bool isWrongSelection =
            _isSubmitted && isSelected && !isCorrectChoice;

        final Color dotColor;
        final Color textColor;

        if (_isSubmitted) {
          if (isCorrectChoice) {
            dotColor = _kCorrectColor;
            textColor = _kCorrectColor;
          } else if (isWrongSelection) {
            dotColor = theme.colorScheme.error;
            textColor = theme.colorScheme.error;
          } else {
            dotColor = theme.colorScheme.outline.withValues(alpha: 0.3);
            textColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);
          }
        } else if (isSelected) {
          dotColor = theme.colorScheme.primary;
          textColor = theme.colorScheme.primary;
        } else {
          dotColor = theme.colorScheme.outline.withValues(alpha: 0.5);
          textColor = baseStyle.color ?? theme.colorScheme.onSurface;
        }

        return InkWell(
          onTap: _isSubmitted ? null : () => _selectAnswer(value),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected && !_isSubmitted ? dotColor : null,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: baseStyle.copyWith(
                    color: textColor,
                    fontWeight: isSelected || (_isSubmitted && isCorrectChoice)
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleButtons(
    TextStyle baseStyle,
    ThemeData theme,
    bool correctAnswer,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleSegment(
              theme: theme,
              baseStyle: baseStyle,
              value: true,
              label: 'TRUE',
              icon: Icons.check_circle_rounded,
              correctAnswer: correctAnswer,
            ),
          ),
          Expanded(
            child: _buildToggleSegment(
              theme: theme,
              baseStyle: baseStyle,
              value: false,
              label: 'FALSE',
              icon: Icons.cancel_rounded,
              correctAnswer: correctAnswer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSegment({
    required ThemeData theme,
    required TextStyle baseStyle,
    required bool value,
    required String label,
    required IconData icon,
    required bool correctAnswer,
  }) {
    final bool isSelected = _selectedAnswer == value;
    final bool isCorrectChoice = correctAnswer == value;
    final bool isWrongSelection =
        _isSubmitted && isSelected && !isCorrectChoice;

    Color bgColor;
    Color contentColor;

    if (_isSubmitted) {
      if (isCorrectChoice) {
        bgColor = _kCorrectColor;
        contentColor = Colors.white;
      } else if (isWrongSelection) {
        bgColor = theme.colorScheme.error;
        contentColor = theme.colorScheme.onError;
      } else {
        bgColor = Colors.transparent;
        contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      }
    } else if (isSelected) {
      bgColor = theme.colorScheme.primary;
      contentColor = theme.colorScheme.onPrimary;
    } else {
      bgColor = Colors.transparent;
      contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    }

    return GestureDetector(
      onTap: _isSubmitted ? null : () => _selectAnswer(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: contentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightButtons(
    TextStyle baseStyle,
    ThemeData theme,
    bool correctAnswer,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSpotlightButton(
            theme: theme,
            baseStyle: baseStyle,
            value: true,
            label: 'TRUE',
            icon: Icons.check_circle_rounded,
            correctAnswer: correctAnswer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSpotlightButton(
            theme: theme,
            baseStyle: baseStyle,
            value: false,
            label: 'FALSE',
            icon: Icons.cancel_rounded,
            correctAnswer: correctAnswer,
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlightButton({
    required ThemeData theme,
    required TextStyle baseStyle,
    required bool value,
    required String label,
    required IconData icon,
    required bool correctAnswer,
  }) {
    final bool isSelected = _selectedAnswer == value;
    final bool isCorrectChoice = correctAnswer == value;
    final bool isWrongSelection =
        _isSubmitted && isSelected && !isCorrectChoice;
    final bool isDimmed =
        (_selectedAnswer != null || _isSubmitted) &&
        !isSelected &&
        !(_isSubmitted && isCorrectChoice);

    Color borderColor;
    Color bgColor;
    Color contentColor;
    List<BoxShadow>? shadows;

    if (_isSubmitted) {
      if (isCorrectChoice) {
        borderColor = _kCorrectColor;
        bgColor = _kCorrectColor.withValues(alpha: 0.1);
        contentColor = _kCorrectColor;
        shadows = [
          BoxShadow(
            color: _kCorrectColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ];
      } else if (isWrongSelection) {
        borderColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withValues(alpha: 0.07);
        contentColor = theme.colorScheme.error;
        shadows = null;
      } else {
        borderColor = theme.colorScheme.outline.withValues(alpha: 0.15);
        bgColor = Colors.transparent;
        contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.2);
        shadows = null;
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      contentColor = theme.colorScheme.primary;
      shadows = [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (isDimmed) {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
      bgColor = Colors.transparent;
      contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);
      shadows = null;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.45);
      bgColor = Colors.transparent;
      contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
      shadows = null;
    }

    return InkWell(
      onTap: _isSubmitted ? null : () => _selectAnswer(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected || (_isSubmitted && isCorrectChoice) ? 2 : 1,
          ),
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: contentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationDropdown(
    String explanation,
    TextStyle baseStyle,
    ThemeData theme,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(
          Icons.lightbulb_outline_rounded,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        title: Text(
          'See Explanation',
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 14) * 0.9,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        collapsedBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.18,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        children: [
          Text(
            explanation,
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14) * 0.9,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single True or False choice button, with state-driven color logic.
  ///
  /// Pre-submission: selected button gets a tinted border; unselected is outlined.
  /// Post-submission: the correct choice is always highlighted with primary color;
  /// the wrong selection (if any) is highlighted with error color; the other
  /// button is dimmed.
  Widget _buildChoiceButton({
    required ThemeData theme,
    required TextStyle baseStyle,
    required bool value, // true = TRUE button, false = FALSE button
    required String label,
    required IconData icon,
    required bool correctAnswer,
  }) {
    final bool isSelected = _selectedAnswer == value;
    final bool isCorrectChoice = correctAnswer == value;
    final bool isWrongSelection =
        _isSubmitted && isSelected && !isCorrectChoice;

    final Color borderColor;
    final Color bgColor;
    final Color contentColor;
    final double borderWidth;

    if (_isSubmitted) {
      if (isCorrectChoice) {
        borderColor = _kCorrectColor;
        bgColor = _kCorrectColor.withValues(alpha: 0.1);
        contentColor = _kCorrectColor;
        borderWidth = 2;
      } else if (isWrongSelection) {
        borderColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withValues(alpha: 0.08);
        contentColor = theme.colorScheme.error;
        borderWidth = 2;
      } else {
        borderColor = theme.colorScheme.outline.withValues(alpha: 0.25);
        bgColor = Colors.transparent;
        contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);
        borderWidth = 1;
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      contentColor = theme.colorScheme.primary;
      borderWidth = 2;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.45);
      bgColor = Colors.transparent;
      contentColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      borderWidth = 1;
    }

    // Pick the trailing icon after submission
    IconData? trailingIcon;
    if (_isSubmitted) {
      if (isCorrectChoice) {
        trailingIcon = Icons.check_circle_rounded;
      } else if (isWrongSelection) {
        trailingIcon = Icons.cancel_rounded;
      }
    }

    return InkWell(
      onTap: _isSubmitted ? null : () => _selectAnswer(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: contentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: contentColor,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 16, color: contentColor),
            ],
          ],
        ),
      ),
    );
  }
}
