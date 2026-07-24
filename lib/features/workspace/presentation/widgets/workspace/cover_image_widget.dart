import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// A widget that displays a cover image for a document.
/// 
/// Supports three types of images:
/// - Network images (from URLs)
/// - Local file images
/// - Default app logo fallback
/// 
/// The widget handles loading states and errors gracefully,
/// always falling back to the default app logo if the image
/// cannot be loaded.
class CoverImageWidget extends StatelessWidget {
  /// The URL or path to the cover image
  final String? coverImageUrl;
  
  /// The theme to use for styling
  final ThemeData theme;

  const CoverImageWidget({
    super.key,
    required this.coverImageUrl,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Show default logo if no cover image or on web
    if (coverImageUrl == null || coverImageUrl!.isEmpty || kIsWeb) {
      return _buildDefaultCover();
    }

    // Handle network images
    if (coverImageUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: coverImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: double.infinity,
          color: theme.colorScheme.surfaceContainerLowest,
          child: Center(
            child: ShimmerCircularProgress(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          logger.w('Failed to load network image: $coverImageUrl', error: error);
          return _buildDefaultCover();
        },
      );
    }

    // Handle local file images
    return Image.file(
      File(coverImageUrl!),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        logger.w('Failed to load local image: $coverImageUrl', error: error);
        return _buildDefaultCover();
      },
    );
  }

  /// Builds the default cover with app logo and gradient background
  Widget _buildDefaultCover() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
