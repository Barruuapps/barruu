import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/string_utils.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages document metadata operations.
///
/// This service handles:
/// - Reading and writing document metadata files
/// - Batch metadata loading for performance
/// - Document information updates
/// - Cover image management
/// - Security validation for metadata access
///
/// All metadata is stored in meta.json files within document directories.
class DocumentMetadataService {
  /// Validates if a directory is within the app's document directory.
  ///
  /// This is a security check to ensure operations only happen within
  /// the app's sandboxed storage area.
  ///
  /// Parameters:
  /// - [dir]: Directory to validate
  /// - [appDocDir]: The app's document directory
  ///
  /// Returns true if the directory is within app boundaries.
  bool isValidDocumentDirectory(Directory dir, Directory appDocDir) {
    final normalizedDir = dir.absolute.path;
    final normalizedAppDir = appDocDir.absolute.path;
    return normalizedDir.startsWith(normalizedAppDir);
  }

  /// Gets document metadata.
  ///
  /// Reads the meta.json file from a document directory and returns
  /// its contents as a map.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  ///
  /// Returns a map of metadata, or null if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The metadata file doesn't exist
  /// - An error occurs reading the file
  Future<Map<String, dynamic>?> getDocumentMetadata(Directory doc) async {
    try {
      if (kIsWeb) {
        logger.w('Metadata retrieval not supported on web');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!isValidDocumentDirectory(doc, appDir)) {
        logger.e('Attempt to access directory outside app boundaries: ${doc.path}');
        return null;
      }

      final metaDb = File('${doc.path}/${MetaFile.fileName}');
      if (!await metaDb.exists()) {
        logger.w('Metadata file not found: ${metaDb.path}');
        return null;
      }

      final metaJson = await metaDb.readAsString();
      final result = jsonDecode(metaJson) as Map<String, dynamic>;
      logger.i('Retrieved metadata for: ${doc.path}');
      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to retrieve metadata: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Batch loads metadata for multiple documents efficiently.
  ///
  /// This method loads metadata for multiple documents in parallel,
  /// which is much faster than loading them sequentially.
  ///
  /// Parameters:
  /// - [docs]: List of document directories to load metadata for
  ///
  /// Returns a map from directory to metadata. Documents that fail
  /// to load are excluded from the result.
  Future<Map<Directory, Map<String, dynamic>>> batchGetDocumentMetadata(
      List<Directory> docs) async {
    final results = <Directory, Map<String, dynamic>>{};

    if (kIsWeb) {
      logger.w('Batch metadata retrieval not supported on web');
      return results;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Process all documents in parallel for better performance
      await Future.wait(
        docs.map((doc) async {
          try {
            if (!isValidDocumentDirectory(doc, appDir)) {
              logger.w('Skipping invalid directory: ${doc.path}');
              return;
            }

            final metaDb = File('${doc.path}/${MetaFile.fileName}');
            if (!await metaDb.exists()) {
              logger.w('Metadata file not found: ${metaDb.path}');
              return;
            }

            final metaJson = await metaDb.readAsString();
            final metadata = jsonDecode(metaJson) as Map<String, dynamic>;

            // Also get last modified timestamp
            final lastModified = await doc.stat().then((stat) => stat.modified);

            results[doc] = {
              ...metadata,
              'lastModified': lastModified,
            };
          } catch (e, stackTrace) {
            logger.e('Failed to load metadata for: ${doc.path}',
                error: e, stackTrace: stackTrace);
          }
        }),
      );

      logger.i('Batch loaded metadata for ${results.length} documents');
      return results;
    } catch (e, stackTrace) {
      logger.e('Failed to batch load metadata', error: e, stackTrace: stackTrace);
      return results;
    }
  }

  /// Updates document meta info.
  ///
  /// Updates the metadata file for a document with new information.
  /// Preserves creation date and author information.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [name]: New document name (required, cannot be empty)
  /// - [description]: New description
  /// - [tags]: New tags string
  /// - [coverPath]: Path to cover image
  /// - [coverOriginalName]: Original name of cover image file
  ///
  /// Returns true if the update succeeded, false otherwise.
  Future<bool> updateDocumentInfo(
    Directory doc,
    String name,
    String description,
    String tags,
    String coverPath, {
    String coverOriginalName = '',
  }) async {
    try {
      if (kIsWeb) {
        logger.w('Document update not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!isValidDocumentDirectory(doc, appDir)) {
        logger.e('Attempt to update directory outside app boundaries: ${doc.path}');
        return false;
      }

      if (!await doc.exists()) {
        logger.w('Document not found: ${doc.path}');
        return false;
      }

      if (name.trim().isEmpty) {
        logger.w('Document name cannot be empty');
        return false;
      }

      final existingMeta = await getDocumentMetadata(doc);
      final metaJson = {
        MetaFile.idKey:
            existingMeta?[MetaFile.idKey] ?? StringUtils.generateSafeId(),
        MetaFile.nameKey: StringUtils.limitLength(name.trim()),
        MetaFile.descriptionKey: StringUtils.limitLength(description),
        MetaFile.tagsKey: StringUtils.limitLength(tags),
        MetaFile.coverKey: coverPath,
        MetaFile.coverOriginalNameKey:
            StringUtils.limitLength(coverOriginalName),
        MetaFile.updatedAtKey: DateTime.now().toIso8601String(),
        MetaFile.authorKey: existingMeta?[MetaFile.authorKey] ?? 'Barruu',
        MetaFile.createdAtKey: existingMeta?[MetaFile.createdAtKey] ??
            DateTime.now().toIso8601String(),
      };

      await File('${doc.path}/${MetaFile.fileName}')
          .writeAsString(jsonEncode(metaJson));
      logger.i('Updated document info: ${doc.path}');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to update document info: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Writes metadata to a document directory.
  ///
  /// This is a lower-level method used during document creation
  /// and import operations.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [metadata]: The metadata map to write
  ///
  /// Returns true if the write succeeded, false otherwise.
  Future<bool> writeDocumentMetadata(
    Directory doc,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await File('${doc.path}/${MetaFile.fileName}')
          .writeAsString(jsonEncode(metadata));
      logger.i('Wrote metadata for: ${doc.path}');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to write metadata: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
