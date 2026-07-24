
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// Shared styling constants and helpers for code blocks (reader and writer).
abstract final class CodeBlockStyle {
  // Dark-mode palette
  static const Color darkBackground = Color(0xFF1E1E2E);
  static const Color darkHeader = Color(0xFF2A2A3C);
  static const Color darkBorder = Color(0xFF3A3A4C);

  // Light-mode palette
  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightHeader = Color(0xFFEAECF0);
  static const Color lightBorder = Color(0xFFD0D7DE);

  /// Returns the main code area background based on brightness.
  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;

  /// Returns the header bar background based on brightness.
  static Color header(Brightness brightness) =>
      brightness == Brightness.dark ? darkHeader : lightHeader;

  /// Returns the border/divider color based on brightness.
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  /// Platform-appropriate monospace font family.
  static String get fontFamily =>
      PlatformThemeHelper.isApplePlatform ? 'SF Mono' : 'monospace';

  /// Shared text style for code content.
  static TextStyle codeTextStyle() => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.6,
        fontWeight: FontWeight.w600,
      );

  /// Shared [GutterStyle] for line numbers.
  static GutterStyle gutterStyle(Color lineNumberColor) => GutterStyle(
        showLineNumbers: true,
        showErrors: false,
        showFoldingHandles: false,
        width: 48,
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: lineNumberColor,
        ),
      );
}
