import 'package:flutter/material.dart';

/// Widget for displaying or editing an image caption.
///
/// In edit mode, shows a text field for entering a caption.
/// In read mode, displays the caption text if it exists.
///
/// Example:
/// ```dart
/// ImageCaptionWidget(
///   theme: theme,
///   isEditing: isEditing,
///   caption: caption,
///   controller: captionController,
///   onChanged: (value) => updateCaption(value),
/// )
/// ```
class ImageCaptionWidget extends StatelessWidget {
  final ThemeData theme;
  final bool isEditing;
  final String caption;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const ImageCaptionWidget({
    super.key,
    required this.theme,
    required this.isEditing,
    required this.caption,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: isEditing
          ? TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onChanged: onChanged,
            )
          : caption.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    caption,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
