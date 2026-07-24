import 'package:flutter/material.dart';

/// Widget for editing or displaying video caption.
///
/// In edit mode: Shows TextField for caption input
/// In read mode: Shows caption text or nothing if empty
///
/// Example:
/// ```dart
/// VideoCaptionWidget(
///   controller: captionController,
///   isEditing: true,
///   caption: 'Video caption',
///   theme: theme,
///   onChanged: (value) => updateCaption(value),
/// )
/// ```
class VideoCaptionWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final String caption;
  final ThemeData theme;
  final ValueChanged<String> onChanged;

  const VideoCaptionWidget({
    required this.controller,
    required this.isEditing,
    required this.caption,
    required this.theme,
    required this.onChanged,
    super.key,
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
