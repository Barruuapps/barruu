import 'package:flutter/material.dart';

/// Constants for styling configurations
class StyleConstants {
  static const listTypes = [
    ListType.numbered,
    ListType.roman,
    ListType.alpha,
    ListType.alphaLower,
    ListType.bulleted,
    ListType.custom,
  ];

  // Common emojis for list markers
  static const commonListEmojis = [
    '🔹', '✓', '✔', '➤', '➢', '⭐', '🔥', '💡', '📌', '🎯',
    '🔸', '🔶', '🔷', '💎', '🌟', '✨', '🎨', '🎵', '📝', '📍',
    '🏁', '🚀', '💯', '👍', '❤️', '💚', '💙', '💜', '🖤', '🤍',
  ];

  static const fontStyles = {
    FontStyleType.normal: 'Normal',
    FontStyleType.bold: 'Bold',
    FontStyleType.italic: 'Italic',
    FontStyleType.boldItalic: 'Bold Italic',
  };

  static const textAligns = {
    'left': TextAlign.left,
    'center': TextAlign.center,
    'right': TextAlign.right,
    'justify': TextAlign.justify,
  };
}

/// Enum for list types
enum ListType {
  numbered('numbered', 'Numbered 1. 2. 3.'),
  roman('roman', 'Roman I. II. III.'),
  alpha('alpha', 'Alpha A. B. C.'),
  alphaLower('alpha-lower', 'Alpha (a. b. c.)'),
  bulleted('bulleted', 'Bulleted •'),
  custom('custom', 'Custom Emoji/Icon');

  final String value;
  final String displayName;

  const ListType(this.value, this.displayName);
}

/// Enum for font styles
enum FontStyleType {
  normal('normal'),
  bold('bold'),
  italic('italic'),
  boldItalic('bold italic');

  final String value;

  const FontStyleType(this.value);
}