import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/learning/presentation/providers/learning_progress_provider.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/data/services/answer_validation_service.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'question_feedback_widgets.dart';

/// Read-only display of multiple choice question block with answer submission.
class MultipleChoiceReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const MultipleChoiceReaderBlock({
    required this.block,
    required this.docDir,
    super.key,
  });

  @override
  ConsumerState<MultipleChoiceReaderBlock> createState() =>
      _MultipleChoiceReaderBlockState();
}

class _MultipleChoiceReaderBlockState
    extends ConsumerState<MultipleChoiceReaderBlock> {
  // Green used for correct-answer highlighting across all templates.
  static const Color _kCorrectColor = Color(0xFF2E7D32);

  // Total horizontal space consumed by padding and gap between grid columns.
  // Accounts for: left/right content padding (2×20=40) + gap between columns (8)
  // and the parent container margins, summing to approximately 80 logical pixels.
  static const double _gridHorizontalOffset = 80.0;

  late Map<String, dynamic> _content;
  final Set<String> _selectedOptions = {};
  bool _isSubmitted = false;
  ValidationResult? _result;
  List<Map<String, dynamic>> _displayedOptions = [];
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

      // Restore persisted interactive state from the block's own JSON content.
      final submitted = _content['_isSubmitted'] as bool? ?? false;
      final savedSelected =
          (_content['_selectedOptions'] as List?)
              ?.map((e) => e.toString())
              .toSet() ??
          {};

      // Restore persisted AI explanation.
      _savedAiExplanation = _content['_aiExplanation'] as String?;

      // Get options
      final options = List<Map<String, dynamic>>.from(
        _content['options'] ?? [],
      );

      // Shuffle only when the question has NOT been started yet (no selection, not submitted).
      if (_content['shuffleOptions'] == true &&
          !submitted &&
          savedSelected.isEmpty) {
        _displayedOptions = List.from(options)..shuffle();
      } else {
        _displayedOptions = options;
      }

      // Restore state after display order is set.
      if (submitted || savedSelected.isNotEmpty) {
        _selectedOptions.addAll(savedSelected);
        if (submitted) {
          _isSubmitted = true;
          final validator = AnswerValidationService();
          _result = validator.validateMultipleChoice(
            userAnswers: savedSelected.toList(),
            options: _displayedOptions,
            allowMultiple: _content['allowMultiple'] ?? false,
          );
        }
      }
    } catch (e) {
      _content = {'question': 'Error loading question', 'options': []};
      _displayedOptions = [];
    }
  }

  void _persistState() {
    try {
      final updatedContent = Map<String, dynamic>.from(_content);
      updatedContent['_selectedOptions'] = _selectedOptions.toList();
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
        'Failed to persist multiple choice state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _toggleOption(String optionId) {
    if (_isSubmitted) return;
    HapticFeedback.selectionClick();

    setState(() {
      final allowMultiple = _content['allowMultiple'] ?? false;

      if (allowMultiple) {
        if (_selectedOptions.contains(optionId)) {
          _selectedOptions.remove(optionId);
        } else {
          _selectedOptions.add(optionId);
        }
      } else {
        _selectedOptions.clear();
        _selectedOptions.add(optionId);
      }
    });
    _persistState();
  }

  Future<void> _submit() async {
    if (_selectedOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one option'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final validator = AnswerValidationService();
    final result = validator.validateMultipleChoice(
      userAnswers: _selectedOptions.toList(),
      options: _displayedOptions,
      allowMultiple: _content['allowMultiple'] ?? false,
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
          blockType: 'multipleChoice',
          isCorrect: result.isCorrect,
        );
    if (mounted) {
      final shouldRetry = await showDuolingoFeedbackSheet(
        context: context,
        isCorrect: result.isCorrect,
        correctAnswer: _displayedOptions
            .where((o) => o['isCorrect'] == true)
            .map((o) => o['text'] as String? ?? '')
            .join(', '),
        explanation: (_content['showExplanation'] as bool? ?? true)
            ? (_content['explanation']?.toString() ?? '')
            : '',
        showExplanation: _content['showExplanation'] as bool? ?? true,
        question: _content['question']?.toString() ?? '',
        studentAnswer: _displayedOptions
            .where((o) => _selectedOptions.contains(o['id']))
            .map((o) => o['text'] as String? ?? '')
            .join(', '),
        questionType: 'multiple choice',
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
      _selectedOptions.clear();
      _isSubmitted = false;
      _result = null;
    });
    _persistState();
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final question = _content['question']?.toString() ?? 'No question provided';
    final explanation = _content['explanation']?.toString() ?? '';
    final showExplanation = _content['showExplanation'] as bool? ?? true;
    final allowMultiple = _content['allowMultiple'] ?? false;

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
                Icons.quiz_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Multiple Choice',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Question
          Text(
            question,
            style: baseStyle.copyWith(fontWeight: FontWeight.w600),
          ),

          // Hint / selection status
          if (!_isSubmitted) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    allowMultiple
                        ? 'Select all that apply'
                        : _selectedOptions.isEmpty
                        ? 'Select one option below'
                        : 'Ready to check!',
                    style: baseStyle.copyWith(
                      fontSize: (baseStyle.fontSize ?? 14) * 0.82,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (allowMultiple) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedOptions.isNotEmpty
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedOptions.length} selected',
                      style: baseStyle.copyWith(
                        fontSize: (baseStyle.fontSize ?? 14) * 0.8,
                        fontWeight: FontWeight.w700,
                        color: _selectedOptions.isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Options
          _buildOptions(
            template: widget.block.style.questionTemplate ?? 'default',
            baseStyle: baseStyle,
            theme: theme,
            allowMultiple: allowMultiple,
          ),

          // Post-submit actions: [↩ Try Again]  [✨ Explain ▾]  on one row
          if (_isSubmitted && _result != null) ...[
            const SizedBox(height: 10),
            PostSubmitActions(
              isCorrect: _result!.isCorrect,
              onRetry: _retry,
              explanation: showExplanation ? explanation : '',
              showExplanation: showExplanation,
              question: question,
              correctAnswer: _displayedOptions
                  .where((o) => o['isCorrect'] == true)
                  .map((o) => o['text'] as String? ?? '')
                  .join(', '),
              studentAnswer: _displayedOptions
                  .where((o) => _selectedOptions.contains(o['id']))
                  .map((o) => o['text'] as String? ?? '')
                  .join(', '),
              questionType: 'multiple choice',
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
                onPressed: _selectedOptions.isNotEmpty ? _submit : null,
                child: const Text('Check Answer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions({
    required String template,
    required TextStyle baseStyle,
    required ThemeData theme,
    required bool allowMultiple,
  }) {
    switch (template) {
      case 'card':
        return _buildCardOptions(baseStyle, theme, allowMultiple);
      case 'grid':
        return _buildGridOptions(baseStyle, theme, allowMultiple);
      case 'minimal':
        return _buildMinimalOptions(baseStyle, theme, allowMultiple);
      case 'pill':
        return _buildPillOptions(baseStyle, theme, allowMultiple);
      case 'numbered':
        return _buildNumberedOptions(baseStyle, theme, allowMultiple);
      case 'highlight':
        return _buildHighlightOptions(baseStyle, theme, allowMultiple);
      default:
        return _buildDefaultOptions(baseStyle, theme, allowMultiple);
    }
  }

  Widget _buildDefaultOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    return Column(
      children: _displayedOptions.map((option) {
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);
        return _buildOptionChip(
          baseStyle: baseStyle,
          theme: theme,
          optionId: optionId,
          optionText: optionText,
          isCorrect: isCorrect,
          isSelected: isSelected,
          allowMultiple: allowMultiple,
        );
      }).toList(),
    );
  }

  Widget _buildCardOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    return Column(
      children: _displayedOptions.asMap().entries.map((entry) {
        final i = entry.key;
        final option = entry.value;
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);
        final letter = i < letters.length ? letters[i] : '${i + 1}';

        final Color borderColor;
        final Color bgColor;
        final Color badgeColor;
        IconData? trailingIcon;
        Color? trailingColor;

        if (_isSubmitted) {
          if (isCorrect) {
            borderColor = _kCorrectColor;
            bgColor = _kCorrectColor.withOpacity(0.06);
            badgeColor = _kCorrectColor;
            trailingIcon = Icons.check_circle_rounded;
            trailingColor = _kCorrectColor;
          } else if (isSelected) {
            borderColor = theme.colorScheme.error;
            bgColor = theme.colorScheme.error.withOpacity(0.06);
            badgeColor = theme.colorScheme.error;
            trailingIcon = Icons.cancel_rounded;
            trailingColor = theme.colorScheme.error;
          } else {
            borderColor = theme.colorScheme.outline.withOpacity(0.2);
            bgColor = Colors.transparent;
            badgeColor = theme.colorScheme.outline.withOpacity(0.4);
          }
        } else if (isSelected) {
          borderColor = theme.colorScheme.primary;
          bgColor = theme.colorScheme.primary.withOpacity(0.07);
          badgeColor = theme.colorScheme.primary;
        } else {
          borderColor = theme.colorScheme.outline.withOpacity(0.3);
          bgColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
          badgeColor = theme.colorScheme.onSurface.withOpacity(0.45);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(10),
            color: bgColor,
            child: InkWell(
              onTap: _isSubmitted ? null : () => _toggleOption(optionId),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (_isSubmitted && isCorrect) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: baseStyle.copyWith(
                          color: _isSubmitted
                              ? (isCorrect
                                    ? _kCorrectColor
                                    : (isSelected
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurface
                                                .withOpacity(0.5)))
                              : null,
                          fontWeight: (_isSubmitted && isCorrect)
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, color: trailingColor, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _displayedOptions.map((option) {
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);

        final Color borderColor;
        final Color bgColor;

        if (_isSubmitted) {
          if (isCorrect) {
            borderColor = _kCorrectColor;
            bgColor = _kCorrectColor.withOpacity(0.09);
          } else if (isSelected) {
            borderColor = theme.colorScheme.error;
            bgColor = theme.colorScheme.error.withOpacity(0.07);
          } else {
            borderColor = theme.colorScheme.outline.withOpacity(0.2);
            bgColor = Colors.transparent;
          }
        } else if (isSelected) {
          borderColor = theme.colorScheme.primary;
          bgColor = theme.colorScheme.primary.withOpacity(0.09);
        } else {
          borderColor = theme.colorScheme.outline.withOpacity(0.35);
          bgColor = Colors.transparent;
        }

        return InkWell(
          onTap: _isSubmitted ? null : () => _toggleOption(optionId),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            width:
                (MediaQuery.of(context).size.width - _gridHorizontalOffset) / 2,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isSelected || (_isSubmitted && isCorrect) ? 2 : 1,
              ),
            ),
            child: Text(
              optionText,
              style: baseStyle.copyWith(
                color: _isSubmitted
                    ? (isCorrect
                          ? _kCorrectColor
                          : (isSelected
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withOpacity(0.5)))
                    : null,
                fontWeight: (_isSubmitted && isCorrect)
                    ? FontWeight.w600
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMinimalOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    return Column(
      children: _displayedOptions.asMap().entries.map((entry) {
        final i = entry.key;
        final option = entry.value;
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);

        final Color dotColor;
        final Color textColor;

        if (_isSubmitted) {
          if (isCorrect) {
            dotColor = _kCorrectColor;
            textColor = _kCorrectColor;
          } else if (isSelected) {
            dotColor = theme.colorScheme.error;
            textColor = theme.colorScheme.error;
          } else {
            dotColor = theme.colorScheme.outline.withOpacity(0.3);
            textColor = theme.colorScheme.onSurface.withOpacity(0.45);
          }
        } else if (isSelected) {
          dotColor = theme.colorScheme.primary;
          textColor = theme.colorScheme.primary;
        } else {
          dotColor = theme.colorScheme.outline.withOpacity(0.45);
          textColor = baseStyle.color ?? theme.colorScheme.onSurface;
        }

        return Column(
          children: [
            InkWell(
              onTap: _isSubmitted ? null : () => _toggleOption(optionId),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected && !_isSubmitted ? dotColor : null,
                        border: Border.all(color: dotColor, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: baseStyle.copyWith(
                          color: textColor,
                          fontWeight: (_isSubmitted && isCorrect)
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _displayedOptions.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPillOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _displayedOptions.map((option) {
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);

        final Color borderColor;
        final Color bgColor;
        final Color textColor;
        IconData? trailingIcon;

        if (_isSubmitted) {
          if (isCorrect) {
            borderColor = _kCorrectColor;
            bgColor = _kCorrectColor.withOpacity(0.1);
            textColor = _kCorrectColor;
            trailingIcon = Icons.check_circle_rounded;
          } else if (isSelected) {
            borderColor = theme.colorScheme.error;
            bgColor = theme.colorScheme.error.withOpacity(0.08);
            textColor = theme.colorScheme.error;
            trailingIcon = Icons.cancel_rounded;
          } else {
            borderColor = theme.colorScheme.outline.withOpacity(0.25);
            bgColor = Colors.transparent;
            textColor = theme.colorScheme.onSurface.withOpacity(0.45);
          }
        } else if (isSelected) {
          borderColor = theme.colorScheme.primary;
          bgColor = theme.colorScheme.primary.withOpacity(0.1);
          textColor = theme.colorScheme.primary;
        } else {
          borderColor = theme.colorScheme.outline.withOpacity(0.4);
          bgColor = Colors.transparent;
          textColor = baseStyle.color ?? theme.colorScheme.onSurface;
        }

        return InkWell(
          onTap: _isSubmitted ? null : () => _toggleOption(optionId),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: isSelected || (_isSubmitted && isCorrect) ? 2 : 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    optionText,
                    style: baseStyle.copyWith(
                      color: textColor,
                      fontWeight: (_isSubmitted && isCorrect)
                          ? FontWeight.w600
                          : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: textColor, size: 16),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberedOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    return Column(
      children: _displayedOptions.asMap().entries.map((entry) {
        final i = entry.key;
        final option = entry.value;
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);

        final Color borderColor;
        final Color bgColor;
        final Color badgeColor;
        IconData? trailingIcon;
        Color? trailingColor;

        if (_isSubmitted) {
          if (isCorrect) {
            borderColor = _kCorrectColor;
            bgColor = _kCorrectColor.withOpacity(0.07);
            badgeColor = _kCorrectColor;
            trailingIcon = Icons.check_circle_rounded;
            trailingColor = _kCorrectColor;
          } else if (isSelected) {
            borderColor = theme.colorScheme.error;
            bgColor = theme.colorScheme.error.withOpacity(0.06);
            badgeColor = theme.colorScheme.error;
            trailingIcon = Icons.cancel_rounded;
            trailingColor = theme.colorScheme.error;
          } else {
            borderColor = theme.colorScheme.outline.withOpacity(0.2);
            bgColor = Colors.transparent;
            badgeColor = theme.colorScheme.outline.withOpacity(0.35);
          }
        } else if (isSelected) {
          borderColor = theme.colorScheme.primary;
          bgColor = theme.colorScheme.primary.withOpacity(0.08);
          badgeColor = theme.colorScheme.primary;
        } else {
          borderColor = theme.colorScheme.outline.withOpacity(0.35);
          bgColor = Colors.transparent;
          badgeColor = theme.colorScheme.outline.withOpacity(0.5);
        }

        return InkWell(
          onTap: _isSubmitted ? null : () => _toggleOption(optionId),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isSelected || (_isSubmitted && isCorrect) ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    optionText,
                    style: baseStyle.copyWith(
                      color: _isSubmitted
                          ? (isCorrect
                                ? _kCorrectColor
                                : (isSelected
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.5,
                                        )))
                          : null,
                      fontWeight: (_isSubmitted && isCorrect)
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: trailingColor, size: 18),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlightOptions(
    TextStyle baseStyle,
    ThemeData theme,
    bool allowMultiple,
  ) {
    final accentColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _displayedOptions.asMap().entries.map((entry) {
        final i = entry.key;
        final option = entry.value;
        final optionId = option['id'] as String;
        final optionText = option['text'] as String? ?? '';
        final isCorrect = option['isCorrect'] as bool? ?? false;
        final isSelected = _selectedOptions.contains(optionId);
        final accentColor = accentColors[i % accentColors.length];

        final Color bgColor;
        final Color textColor;
        final double bgOpacity;

        if (_isSubmitted) {
          if (isCorrect) {
            bgColor = _kCorrectColor;
            textColor = Colors.white;
            bgOpacity = 1.0;
          } else if (isSelected) {
            bgColor = theme.colorScheme.error;
            textColor = theme.colorScheme.onError;
            bgOpacity = 1.0;
          } else {
            bgColor = theme.colorScheme.surfaceContainerHighest;
            textColor = theme.colorScheme.onSurface.withOpacity(0.4);
            bgOpacity = 1.0;
          }
        } else if (isSelected) {
          bgColor = accentColor;
          textColor = Colors.white;
          bgOpacity = 1.0;
        } else {
          bgColor = accentColor;
          textColor = Colors.white;
          bgOpacity = 0.18;
        }

        return InkWell(
          onTap: _isSubmitted ? null : () => _toggleOption(optionId),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              color: _isSubmitted
                  ? bgColor.withOpacity(1.0)
                  : bgColor.withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    optionText,
                    style: baseStyle.copyWith(
                      color: _isSubmitted
                          ? textColor
                          : (isSelected
                                ? textColor
                                : accentColor.withOpacity(0.85)),
                      fontWeight: (isSelected || (_isSubmitted && isCorrect))
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ),
                if (_isSubmitted) ...[
                  if (isCorrect)
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 18,
                    )
                  else if (isSelected)
                    Icon(
                      Icons.cancel_rounded,
                      color: theme.colorScheme.onError,
                      size: 18,
                    ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
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
          color: theme.colorScheme.onSurface.withOpacity(0.55),
        ),
        title: Text(
          'See Explanation',
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 14) * 0.9,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        collapsedBackgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
          0.18,
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String optionId,
    required String optionText,
    required bool isCorrect,
    required bool isSelected,
    required bool allowMultiple,
  }) {
    final Color borderColor;
    final Color bgColor;
    final double borderWidth;
    IconData? trailingIcon;
    Color? trailingColor;

    if (_isSubmitted) {
      if (isCorrect) {
        borderColor = _kCorrectColor;
        bgColor = _kCorrectColor.withOpacity(0.08);
        borderWidth = 2;
        trailingIcon = Icons.check_circle_rounded;
        trailingColor = _kCorrectColor;
      } else if (isSelected) {
        // Wrong selection
        borderColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withOpacity(0.08);
        borderWidth = 2;
        trailingIcon = Icons.cancel_rounded;
        trailingColor = theme.colorScheme.error;
      } else {
        borderColor = theme.colorScheme.outline.withOpacity(0.3);
        bgColor = Colors.transparent;
        borderWidth = 1;
      }
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withOpacity(0.1);
      borderWidth = 2;
    } else {
      borderColor = theme.colorScheme.outline.withOpacity(0.35);
      bgColor = Colors.transparent;
      borderWidth = 1;
    }

    return InkWell(
      onTap: _isSubmitted ? null : () => _toggleOption(optionId),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: (!_isSubmitted && isSelected)
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: (!_isSubmitted && isSelected)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.5),
                  width: 1.5,
                ),
                shape: allowMultiple ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: allowMultiple ? BorderRadius.circular(4) : null,
              ),
              child: (!_isSubmitted && isSelected)
                  ? Icon(
                      Icons.check,
                      size: 13,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                optionText,
                style: baseStyle.copyWith(
                  color: _isSubmitted
                      ? (isCorrect
                            ? _kCorrectColor
                            : (isSelected
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.5,
                                    )))
                      : null,
                  fontWeight: (_isSubmitted && isCorrect)
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ),
            // Trailing feedback icon (after submission)
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: trailingColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
