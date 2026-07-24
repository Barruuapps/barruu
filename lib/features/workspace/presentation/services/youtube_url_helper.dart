import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Helper class for YouTube URL detection and video ID extraction.
///
/// Provides enhanced YouTube URL detection that handles various URL formats
/// including youtube-nocookie.com and other variations that the standard
/// YoutubePlayer.convertUrlToId() might miss.
class YouTubeUrlHelper {
  /// Extracts YouTube video ID from a YouTube URL.
  ///
  /// Supports various YouTube URL formats including:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://www.youtube-nocookie.com/embed/VIDEO_ID
  /// - https://m.youtube.com/watch?v=VIDEO_ID
  ///
  /// Examples:
  /// ```dart
  /// final id = YouTubeUrlHelper.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  /// print(id); // Output: dQw4w9WgXcQ
  ///
  /// final id2 = YouTubeUrlHelper.extractVideoId('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ');
  /// print(id2); // Output: dQw4w9WgXcQ
  /// ```
  ///
  /// Returns null if the URL is not a valid YouTube URL.
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;
    
    // First try the built-in converter
    final convertedId = YoutubePlayer.convertUrlToId(url);
    if (convertedId != null && convertedId.isNotEmpty) {
      return convertedId;
    }
    
    // Handle additional YouTube URL formats not covered by the converter
    // This includes youtube-nocookie.com and other variations
    // Patterns allow for query parameters (?), fragments (#), or end of string ($)
    final regexPatterns = [
      // youtube-nocookie.com embed URLs
      RegExp(r'youtube-nocookie\.com/embed/([a-zA-Z0-9_-]{11})(?:\?|#|&|$)', caseSensitive: false),
      // Standard youtube.com URLs (fallback if converter failed)
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})(?:&|#|$)', caseSensitive: false),
      // youtu.be short URLs (fallback) - CRITICAL: Must handle query params like ?si=...
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})(?:\?|#|$)', caseSensitive: false),
      // youtube.com embed URLs (fallback)
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})(?:\?|#|&|$)', caseSensitive: false),
      // youtube.com/v/ URLs
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})(?:\?|#|&|$)', caseSensitive: false),
    ];
    
    for (final pattern in regexPatterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final videoId = match.group(1);
        // YouTube video IDs are always exactly 11 characters
        // This is a defensive check even though the regex already enforces this
        if (videoId != null && videoId.length == 11) {
          return videoId;
        }
      }
    }
    
    return null;
  }

  /// Checks if a URL is a YouTube URL.
  ///
  /// Returns true if the URL can be identified as a YouTube URL,
  /// false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final isYouTube = YouTubeUrlHelper.isYouTubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  /// print(isYouTube); // Output: true
  /// ```
  static bool isYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }
}
