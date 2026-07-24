import 'package:flutter/material.dart';

/// Widget for image editing controls (add, remove, rotate).
///
/// Displays a row of icon buttons for managing images in edit mode.
/// Positioned at the bottom-right of the image container.
///
/// Example:
/// ```dart
/// ImageEditControlsWidget(
///   theme: theme,
///   hasImages: hasImages,
///   onRemove: () => removeCurrentImage(),
///   onAddLocal: () => pickLocalImages(),
///   onAddNetwork: () => toggleUrlInput(),
///   onRotate: () => rotateImage(),
/// )
/// ```
class ImageEditControlsWidget extends StatelessWidget {
  final ThemeData theme;
  final bool hasImages;
  final VoidCallback onRemove;
  final VoidCallback onAddLocal;
  final VoidCallback onAddNetwork;
  final VoidCallback? onRotate;

  const ImageEditControlsWidget({
    super.key,
    required this.theme,
    required this.hasImages,
    required this.onRemove,
    required this.onAddLocal,
    required this.onAddNetwork,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImages)
            IconButton(
              icon: Icon(Icons.delete, color: theme.colorScheme.error),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(8),
              ),
              tooltip: 'Remove current image',
              onPressed: onRemove,
            ),
          if (hasImages) const SizedBox(width: 8),
          // Add local image
          IconButton(
            icon: Icon(
              Icons.add_photo_alternate,
              color: theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(8),
            ),
            tooltip: 'Add local images',
            onPressed: onAddLocal,
          ),
          const SizedBox(width: 8),
          // Add network image
          IconButton(
            icon: Icon(Icons.link, color: theme.colorScheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(8),
            ),
            tooltip: 'Add image from URL',
            onPressed: onAddNetwork,
          ),
          if (hasImages && onRotate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.rotate_right, color: theme.colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(8),
              ),
              tooltip: 'Rotate image',
              onPressed: onRotate,
            ),
          ],
        ],
      ),
    );
  }
}
