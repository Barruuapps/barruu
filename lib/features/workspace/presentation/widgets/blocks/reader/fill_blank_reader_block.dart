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

/// Read-only display of fill-in-the-blank question block with answer submission.
class FillBlankReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const FillBlankReaderBlock({
    required this.block,
    required this.docDir,
    super.key,
  });

  @override
  ConsumerState<FillBlankReaderBlock> createState() =>
      _FillBlankReaderBlockState();
}

class _FillBlankReaderBlockState extends ConsumerState<FillBlankReaderBlock> {
  // Shared regex for bracket notation used both in the paragraph and exam layouts.
  static final RegExp _bracketRegex = RegExp(r'\[([^\]]+)\]');

  // Green used for correct-answer highlighting.
  static const Color _kCorrectColor = Color(0xFF2E7D32);

  late Map<String, dynamic> _content;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _isSubmitted = false;
  ValidationResult? _result;
  String? _savedAiExplanation;

  // Track filled count for live hint.
  int _filledCount = 0;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _parseContent() {
    final converter = JsonStringConverter();
    try {
      _content = converter.convertFromJsonString(widget.block.content);

      // Restore persisted answers from the block's own JSON content.
      final savedAnswers =
          (_content['_userAnswers'] as Map<String, dynamic>?) ?? {};
      final submitted = _content['_isSubmitted'] as bool? ?? false;

      // Restore persisted AI explanation.
      _savedAiExplanation = _content['_aiExplanation'] as String?;

      // Initialize controllers for each blank
      final blanks = List<Map<String, dynamic>>.from(_content['blanks'] ?? []);
      for (var blank in blanks) {
        final blankId = blank['id'] as String;
        final savedText = savedAnswers[blankId]?.toString() ?? '';
        final controller = TextEditingController(text: savedText);
        _controllers[blankId] = controller;
        _focusNodes[blankId] = FocusNode();
        // Ensure the field is visible above the software keyboard when focused.
        _focusNodes[blankId]!.addListener(() {
          if (_focusNodes[blankId]?.hasFocus == true && mounted) {
            Future.microtask(() {
              if (mounted) {
                Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: 0.5,
                );
              }
            });
          }
        });
        // listen for live fill count
        controller.addListener(_onTextChanged);
      }
      _updateFilledCount();

      if (submitted) {
        _isSubmitted = true;
        final userAnswers = {
          for (var e in savedAnswers.entries) e.key: e.value.toString(),
        };
        final validator = AnswerValidationService();
        _result = validator.validateFillInBlank(
          userAnswers: userAnswers,
          blanks: blanks,
        );
      }
    } catch (e) {
      _content = {'template': 'Error loading question', 'blanks': []};
    }
  }

  void _onTextChanged() {
    if (!_isSubmitted) {
      setState(_updateFilledCount);
    }
  }

  void _updateFilledCount() {
    _filledCount = _controllers.values
        .where((c) => c.text.trim().isNotEmpty)
        .length;
  }

  void _persistState() {
    try {
      final updatedContent = Map<String, dynamic>.from(_content);
      final userAnswers = {
        for (var e in _controllers.entries) e.key: e.value.text,
      };
      updatedContent['_userAnswers'] = userAnswers;
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
        'Failed to persist fill-blank state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _submit() async {
    // Check if all blanks are filled
    final userAnswers = <String, String>{};
    for (var entry in _controllers.entries) {
      final answer = entry.value.text.trim();
      if (answer.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please fill in all blanks'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      userAnswers[entry.key] = answer;
    }

    HapticFeedback.mediumImpact();
    final validator = AnswerValidationService();
    final blanks = List<Map<String, dynamic>>.from(_content['blanks'] ?? []);

    final result = validator.validateFillInBlank(
      userAnswers: userAnswers,
      blanks: blanks,
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
          blockType: 'fillBlank',
          isCorrect: result.isCorrect,
        );
    if (mounted) {
      final shouldRetry = await showDuolingoFeedbackSheet(
        context: context,
        isCorrect: result.isCorrect,
        correctAnswer: _getCorrectAnswersLabel(),
        explanation: (_content['showExplanation'] as bool? ?? true)
            ? (_content['explanation']?.toString() ?? '')
            : '',
        showExplanation: _content['showExplanation'] as bool? ?? true,
        question: (_content['template'] as String? ?? '').isNotEmpty
            ? _content['template'] as String
            : 'Fill in the blank question',
        studentAnswer: _controllers.values
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .join(', '),
        questionType: 'fill in the blank',
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
      for (var controller in _controllers.values) {
        controller.clear();
      }
      _isSubmitted = false;
      _result = null;
      _filledCount = 0;
    });
    _persistState();
  }

  /// Builds the sentence as a single flowing `Text.rich` widget with inline
  /// blank fields rendered via [WidgetSpan] — so it reads like a paragraph.
  Widget _buildParagraph(
    TextStyle baseStyle,
    ThemeData theme, {
    String blankTemplate = 'default',
  }) {
    final template = _content['template']?.toString() ?? '';
    final blanks = List<Map<String, dynamic>>.from(_content['blanks'] ?? []);
    final spans = <InlineSpan>[];

    final bracketRegex = _bracketRegex;
    final hasBrackets = bracketRegex.hasMatch(template);

    void addBlank(int index) {
      if (index < blanks.length) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildBlankField(
              blanks[index],
              baseStyle,
              theme,
              blankTemplate: blankTemplate,
            ),
          ),
        );
      }
    }

    if (hasBrackets) {
      int lastEnd = 0;
      int blankIndex = 0;
      for (final match in bracketRegex.allMatches(template)) {
        if (match.start > lastEnd) {
          spans.add(
            TextSpan(
              text: template.substring(lastEnd, match.start),
              style: baseStyle,
            ),
          );
        }
        addBlank(blankIndex);
        lastEnd = match.end;
        blankIndex++;
      }
      if (lastEnd < template.length) {
        spans.add(
          TextSpan(text: template.substring(lastEnd), style: baseStyle),
        );
      }
    } else {
      // Legacy _____ format.
      final parts = template.split('_____');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(text: parts[i], style: baseStyle));
        }
        if (i < parts.length - 1) {
          addBlank(i);
        }
      }
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildBlankField(
    Map<String, dynamic> blank,
    TextStyle baseStyle,
    ThemeData theme, {
    String blankTemplate = 'default',
  }) {
    final blankId = blank['id'] as String;
    final controller = _controllers[blankId];
    final focusNode = _focusNodes[blankId];

    if (controller == null || focusNode == null) {
      return const SizedBox.shrink();
    }

    bool? isCorrect;
    if (_isSubmitted && _result?.detailedFeedback != null) {
      isCorrect = _result!.detailedFeedback![blankId] as bool?;
    }

    final Color underlineColor;
    final Color textColor;
    if (_isSubmitted && isCorrect != null) {
      underlineColor = isCorrect ? _kCorrectColor : theme.colorScheme.error;
      textColor = isCorrect ? _kCorrectColor : theme.colorScheme.error;
    } else {
      underlineColor = theme.colorScheme.outline;
      textColor = baseStyle.color ?? theme.colorScheme.onSurface;
    }

    // Min width ≈ 4 average characters at the current font size.
    final double minWidth = (baseStyle.fontSize ?? 14) * 4;

    final InputDecoration decoration;
    switch (blankTemplate) {
      case 'boxed_blank':
        decoration = InputDecoration(
          hintText: '···',
          hintStyle: baseStyle.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: underlineColor, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: underlineColor, width: 2.0),
            borderRadius: BorderRadius.circular(4),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          filled: false,
        );
        break;
      case 'highlighted_blank':
        decoration = InputDecoration(
          hintText: '···',
          hintStyle: baseStyle.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          filled: true,
          fillColor: underlineColor.withValues(alpha: 0.12),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: underlineColor, width: 2),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2.5,
            ),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: underlineColor, width: 2),
          ),
          border: const UnderlineInputBorder(),
        );
        break;
      default:
        decoration = InputDecoration(
          hintText: '···',
          hintStyle: baseStyle.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: underlineColor, width: 1.5),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2.0,
            ),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: underlineColor, width: 2.0),
          ),
          border: const UnderlineInputBorder(),
          filled: false,
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: 200),
        child: IntrinsicWidth(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !_isSubmitted,
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(
              color: textColor,
              fontWeight: _isSubmitted ? FontWeight.w600 : FontWeight.normal,
            ),
            decoration: decoration,
          ),
        ),
      ),
    );
  }

  /// Returns a comma-separated string of the first correct answer for each blank,
  /// e.g. "Paris, 1789" — used as AI context.
  String _getCorrectAnswersLabel() {
    return List<Map<String, dynamic>>.from(_content['blanks'] ?? [])
        .map((b) {
          final answers =
              (b['correctAnswers'] as List?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              [];
          return answers.isNotEmpty ? answers.first : '';
        })
        .where((a) => a.isNotEmpty)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final explanation = _content['explanation']?.toString() ?? '';
    final showExplanation = _content['showExplanation'] as bool? ?? true;
    final totalBlanks = (_content['blanks'] as List?)?.length ?? 0;

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

    final allFilled = _filledCount == totalBlanks && totalBlanks > 0;

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
                Icons.edit_note_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Fill in the Blank',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Sentence with inline blank fields (template-driven) ──────
          _buildSentenceSection(
            template: widget.block.style.questionTemplate ?? 'default',
            baseStyle: baseStyle,
            theme: theme,
            totalBlanks: totalBlanks,
          ),

          // ── Live hint ────────────────────────────────────────────────
          if (!_isSubmitted && totalBlanks > 0) ...[
            const SizedBox(height: 6),
            Text(
              allFilled
                  ? 'All blanks filled — ready to check!'
                  : '$_filledCount of $totalBlanks blank${totalBlanks == 1 ? '' : 's'} filled',
              style: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 14) * 0.82,
                color: allFilled
                    ? theme.colorScheme.primary.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // ── Feedback + AI explanation (after submission) ─────────────
          if (_isSubmitted && _result != null) ...[
            const SizedBox(height: 6),

            // Correct answer reveal for wrong blanks
            ..._buildCorrectAnswerCards(baseStyle, theme),

            // Post-submit actions: [↩ Try Again]  [✨ Explain ▾]  on one row
            const SizedBox(height: 10),
            PostSubmitActions(
              isCorrect: _result!.isCorrect,
              onRetry: _retry,
              explanation: showExplanation ? explanation : '',
              showExplanation: showExplanation,
              question: (_content['template'] as String? ?? '').isNotEmpty
                  ? _content['template'] as String
                  : 'Fill in the blank question',
              correctAnswer: _getCorrectAnswersLabel(),
              studentAnswer: _controllers.values
                  .map((c) => c.text.trim())
                  .where((t) => t.isNotEmpty)
                  .join(', '),
              questionType: 'fill in the blank',
              baseStyle: baseStyle,
              savedAiExplanation: _savedAiExplanation,
              onAiExplanationGenerated: (ai) {
                setState(() => _savedAiExplanation = ai);
                _persistState();
              },
            ),
          ],

          // ── Submit button (before submission) ────────────────────────
          if (!_isSubmitted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: allFilled ? _submit : null,
                child: const Text('Check Answer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentenceSection({
    required String template,
    required TextStyle baseStyle,
    required ThemeData theme,
    required int totalBlanks,
  }) {
    switch (template) {
      case 'card':
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildParagraph(baseStyle, theme),
        );
      case 'exam':
        return _buildExamLayout(baseStyle, theme, totalBlanks);
      case 'boxed_blank':
        return _buildParagraph(baseStyle, theme, blankTemplate: 'boxed_blank');
      case 'highlighted_blank':
        return _buildParagraph(
          baseStyle,
          theme,
          blankTemplate: 'highlighted_blank',
        );
      default:
        return _buildParagraph(baseStyle, theme);
    }
  }

  Widget _buildExamLayout(
    TextStyle baseStyle,
    ThemeData theme,
    int totalBlanks,
  ) {
    final blanks = List<Map<String, dynamic>>.from(_content['blanks'] ?? []);
    final templateText = _content['template']?.toString() ?? '';

    // Build sentence with numbered placeholders instead of input fields
    final hasBrackets = _bracketRegex.hasMatch(templateText);

    final spans = <InlineSpan>[];
    if (hasBrackets) {
      int lastEnd = 0;
      int blankIndex = 0;
      for (final match in _bracketRegex.allMatches(templateText)) {
        if (match.start > lastEnd) {
          spans.add(
            TextSpan(
              text: templateText.substring(lastEnd, match.start),
              style: baseStyle,
            ),
          );
        }
        final num = blankIndex + 1;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$num',
                style: baseStyle.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: (baseStyle.fontSize ?? 14) * 0.85,
                ),
              ),
            ),
          ),
        );
        lastEnd = match.end;
        blankIndex++;
      }
      if (lastEnd < templateText.length) {
        spans.add(
          TextSpan(text: templateText.substring(lastEnd), style: baseStyle),
        );
      }
    } else {
      final parts = templateText.split('_____');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(text: parts[i], style: baseStyle));
        }
        if (i < parts.length - 1) {
          final num = i + 1;
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$num',
                  style: baseStyle.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: (baseStyle.fontSize ?? 14) * 0.85,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: spans)),
        if (blanks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(
            thickness: 0.5,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          ...blanks.asMap().entries.map((entry) {
            final i = entry.key;
            final blank = entry.value;
            final blankId = blank['id'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}.',
                      style: baseStyle.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: _buildBlankField(blank, baseStyle, theme)),
                ],
              ),
            );
          }),
        ],
      ],
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


  /// Shows a card for each wrong blank revealing the accepted answer(s).
  List<Widget> _buildCorrectAnswerCards(TextStyle baseStyle, ThemeData theme) {
    final blanks = List<Map<String, dynamic>>.from(_content['blanks'] ?? []);
    final cards = <Widget>[];
    for (int i = 0; i < blanks.length; i++) {
      final blank = blanks[i];
      final blankId = blank['id'] as String;
      final isCorrect = _result?.detailedFeedback?[blankId] as bool? ?? true;
      if (!isCorrect) {
        final correctAnswers =
            (blank['correctAnswers'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        if (correctAnswers.isNotEmpty) {
          cards.add(
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: baseStyle.copyWith(
                            fontSize: (baseStyle.fontSize ?? 14) * 0.9,
                          ),
                          children: [
                            TextSpan(
                              text: 'Blank ${i + 1}: ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: correctAnswers.join(' / '),
                              style: TextStyle(
                                color: _kCorrectColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    return cards;
  }
}
