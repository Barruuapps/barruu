/// Utility class for formatting various types of data
class FormatUtils {
  // Private constructor to prevent instantiation
  FormatUtils._();

  /// Format bytes to human-readable file size
  /// 
  /// Examples:
  /// - 500 bytes -> "500 B"
  /// - 1500 bytes -> "1.5 KB"
  /// - 1500000 bytes -> "1.4 MB"
  /// - 1500000000 bytes -> "1.4 GB"
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';
    
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (bytes < kb) {
      return '$bytes B';
    } else if (bytes < mb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else if (bytes < gb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    }
  }

  /// Format download count to human-readable format
  /// 
  /// Examples:
  /// - 500 -> "500"
  /// - 1500 -> "1.5K"
  /// - 1500000 -> "1.5M"
  static String formatDownloads(int downloads) {
    if (downloads < 0) return '0';
    
    const int thousand = 1000;
    const int million = thousand * 1000;

    if (downloads < thousand) {
      return downloads.toString();
    } else if (downloads < million) {
      return '${(downloads / thousand).toStringAsFixed(1)}K';
    } else {
      return '${(downloads / million).toStringAsFixed(1)}M';
    }
  }

  /// Validate email format
  /// 
  /// Uses a more comprehensive regex pattern to validate email addresses
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // RFC 5322 Official Standard compliant email regex (simplified)
    final emailRegex = RegExp(
      "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\$",
    );
    
    return emailRegex.hasMatch(email);
  }
}
