/// Application-wide constants
///
/// Contains configuration values and settings used throughout the application.
class AppConstants {
  /// Application name displayed to users
  static const String appName = 'Barruu';

  /// Short description of the application
  static const String appDescription =
      'Professional social media for expertise and knowledge sharing';

  /// Application tagline
  static const String appTagline = 'Share what you know. Build credibility.';

  /// Application version for tracking
  static const String appVersion = '1.0.1+7';

  /// Base URL for the web application
  static const String webBaseUrl = 'https://barruu.app';

  /// Maximum file size for uploads (in bytes) - 100MB
  static const int maxFileSize = 100 * 1024 * 1024;

  /// Maximum image dimensions for thumbnails
  static const int maxThumbnailWidth = 400;
  static const int maxThumbnailHeight = 400;

  /// Auto-save interval in milliseconds
  static const int autoSaveInterval = 3000; // 3 seconds

  /// Maximum undo history size
  static const int maxUndoHistorySize = 50;

  /// Pagination page size for document lists
  static const int documentsPageSize = 20;

  /// Cache duration in hours
  static const int cacheExpirationHours = 24;
}
