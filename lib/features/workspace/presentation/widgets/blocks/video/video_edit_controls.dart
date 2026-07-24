import 'package:flutter/material.dart';

/// Overlay controls for video editing actions.
///
/// Provides buttons for:
/// - Add from gallery
/// - Add from URL
/// - Rotate video (only shown if video exists)
///
/// Example:
/// ```dart
/// VideoEditControls(
///   theme: theme,
///   hasVideo: true,
///   onGalleryTap: () => pickFromGallery(),
///   onUrlTap: () => toggleUrlInput(),
///   onRotateTap: () => rotateVideo(),
/// )
/// ```
class VideoEditControls extends StatelessWidget {
  final ThemeData theme;
  final bool hasVideo;
  final VoidCallback onGalleryTap;
  final VoidCallback onUrlTap;
  final VoidCallback? onRotateTap;

  const VideoEditControls({
    required this.theme,
    required this.hasVideo,
    required this.onGalleryTap,
    required this.onUrlTap,
    this.onRotateTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add from gallery
            IconButton(
              icon: Icon(Icons.video_library, color: theme.colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.all(12),
              ),
              tooltip: 'Add from gallery',
              onPressed: onGalleryTap,
            ),
            const SizedBox(width: 8),
            // Add from URL
            IconButton(
              icon: Icon(Icons.link, color: theme.colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.all(12),
              ),
              tooltip: 'Add from URL or YouTube',
              onPressed: onUrlTap,
            ),
            if (hasVideo && onRotateTap != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.rotate_right,
                  color: theme.colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Rotate video',
                onPressed: onRotateTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
