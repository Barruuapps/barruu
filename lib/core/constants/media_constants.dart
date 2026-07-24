/// Constants for media optimization and caching
///
/// These values are used across the application to ensure consistent
/// memory management and performance optimization for images and videos.
class MediaConstants {
  /// Maximum width for cached images (in pixels)
  ///
  /// This limit prevents excessive memory usage by constraining the
  /// cache size for both network and local images.
  static const int maxImageCacheWidth = 1200;

  /// Maximum height for cached images (in pixels)
  ///
  /// This limit prevents excessive memory usage by constraining the
  /// cache size for both network and local images.
  static const int maxImageCacheHeight = 1200;

  /// Default visibility threshold for lazy loading (0.0 to 1.0)
  ///
  /// A value of 0.1 means content loads when 10% is visible.
  /// Lower values cause earlier loading, higher values delay loading.
  static const double defaultLazyLoadThreshold = 0.1;

  /// Maximum cache size for image memory (in pixels)
  ///
  /// Combined limit for width/height to prevent memory issues.
  static const int maxImageCacheSize = 1200;

  /// Minimum cache size for images (in pixels)
  ///
  /// Ensures images are at least rendered at a minimum quality.
  static const int minImageCacheSize = 1;

  // Prevent instantiation
  MediaConstants._();
}
