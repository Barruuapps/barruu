import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/style_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for style utilities
final styleUtilsProvider = Provider<StyleUtils>((ref) {
  return StyleUtils();
});

class StyleUtils {
  Color? parseHex(String? hex) => hex == null || hex.isEmpty
      ? null
      : Color(int.parse(hex.replaceFirst('#', '0xff')));

  String toHex(Color c) {
    final v = c.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${v.substring(2)}';
  }

  /// Applies responsive text styling
  TextStyle applyStyle(BlockStyle style, {BuildContext? context}) {
    double fontSize = style.fontSize;

    if (context != null) {
      final width = MediaQuery.of(context).size.width;
      final isWide = width > 600;

      /// Scale font size based on screen width
      fontSize = isWide ? fontSize * 1.2 : fontSize;
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.w400,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        if (style.underline) TextDecoration.underline,
        if (style.strikethrough) TextDecoration.lineThrough,
      ]),
      color: parseHex(style.color),
      backgroundColor: parseHex(style.background),
      fontFamily: style.fontFamily,
    );
  }

  TextAlign textAlignFromStyle(BlockStyle style) {
    return StyleConstants.textAligns[style.align] ?? TextAlign.left;
  }

  double dividerThicknessFromStyle(BlockStyle style) =>
      (style.fontSize / 10).clamp(1.0, 12.0);

  // New method to get default style
  BlockStyle getDefaultStyle() {
    return const BlockStyle(color: '#000000');
  }

  // New method to merge styles
  BlockStyle mergeStyles(BlockStyle baseStyle, BlockStyle newStyle) {
    return baseStyle.copyWith(
      bold: newStyle.bold,
      italic: newStyle.italic,
      underline: newStyle.underline,
      strikethrough: newStyle.strikethrough,
      align: newStyle.align,
      color: newStyle.color,
      background: newStyle.background,
      fontSize: newStyle.fontSize,
      fontFamily: newStyle.fontFamily,
      borderColor: newStyle.borderColor,
      language: newStyle.language,
      listType: newStyle.listType,
      headerStyle: newStyle.headerStyle,
      customIcon: newStyle.customIcon,
      width: newStyle.width,
      height: newStyle.height,
      rotation: newStyle.rotation,
      useAppBackground: newStyle.useAppBackground,
    );
  }
}

// Extension for easy access to style utils
extension StyleUtilsExtension on WidgetRef {
  StyleUtils get styleUtils => read(styleUtilsProvider);
}

// Extension for easy access to style utils from BuildContext
extension StyleUtilsContextExtension on BuildContext {
  StyleUtils styleUtils(WidgetRef ref) => ref.read(styleUtilsProvider);
}
