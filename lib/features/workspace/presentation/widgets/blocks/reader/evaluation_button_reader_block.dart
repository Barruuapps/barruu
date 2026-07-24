import 'dart:io';

import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';

class EvaluationButtonReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory? docDir;

  const EvaluationButtonReaderBlock({
    super.key,
    required this.block,
    this.docDir,
  });

  @override
  ConsumerState<EvaluationButtonReaderBlock> createState() =>
      _EvaluationButtonReaderBlockState();
}

class _EvaluationButtonReaderBlockState
    extends ConsumerState<EvaluationButtonReaderBlock> {
  late Map<String, dynamic> _content;
  bool _showResults = false;
  Map<String, dynamic>? _evaluationResults;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.block.content.isNotEmpty) {
        _content = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
      } else {
        _content = {'buttonText': 'Show Results', 'questionGroup': ''};
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse block content',
        error: e,
        stackTrace: stackTrace,
      );
      _content = {'buttonText': 'Show Results', 'questionGroup': ''};
    }
  }

  /// Clears all submitted quiz block state so the user can retry the entire quiz.
  Future<void> _resetQuiz() async {
    if (widget.docDir == null) return;
    try {
      final documentProvider = editDocumentControllerProvider(widget.docDir!);
      final blocks = ref.read(documentProvider);
      const quizTypes = {
        BlockType.checkbox,
        BlockType.multipleChoice,
        BlockType.trueFalse,
        BlockType.fillInBlank,
        BlockType.matching,
        BlockType.wordOrder,
        BlockType.mathWorkpad,
      };
      for (final block in blocks) {
        if (!quizTypes.contains(block.type)) continue;
        try {
          final blockContent = JsonStringConverter().convertFromJsonString(
            block.content,
          );
          // Only reset blocks that have been submitted
          final isSubmitted =
              (blockContent['_isSubmitted'] as bool?) ??
              (blockContent['isSubmitted'] as bool?) ??
              false;
          if (!isSubmitted) continue;

          // Clear all interactive-state fields
          blockContent.remove('_isSubmitted');
          blockContent.remove('_selectedOptions');
          blockContent.remove('_selectedAnswer');
          blockContent.remove('_userPairs');
          blockContent.remove('_userAnswers');
          blockContent.remove('_earnedMarks');
          blockContent.remove('_totalMarks');
          blockContent.remove('isSubmitted');
          blockContent.remove('earnedMarks');
          blockContent.remove('selectedOptions');

          final jsonString = JsonStringConverter().convertToJsonString(
            blockContent,
          );
          final updatedBlock = block.copyWith(content: jsonString);
          await ref
              .read(editDocumentControllerProvider(widget.docDir!).notifier)
              .saveBlock(updatedBlock);
        } catch (e) {
          logger.e('Error resetting quiz block', error: e);
        }
      }
      setState(() {
        _showResults = false;
        _evaluationResults = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz reset — you can try again')),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Failed to reset quiz', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _evaluateQuestions() async {
    if (widget.docDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot evaluate: Document directory not available'),
        ),
      );
      return;
    }

    try {
      // Get all blocks from the document
      final documentProvider = editDocumentControllerProvider(widget.docDir!);
      final blocks = ref.read(documentProvider);

      if (blocks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot evaluate: No blocks found')),
        );
        return;
      }

      final questionGroup = _content['questionGroup']?.toString().trim() ?? '';

      // Quiz block types (old checkbox-with-options and new dedicated quiz blocks)
      const quizTypes = {
        BlockType.checkbox,
        BlockType.multipleChoice,
        BlockType.trueFalse,
        BlockType.fillInBlank,
        BlockType.matching,
        BlockType.wordOrder,
        BlockType.mathWorkpad,
      };

      // Find all question blocks (checkbox-with-options + dedicated quiz blocks)
      final questionBlocks = blocks.where((block) {
        if (!quizTypes.contains(block.type)) return false;

        try {
          final blockContent = JsonStringConverter().convertFromJsonString(
            block.content,
          );

          // Legacy checkbox quiz blocks must have 'options' field
          if (block.type == BlockType.checkbox &&
              blockContent['options'] == null) {
            return false;
          }

          // Filter by group if specified
          if (questionGroup.isNotEmpty) {
            final blockGroup =
                blockContent['questionGroup']?.toString().trim() ?? '';
            return blockGroup == questionGroup;
          }

          return true;
        } catch (e) {
          return false;
        }
      }).toList();

      if (questionBlocks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              questionGroup.isEmpty
                  ? 'No questions found in this document'
                  : 'No questions found in group "$questionGroup"',
            ),
          ),
        );
        return;
      }

      // Calculate question numbers in a single pass (O(n))
      final questionNumberMap = <String, int>{};
      int qNum = 0;
      for (final b in blocks) {
        if (quizTypes.contains(b.type)) {
          try {
            final bContent = JsonStringConverter().convertFromJsonString(
              b.content,
            );
            final isLegacy = b.type == BlockType.checkbox;
            if (!isLegacy || bContent['options'] != null) {
              qNum++;
              if (b.id != null) {
                questionNumberMap[b.id!] = qNum;
              }
            }
          } catch (e) {
            // Skip
          }
        }
      }

      // Calculate results - only count submitted questions
      int totalQuestions = 0;
      int submittedQuestions = 0;
      int correctAnswers = 0;
      double totalMarks = 0.0;
      double earnedMarks = 0.0;
      final List<Map<String, dynamic>> questionDetails = [];

      for (final block in questionBlocks) {
        try {
          final blockContent = JsonStringConverter().convertFromJsonString(
            block.content,
          );

          totalQuestions++;

          // Support both legacy (isSubmitted) and new (_isSubmitted) state keys
          final isSubmitted =
              (blockContent['_isSubmitted'] as bool?) ??
              (blockContent['isSubmitted'] as bool?) ??
              false;

          if (isSubmitted) {
            submittedQuestions++;

            // Support both legacy (marksPerQuestion/earnedMarks) and new (_totalMarks/_earnedMarks)
            final questionMarks =
                (blockContent['_totalMarks'] as num?)?.toDouble() ??
                (blockContent['marksPerQuestion'] as num?)?.toDouble() ??
                (blockContent['points'] as num?)?.toDouble() ??
                1.0;
            totalMarks += questionMarks;

            final blockEarnedMarks =
                (blockContent['_earnedMarks'] as num?)?.toDouble() ??
                (blockContent['earnedMarks'] as num?)?.toDouble() ??
                0.0;
            earnedMarks += blockEarnedMarks;

            // Check if answer was correct (earned full marks)
            if ((blockEarnedMarks - questionMarks).abs() < 0.01) {
              correctAnswers++;
            }

            // Look up question number from precomputed map
            final questionNum =
                (block.id != null ? questionNumberMap[block.id!] : null) ?? 0;

            questionDetails.add({
              'blockId': block.id,
              'questionNumber': questionNum,
              'question':
                  blockContent['question']?.toString() ??
                  blockContent['statement']?.toString() ??
                  blockContent['instruction']?.toString() ??
                  'Question $questionNum',
              'earnedMarks': blockEarnedMarks,
              'totalMarks': questionMarks,
              'isCorrect': (blockEarnedMarks - questionMarks).abs() < 0.01,
            });
          }
        } catch (e) {
          logger.e('Error processing question block', error: e);
        }
      }

      // Check if any questions were submitted
      if (submittedQuestions == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                questionGroup.isEmpty
                    ? 'No submitted questions found. Please answer the questions first.'
                    : 'No submitted questions found in group "$questionGroup". Please answer the questions first.',
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _evaluationResults = {
          'totalQuestions': totalQuestions,
          'submittedQuestions': submittedQuestions,
          'unansweredQuestions': totalQuestions - submittedQuestions,
          'correctAnswers': correctAnswers,
          'totalMarks': totalMarks,
          'earnedMarks': earnedMarks,
          'percentage': totalMarks > 0 ? (earnedMarks / totalMarks * 100) : 0.0,
          'questionDetails': questionDetails,
          'questionGroup': questionGroup,
        };
        _showResults = true;
      });

      // Reveal all hidden feedback by updating question blocks
      for (final block in questionBlocks) {
        try {
          final blockContent = JsonStringConverter().convertFromJsonString(
            block.content,
          );

          // Only update if feedback was hidden
          final showFeedbackInstantly =
              blockContent['showFeedbackInstantly'] as bool? ?? true;
          if (!showFeedbackInstantly && blockContent['isSubmitted'] == true) {
            // Calculate and set proper feedback
            final selectedOptions =
                (blockContent['selectedOptions'] as List?)?.cast<bool>() ?? [];
            final options = blockContent['options'] as List;
            final correctIndices = <int>[];

            for (int i = 0; i < options.length; i++) {
              if (options[i] is Map<String, dynamic> &&
                  options[i]['correct'] == true) {
                correctIndices.add(i);
              }
            }

            final selectedIndices = selectedOptions
                .asMap()
                .entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();

            final selectedSet = selectedIndices.toSet();
            final correctSet = correctIndices.toSet();
            final isCorrect =
                selectedSet.length == correctSet.length &&
                selectedSet.containsAll(correctSet) &&
                correctSet.containsAll(selectedSet);

            final marks =
                (blockContent['earnedMarks'] as num?)?.toDouble() ?? 0.0;

            blockContent['feedback'] = isCorrect
                ? 'Correct! (+${marks.toStringAsFixed(1)} marks)'
                : 'Incorrect. ${marks > 0 ? 'Partial credit: +${marks.toStringAsFixed(1)} marks. ' : ''}The correct options are: ${correctIndices.map((i) => '${String.fromCharCode(65 + i)}) ${options[i]['text']}').join(', ')}';

            // Mark that feedback is now revealed
            blockContent['feedbackRevealed'] = true;

            final updatedBlock = block.copyWith(
              content: JsonStringConverter().convertToJsonString(blockContent),
            );

            ref
                .read(editDocumentControllerProvider(widget.docDir!).notifier)
                .saveBlock(updatedBlock);
          }
        } catch (e) {
          logger.e('Error revealing feedback for block', error: e);
        }
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to evaluate questions',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error evaluating questions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonText = _content['buttonText']?.toString() ?? 'Show Results';

    if (_showResults && _evaluationResults != null) {
      return _buildResults(theme);
    }

    // Professional button design using theme
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        children: [
          // Decorative divider before button
          Divider(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            thickness: 2,
            height: 32,
          ),
          // Evaluation button with professional styling
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _evaluateQuestions,
              icon: const Icon(Icons.analytics_outlined, size: 24),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Helper text
          Text(
            'Click to calculate your score',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          Divider(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            thickness: 2,
            height: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final results = _evaluationResults!;
    final percentage = results['percentage'] as double;
    final earnedMarks = results['earnedMarks'] as double;
    final totalMarks = results['totalMarks'] as double;
    final correctAnswers = results['correctAnswers'] as int;
    final submittedQuestions = results['submittedQuestions'] as int;
    final totalQuestions = results['totalQuestions'] as int;
    final unansweredQuestions = results['unansweredQuestions'] as int;
    final questionGroup = results['questionGroup'] as String;

    Color getGradeColor() {
      if (percentage >= 85) return theme.colorScheme.primary;
      if (percentage >= 75) return theme.colorScheme.secondary;
      if (percentage >= 50) return theme.colorScheme.tertiary;
      return theme.colorScheme.error;
    }

    String getGrade() {
      if (percentage >= 90) return 'A+';
      if (percentage >= 85) return 'A';
      if (percentage >= 75) return 'B';
      if (percentage >= 60) return 'C';
      if (percentage >= 50) return 'D';
      return 'F';
    }

    final gradeColor = getGradeColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: gradeColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with grade
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradeColor.withValues(alpha: 0.15),
                  gradeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Grade badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getGrade(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          ThemeData.estimateBrightnessForColor(gradeColor) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionGroup.isEmpty ? 'Quiz Results' : questionGroup,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$submittedQuestions of $totalQuestions question${totalQuestions != 1 ? 's' : ''} answered',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (unansweredQuestions > 0)
                        Text(
                          '$unansweredQuestions unanswered',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.tertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // Trophy icon
                Icon(Icons.emoji_events_rounded, color: gradeColor, size: 36),
              ],
            ),
          ),

          // Stats section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Main stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Score',
                        value: earnedMarks.toStringAsFixed(1),
                        subtitle: 'of ${totalMarks.toStringAsFixed(1)}',
                        icon: Icons.stars_rounded,
                        color: theme.colorScheme.primary,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Percentage',
                        value: '${percentage.toStringAsFixed(0)}%',
                        subtitle: getGrade(),
                        icon: Icons.trending_up_rounded,
                        color: gradeColor,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Correct',
                        value: '$correctAnswers',
                        subtitle: 'of $submittedQuestions',
                        icon: Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        theme: theme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showResults = false),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Recalculate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetQuiz,
                        icon: const Icon(Icons.restart_alt_rounded, size: 20),
                        label: const Text('Reset Quiz'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
