import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/services/ai/ai_providers.dart';

// ---------------------------------------------------------------------------
// showDuolingoFeedbackSheet — Duolingo-style modal bottom sheet shown after
// any question submission. Returns true when the user wants to retry.
// ---------------------------------------------------------------------------

/// Returns `true` when the user wants to retry (pressed "Try Again").
/// Returns `false` when the user wants to continue (pressed "Continue"/"Got it").
Future<bool> showDuolingoFeedbackSheet({
  required BuildContext context,
  required bool isCorrect,
  required String correctAnswer,
  required String explanation,
  required bool showExplanation,
  String question = '',
  String studentAnswer = '',
  String questionType = '',
  TextStyle? baseStyle,
  String? savedAiExplanation,
  ValueChanged<String>? onAiExplanationGenerated,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DuolingoSheet(
      isCorrect: isCorrect,
      correctAnswer: correctAnswer,
      explanation: explanation,
      showExplanation: showExplanation,
      question: question,
      studentAnswer: studentAnswer,
      questionType: questionType,
      baseStyle: baseStyle,
      savedAiExplanation: savedAiExplanation,
      onAiExplanationGenerated: onAiExplanationGenerated,
    ),
  );
  return result == true;
}

class _DuolingoSheet extends ConsumerStatefulWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final bool showExplanation;
  final String question;
  final String studentAnswer;
  final String questionType;
  final TextStyle? baseStyle;
  final String? savedAiExplanation;
  final ValueChanged<String>? onAiExplanationGenerated;

  const _DuolingoSheet({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.showExplanation,
    required this.question,
    required this.studentAnswer,
    required this.questionType,
    this.baseStyle,
    this.savedAiExplanation,
    this.onAiExplanationGenerated,
  });

  @override
  ConsumerState<_DuolingoSheet> createState() => _DuolingoSheetState();
}

class _DuolingoSheetState extends ConsumerState<_DuolingoSheet> {
  final List<String> _aiExplanations = [];
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedAiExplanation;
    if (saved != null && saved.isNotEmpty) {
      _aiExplanations.addAll(
        saved.split(_kAiSeparator).where((s) => s.isNotEmpty),
      );
    }
  }

  Future<void> _generateAi() async {
    if (_loadingAi) return;
    setState(() => _loadingAi = true);
    try {
      final service = ref.read(aiContentServiceProvider);
      final result = await service.generateQuestionExplanation(
        question: widget.question,
        correctAnswer: widget.correctAnswer,
        studentAnswer: widget.studentAnswer,
        teacherExplanation: widget.explanation,
        questionType: widget.questionType,
      );
      if (mounted && result.isNotEmpty) {
        setState(() {
          _aiExplanations.add(result);
          _loadingAi = false;
        });
        widget.onAiExplanationGenerated?.call(
          _aiExplanations.join(_kAiSeparator),
        );
      } else if (mounted) {
        setState(() => _loadingAi = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerColor = widget.isCorrect
        ? Colors.green.shade600
        : Colors.red.shade600;
    final hasExplanation =
        widget.showExplanation && widget.explanation.isNotEmpty;

    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                color: bannerColor,
                child: Row(
                  children: [
                    Icon(
                      widget.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isCorrect ? 'Excellent! 🎉' : 'Incorrect',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isCorrect &&
                        widget.correctAnswer.isNotEmpty) ...[
                      Text(
                        'Correct answer:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.correctAnswer,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (hasExplanation) ...[
                      Text(
                        widget.explanation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!widget.isCorrect) ...[
                      for (final text in _aiExplanations) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_loadingAi)
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generating…',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: _generateAi,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _aiExplanations.isEmpty
                                ? 'Ask AI for more'
                                : 'Ask AI again',
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (!widget.isCorrect)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(color: Colors.red.shade400),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Got it'),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PostSubmitActions — the single widget that replaces the old stack of
// QuestionFeedbackBar + AiExplanationTile + CompactRetryButton.
//
// Layout after submission:
//   [ ↩ Try Again ]  [ Explanation ▾ ]    ← single row, two small pills
//   ┌──────────────────────────────────┐  ← auto-expanded when content exists
//   │ static explanation (if any)      │
//   │ ──────────────────────────────── │  ← divider (only when both present)
//   │ [✨ Ask AI]  ← button (wrong ans) │  ← OR spinner OR AI text
//   └──────────────────────────────────┘
//
// Offline-first:  static explanation is shown immediately; AI is opt-in.
// Persistence:    AI explanation is saved via [onAiExplanationGenerated] so
//                 it is restored on the next render (e.g. after retry).
// ---------------------------------------------------------------------------

class PostSubmitActions extends ConsumerStatefulWidget {
  final bool isCorrect;
  final VoidCallback onRetry;

  /// Static explanation stored in the block content (may be empty).
  final String explanation;

  /// Whether the teacher opted to show the explanation to students.
  final bool showExplanation;

  // AI context ---------------------------------------------------------------
  final String question;
  final String correctAnswer;
  final String studentAnswer;
  final String questionType;
  final TextStyle baseStyle;

  /// Previously generated (and persisted) AI explanation. When non-null it is
  /// shown immediately without triggering a new network request.
  final String? savedAiExplanation;

  /// Called once when AI generates a new explanation — use this to persist the
  /// text so it survives retry / hot-reload.
  final ValueChanged<String>? onAiExplanationGenerated;

  const PostSubmitActions({
    required this.isCorrect,
    required this.onRetry,
    required this.question,
    required this.questionType,
    required this.baseStyle,
    this.explanation = '',
    this.showExplanation = true,
    this.correctAnswer = '',
    this.studentAnswer = '',
    this.savedAiExplanation,
    this.onAiExplanationGenerated,
    super.key,
  });

  @override
  ConsumerState<PostSubmitActions> createState() => _PostSubmitActionsState();
}

// Separator used to join/split multiple accumulated AI explanations in the
// persisted string.
const _kAiSeparator = '\n\n---\n\n';

class _PostSubmitActionsState extends ConsumerState<PostSubmitActions> {
  late bool _expanded;
  // Accumulated AI explanations — each new "Ask AI for more" tap appends one.
  final List<String> _aiExplanations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Restore persisted AI explanations.
    final saved = widget.savedAiExplanation;
    if (saved != null && saved.isNotEmpty) {
      _aiExplanations.addAll(
        saved.split(_kAiSeparator).where((s) => s.isNotEmpty),
      );
    }
    // Auto-expand when there is something to show right away.
    _expanded = _hasStaticExplanation || _aiExplanations.isNotEmpty;
  }

  double get _bodyFontSize => (widget.baseStyle.fontSize ?? 14) * 0.9;

  bool get _hasStaticExplanation =>
      widget.showExplanation && widget.explanation.isNotEmpty;

  // Show the explain pill only when there is visible content to display:
  // for wrong answers the AI section is always available; for correct answers
  // only show the pill when a static explanation exists.
  bool get _showExplainPill => _hasStaticExplanation || !widget.isCorrect;

  Future<void> _generateExplanation() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(aiContentServiceProvider);
      final result = await service.generateQuestionExplanation(
        question: widget.question,
        correctAnswer: widget.correctAnswer,
        studentAnswer: widget.studentAnswer,
        teacherExplanation: widget.explanation,
        questionType: widget.questionType,
      );
      if (mounted && result.isNotEmpty) {
        setState(() {
          _aiExplanations.add(result);
          _loading = false;
        });
        // Persist the full accumulated list as one joined string.
        widget.onAiExplanationGenerated?.call(
          _aiExplanations.join(_kAiSeparator),
        );
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  // --------------------------------------------------------------------------
  // Pill builders
  // --------------------------------------------------------------------------

  Widget _retryPill(ThemeData theme) {
    return InkWell(
      onTap: widget.onRetry,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 4),
            Text(
              'Try Again',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _explainPill(ThemeData theme) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 13,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Explanation',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 13,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Expanded panel
  // --------------------------------------------------------------------------

  Widget _expandedPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Static explanation — shown immediately, no network needed.
          if (_hasStaticExplanation)
            Text(
              widget.explanation,
              style: widget.baseStyle.copyWith(
                fontSize: _bodyFontSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),

          // AI section — only available for wrong answers.
          if (!widget.isCorrect) ...[
            // Render every accumulated AI explanation in order.
            for (final (index, text) in _aiExplanations.indexed) ...[
              if (index == 0 && _hasStaticExplanation) ...[
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ] else if (index > 0) ...[
                const SizedBox(height: 6),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: widget.baseStyle.copyWith(
                        fontSize: _bodyFontSize,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Spinner while generating, or "Ask AI for more" button otherwise.
            const SizedBox(height: 10),
            if (_loading)
              Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generating…',
                    style: widget.baseStyle.copyWith(
                      fontSize: _bodyFontSize,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _generateExplanation,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.25,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _aiExplanations.isEmpty
                            ? 'Ask AI for more'
                            : 'Ask AI again',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.85,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single row: [Try Again] [Explanation ▾]
        Row(
          children: [
            _retryPill(theme),
            if (_showExplainPill) ...[
              const SizedBox(width: 8),
              _explainPill(theme),
            ],
          ],
        ),

        // Expanded explanation panel.
        if (_expanded && _showExplainPill) ...[
          const SizedBox(height: 8),
          _expandedPanel(theme),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Legacy widgets kept for reference — replaced by PostSubmitActions above.
// ---------------------------------------------------------------------------

/// @deprecated Use [PostSubmitActions] instead.
class QuestionFeedbackBar extends StatelessWidget {
  final bool isCorrect;
  const QuestionFeedbackBar({required this.isCorrect, super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// @deprecated Use [PostSubmitActions] instead.
class AiExplanationTile extends ConsumerStatefulWidget {
  final String explanation;
  final String question;
  final String correctAnswer;
  final String studentAnswer;
  final String questionType;
  final TextStyle baseStyle;

  const AiExplanationTile({
    required this.explanation,
    required this.question,
    required this.correctAnswer,
    required this.questionType,
    required this.baseStyle,
    this.studentAnswer = '',
    super.key,
  });

  @override
  ConsumerState<AiExplanationTile> createState() => _AiExplanationTileState();
}

class _AiExplanationTileState extends ConsumerState<AiExplanationTile> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// @deprecated Use [PostSubmitActions] instead.
class CompactRetryButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const CompactRetryButton({
    required this.onTap,
    this.label = 'Try Again',
    super.key,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
