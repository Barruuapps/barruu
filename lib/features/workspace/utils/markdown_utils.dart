import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';

/// Utility class for rendering markdown text inline within other widgets
class MarkdownUtils {
  /// Parse markdown text and return a TextSpan with proper formatting
  /// Supports: **bold**, *italic*, ***bold+italic***, [links](url), and plain URLs
  static Widget buildMarkdownText(
    String text,
    TextStyle baseStyle, {
    Color? linkColor,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (text.isEmpty) {
      return Text('', style: baseStyle);
    }

    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        a: baseStyle.copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
        ),
      ),
      selectable: true,
      onTapLink: (text, href, title) async {
        if (href != null) {
          await LinkUtils.launchURL(href);
        }
      },
    );
  }

  /// Parse markdown and return InlineSpan for use in RichText
  /// This is a simplified version that handles basic formatting
  static InlineSpan parseMarkdownToSpan(
    String text,
    TextStyle baseStyle, {
    Color? linkColor,
  }) {
    if (text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // For complex markdown rendering in RichText context, we use a custom parser
    // that handles the most common cases: bold, italic, and links
    return _parseSimpleMarkdown(text, baseStyle, linkColor);
  }

  /// Simple markdown parser for inline spans
  static InlineSpan _parseSimpleMarkdown(
    String text,
    TextStyle baseStyle,
    Color? linkColor,
  ) {
    final spans = <InlineSpan>[];
    final patterns = [
      // Bold and italic: ***text***
      _MarkdownPattern(
        RegExp(r'\*\*\*(.+?)\*\*\*'),
        (match, style) => TextSpan(
          text: match.group(1),
          style: style.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      // Bold: **text**
      _MarkdownPattern(
        RegExp(r'\*\*(.+?)\*\*'),
        (match, style) => TextSpan(
          text: match.group(1),
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      // Italic: *text*
      _MarkdownPattern(
        RegExp(r'\*(.+?)\*'),
        (match, style) => TextSpan(
          text: match.group(1),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ),
      ),
      // Links: [text](url)
      _MarkdownPattern(
        RegExp(r'\[(.+?)\]\((.+?)\)'),
        (match, style) => WidgetSpan(
          child: GestureDetector(
            onTap: () {
              final url = match.group(2);
              if (url != null) {
                LinkUtils.launchURL(url);
              }
            },
            child: Text(
              match.group(1) ?? '',
              style: style.copyWith(
                color: linkColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    ];

    int currentPos = 0;

    while (currentPos < text.length) {
      bool foundPattern = false;

      for (final pattern in patterns) {
        final match = pattern.regex.matchAsPrefix(text, currentPos);
        if (match != null) {
          spans.add(pattern.builder(match, baseStyle));
          currentPos = match.end;
          foundPattern = true;
          break;
        }
      }

      if (!foundPattern) {
        // Find the next markdown character
        int nextPos = text.length;
        for (int i = currentPos + 1; i < text.length; i++) {
          if (text[i] == '*' || text[i] == '[') {
            nextPos = i;
            break;
          }
        }

        spans.add(
          TextSpan(text: text.substring(currentPos, nextPos), style: baseStyle),
        );
        currentPos = nextPos;
      }
    }

    return TextSpan(
      children: spans.isEmpty
          ? [TextSpan(text: text, style: baseStyle)]
          : spans,
    );
  }
}

/// Helper class for markdown pattern matching
class _MarkdownPattern {
  final RegExp regex;
  final InlineSpan Function(Match match, TextStyle style) builder;

  _MarkdownPattern(this.regex, this.builder);
}
