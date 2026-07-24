import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for validating and sanitizing media file paths.
///
/// Provides utilities for:
/// - Validating media paths for security
/// - Sanitizing file names
/// - Resolving relative paths
/// - Checking file operation support
class MediaPathValidator {
  final Directory docDir;

  /// Maximum file name length to prevent filesystem issues.
  /// Many filesystems have a 255-byte limit, we use 245 to leave room for extensions.
  static const int maxFileNameLength = 245;

  MediaPathValidator(this.docDir);

  /// Checks if file operations are supported on the current platform.
  ///
  /// Returns false on web platform, true otherwise.
  bool get isFileOperationSupported {
    if (kIsWeb) {
      logger.w('File operations not supported on web');
      return false;
    }
    return true;
  }

  /// Limits the length of a string to prevent filesystem issues.
  ///
  /// [input] - The string to limit
  /// [maxLength] - Maximum length (default: maxFileNameLength)
  ///
  /// Returns the input string truncated to maxLength if necessary.
  String limitLength(String input, {int maxLength = maxFileNameLength}) {
    return input.length > maxLength ? input.substring(0, maxLength) : input;
  }

  /// Sanitizes a file name by removing invalid characters.
  ///
  /// Removes characters that are not allowed in file names:
  /// < > : " / \ | ? *
  ///
  /// Also limits the length to prevent filesystem issues.
  ///
  /// [fileName] - The file name to sanitize
  ///
  /// Returns a sanitized file name safe for all filesystems.
  String sanitizeFileName(String fileName) {
    return limitLength(fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_'));
  }

  /// Validates that a media file path is within allowed directories.
  ///
  /// Security checks:
  /// - Rejects paths containing '..' (directory traversal)
  /// - Ensures path is within document's media directory
  /// - Ensures path is within application documents directory
  ///
  /// [filePath] - The file path to validate (can be relative or absolute)
  ///
  /// Returns true if the path is valid and secure, false otherwise.
  Future<bool> isValidMediaPath(String filePath) async {
    if (filePath.contains('..')) {
      logger.w('Invalid media path (contains ..): $filePath');
      return false;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${docDir.path}/media');
    final normalizedFilePath = File(filePath).absolute.path;
    final normalizedMediaDir = mediaDir.absolute.path;
    return normalizedFilePath.startsWith(normalizedMediaDir) &&
        normalizedFilePath.startsWith(appDir.absolute.path);
  }

  /// Resolves a relative path to an absolute path within the document directory.
  ///
  /// [relativePath] - The relative path to resolve
  ///
  /// Returns the absolute path, or empty string if input is empty.
  String resolveRelativePath(String relativePath) {
    if (relativePath.isEmpty) return '';
    return '${docDir.path}/$relativePath';
  }
}
