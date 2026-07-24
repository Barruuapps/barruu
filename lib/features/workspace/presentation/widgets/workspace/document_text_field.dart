import 'package:flutter/material.dart';

/// A styled text field widget used in document dialogs.
///
/// Provides consistent styling for text input fields across
/// workspace dialogs, with support for multi-line input and
/// character limits.
class DocumentTextField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;

  /// The label text to display
  final String label;

  /// Optional hint text
  final String? hintText;

  /// Maximum character length
  final int maxLength;

  /// Maximum number of lines
  final int maxLines;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// The theme to use for styling
  final ThemeData theme;

  const DocumentTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.theme,
    this.hintText,
    this.maxLength = 200,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
