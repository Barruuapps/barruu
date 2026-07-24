import 'package:flutter/material.dart';

/// Bottom sheet dialog for selecting video source.
///
/// Provides options for:
/// - Choosing from gallery
/// - Adding via URL (YouTube or direct video URL)
///
/// Example:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (context) => VideoSourceDialog(
///     onGallerySelected: () => pickFromGallery(),
///     onUrlSelected: () => showUrlInput(),
///   ),
/// );
/// ```
class VideoSourceDialog extends StatelessWidget {
  final VoidCallback onGallerySelected;
  final VoidCallback onUrlSelected;

  const VideoSourceDialog({
    required this.onGallerySelected,
    required this.onUrlSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.video_library, color: theme.colorScheme.primary),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select a video from your device'),
              onTap: () {
                Navigator.pop(context);
                onGallerySelected();
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: theme.colorScheme.secondary),
              title: const Text('Video URL'),
              subtitle: const Text('YouTube link or direct video URL'),
              onTap: () {
                Navigator.pop(context);
                onUrlSelected();
              },
            ),
          ],
        ),
      ),
    );
  }
}
