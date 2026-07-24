import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barruu/features/workspace/utils/markdown_utils.dart';

/// Utility class for handling links in text content
class LinkUtils {
  /// Parse text and return TextSpan with clickable links and markdown formatting
  /// Supports: **bold**, *italic*, ***bold+italic***, [links](url), and plain URLs
  static InlineSpan parseTextWithLinks(
    String text,
    TextStyle baseStyle,
    TextStyle linkStyle,
    Color hoverColor,
  ) {
    // Use the MarkdownUtils which uses flutter_markdown package
    return MarkdownUtils.parseMarkdownToSpan(
      text,
      baseStyle,
      linkColor: linkStyle.color ?? hoverColor,
    );
  }

  /// Check if a string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Launch a URL
  static Future<bool> launchURL(String url) async {
    if (!isValidUrl(url)) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      // Try to launch URL with platformDefault mode first, fallback to externalApplication
      return await launchUrl(
        uri,
      );
    } catch (e) {
      // If platformDefault fails, try with externalApplication
      try {
        final uri = Uri.parse(url);
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        return false;
      }
    }
  }
}
