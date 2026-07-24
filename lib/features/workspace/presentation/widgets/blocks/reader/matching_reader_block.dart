import 'dart:async';
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

/// Read-only display of matching question block with interactive pairing interface.
class MatchingReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const MatchingReaderBlock({
    required this.block,
    required this.docDir,
    super.key,
  });

  @override
  ConsumerState<MatchingReaderBlock> createState() =>
      _MatchingReaderBlockState();
}

class _MatchingReaderBlockState extends ConsumerState<MatchingReaderBlock> {
  late Map<String, dynamic> _content;
  List<Map<String, dynamic>> _leftItems = [];
  List<Map<String, dynamic>> _rightItems = [];
  final Map<String, String> _userPairs = {}; // leftId -> rightId
  String? _selectedLeftId;
  bool _isSubmitted = false;
  ValidationResult? _result;
  String? _savedAiExplanation;
  // leftId that was just matched incorrectly (shows a brief red rejection)
  String? _rejectedLeftId;
  Timer? _rejectionTimer;
  final _validator = AnswerValidationService();

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void dispose() {
    _rejectionTimer?.cancel();
    super.dispose();
  }

  void _parseContent() {
    final converter = JsonStringConverter();
    try {
      _content = converter.convertFromJsonString(widget.block.content);

      _leftItems = List<Map<String, dynamic>>.from(
        _content['leftColumn'] ?? [],
      );
      _rightItems = List<Map<String, dynamic>>.from(
        _content['rightColumn'] ?? [],
      );

      // Restore persisted pairs from the block's own JSON content.
      final savedPairsMap = _content['_userPairs'] as Map<String, dynamic>?;
      if (savedPairsMap != null) {
        _userPairs.addAll(
          savedPairsMap.map((k, v) => MapEntry(k, v.toString())),
        );
      }
      final submitted = _content['_isSubmitted'] as bool? ?? false;

      // Restore persisted AI explanation.
      _savedAiExplanation = _content['_aiExplanation'] as String?;

      // Shuffle only when the question hasn't been answered yet.
      if (_content['shuffleItems'] == true &&
          !submitted &&
          _userPairs.isEmpty) {
        _leftItems.shuffle();
        _rightItems.shuffle();
      }

      if (submitted && _userPairs.length == _leftItems.length) {
        _isSubmitted = true;
        final correctPairs = List<Map<String, dynamic>>.from(
          _content['correctPairs'] ?? [],
        );
        _result = _validator.validateMatching(
          userPairs: _userPairs,
          correctPairs: correctPairs,
          allowPartialCredit: _content['allowPartialCredit'] ?? true,
          rightColumn: _rightItems,
        );
      }
    } catch (e) {
      _content = {
        'instruction': 'Error loading question',
        'leftColumn': [],
        'rightColumn': [],
        'correctPairs': [],
      };
      _leftItems = [];
      _rightItems = [];
    }
  }

  void _persistState() {
    try {
      final updatedContent = Map<String, dynamic>.from(_content);
      updatedContent['_userPairs'] = Map<String, dynamic>.from(_userPairs);
      updatedContent['_isSubmitted'] = _isSubmitted;
      if (_savedAiExplanation != null) {
        updatedContent['_aiExplanation'] = _savedAiExplanation;
      }
      if (_isSubmitted && _result != null) {
        final points = (updatedContent['points'] as num?)?.toDouble() ?? 2.0;
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
        'Failed to persist matching state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _selectLeft(String leftId) {
    if (_isSubmitted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLeftId = _selectedLeftId == leftId ? null : leftId;
    });
  }

  void _selectRight(String rightId) {
    if (_isSubmitted || _selectedLeftId == null) return;
    HapticFeedback.selectionClick();

    final evaluateOnMatch = _content['evaluateOnMatch'] as bool? ?? false;
    final leftId = _selectedLeftId!;

    // If already correctly paired to the selected left, treat as no-op / deselect.
    if (_userPairs[leftId] == rightId) {
      setState(() => _selectedLeftId = null);
      return;
    }

    if (evaluateOnMatch) {
      // -----------------------------------------------------------------------
      // Instant-check mode: accept correct (by text/math equivalence), reject wrong.
      // Duplicate resolution is skipped here — text equivalence in
      // _isSinglePairCorrect handles the "same answer text, different IDs" case.
      // -----------------------------------------------------------------------
      final isCorrect = _isSinglePairCorrect(leftId, rightId);
      if (isCorrect) {
        HapticFeedback.mediumImpact();
        setState(() {
          // Do NOT removeWhere: locked correct pairs must never be displaced.
          _userPairs[leftId] = rightId;
          _selectedLeftId = null;
          _rejectedLeftId = null;
        });
        _persistState();
        // Auto-complete when every left item has been correctly matched.
        if (_userPairs.length == _leftItems.length) {
          _autoSubmit();
        }
      } else {
        // Wrong match: show red flash then clear.
        HapticFeedback.vibrate();
        _rejectionTimer?.cancel();
        setState(() {
          _userPairs[leftId] = rightId; // temporarily pair to show rejection
          _selectedLeftId = null;
          _rejectedLeftId = leftId;
        });
        _rejectionTimer = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _userPairs.remove(leftId);
            _rejectedLeftId = null;
          });
        });
      }
    } else {
      // -----------------------------------------------------------------------
      // Normal mode: resolve duplicates, then record the pairing.
      // -----------------------------------------------------------------------
      String resolvedRightId = rightId;

      // If this right item is used by a different left, try to find a free
      // duplicate text instead.
      if (_userPairs.values.contains(resolvedRightId)) {
        final tappedText = _getRightTextById(resolvedRightId) ?? '';
        if (tappedText.isNotEmpty) {
          final unusedDuplicate = _rightItems.firstWhere((item) {
            final id = item['id'] as String;
            if (_userPairs.values.contains(id)) return false;
            final text = item['text'] as String? ?? '';
            return text.trim().toLowerCase() == tappedText.trim().toLowerCase();
          }, orElse: () => <String, dynamic>{});
          if (unusedDuplicate.isNotEmpty) {
            resolvedRightId = unusedDuplicate['id'] as String;
          }
        }
      }

      setState(() {
        _userPairs.removeWhere((l, r) => r == resolvedRightId);
        _userPairs[leftId] = resolvedRightId;
        _selectedLeftId = null;
      });
      _persistState();
    }
  }

  /// Returns true when [leftId] -> [rightId] is a correct pair.
  ///
  /// Delegates to [AnswerValidationService.validateMatching] so that text and
  /// math equivalence (e.g. "5" == "5", "2+3" == "5") are handled the same way
  /// as the final submission check.  This means the user can tap any right-column
  /// item whose displayed text is equivalent to the correct answer — important
  /// when multiple right items share the same answer text (e.g. two rows that
  /// both equal "5").
  bool _isSinglePairCorrect(String leftId, String rightId) {
    final correctPairs = List<Map<String, dynamic>>.from(
      _content['correctPairs'] ?? [],
    );
    final result = _validator.validateMatching(
      userPairs: {leftId: rightId},
      correctPairs: correctPairs,
      allowPartialCredit: true,
      rightColumn: _rightItems,
    );
    return result.detailedFeedback?[leftId] == true;
  }

  /// Called automatically in evaluateOnMatch mode once all items are paired.
  void _autoSubmit() {
    final correctPairs = List<Map<String, dynamic>>.from(
      _content['correctPairs'] ?? [],
    );
    final result = _validator.validateMatching(
      userPairs: _userPairs,
      correctPairs: correctPairs,
      allowPartialCredit: _content['allowPartialCredit'] ?? true,
      rightColumn: _rightItems,
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
          blockType: 'matching',
          isCorrect: result.isCorrect,
        );
    final correctAnswerStr = _leftItems
        .map((l) {
          final lId = l['id'] as String;
          final leftText = l['text'] as String? ?? '';
          final rightText = _getCorrectRightTextForLeft(lId) ?? '';
          return '$leftText → $rightText';
        })
        .join(', ');
    final studentAnswerStr = _userPairs.entries
        .map((e) => _formatPair(e.key, e.value))
        .join(', ');
    final instruction = _content['instruction']?.toString() ?? '';
    final explanation = _content['explanation']?.toString() ?? '';
    final showExplanation = _content['showExplanation'] as bool? ?? true;
    if (mounted) {
      showDuolingoFeedbackSheet(
        context: context,
        isCorrect: result.isCorrect,
        correctAnswer: correctAnswerStr,
        explanation: showExplanation ? explanation : '',
        showExplanation: showExplanation,
        question: instruction,
        studentAnswer: studentAnswerStr,
        questionType: 'matching',
        savedAiExplanation: _savedAiExplanation,
        onAiExplanationGenerated: (ai) {
          setState(() => _savedAiExplanation = ai);
          _persistState();
        },
      ).then((shouldRetry) {
        if (shouldRetry && mounted) _retry();
      });
    }
  }

  void _clearPair(String leftId) {
    if (_isSubmitted) return;
    // In evaluateOnMatch mode, confirmed pairs are locked and cannot be cleared.
    if (_content['evaluateOnMatch'] as bool? ?? false) return;
    setState(() {
      _userPairs.remove(leftId);
      if (_selectedLeftId == leftId) _selectedLeftId = null;
    });
    _persistState();
  }

  Future<void> _submit() async {
    if (_userPairs.length != _leftItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please match all items (${_userPairs.length} of ${_leftItems.length} matched)',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final correctPairs = List<Map<String, dynamic>>.from(
      _content['correctPairs'] ?? [],
    );
    final result = _validator.validateMatching(
      userPairs: _userPairs,
      correctPairs: correctPairs,
      allowPartialCredit: _content['allowPartialCredit'] ?? true,
      rightColumn: _rightItems,
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
          blockType: 'matching',
          isCorrect: result.isCorrect,
        );
    if (mounted) {
      final instruction =
          _content['instruction']?.toString() ?? 'Match the items:';
      final explanation = _content['explanation']?.toString() ?? '';
      final showExplanation = _content['showExplanation'] as bool? ?? true;
      final correctAnswerStr = _leftItems
          .map((l) {
            final lId = l['id'] as String;
            final leftText = l['text'] as String? ?? '';
            final rightText = _getCorrectRightTextForLeft(lId) ?? '';
            return '$leftText → $rightText';
          })
          .join(', ');
      final studentAnswerStr = _userPairs.entries
          .map((e) => _formatPair(e.key, e.value))
          .join(', ');
      final shouldRetry = await showDuolingoFeedbackSheet(
        context: context,
        isCorrect: result.isCorrect,
        correctAnswer: correctAnswerStr,
        explanation: showExplanation ? explanation : '',
        showExplanation: showExplanation,
        question: instruction,
        studentAnswer: studentAnswerStr,
        questionType: 'matching',
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
      _userPairs.clear();
      _selectedLeftId = null;
      _isSubmitted = false;
      _result = null;
    });
    _persistState();
  }

  String? _getRightTextById(String rightId) {
    final item = _rightItems.firstWhere(
      (item) => item['id'] == rightId,
      orElse: () => {'text': ''},
    );
    return item['text'] as String?;
  }

  /// Formats a left→right pair as a human-readable string, e.g. "Cat → Meow".
  String _formatPair(String leftId, String rightId) {
    final leftText =
        _leftItems.firstWhere(
              (l) => l['id'] == leftId,
              orElse: () => <String, dynamic>{},
            )['text']
            as String? ??
        '';
    final rightText = _getRightTextById(rightId) ?? '';
    return '$leftText → $rightText';
  }

  /// Returns the correct right-side text for a given left item ID (used for answer reveal).
  String? _getCorrectRightTextForLeft(String leftId) {
    final correctPairs = List<Map<String, dynamic>>.from(
      _content['correctPairs'] ?? [],
    );
    final pair = correctPairs.firstWhere(
      (p) => p['left'] == leftId,
      orElse: () => {},
    );
    if (pair.isEmpty) return null;
    return _getRightTextById(pair['right'] as String);
  }

  bool? _isPairCorrect(String leftId) {
    if (!_isSubmitted || _result?.detailedFeedback == null) return null;
    return _result!.detailedFeedback![leftId] as bool?;
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final instruction =
        _content['instruction']?.toString() ?? 'Match the items:';
    final explanation = _content['explanation']?.toString() ?? '';
    final showExplanation = _content['showExplanation'] as bool? ?? true;

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

    final matchedCount = _userPairs.length;
    final totalCount = _leftItems.length;
    final allMatched = matchedCount == totalCount && totalCount > 0;
    final evaluateOnMatch = _content['evaluateOnMatch'] as bool? ?? false;

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
                Icons.link_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Matching',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Instruction
          Text(
            instruction,
            style: baseStyle.copyWith(fontWeight: FontWeight.w600),
          ),

          // Progress row / hint
          if (!_isSubmitted) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    evaluateOnMatch
                        ? 'Tap an item on the left, then its match on the right.'
                        : allMatched
                        ? 'All matched — ready to check!'
                        : 'Tap an item on the left, then its match on the right.',
                    style: baseStyle.copyWith(
                      fontSize: (baseStyle.fontSize ?? 14) * 0.82,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: allMatched
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$matchedCount / $totalCount',
                    style: baseStyle.copyWith(
                      fontSize: (baseStyle.fontSize ?? 14) * 0.8,
                      fontWeight: FontWeight.w700,
                      color: allMatched
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Matching interface
          if (_isSubmitted)
            _buildSubmittedView(baseStyle, theme)
          else
            _buildInteractiveView(
              baseStyle,
              theme,
              template: widget.block.style.questionTemplate ?? 'default',
            ),

          // Post-submit actions: [↩ Try Again]  [✨ Explain ▾]  on one row
          if (_isSubmitted && _result != null) ...[
            const SizedBox(height: 10),
            PostSubmitActions(
              isCorrect: _result!.isCorrect,
              onRetry: _retry,
              explanation: showExplanation ? explanation : '',
              showExplanation: showExplanation,
              question: instruction,
              correctAnswer: _leftItems
                  .map((l) {
                    final lId = l['id'] as String;
                    final leftText = l['text'] as String? ?? '';
                    final rightText = _getCorrectRightTextForLeft(lId) ?? '';
                    return '$leftText → $rightText';
                  })
                  .join(', '),
              studentAnswer: _userPairs.entries
                  .map((e) => _formatPair(e.key, e.value))
                  .join(', '),
              questionType: 'matching',
              baseStyle: baseStyle,
              savedAiExplanation: _savedAiExplanation,
              onAiExplanationGenerated: (ai) {
                setState(() => _savedAiExplanation = ai);
                _persistState();
              },
            ),
          ],

          // Submit button (before submission)
          if (!_isSubmitted && !evaluateOnMatch) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: allMatched ? _submit : null,
                child: const Text('Check Answers'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactive (pre-submission) view
  // ---------------------------------------------------------------------------

  Widget _buildInteractiveView(
    TextStyle baseStyle,
    ThemeData theme, {
    String template = 'default',
  }) {
    final isCompact = template == 'compact';
    final isCard = template == 'card';
    final isNumbered = template == 'numbered';
    final isList = template == 'list';
    final itemPadding = isCompact
        ? const EdgeInsets.symmetric(vertical: 7, horizontal: 10)
        : const EdgeInsets.symmetric(vertical: 11, horizontal: 13);
    final itemMargin = isCompact
        ? const EdgeInsets.only(bottom: 5)
        : const EdgeInsets.only(bottom: 8);
    final itemRadius = isCompact ? 7.0 : 10.0;
    final surface = theme.colorScheme.surfaceContainerHighest;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _columnHeader('Items', baseStyle, theme, compact: isCompact),
              ..._leftItems.asMap().entries.map((entry) {
                final i = entry.key;
                final leftItem = entry.value;
                final leftId = leftItem['id'] as String;
                final leftText = leftItem['text'] as String;
                final isSelected = _selectedLeftId == leftId;
                final isPaired = _userPairs.containsKey(leftId);
                final isRejected = _rejectedLeftId == leftId;
                if (isCard) {
                  return _buildCardLeftChip(
                    baseStyle: baseStyle,
                    theme: theme,
                    leftId: leftId,
                    leftText: leftText,
                    isSelected: isSelected,
                    isPaired: isPaired,
                    isRejected: isRejected,
                    surface: surface,
                  );
                }
                if (isNumbered) {
                  return _buildNumberedLeftChip(
                    baseStyle: baseStyle,
                    theme: theme,
                    leftId: leftId,
                    leftText: leftText,
                    isSelected: isSelected,
                    isPaired: isPaired,
                    isRejected: isRejected,
                    index: i,
                  );
                }
                if (isList) {
                  return _buildListLeftChip(
                    baseStyle: baseStyle,
                    theme: theme,
                    leftId: leftId,
                    leftText: leftText,
                    isSelected: isSelected,
                    isPaired: isPaired,
                    isRejected: isRejected,
                  );
                }
                return _buildLeftChip(
                  baseStyle: baseStyle,
                  theme: theme,
                  leftId: leftId,
                  leftText: leftText,
                  isSelected: isSelected,
                  isPaired: isPaired,
                  isRejected: isRejected,
                  padding: itemPadding,
                  margin: itemMargin,
                  radius: itemRadius,
                );
              }),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Right column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _columnHeader('Matches', baseStyle, theme, compact: isCompact),
              ..._rightItems.asMap().entries.map((entry) {
                final i = entry.key;
                final rightItem = entry.value;
                final rightId = rightItem['id'] as String;
                final rightText = rightItem['text'] as String;
                final isUsed = _userPairs.values.contains(rightId);
                final isActiveTarget = _selectedLeftId != null;
                if (isCard) {
                  return _buildCardRightChip(
                    baseStyle: baseStyle,
                    theme: theme,
                    rightId: rightId,
                    rightText: rightText,
                    isUsed: isUsed,
                    isActiveTarget: isActiveTarget,
                    surface: surface,
                  );
                }
                if (isNumbered) {
                  return _buildNumberedRightChip(
                    baseStyle: baseStyle,
                    theme: theme,
                    rightId: rightId,
                    rightText: rightText,
                    isUsed: isUsed,
                    isActiveTarget: isActiveTarget,
                    index: i,
                  );
                }
                if (isList) {
                  return _buildListRightChip(
                    baseStyle: baseStyle,
                    theme: theme,
                    rightId: rightId,
                    rightText: rightText,
                    isUsed: isUsed,
                    isActiveTarget: isActiveTarget,
                  );
                }
                return _buildRightChip(
                  baseStyle: baseStyle,
                  theme: theme,
                  rightId: rightId,
                  rightText: rightText,
                  isUsed: isUsed,
                  isActiveTarget: isActiveTarget,
                  padding: itemPadding,
                  margin: itemMargin,
                  radius: itemRadius,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardLeftChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String leftId,
    required String leftText,
    required bool isSelected,
    required bool isPaired,
    bool isRejected = false,
    required Color surface,
  }) {
    final Color borderColor;
    final Color bgColor;
    final double borderWidth;

    if (isRejected) {
      borderColor = theme.colorScheme.error;
      bgColor = theme.colorScheme.error.withValues(alpha: 0.1);
      borderWidth = 2;
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.08);
      borderWidth = 2;
    } else if (isPaired) {
      borderColor = theme.colorScheme.secondary.withValues(alpha: 0.55);
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.05);
      borderWidth = 1.5;
    } else {
      borderColor = Colors.transparent;
      bgColor = surface;
      borderWidth = 1;
    }

    final evaluateOnMatch = _content['evaluateOnMatch'] as bool? ?? false;
    final isLockedPair = evaluateOnMatch && isPaired;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 1.5,
        borderRadius: BorderRadius.circular(10),
        color: bgColor,
        child: InkWell(
          onTap: (isRejected || isLockedPair)
              ? null
              : () => _selectLeft(leftId),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              children: [
                Expanded(child: Text(leftText, style: baseStyle)),
                if (isRejected)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: theme.colorScheme.error,
                    ),
                  )
                else if (isLockedPair)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: theme.colorScheme.secondary,
                    ),
                  )
                else if (isPaired)
                  GestureDetector(
                    onTap: () => _clearPair(leftId),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  )
                else if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardRightChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String rightId,
    required String rightText,
    required bool isUsed,
    required bool isActiveTarget,
    required Color surface,
  }) {
    final Color bgColor;
    final double opacity;

    if (isUsed) {
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.08);
      opacity = 0.6;
    } else if (isActiveTarget) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.06);
      opacity = 1.0;
    } else {
      bgColor = surface;
      opacity = 1.0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 1.5,
        borderRadius: BorderRadius.circular(10),
        color: bgColor,
        child: InkWell(
          onTap: () => _selectRight(rightId),
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActiveTarget
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(rightText, style: baseStyle)),
                  if (isUsed)
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: theme.colorScheme.secondary.withValues(alpha: 0.65),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _columnHeader(
    String label,
    TextStyle baseStyle,
    ThemeData theme, {
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * (compact ? 0.7 : 0.75),
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildLeftChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String leftId,
    required String leftText,
    required bool isSelected,
    required bool isPaired,
    bool isRejected = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 11,
      horizontal: 13,
    ),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 8),
    double radius = 10.0,
  }) {
    final Color borderColor;
    final Color bgColor;
    final double borderWidth;

    if (isRejected) {
      borderColor = theme.colorScheme.error;
      bgColor = theme.colorScheme.error.withValues(alpha: 0.1);
      borderWidth = 2;
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      borderWidth = 2;
    } else if (isPaired) {
      borderColor = theme.colorScheme.secondary.withValues(alpha: 0.55);
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.06);
      borderWidth = 1.5;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
      bgColor = Colors.transparent;
      borderWidth = 1;
    }

    final evaluateOnMatch = _content['evaluateOnMatch'] as bool? ?? false;
    // In evaluateOnMatch mode, a correctly paired item is locked (shows ✓, not ×).
    final isLockedPair = evaluateOnMatch && isPaired;

    return InkWell(
      onTap: (isRejected || isLockedPair) ? null : () => _selectLeft(leftId),
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            Expanded(child: Text(leftText, style: baseStyle)),
            if (isRejected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: theme.colorScheme.error,
                ),
              )
            else if (isLockedPair)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: theme.colorScheme.secondary,
                ),
              )
            else if (isPaired)
              GestureDetector(
                onTap: () => _clearPair(leftId),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              )
            else if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String rightId,
    required String rightText,
    required bool isUsed,
    required bool isActiveTarget,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 11,
      horizontal: 13,
    ),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 8),
    double radius = 10.0,
  }) {
    final Color borderColor;
    final Color bgColor;
    final double borderWidth;
    final double opacity;

    if (isUsed) {
      borderColor = theme.colorScheme.secondary.withValues(alpha: 0.35);
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.05);
      borderWidth = 1.5;
      opacity = 0.6;
    } else if (isActiveTarget) {
      borderColor = theme.colorScheme.primary.withValues(alpha: 0.55);
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.05);
      borderWidth = 1.5;
      opacity = 1.0;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
      bgColor = Colors.transparent;
      borderWidth = 1;
      opacity = 1.0;
    }

    return InkWell(
      onTap: () => _selectRight(rightId),
      borderRadius: BorderRadius.circular(radius),
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              Expanded(child: Text(rightText, style: baseStyle)),
              if (isUsed)
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.65),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedLeftChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String leftId,
    required String leftText,
    required bool isSelected,
    required bool isPaired,
    bool isRejected = false,
    required int index,
  }) {
    final Color borderColor;
    final Color bgColor;
    final Color badgeColor;
    final double borderWidth;

    if (isRejected) {
      borderColor = theme.colorScheme.error;
      bgColor = theme.colorScheme.error.withValues(alpha: 0.1);
      badgeColor = theme.colorScheme.error;
      borderWidth = 2;
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      badgeColor = theme.colorScheme.primary;
      borderWidth = 2;
    } else if (isPaired) {
      borderColor = theme.colorScheme.secondary.withValues(alpha: 0.55);
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.06);
      badgeColor = theme.colorScheme.secondary;
      borderWidth = 1.5;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
      bgColor = Colors.transparent;
      badgeColor = theme.colorScheme.outline.withValues(alpha: 0.5);
      borderWidth = 1;
    }

    final evaluateOnMatch = _content['evaluateOnMatch'] as bool? ?? false;
    final isLockedPair = evaluateOnMatch && isPaired;

    return InkWell(
      onTap: (isRejected || isLockedPair) ? null : () => _selectLeft(leftId),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(leftText, style: baseStyle)),
            if (isRejected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: theme.colorScheme.error,
                ),
              )
            else if (isLockedPair)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: theme.colorScheme.secondary,
                ),
              )
            else if (isPaired)
              GestureDetector(
                onTap: () => _clearPair(leftId),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              )
            else if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberedRightChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String rightId,
    required String rightText,
    required bool isUsed,
    required bool isActiveTarget,
    required int index,
  }) {
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final letter = index < letters.length ? letters[index] : '${index + 1}';
    final Color borderColor;
    final Color bgColor;
    final Color badgeColor;
    final double borderWidth;
    final double opacity;

    if (isUsed) {
      borderColor = theme.colorScheme.secondary.withValues(alpha: 0.35);
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.05);
      badgeColor = theme.colorScheme.secondary;
      borderWidth = 1.5;
      opacity = 0.6;
    } else if (isActiveTarget) {
      borderColor = theme.colorScheme.primary.withValues(alpha: 0.55);
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.05);
      badgeColor = theme.colorScheme.primary;
      borderWidth = 1.5;
      opacity = 1.0;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
      bgColor = Colors.transparent;
      badgeColor = theme.colorScheme.outline.withValues(alpha: 0.5);
      borderWidth = 1;
      opacity = 1.0;
    }

    return InkWell(
      onTap: () => _selectRight(rightId),
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: opacity,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(rightText, style: baseStyle)),
              if (isUsed)
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.65),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListLeftChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String leftId,
    required String leftText,
    required bool isSelected,
    required bool isPaired,
    bool isRejected = false,
  }) {
    final Color accentColor;
    final Color bgColor;
    const double borderLeftWidth = 3.5;

    if (isRejected) {
      accentColor = theme.colorScheme.error;
      bgColor = theme.colorScheme.error.withValues(alpha: 0.06);
    } else if (isSelected) {
      accentColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.07);
    } else if (isPaired) {
      accentColor = theme.colorScheme.secondary;
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.05);
    } else {
      accentColor = theme.colorScheme.outline.withValues(alpha: 0.4);
      bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }

    final evaluateOnMatch = _content['evaluateOnMatch'] as bool? ?? false;
    final isLockedPair = evaluateOnMatch && isPaired;

    return InkWell(
      onTap: (isRejected || isLockedPair) ? null : () => _selectLeft(leftId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: accentColor, width: borderLeftWidth),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                leftText,
                style: baseStyle.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isRejected ? theme.colorScheme.error : null),
                ),
              ),
            ),
            if (isRejected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: theme.colorScheme.error,
                ),
              )
            else if (isLockedPair)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: theme.colorScheme.secondary,
                ),
              )
            else if (isPaired)
              GestureDetector(
                onTap: () => _clearPair(leftId),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              )
            else if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListRightChip({
    required TextStyle baseStyle,
    required ThemeData theme,
    required String rightId,
    required String rightText,
    required bool isUsed,
    required bool isActiveTarget,
  }) {
    final Color accentColor;
    final Color bgColor;
    final double opacity;

    if (isUsed) {
      accentColor = theme.colorScheme.secondary;
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.05);
      opacity = 0.6;
    } else if (isActiveTarget) {
      accentColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.05);
      opacity = 1.0;
    } else {
      accentColor = theme.colorScheme.outline.withValues(alpha: 0.3);
      bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
      opacity = 1.0;
    }

    return InkWell(
      onTap: () => _selectRight(rightId),
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: opacity,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: accentColor, width: 3.5)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(rightText, style: baseStyle)),
              if (isUsed)
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.65),
                ),
            ],
          ),
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

  // ---------------------------------------------------------------------------
  // Submitted view (shows all pairs with correct/incorrect feedback)
  // ---------------------------------------------------------------------------

  Widget _buildSubmittedView(TextStyle baseStyle, ThemeData theme) {
    return Column(
      children: _leftItems.map((leftItem) {
        final leftId = leftItem['id'] as String;
        final leftText = leftItem['text'] as String;
        final isCorrect = _isPairCorrect(leftId);
        final pairedRightText = _userPairs.containsKey(leftId)
            ? _getRightTextById(_userPairs[leftId]!)
            : null;
        final correctRightText = isCorrect == false
            ? _getCorrectRightTextForLeft(leftId)
            : null;

        final pairColor = isCorrect == true
            ? const Color(0xFF2E7D32)
            : (isCorrect == false
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline);
        final pairBg = isCorrect == true
            ? const Color(0xFF2E7D32).withValues(alpha: 0.06)
            : (isCorrect == false
                  ? theme.colorScheme.error.withValues(alpha: 0.06)
                  : Colors.transparent);

        return Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
          decoration: BoxDecoration(
            color: pairBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pairColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect == true
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: pairColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              // Left item
              Expanded(child: Text(leftText, style: baseStyle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              // Right item (user answer + correct answer if wrong)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pairedRightText ?? '—',
                      style: baseStyle.copyWith(
                        color: isCorrect == false
                            ? theme.colorScheme.error
                            : null,
                        decoration: isCorrect == false
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (correctRightText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        correctRightText,
                        style: baseStyle.copyWith(
                          fontSize: (baseStyle.fontSize ?? 14) * 0.88,
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Result banner
  // ---------------------------------------------------------------------------
}
