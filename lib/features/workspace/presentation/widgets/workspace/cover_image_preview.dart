import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// A widget that displays a preview of a cover image in the edit dialog.
/// 
/// Shows a small thumbnail of the selected image with optional filename
/// overlay. Falls back to app logo if image is not available or on web.
class CoverImagePreview extends StatelessWidget {
  /// The image file to preview
  final File? image;
  
  /// The original filename of the image
  final String? originalName;
  
  /// The theme to use for styling
  final ThemeData theme;

  const CoverImagePreview({
    super.key,
    required this.image,
    required this.originalName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image != null && !kIsWeb
                ? Image.file(
              image!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                logger.w('Failed to load cover: ${image!.path}', error: error);
                return Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                );
              },
            )
                : Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
          if (originalName != null && originalName!.isNotEmpty)
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  originalName!.length > 20 ? '${originalName!.substring(0, 17)}...' : originalName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
