import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for image storage service
final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

/// Service for resolving image/icon URLs.
///
/// All new uploads use Cloudflare R2 and produce full HTTP URLs.
/// This service handles URL resolution for display, gracefully
/// ignoring any legacy non-URL references.
class ImageStorageService {
  /// Resolves an icon reference to a usable URL.
  /// Returns the value as-is when it is already an HTTP(S) URL,
  /// otherwise returns null (legacy R2 keys or obsolete Firebase IDs).
  Future<String?> resolveIconUrl(String? iconRef) async {
    if (iconRef == null || iconRef.isEmpty) {
      return null;
    }

    if (iconRef.startsWith('http')) {
      if (iconRef.contains('your-custom-domain.com')) {
        return null;
      }
      return iconRef;
    }

    logger.w('Cannot resolve non-URL icon reference: $iconRef');
    return null;
  }
}
