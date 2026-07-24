import 'package:flutter/material.dart';

/// Widget for inputting video URL (YouTube or direct video URL).
///
/// Features:
/// - Text field for URL entry
/// - Submit and cancel buttons
/// - Helper text showing supported URLs
///
/// Example:
/// ```dart
/// VideoUrlInputWidget(
///   controller: urlController,
///   onSubmit: (url) => addVideoFromUrl(url),
///   onCancel: () => hideUrlInput(),
/// )
/// ```
class VideoUrlInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final ThemeData theme;

  const VideoUrlInputWidget({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supports YouTube URLs and direct video URLs',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter video URL...',
                    prefixIcon: const Icon(Icons.link, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
              IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
            ],
          ),
        ],
      ),
    );
  }
}
