import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Widget to render text with embedded LaTeX math formulas.
///
/// Supports:
/// - Inline equations: $x^2$
/// - Display equations: $$x^2 + y^2 = z^2$$
/// - Mixed text and equations
/// - Proper text wrapping
///
/// Example:
/// ```dart
/// MathText(
///   text: 'The formula is $E = mc^2$ where E is energy.',
///   style: TextStyle(fontSize: 16),
/// )
/// ```
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final TextAlign textAlign;

  const MathText({
    super.key,
    required this.text,
    this.style,
    this.semanticsLabel,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    if (!text.contains(r'$')) {
      return Text(text, style: style, semanticsLabel: semanticsLabel, textAlign: textAlign);
    }

    try {
      final parts = _parseEquations(text);

      // For display mode equations ($$...$$), keep them in a column
      if (parts.any((part) => part.isDisplayMode)) {
        return SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildTextParts(parts),
          ),
        );
      }

      // For inline mode equations, use RichText with spans for better flow
      return SelectionArea(
        child: RichText(
          text: TextSpan(
            style: style ?? DefaultTextStyle.of(context).style,
            children: _buildInlineTextSpans(parts, context),
          ),
          textAlign: textAlign,
        ),
      );
    } catch (e) {
      // If parsing fails, just show the raw text
      return Text(text, style: style, semanticsLabel: semanticsLabel);
    }
  }

  /// Parses the text to identify equations and regular text.
  List<TextPart> _parseEquations(String text) {
    final result = <TextPart>[];
    int currentPos = 0;

    while (currentPos < text.length) {
      final nextDisplayStart = text.indexOf(r'$$', currentPos);
      final nextInlineStart = text.indexOf(r'$', currentPos);

      if (nextDisplayStart == -1 && nextInlineStart == -1) {
        // No more equations, add remaining text
        if (currentPos < text.length) {
          result.add(TextPart(text.substring(currentPos), false, false));
        }
        break;
      }

      int equationStart = -1;

      if (nextDisplayStart != -1 && (nextInlineStart == -1 || nextDisplayStart <= nextInlineStart)) {
        // Display equation comes first
        equationStart = nextDisplayStart;

        // Add text before the equation
        if (equationStart > currentPos) {
          result.add(TextPart(text.substring(currentPos, equationStart), false, false));
        }

        // Find closing delimiters
        final equationContentStart = equationStart + 2; // Skip $$
        final equationContentEnd = text.indexOf(r'$$', equationContentStart);

        if (equationContentEnd != -1) {
          final equationContent = text.substring(equationContentStart, equationContentEnd);
          result.add(TextPart(equationContent, true, true));
          currentPos = equationContentEnd + 2; // Skip closing $$
        } else {
          // No closing delimiter, treat as text
          result.add(TextPart(text.substring(equationStart), false, false));
          break;
        }
      } else {
        // Inline equation comes first
        equationStart = nextInlineStart;

        // Add text before the equation
        if (equationStart > currentPos) {
          result.add(TextPart(text.substring(currentPos, equationStart), false, false));
        }

        // Find closing delimiter
        final equationContentStart = equationStart + 1; // Skip $
        final equationContentEnd = text.indexOf(r'$', equationContentStart);

        if (equationContentEnd != -1) {
          final equationContent = text.substring(equationContentStart, equationContentEnd);
          result.add(TextPart(equationContent, true, false));
          currentPos = equationContentEnd + 1; // Skip closing $
        } else {
          // No closing delimiter, treat as text
          result.add(TextPart(text.substring(equationStart), false, false));
          break;
        }
      }
    }

    return result;
  }

  /// Builds a list of widgets for text with display mode equations.
  List<Widget> _buildTextParts(List<TextPart> parts) {
    final result = <Widget>[];
    List<TextPart> currentTextParts = [];

    for (final part in parts) {
      if (part.isDisplayMode) {
        // Flush any accumulated text parts as a paragraph
        if (currentTextParts.isNotEmpty) {
          result.add(
            RichText(
              text: TextSpan(
                style: style,
                children: currentTextParts.map((p) {
                  if (p.isEquation) {
                    return WidgetSpan(
                      child: Math.tex(p.content, textStyle: style),
                      alignment: PlaceholderAlignment.middle,
                    );
                  } else {
                    return TextSpan(text: p.content);
                  }
                }).toList(),
              ),
            ),
          );
          currentTextParts = [];
        }

        // Add the display mode equation
        result.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Math.tex(
              part.content,
              textStyle: style,
            ),
          ),
        );
      } else {
        // Accumulate text parts
        currentTextParts.add(part);
      }
    }

    // Add any remaining text parts
    if (currentTextParts.isNotEmpty) {
      result.add(
        RichText(
          text: TextSpan(
            style: style,
            children: currentTextParts.map((p) {
              if (p.isEquation) {
                return WidgetSpan(
                  child: Math.tex(p.content, textStyle: style),
                  alignment: PlaceholderAlignment.middle,
                );
              } else {
                return TextSpan(text: p.content);
              }
            }).toList(),
          ),
        ),
      );
    }

    return result;
  }

  /// Builds inline text spans for text with only inline equations.
  List<InlineSpan> _buildInlineTextSpans(List<TextPart> parts, BuildContext context) {
    final spans = <InlineSpan>[];

    for (final part in parts) {
      if (part.isEquation) {
        spans.add(
          WidgetSpan(
            child: Math.tex(
              part.content,
              textStyle: style,
            ),
            alignment: PlaceholderAlignment.middle,
          ),
        );
      } else {
        spans.add(TextSpan(text: part.content));
      }
    }

    return spans;
  }
}

/// Represents a part of text that can be either plain text or an equation.
class TextPart {
  final String content;
  final bool isEquation;
  final bool isDisplayMode;

  TextPart(this.content, this.isEquation, this.isDisplayMode);
}
