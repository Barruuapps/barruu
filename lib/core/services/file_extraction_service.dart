import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';

/// Service for extracting text content from various file formats
/// 
/// Supports:
/// - Text files (.txt)
/// - Future: PDF files (.pdf) with text extraction library
/// - Future: Word documents (.docx)
class FileExtractionService {
  /// Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
  
  /// Bytes per megabyte
  static const int bytesPerMB = 1024 * 1024;
  
  /// Extract text from a file based on its extension
  /// 
  /// Parameters:
  /// - [file]: The file to extract text from
  /// 
  /// Returns the extracted text content, or null if extraction fails
  /// 
  /// Throws:
  /// - [FileExtractionException] if file is too large or format is unsupported
  Future<String?> extractTextFromFile(File file) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw FileExtractionException(
          'File is too large. Maximum size is ${maxFileSize ~/ bytesPerMB}MB'
        );
      }
      
      final extension = file.path.split('.').last.toLowerCase();
      
      switch (extension) {
        case 'txt':
          return await _extractFromTxt(file);
        case 'pdf':
          throw FileExtractionException(
            'PDF text extraction is not yet supported. Please use a text file (.txt) or convert your PDF to text format first.'
          );
        default:
          throw FileExtractionException(
            'Unsupported file format: .$extension. Currently supported: .txt'
          );
      }
    } catch (e, stackTrace) {
      logger.e('Failed to extract text from file: ${file.path}', 
        error: e, stackTrace: stackTrace);
      
      if (e is FileExtractionException) {
        rethrow;
      }
      
      return null;
    }
  }
  

  /// Extract text from a plain text file
  Future<String?> _extractFromTxt(File file) async {
    try {
      final content = await file.readAsString();
      
      if (content.trim().isEmpty) {
        logger.w('Text file is empty');
        return null;
      }
      
      logger.i('Successfully extracted ${content.length} characters from text file');
      return content;
    } catch (e, stackTrace) {
      logger.e('Failed to read text file', error: e, stackTrace: stackTrace);
      throw FileExtractionException('Failed to read text file: $e');
    }
  }
  
  /// Get a user-friendly error message for common issues
  String getErrorMessage(Object error) {
    if (error is FileExtractionException) {
      return error.message;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied. Please check file permissions.';
    }
    
    if (errorString.contains('not found') || errorString.contains('no such file')) {
      return 'File not found. Please try selecting the file again.';
    }
    
    if (errorString.contains('format') || errorString.contains('corrupt')) {
      return 'File format error. The file may be corrupted or invalid.';
    }
    
    return 'Failed to process file. Please try a different file.';
  }
}

/// Exception thrown when file extraction fails
class FileExtractionException implements Exception {
  final String message;
  
  FileExtractionException(this.message);
  
  @override
  String toString() => message;
}
