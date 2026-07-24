import 'dart:async';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider for managing workspace documents state
final documentsProvider = StateNotifierProvider<DocumentsNotifier, AsyncValue<List<Directory>>>((ref) {
  return DocumentsNotifier(ref.read(documentServiceProvider));
});

/// Manages the state of documents in the workspace
/// Handles loading, caching metadata, and providing document information
class DocumentsNotifier extends StateNotifier<AsyncValue<List<Directory>>> {
  final DocumentService _documentService;
  final Map<String, Map<String, dynamic>> _metaCache = {};

  DocumentsNotifier(this._documentService) : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  /// Loads all documents and caches their metadata for performance
  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    try {
      final documents = await _documentService.listDocuments();
      
      // Use batch loading for better performance
      final metadataMap = await _documentService.batchGetDocumentMetadata(documents);
      
      // Cache the loaded metadata
      for (final entry in metadataMap.entries) {
        final doc = entry.key;
        final meta = entry.value;
        _metaCache[doc.path] = {
          MetaFile.nameKey: meta[MetaFile.nameKey]?.toString().trim().isNotEmpty == true
              ? meta[MetaFile.nameKey]
              : 'Untitled Document',
          MetaFile.descriptionKey: meta[MetaFile.descriptionKey]?.toString() ?? '',
          MetaFile.coverKey: meta[MetaFile.coverKey]?.toString(),
          MetaFile.coverOriginalNameKey: meta[MetaFile.coverOriginalNameKey]?.toString(),
          'lastModified': meta['lastModified'] ?? DateTime.now(),
        };
      }
      
      state = AsyncValue.data(documents);
    } catch (error, stackTrace) {
      logger.e('Failed to load documents', error: error, stackTrace: stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Retrieves cached metadata for a document
  /// Returns null if metadata is not cached
  Map<String, dynamic>? getCachedMeta(Directory doc) => _metaCache[doc.path];
}
