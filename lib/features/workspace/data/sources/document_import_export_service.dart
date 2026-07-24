import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/string_utils.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/data/sources/encryption_service.dart';
import 'package:barruu/features/workspace/data/sources/document_metadata_service.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Manages document import and export operations.
///
/// This service handles:
/// - Exporting documents as encrypted .bipy files
/// - Importing documents from .bipy files
/// - File sharing
/// - Archive creation and extraction
/// - Legacy format migration during import
///
/// The .bipy format is a ZIP archive containing all document files,
/// encrypted with the app's encryption service.
class DocumentImportExportService {
  final EncryptionService _encryptionService;
  final DocumentMetadataService _metadataService;

  DocumentImportExportService(
    this._encryptionService,
    this._metadataService,
  );

  /// Validates if a directory is within the app's document directory.
  bool _isValidDocumentDirectory(Directory dir, Directory appDocDir) {
    final normalizedDir = dir.absolute.path;
    final normalizedAppDir = appDocDir.absolute.path;
    return normalizedDir.startsWith(normalizedAppDir);
  }

  /// Creates basic metadata map for imported documents
  Map<String, dynamic> _createBasicMetadata(
    String documentId,
    String documentName,
    Map<String, dynamic>? originalMetaData,
  ) {
    return {
      MetaFile.idKey: documentId,
      MetaFile.nameKey: documentName,
      MetaFile.descriptionKey: originalMetaData?[MetaFile.descriptionKey] ?? '',
      MetaFile.tagsKey: originalMetaData?[MetaFile.tagsKey] ?? '',
      MetaFile.coverKey: '',
      MetaFile.coverOriginalNameKey: '',
      MetaFile.createdAtKey: originalMetaData?[MetaFile.createdAtKey] ?? DateTime.now().toIso8601String(),
      MetaFile.updatedAtKey: DateTime.now().toIso8601String(),
      MetaFile.authorKey: originalMetaData?[MetaFile.authorKey] ?? 'Barruu',
      MetaFile.currentPageIdKey: originalMetaData?[MetaFile.currentPageIdKey] ?? PageConstants.defaultPageId,
    };
  }

  /// Shares an exported file.
  ///
  /// Uses the system share dialog to share a file.
  ///
  /// Parameters:
  /// - [filePath]: Path to the file to share
  ///
  /// Returns true if successful, false if:
  /// - Platform is web (not supported)
  /// - File path is invalid
  /// - An error occurs
  Future<bool> shareExportedFile(String filePath) async {
    try {
      if (kIsWeb) {
        logger.w('File sharing not supported on web');
        return false;
      }
      if (filePath.contains('..')) {
        logger.w('Invalid file path: $filePath');
        return false;
      }

      await Share.shareXFiles([XFile(filePath)], text: AppFile.shareMessage);
      logger.i('Shared file: $filePath');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to share file: $filePath',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Exports a document as an encrypted .bipy file.
  ///
  /// Creates a ZIP archive of all document files, encrypts it,
  /// and optionally shares it.
  ///
  /// Parameters:
  /// - [docDir]: The document directory to export
  /// - [shareAfter]: Whether to show share dialog after export (default: true)
  ///
  /// Returns the path to the exported file, or null if:
  /// - Platform is web (not supported)
  /// - Directory is invalid
  /// - Document doesn't exist
  /// - Document is empty
  /// - An error occurs
  Future<String?> exportDocumentEncrypted(Directory docDir,
      {bool shareAfter = true}) async {
    try {
      if (kIsWeb) {
        logger.w('Document export not supported on web');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(docDir, appDir)) {
        logger.e('Attempt to export directory outside app boundaries: ${docDir.path}');
        return null;
      }

      if (!await docDir.exists()) {
        logger.w('Document directory not found: ${docDir.path}');
        return null;
      }

      final files = <File>[];
      final entities = await docDir.list(recursive: true).toList();

      for (var entity in entities) {
        if (entity is File && !entity.path.contains('..')) {
          files.add(entity);
        }
      }

      if (files.isEmpty) {
        logger.w('Document folder is empty: ${docDir.path}');
        return null;
      }

      final archive = Archive();
      for (final file in files) {
        try {
          final relativePath = file.path.substring(docDir.path.length + 1);
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        } catch (e) {
          logger.w('Failed to add file to archive: ${file.path} - $e');
        }
      }

      final zipBytes = ZipEncoder().encode(archive);

      final finalBytes = await _encryptionService.encryptBipyBytes(zipBytes);

      final tempDir = await getTemporaryDirectory();
      final metadata = await _metadataService.getDocumentMetadata(docDir);
      final docName = metadata?[MetaFile.nameKey] as String? ?? 'document';
      final fileName = '${StringUtils.limitLength(docName)}.${AppFile.extension}';
      final tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(finalBytes, flush: true);

      if (shareAfter) {
        await shareExportedFile(tempFile.path);
      }

      logger.i('Exported document: ${tempFile.path}');
      return tempFile.path;
    } catch (e, stackTrace) {
      logger.e('Failed to export document: ${docDir.path}',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Imports a .bipy file using file picker.
  ///
  /// Shows a file picker dialog and imports the selected file.
  ///
  /// Parameters:
  /// - [getDocumentBlocks]: Function to get blocks from imported document
  /// - [saveDocumentBlocks]: Function to save normalized blocks
  ///
  /// Returns the imported document directory, or null if:
  /// - Platform is web (not supported)
  /// - No file selected
  /// - File is not a .bipy file
  /// - An error occurs
  ///
  /// This method delegates to [importDocumentFromBipyFile] for the actual import.
  Future<Directory?> importDocumentFromBipy({
    required Future<List<Block>> Function(Directory) getDocumentBlocks,
    required Future<bool> Function(Directory, List<Block>) saveDocumentBlocks,
  }) async {
    try {
      if (kIsWeb) {
        logger.w('Document import not supported on web');
        return null;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [AppFile.extension],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        logger.i('No file selected for import');
        return null;
      }

      final file = File(result.files.single.path!);
      if (!file.path.endsWith('.${AppFile.extension}')) {
        logger.w('Import file is not a .bipy file: ${file.path}');
        return null;
      }
      if (file.path.contains('..')) {
        logger.w('Invalid file path: ${file.path}');
        return null;
      }
      final fileName =
          result.files.single.name.replaceAll('.${AppFile.extension}', '');
      return await importDocumentFromBipyFile(
        file,
        fileName,
        getDocumentBlocks: getDocumentBlocks,
        saveDocumentBlocks: saveDocumentBlocks,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to import document', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Imports a .bipy file to a specific document name.
  ///
  /// Decrypts and extracts the .bipy file, normalizes block content,
  /// and creates a new document in the documents directory.
  ///
  /// This method handles:
  /// - Decryption with both new and legacy keys
  /// - Archive extraction
  /// - Block content normalization for media blocks
  /// - Metadata updates with new document ID
  /// - Path sanitization and security validation
  ///
  /// Parameters:
  /// - [bipyFile]: The .bipy file to import
  /// - [suggestedName]: Suggested name for the imported document
  /// - [getDocumentBlocks]: Function to get blocks from imported document
  /// - [saveDocumentBlocks]: Function to save normalized blocks
  ///
  /// Returns the imported document directory, or null if:
  /// - Platform is web (not supported)
  /// - File doesn't exist or is invalid
  /// - Decryption fails
  /// - An error occurs during extraction or normalization
  Future<Directory?> importDocumentFromBipyFile(
    File bipyFile,
    String suggestedName, {
    required Future<List<Block>> Function(Directory) getDocumentBlocks,
    required Future<bool> Function(Directory, List<Block>) saveDocumentBlocks,
  }) async {
    try {
      if (kIsWeb) {
        logger.w('Document import not supported on web');
        return null;
      }

      if (!await bipyFile.exists()) {
        logger.w('Import file not found: ${bipyFile.path}');
        return null;
      }

      if (!bipyFile.path.endsWith('.${AppFile.extension}')) {
        logger.w('Import file is not a .bipy file: ${bipyFile.path}');
        return null;
      }

      if (bipyFile.path.contains('..')) {
        logger.w('Invalid file path: ${bipyFile.path}');
        return null;
      }

      final allBytes = await bipyFile.readAsBytes();

      // Try decrypting with new app-wide key first, fallback to old device-specific key
      List<int> decrypted;
      try {
        decrypted = await _encryptionService.decryptBipyBytes(allBytes);
        logger.i('Successfully decrypted .bipy file with app-wide key');
      } catch (e) {
        logger.w('Failed to decrypt with app-wide key, trying device-specific key for backward compatibility');
        try {
          decrypted = await _encryptionService.decryptBytes(allBytes);
          logger.i('Successfully decrypted .bipy file with device-specific key (legacy format)');
        } catch (e2) {
          logger.e('Failed to decrypt .bipy file with both keys', error: e2);
          throw Exception('Failed to decrypt .bipy file. File may be corrupted or from an incompatible source.');
        }
      }

      // Try to decode the archive - will throw if not a valid ZIP
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(Uint8List.fromList(decrypted));
      } catch (e) {
        logger.e('Failed to load .bipy file - not a valid ZIP archive', error: e);
        rethrow;
      }

      String? originalDocumentId;
      String documentName = StringUtils.limitLength(suggestedName);
      Map<String, dynamic>? originalMetaData;

      // Extract metadata
      for (final file in archive.files) {
        if (file.name.endsWith('/${MetaFile.fileName}') ||
            file.name == MetaFile.fileName) {
          try {
            final metaContent = utf8.decode(file.content as List<int>);
            originalMetaData = jsonDecode(metaContent) as Map<String, dynamic>;
            originalDocumentId = originalMetaData[MetaFile.idKey] as String?;
            documentName = StringUtils.limitLength(
                originalMetaData[MetaFile.nameKey] as String? ?? suggestedName);
            break;
          } catch (e) {
            logger.w('Failed to parse metadata from archive: $e');
          }
        }
      }

      String newDocumentId = StringUtils.generateSafeId();
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDir.path}/documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Check for conflicts and append counter if needed
      var outDir = Directory('${documentsDir.path}/$newDocumentId');
      int counter = 1;
      while (await outDir.exists()) {
        newDocumentId = '${StringUtils.generateSafeId()}_$counter';
        outDir = Directory('${documentsDir.path}/$newDocumentId');
        counter++;
        if (counter > 10) {
          logger.e('Too many attempts to find unique ID');
          return null;
        }
      }

      await outDir.create(recursive: true);

      if (!_isValidDocumentDirectory(outDir, appDir)) {
        logger.e('Import directory outside app boundaries: ${outDir.path}');
        await outDir.delete(recursive: true);
        return null;
      }

      // Detect and strip an outer <documentId>/ prefix written by the web app.
      // The spec places all files under a top-level directory named after the
      // document UUID (e.g. "abc123/meta.json").  Older / Flutter exports omit
      // this prefix and place files at the archive root.  Both layouts are
      // supported: we detect the prefix by looking for "<dir>/meta.json" and
      // strip it so that files always land directly inside [outDir].
      String? archivePrefix;
      for (final f in archive.files) {
        if (f.name.endsWith('/${MetaFile.fileName}') &&
            f.name != MetaFile.fileName) {
          archivePrefix =
              f.name.substring(0, f.name.length - MetaFile.fileName.length);
          logger.i('Detected archive prefix: "$archivePrefix" — will be stripped during extraction');
          break;
        }
      }

      // Extract all files
      for (final file in archive.files) {
        if (file.isFile) {
          try {
            String relativeName = file.name;
            if (archivePrefix != null &&
                relativeName.startsWith(archivePrefix)) {
              relativeName =
                  relativeName.substring(archivePrefix.length);
            }
            if (relativeName.isEmpty) continue;
            final filePath = '${outDir.path}/$relativeName';
            final outFile = File(filePath);
            if (!await outFile.parent.exists()) {
              await outFile.parent.create(recursive: true);
            }
            await outFile.writeAsBytes(file.content as List<int>);
          } catch (e) {
            logger.w('Failed to extract file: ${file.name} - $e');
          }
        }
      }

      // Load blocks and normalize content to pure JSON
      final blocks = await getDocumentBlocks(outDir);
      final updatedBlocks = blocks.map((block) {
        if (block.type == BlockType.image ||
            block.type == BlockType.audio ||
            block.type == BlockType.video) {
          String contentStr = block.content;
          if (contentStr.endsWith('|')) {
            contentStr = contentStr.substring(0, contentStr.length - 1);
          }
          if (contentStr.startsWith('/data/user/0')) {
            // Extract relative path from legacy absolute path
            final relativePath = contentStr.substring(contentStr.indexOf('media/'));
            final jsonMap = <String, dynamic>{'path': relativePath};
            if (block.type == BlockType.image) {
              jsonMap.addAll({
                'caption': '',
                'cropTop': 0.0,
                'cropBottom': 0.0,
                'fit': 'cover',
                'fileName': path.basename(relativePath),
              });
            } else if (block.type == BlockType.video) {
              jsonMap.addAll({
                'caption': '',
                'fileName': path.basename(relativePath),
              });
            } else if (block.type == BlockType.audio) {
              jsonMap.addAll({
                'customTitle': '',
                'caption': '',
                'fileName': path.basename(relativePath),
              });
              logger.d('Updated block content for block ID: ${block.id}, new content: ${jsonEncode(jsonMap)}');
            }
            return block.copyWith(content: jsonEncode(jsonMap));
          } else {
            try {
              jsonDecode(contentStr);
            } catch (e) {
              logger.w('Invalid JSON in imported block ${block.id}: $contentStr');
              final jsonMap = <String, dynamic>{'path': ''};
              if (block.type == BlockType.image) {
                jsonMap.addAll({
                  'caption': '',
                  'cropTop': 0.0,
                  'cropBottom': 0.0,
                  'fit': 'cover',
                  'fileName': '',
                });
              } else if (block.type == BlockType.video) {
                jsonMap.addAll({
                  'caption': '',
                  'fileName': '',
                });
              } else if (block.type == BlockType.audio) {
                jsonMap.addAll({
                  'customTitle': '',
                  'caption': '',
                  'fileName': '',
                });
              }
              return block.copyWith(content: jsonEncode(jsonMap));
            }
          }
        }
        return block;
      }).toList();
      await saveDocumentBlocks(outDir, updatedBlocks);

      // Update metadata
      final metaFile = File('${outDir.path}/${MetaFile.fileName}');
      if (await metaFile.exists()) {
        try {
          final metaContent = await metaFile.readAsString();
          final metaData = jsonDecode(metaContent) as Map<String, dynamic>;
          metaData[MetaFile.idKey] = newDocumentId;
          metaData[MetaFile.nameKey] = documentName;
          metaData[MetaFile.coverKey] =
              metaData[MetaFile.coverKey] != null && metaData[MetaFile.coverKey].isNotEmpty
                  ? '${outDir.path}/${AppFile.imageFolder}/${metaData[MetaFile.coverKey].split('/').last}'
                  : '';
          metaData[MetaFile.coverOriginalNameKey] =
              metaData[MetaFile.coverOriginalNameKey] ?? '';
          metaData[MetaFile.updatedAtKey] = DateTime.now().toIso8601String();
          metaData[MetaFile.createdAtKey] =
              originalMetaData?[MetaFile.createdAtKey] ??
                  DateTime.now().toIso8601String();
          await metaFile.writeAsString(jsonEncode(metaData));
        } catch (e) {
          logger.w('Failed to update metadata during import: $e');
          final basicMeta = _createBasicMetadata(newDocumentId, documentName, originalMetaData);
          await metaFile.writeAsString(jsonEncode(basicMeta));
        }
      } else {
        // Create metadata file if it doesn't exist
        logger.i('Creating metadata file for imported document');
        final basicMeta = _createBasicMetadata(newDocumentId, documentName, originalMetaData);
        await metaFile.writeAsString(jsonEncode(basicMeta));
      }

      logger.i('Imported document: $documentName with ID: $newDocumentId');
      return outDir;
    } catch (e, stackTrace) {
      logger.e('Failed to import document: $suggestedName',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
