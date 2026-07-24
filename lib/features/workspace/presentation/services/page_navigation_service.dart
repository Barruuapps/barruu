import 'dart:io';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// Service for managing page navigation and nested page operations.
///
/// Provides functionality for:
/// - Creating nested child pages
/// - Updating page titles
/// - Checking page references across the document
/// - Managing page lifecycle (creation, deletion)
///
/// Example:
/// ```dart
/// final service = PageNavigationService(documentService);
/// final newPage = await service.createNestedPage(docDir, 'My Page', parentPageId);
/// ```
class PageNavigationService {
  final DocumentService documentService;
  final JsonStringConverter _jsonConverter = JsonStringConverter();

  PageNavigationService(this.documentService);

  /// Creates a nested child page within the document.
  ///
  /// Returns the newly created [DocumentPage] or null if creation fails.
  Future<DocumentPage?> createNestedPage(
    Directory docDir,
    String title,
    String parentPageId,
  ) async {
    try {
      return await documentService.createNestedPage(
        docDir,
        title,
        parentPageId,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to create nested page', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Updates the title of a page.
  ///
  /// Returns true if the update was successful, false otherwise.
  Future<bool> updatePageTitle(
    Directory docDir,
    String pageId,
    String newTitle,
  ) async {
    try {
      await documentService.updatePageTitle(docDir, pageId, newTitle);
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to update page title', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Gets all pages in the document.
  Future<List<DocumentPage>> getAllPages(Directory docDir) async {
    try {
      return await documentService.getDocumentPages(docDir);
    } catch (e, stackTrace) {
      logger.e('Failed to get document pages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Gets all page IDs that are referenced by page blocks in the document.
  ///
  /// This is useful for determining which pages are linked and which are orphaned.
  Future<Set<String>> getReferencedPageIds(Directory docDir) async {
    final referencedPageIds = <String>{};
    
    try {
      final allPages = await getAllPages(docDir);
      
      for (final page in allPages) {
        try {
          final blocks = await documentService.getPageBlocks(docDir, page.id);
          for (final block in blocks) {
            if (block.type == BlockType.page && block.content.isNotEmpty) {
              try {
                final content = _jsonConverter.convertFromJsonString(block.content);
                final pageId = content['pageId']?.toString();
                if (pageId != null && pageId.isNotEmpty) {
                  referencedPageIds.add(pageId);
                }
              } catch (e) {
                // Skip invalid block content
              }
            }
          }
        } catch (e) {
          // Skip if can't read page blocks
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to get referenced page IDs', error: e, stackTrace: stackTrace);
    }
    
    return referencedPageIds;
  }

  /// Checks if a specific page is referenced by any page block other than the specified block.
  ///
  /// Used to determine if a page can be safely deleted.
  Future<bool> isPageReferencedElsewhere(
    Directory docDir,
    String targetPageId,
    String excludeBlockId,
  ) async {
    try {
      final allPages = await getAllPages(docDir);
      
      for (final page in allPages) {
        try {
          final blocks = await documentService.getPageBlocks(docDir, page.id);
          for (final block in blocks) {
            // Skip the excluded block
            if (block.id == excludeBlockId) continue;
            
            if (block.type == BlockType.page && block.content.isNotEmpty) {
              try {
                final content = _jsonConverter.convertFromJsonString(block.content);
                final refPageId = content['pageId']?.toString();
                if (refPageId == targetPageId) {
                  return true;
                }
              } catch (e) {
                // Skip invalid block content
              }
            }
          }
        } catch (e) {
          // Skip if can't read page blocks
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to check page references', error: e, stackTrace: stackTrace);
    }
    
    return false;
  }

  /// Deletes a page if it is not referenced elsewhere.
  ///
  /// Returns true if the page was deleted, false if it was not deleted
  /// (either because it's referenced or deletion failed).
  Future<bool> deletePageIfUnused(
    Directory docDir,
    String pageId,
    String excludeBlockId,
  ) async {
    try {
      final isReferenced = await isPageReferencedElsewhere(
        docDir,
        pageId,
        excludeBlockId,
      );
      
      if (!isReferenced) {
        await documentService.deletePage(docDir, pageId);
        logger.i('Deleted unused auto-created page: $pageId');
        return true;
      } else {
        logger.i('Not deleting page $pageId as it is referenced by other blocks');
        return false;
      }
    } catch (e, stackTrace) {
      logger.w('Could not delete page: $pageId', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
