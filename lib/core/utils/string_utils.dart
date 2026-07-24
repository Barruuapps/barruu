import 'package:uuid/uuid.dart';

/// Utility functions for string validation, sanitization, and transformation.
///
/// This class provides reusable validation and formatting methods to ensure
/// data consistency and security across the application, particularly for
/// filesystem operations and database storage.
class StringUtils {
  // Private constructor to prevent instantiation
  StringUtils._();

  static const Uuid _uuid = Uuid();

  /// Maximum safe length for file names and database fields to prevent issues.
  static const int defaultMaxLength = 245;

  /// Limits input length to prevent filesystem and database issues.
  ///
  /// [input] - The string to limit
  /// [maxLength] - Maximum allowed length (default: 245)
  ///
  /// Returns the truncated string if it exceeds maxLength, otherwise returns the original.
  ///
  /// Example:
  /// ```dart
  /// final limited = StringUtils.limitLength('Very long string...', maxLength: 10);
  /// // Returns: 'Very long '
  /// ```
  static String limitLength(String input, {int maxLength = defaultMaxLength}) {
    return input.length > maxLength ? input.substring(0, maxLength) : input;
  }

  /// Sanitizes a file name by removing or replacing invalid characters.
  ///
  /// Removes characters that are invalid in most filesystems: < > : " / \ | ? *
  /// Also limits the length to prevent filesystem issues.
  ///
  /// [fileName] - The file name to sanitize
  /// [maxLength] - Maximum allowed length (default: 245)
  ///
  /// Returns a safe file name that can be used in filesystem operations.
  ///
  /// Example:
  /// ```dart
  /// final safe = StringUtils.sanitizeFileName('My Document: Draft #1');
  /// // Returns: 'My Document_ Draft _1'
  /// ```
  static String sanitizeFileName(String fileName, {int maxLength = defaultMaxLength}) {
    final sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return limitLength(sanitized, maxLength: maxLength);
  }

  /// Generates a safe UUID for use in directory names and database keys.
  ///
  /// Replaces hyphens with underscores to ensure compatibility with
  /// various filesystem and naming constraints.
  ///
  /// Returns a UUID string with underscores instead of hyphens.
  ///
  /// Example:
  /// ```dart
  /// final id = StringUtils.generateSafeId();
  /// // Returns: '123e4567_e89b_12d3_a456_426614174000'
  /// ```
  static String generateSafeId() {
    return _uuid.v4().replaceAll('-', '_');
  }

  /// Checks if a string is null or empty.
  ///
  /// [value] - The string to check
  ///
  /// Returns true if the string is null or empty, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (StringUtils.isNullOrEmpty(userInput)) {
  ///   // Handle empty input
  /// }
  /// ```
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }

  /// Checks if a string is null, empty, or contains only whitespace.
  ///
  /// [value] - The string to check
  ///
  /// Returns true if the string is null, empty, or only whitespace, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (StringUtils.isNullOrWhitespace('   ')) {
  ///   // Returns true
  /// }
  /// ```
  static bool isNullOrWhitespace(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Trims a string and returns null if it's empty after trimming.
  ///
  /// [value] - The string to process
  ///
  /// Returns the trimmed string or null if empty/whitespace.
  ///
  /// Example:
  /// ```dart
  /// final result = StringUtils.trimOrNull('  hello  ');
  /// // Returns: 'hello'
  ///
  /// final empty = StringUtils.trimOrNull('   ');
  /// // Returns: null
  /// ```
  static String? trimOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Capitalizes the first letter of a string.
  ///
  /// [value] - The string to capitalize
  ///
  /// Returns the string with the first letter capitalized, or the original if empty.
  ///
  /// Example:
  /// ```dart
  /// final result = StringUtils.capitalize('hello world');
  /// // Returns: 'Hello world'
  /// ```
  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Converts a string to title case (capitalizes first letter of each word).
  ///
  /// [value] - The string to convert
  ///
  /// Returns the string in title case.
  ///
  /// Example:
  /// ```dart
  /// final result = StringUtils.toTitleCase('hello world');
  /// // Returns: 'Hello World'
  /// ```
  static String toTitleCase(String value) {
    if (value.isEmpty) return value;
    return value.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Extracts a file name without extension from a path.
  ///
  /// [filePath] - The file path or name
  ///
  /// Returns the file name without extension.
  ///
  /// Example:
  /// ```dart
  /// final name = StringUtils.getFileNameWithoutExtension('document.bipy');
  /// // Returns: 'document'
  /// ```
  static String getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /// Normalizes whitespace in a string (replaces multiple spaces with single space).
  ///
  /// [value] - The string to normalize
  ///
  /// Returns the string with normalized whitespace.
  ///
  /// Example:
  /// ```dart
  /// final result = StringUtils.normalizeWhitespace('hello    world');
  /// // Returns: 'hello world'
  /// ```
  static String normalizeWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Normalizes a title for display and storage.
  ///
  /// - Trims surrounding whitespace
  /// - Capitalizes the first letter
  /// - Limits length to [maxLength] characters (default: 100)
  ///
  /// [value] - The title string to normalize
  /// [maxLength] - Maximum allowed length (default: 100)
  ///
  /// Returns the normalized title.
  ///
  /// Example:
  /// ```dart
  /// final title = StringUtils.normalizeTitle('hello world post');
  /// // Returns: 'Hello world post'
  ///
  /// final long = StringUtils.normalizeTitle('a' * 200);
  /// // Returns: 'A' + 'a' * 99 (100 chars total)
  /// ```
  static String normalizeTitle(String value, {int maxLength = 100}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final limited = trimmed.length > maxLength
        ? trimmed.substring(0, maxLength)
        : trimmed;
    return limited[0].toUpperCase() + limited.substring(1);
  }
}
