import 'package:flutter/material.dart';

/// Widget for entering a network image URL.
///
/// Displays a text field with submit and cancel buttons for adding
/// images from URLs.
///
/// Example:
/// ```dart
/// ImageUrlInputWidget(
///   theme: theme,
///   controller: urlController,
///   onSubmit: (url) => addNetworkImage(url),
///   onCancel: () => hideUrlInput(),
/// )
/// ```
class ImageUrlInputWidget extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  const ImageUrlInputWidget({
    super.key,
    required this.theme,
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter image URL...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => onSubmit(controller.text),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
