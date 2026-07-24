import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:barruu/core/services/block_ai_service.dart';

/// A non-persistent card that streams an AI-generated insight below a block.
///
/// The card renders markdown content as it streams in from the AI.  When the
/// stream is done the user may optionally add the content to the document via
/// the [onAddToDocument] callback (creator context only).
class AiInsightCard extends StatefulWidget {
  /// The AI action label (e.g. "💡 Explain this").
  final AiAction action;

  /// The stream of text deltas from [BlockAiService.query].
  final Stream<String> stream;

  /// Called when the user dismisses the card.
  final VoidCallback onDismiss;

  /// Optional callback for inserting the generated text as a new block.
  /// When null the "Add to document" button is hidden.
  final void Function(String content)? onAddToDocument;

  const AiInsightCard({
    super.key,
    required this.action,
    required this.stream,
    required this.onDismiss,
    this.onAddToDocument,
  });

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  final StringBuffer _buffer = StringBuffer();
  StreamSubscription<String>? _sub;
  bool _done = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.stream);
  }

  @override
  void didUpdateWidget(AiInsightCard old) {
    super.didUpdateWidget(old);
    if (old.stream != widget.stream) {
      _sub?.cancel();
      _buffer.clear();
      setState(() {
        _done = false;
        _error = false;
      });
      _subscribe(widget.stream);
    }
  }

  void _subscribe(Stream<String> stream) {
    _sub = stream.listen(
      (delta) {
        if (mounted) setState(() => _buffer.write(delta));
      },
      onDone: () {
        if (mounted) setState(() => _done = true);
      },
      onError: (_) {
        if (mounted) setState(() { _done = true; _error = true; });
      },
    );
  }

  void _stop() {
    _sub?.cancel();
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = _buffer.toString();

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.18),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
            child: Row(
              children: [
                Text(
                  '✨ AI · ${widget.action.label}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if (!_done)
                  _SmallButton(
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    onTap: _stop,
                    color: colorScheme.error,
                  ),
                const SizedBox(width: 4),
                _SmallButton(
                  icon: Icons.close_rounded,
                  label: 'Dismiss',
                  onTap: widget.onDismiss,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _error
                ? Text(
                    'Could not reach the AI. Check your connection and try again.',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 13,
                    ),
                  )
                : content.isEmpty
                    ? const _ThinkingIndicator()
                    : MarkdownBody(
                        data: content,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                          code: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
          ),

          // Footer actions (when done)
          if (_done && !_error && content.isNotEmpty) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onAddToDocument != null)
                    TextButton.icon(
                      onPressed: () => widget.onAddToDocument!(content),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: const Text('Add to document'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Thinking…',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
