import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/block_type_constants.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/data/sources/document_database_manager.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Manages document page operations.
///
/// This service handles:
/// - Page CRUD operations (create, read, update, delete)
/// - Page block management
/// - Multi-page document support
/// - Migration from old single-page format
/// - Page ordering and hierarchy
///
/// Pages are stored as separate database files within document directories,
/// with a pages.json file tracking all pages and their metadata.
class DocumentPageManager {
  final DocumentDatabaseManager _databaseManager;

  DocumentPageManager(this._databaseManager);

  /// Validates if a directory is within the app's document directory.
  bool _isValidDocumentDirectory(Directory dir, Directory appDocDir) {
    final normalizedDir = dir.absolute.path;
    final normalizedAppDir = appDocDir.absolute.path;
    return normalizedDir.startsWith(normalizedAppDir);
  }

  /// Gets all pages from a document.
  ///
  /// If the document doesn't have a pages.json file, it will be automatically
  /// migrated from the old single-page format.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  ///
  /// Returns a list of document pages, or an empty list if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - An error occurs
  Future<List<DocumentPage>> getDocumentPages(Directory doc) async {
    try {
      if (kIsWeb) {
        logger.w('Page retrieval not supported on web');
        return [];
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return [];
      }

      final pagesFile = File('${doc.path}/${PageConstants.pagesFileName}');

      // If pages.json doesn't exist, migrate from old single-page format
      if (!await pagesFile.exists()) {
        logger.i('Migrating document to multi-page format: ${doc.path}');
        return await _migrateToMultiPage(doc);
      }

      final pagesJson = await pagesFile.readAsString();
      final pagesData = jsonDecode(pagesJson) as Map<String, dynamic>;

      // Validate pages key exists and is a list
      if (!pagesData.containsKey(PageConstants.pagesKey) ||
          pagesData[PageConstants.pagesKey] is! List) {
        logger.w('Invalid pages.json format: ${doc.path}');
        return await _migrateToMultiPage(doc);
      }

      final pagesList = pagesData[PageConstants.pagesKey] as List<dynamic>;

      final pages = pagesList
          .whereType<Map<String, dynamic>>()
          .map((pageJson) {
            try {
              return DocumentPage.fromJson(pageJson);
            } catch (e) {
              logger.w('Failed to parse page from JSON: $pageJson - $e');
              return null;
            }
          })
          .whereType<DocumentPage>()
          .toList();

      logger.i('Retrieved ${pages.length} pages for: ${doc.path}');
      return pages;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to retrieve pages: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Migrates old single-page document to multi-page format.
  ///
  /// This method:
  /// 1. Renames book.db to page_page_1.db
  /// 2. Creates a default page entry
  /// 3. Creates pages.json to track pages
  ///
  /// Parameters:
  /// - [doc]: The document directory to migrate
  ///
  /// Returns a list containing the default page, or empty list on failure.
  Future<List<DocumentPage>> _migrateToMultiPage(Directory doc) async {
    try {
      // Check if old book.db exists
      final oldBookDb = File('${doc.path}/${BlockConstants.fileName}');
      if (await oldBookDb.exists()) {
        // Rename book.db to page_page_1.db
        final newPageDb = File(
          '${doc.path}/${PageConstants.getPageFileName(PageConstants.defaultPageId)}',
        );
        await oldBookDb.copy(newPageDb.path);
        await oldBookDb.delete();
        logger.i('Migrated book.db to ${newPageDb.path}');
      }

      // Create default page with "Tab 1" as the default tab display name
      final defaultPage = DocumentPage(
        id: PageConstants.defaultPageId,
        title: PageConstants.defaultPageTitle,
        order: 0,
        createdAt: DateTime.now(),
        tabDisplayName: 'Tab 1', // Default tab display name
      );

      // Create pages.json
      await _savePages(doc, [defaultPage]);

      return [defaultPage];
    } catch (e, stackTrace) {
      logger.e(
        'Failed to migrate document to multi-page: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Saves pages list to document.
  ///
  /// Writes the pages metadata to pages.json file.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pages]: List of pages to save
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> _savePages(Directory doc, List<DocumentPage> pages) async {
    try {
      final pagesFile = File('${doc.path}/${PageConstants.pagesFileName}');
      final pagesData = {
        PageConstants.pagesKey: pages.map((page) => page.toJson()).toList(),
      };
      await pagesFile.writeAsString(jsonEncode(pagesData));
      logger.i('Saved ${pages.length} pages metadata for: ${doc.path}');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to save pages metadata: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Creates a new page in the document.
  ///
  /// Creates a new page database file and adds the page to the pages list.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [title]: Title for the new page
  ///
  /// Returns the created page, or null if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - An error occurs
  Future<DocumentPage?> createPage(Directory doc, String title) async {
    try {
      if (kIsWeb) {
        logger.w('Page creation not supported on web');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return null;
      }

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Create new page
      final pageNumber = pages.length + 1;
      final newPage = DocumentPage(
        id: 'page_$pageNumber',
        title: title.trim().isEmpty ? 'Page $pageNumber' : title,
        order: pages.length,
        createdAt: DateTime.now(),
      );

      // Create database file for the new page
      final pageDbPath =
          '${doc.path}/${PageConstants.getPageFileName(newPage.id)}';
      final db = await _databaseManager.openPageDatabase(pageDbPath);

      // Start with an empty page - no initial block
      await _databaseManager.closeDatabase(db);

      // Add new page to pages list
      pages.add(newPage);
      await _savePages(doc, pages);

      logger.i('Created new page: ${newPage.title} (${newPage.id})');
      return newPage;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to create page: $title',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Creates a new nested page as a child of a parent page.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [title]: Title for the new page
  /// - [parentPageId]: ID of the parent page
  ///
  /// Returns the created nested page, or null if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The parent page doesn't exist
  /// - An error occurs
  Future<DocumentPage?> createNestedPage(
    Directory doc,
    String title,
    String parentPageId,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Page creation not supported on web');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return null;
      }

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Verify parent page exists
      final parentExists = pages.any((p) => p.id == parentPageId);
      if (!parentExists) {
        logger.e('Parent page does not exist: $parentPageId');
        return null;
      }

      // Create new nested page
      final pageNumber = pages.length + 1;
      final newPage = DocumentPage(
        id: 'page_$pageNumber',
        title: title.trim().isEmpty ? 'Nested Page $pageNumber' : title,
        order: pages.length,
        createdAt: DateTime.now(),
        parentPageId: parentPageId,
      );

      // Create database file for the new page
      final pageDbPath =
          '${doc.path}/${PageConstants.getPageFileName(newPage.id)}';
      final db = await _databaseManager.openPageDatabase(pageDbPath);

      // Start with an empty page - no initial block
      await _databaseManager.closeDatabase(db);

      // Add new page to pages list
      pages.add(newPage);
      await _savePages(doc, pages);

      logger.i(
        'Created new nested page: ${newPage.title} (${newPage.id}) under parent $parentPageId',
      );
      return newPage;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to create nested page: $title',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Creates a new tab page in the document.
  ///
  /// Tab pages appear in the AppBar as tabs for navigation and are not shown in the drawer.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [title]: Title for the new tab page
  ///
  /// Returns the created tab page, or null if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - An error occurs
  Future<DocumentPage?> createTabPage(Directory doc, String title) async {
    try {
      if (kIsWeb) {
        logger.w('Page creation not supported on web');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return null;
      }

      // Get existing pages
      final pages = await getDocumentPages(doc);
      final tabPages = pages.where((p) => p.isTabPage).toList();

      // Create new tab page
      final pageNumber = pages.length + 1;
      final tabNumber = tabPages.length + 1;
      final newPage = DocumentPage(
        id: 'page_$pageNumber',
        title: title.trim().isEmpty ? 'Tab $tabNumber' : title,
        order: pages.length,
        createdAt: DateTime.now(),
        isTabPage: true,
      );

      // Create database file for the new page
      final pageDbPath =
          '${doc.path}/${PageConstants.getPageFileName(newPage.id)}';
      final db = await _databaseManager.openPageDatabase(pageDbPath);

      // Start with an empty page - no initial block
      await _databaseManager.closeDatabase(db);

      // Add new page to pages list
      pages.add(newPage);
      await _savePages(doc, pages);

      logger.i('Created new tab page: ${newPage.title} (${newPage.id})');
      return newPage;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to create tab page: $title',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Creates a new nested tab page as a child of a parent drawer page.
  ///
  /// This creates a tab page that belongs to a specific drawer page,
  /// allowing each drawer page to have its own set of tabs.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [title]: Title for the new tab page
  /// - [parentPageId]: ID of the parent drawer page
  ///
  /// Returns the created nested tab page, or null if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The parent page doesn't exist
  /// - An error occurs
  Future<DocumentPage?> createNestedTabPage(
    Directory doc,
    String title,
    String parentPageId,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Page creation not supported on web');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return null;
      }

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Verify parent page exists
      final parentExists = pages.any((p) => p.id == parentPageId);
      if (!parentExists) {
        logger.e('Parent page does not exist: $parentPageId');
        return null;
      }

      // Create new nested tab page
      final pageNumber = pages.length + 1;
      final newPage = DocumentPage(
        id: 'page_$pageNumber',
        title: title.trim().isEmpty ? 'Tab Page $pageNumber' : title,
        order: pages.length,
        createdAt: DateTime.now(),
        parentPageId: parentPageId,
        isTabPage: true, // This is a tab page
      );

      // Create database file for the new page
      final pageDbPath =
          '${doc.path}/${PageConstants.getPageFileName(newPage.id)}';
      final db = await _databaseManager.openPageDatabase(pageDbPath);

      // Start with an empty page - no initial block
      await _databaseManager.closeDatabase(db);

      // Add new page to pages list
      pages.add(newPage);
      await _savePages(doc, pages);

      logger.i(
        'Created new nested tab page: ${newPage.title} (${newPage.id}) under parent $parentPageId',
      );
      return newPage;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to create nested tab page: $title',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Deletes a page from the document.
  ///
  /// Deletes the page database file and removes it from the pages list.
  /// Cannot delete the only remaining page.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pageId]: ID of the page to delete
  ///
  /// Returns true if successful, false if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - It's the only page (cannot delete)
  /// - An error occurs
  Future<bool> deletePage(Directory doc, String pageId) async {
    try {
      if (kIsWeb) {
        logger.w('Page deletion not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Cannot delete if it's the only page
      if (pages.length <= 1) {
        logger.w('Cannot delete the only page in document: ${doc.path}');
        return false;
      }

      // Delete page database file and all its data
      final pageDb = File(
        '${doc.path}/${PageConstants.getPageFileName(pageId)}',
      );
      if (await pageDb.exists()) {
        try {
          // Close any open database connections by opening and closing
          final db = await openDatabase(pageDb.path);
          await db.close();

          // Delete the database file
          await pageDb.delete();
          logger.i('Deleted page database file: ${pageDb.path}');
        } catch (e, stackTrace) {
          logger.e(
            'Failed to delete page database file: ${pageDb.path}',
            error: e,
            stackTrace: stackTrace,
          );
          // Try to delete anyway even if closing failed
          try {
            await pageDb.delete();
          } catch (deleteError) {
            logger.e(
              'Failed to force delete database file',
              error: deleteError,
            );
            return false;
          }
        }
      } else {
        logger.w('Page database file not found: ${pageDb.path}');
      }

      // Remove page from list
      pages.removeWhere((page) => page.id == pageId);

      // Reorder remaining pages
      for (int i = 0; i < pages.length; i++) {
        pages[i] = pages[i].copyWith(order: i);
      }

      // Save updated pages list
      await _savePages(doc, pages);

      logger.i('Successfully deleted page: $pageId');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to delete page: $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Updates the title of an existing page.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pageId]: ID of the page to update
  /// - [newTitle]: New title for the page (can be empty for "Untitled Screen")
  ///
  /// When the title is set, this method also:
  /// - Creates a header block with the title as the first block if none exists
  /// - Updates the first header block if one exists at position 0
  ///
  /// Returns true if successful, false if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The page doesn't exist
  /// - An error occurs
  Future<bool> updatePageTitle(
    Directory doc,
    String pageId,
    String newTitle,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Page update not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      // Allow empty title - will be displayed as "Untitled Screen"
      final trimmedTitle = newTitle.trim();

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Find the page to update
      final pageIndex = pages.indexWhere((page) => page.id == pageId);
      if (pageIndex == -1) {
        logger.w('Page not found: $pageId');
        return false;
      }

      // Update the page title
      pages[pageIndex] = pages[pageIndex].copyWith(title: trimmedTitle);

      // Save updated pages list
      await _savePages(doc, pages);

      // Also update or create the first header block with the page title
      if (trimmedTitle.isNotEmpty) {
        await _updateOrCreateFirstHeaderBlock(doc, pageId, trimmedTitle);
      }

      logger.i(
        'Updated page title: $pageId -> ${trimmedTitle.isEmpty ? "(untitled)" : trimmedTitle}',
      );
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update page title: $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Updates a tab page's display name without modifying page content or page title.
  ///
  /// This method ONLY updates the tabDisplayName field in pages.json and does NOT:
  /// - Modify the page title
  /// - Add or modify any header blocks in the page content
  /// - Add content to any tables
  /// - Change the page structure
  ///
  /// Use this for renaming tabs in the tab bar.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pageId]: ID of the page to update
  /// - [newTabName]: New display name for the tab (can be empty for default display)
  ///
  /// Returns true if successful, false if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The page doesn't exist
  /// - An error occurs
  Future<bool> updateTabTitleOnly(
    Directory doc,
    String pageId,
    String newTabName,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Page update not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      // Allow empty tab name - will use default display
      final trimmedTabName = newTabName.trim();

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Find the page to update
      final pageIndex = pages.indexWhere((page) => page.id == pageId);
      if (pageIndex == -1) {
        logger.w('Page not found: $pageId');
        return false;
      }

      // Update ONLY the tabDisplayName field in pages.json
      pages[pageIndex] = pages[pageIndex].copyWith(
        tabDisplayName: trimmedTabName.isEmpty ? null : trimmedTabName,
        clearTabDisplayName: trimmedTabName.isEmpty,
      );

      // Save updated pages list
      await _savePages(doc, pages);

      logger.i(
        'Updated tab display name only: $pageId -> ${trimmedTabName.isEmpty ? "(default)" : trimmedTabName}',
      );
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update tab display name: $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Creates the JSON content for a header block.
  String _createHeaderBlockContent(String title) {
    return jsonEncode({'content': title});
  }

  /// Updates or creates the first header block with the page title.
  ///
  /// If a header block exists at position 0, it updates its content.
  /// If no header block exists at position 0, it inserts one at the beginning.
  Future<void> _updateOrCreateFirstHeaderBlock(
    Directory doc,
    String pageId,
    String title,
  ) async {
    try {
      final pageDbPath = '${doc.path}/${PageConstants.getPageFileName(pageId)}';
      final pageDb = File(pageDbPath);
      if (!await pageDb.exists()) {
        logger.w('Page database not found: $pageDbPath');
        return;
      }

      final db = await _databaseManager.openPageDatabase(pageDbPath);

      // Get all blocks ordered by position
      final results = await db.query(
        BlockConstants.tableName,
        orderBy: BlockConstants.positionKey,
      );

      // Check if there's already a header block at position 0
      if (results.isNotEmpty) {
        final firstBlock = results.first;
        final firstBlockType =
            firstBlock[BlockConstants.blockTypeKey] as String? ?? 'paragraph';

        if (BlockTypeExtension.fromJson(firstBlockType) == BlockType.header &&
            (firstBlock[BlockConstants.positionKey] as int? ?? 0) == 0) {
          // Update the existing header block content
          final blockId = firstBlock[BlockConstants.idKey];

          await db.update(
            BlockConstants.tableName,
            {BlockConstants.contentKey: _createHeaderBlockContent(title)},
            where: '${BlockConstants.idKey} = ?',
            whereArgs: [blockId],
          );

          logger.i('Updated first header block with title: $title');
        } else {
          // Shift all existing blocks down by 1
          // Using rawUpdate to increment position for all blocks
          await db.rawUpdate(
            'UPDATE ${BlockConstants.tableName} SET ${BlockConstants.positionKey} = ${BlockConstants.positionKey} + 1',
          );

          // Insert new header block at position 0
          await _insertHeaderBlock(db, title);
          logger.i('Inserted new header block with title: $title');
        }
      } else {
        // No blocks exist, insert the header block at position 0
        await _insertHeaderBlock(db, title);
        logger.i('Created first header block with title: $title');
      }

      await _databaseManager.closeDatabase(db);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update/create first header block',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Inserts a header block at position 0.
  Future<void> _insertHeaderBlock(Database db, String title) async {
    final defaultStyle = const BlockStyle().toJson();

    await db.insert(BlockConstants.tableName, {
      BlockConstants.contentKey: _createHeaderBlockContent(title),
      BlockConstants.blockTypeKey: BlockTypeConstants.header,
      BlockConstants.styleKey: jsonEncode(defaultStyle),
      BlockConstants.positionKey: 0,
    });
  }

  /// Updates the icon of an existing page.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pageId]: ID of the page to update
  /// - [iconName]: Icon name to set, or null to remove the icon
  ///
  /// Returns true if successful, false if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The page doesn't exist
  /// - An error occurs
  Future<bool> updatePageIcon(
    Directory doc,
    String pageId,
    String? iconName,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Page update not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      // Get existing pages
      final pages = await getDocumentPages(doc);

      // Find the page to update
      final pageIndex = pages.indexWhere((page) => page.id == pageId);
      if (pageIndex == -1) {
        logger.w('Page not found: $pageId');
        return false;
      }

      // Update the page icon
      if (iconName == null || iconName.isEmpty) {
        pages[pageIndex] = pages[pageIndex].copyWith(clearIcon: true);
      } else {
        pages[pageIndex] = pages[pageIndex].copyWith(icon: iconName);
      }

      // Save updated pages list
      await _savePages(doc, pages);

      logger.i('Updated page icon: $pageId -> ${iconName ?? 'none'}');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update page icon: $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Gets blocks for a specific page.
  ///
  /// Reads the page database and returns all blocks in order.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pageId]: ID of the page
  ///
  /// Returns a list of blocks, or an empty list if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - The page database doesn't exist
  /// - An error occurs
  Future<List<Block>> getPageBlocks(Directory doc, String pageId) async {
    try {
      if (kIsWeb) {
        logger.w('Block retrieval not supported on web');
        return [];
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return [];
      }

      final pageDbPath = '${doc.path}/${PageConstants.getPageFileName(pageId)}';
      final pageDb = File(pageDbPath);
      if (!await pageDb.exists()) {
        logger.w('Page database not found: $pageDbPath');
        return [];
      }

      final db = await _databaseManager.openPageDatabase(pageDbPath);
      final results = await db.query(
        BlockConstants.tableName,
        orderBy: BlockConstants.positionKey,
      );
      await _databaseManager.closeDatabase(db);

      final blocks = results.map((row) {
        return Block.fromDatabaseMap(Map<String, dynamic>.from(row));
      }).toList();

      logger.i(
        'Retrieved ${blocks.length} blocks for page $pageId in: ${doc.path}',
      );
      return blocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to retrieve blocks for page $pageId: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Saves blocks for a specific page.
  ///
  /// Replaces all blocks in the page database with the provided blocks.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [pageId]: ID of the page
  /// - [blocks]: List of blocks to save
  ///
  /// Returns true if successful, false if:
  /// - The platform is web (not supported)
  /// - The directory is invalid
  /// - An error occurs
  Future<bool> savePageBlocks(
    Directory doc,
    String pageId,
    List<Block> blocks,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Block saving not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to access directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      final pageDbPath = '${doc.path}/${PageConstants.getPageFileName(pageId)}';
      final db = await _databaseManager.openPageDatabase(pageDbPath);

      await db.delete(BlockConstants.tableName);
      for (final block in blocks) {
        await db.insert(BlockConstants.tableName, {
          BlockConstants.contentKey: block.content,
          BlockConstants.blockTypeKey: block.serialisedBlockType,
          BlockConstants.styleKey: jsonEncode(block.style.toJson()),
          BlockConstants.positionKey: block.position,
        });
      }
      await _databaseManager.closeDatabase(db);

      logger.i(
        'Saved ${blocks.length} blocks for page $pageId in: ${doc.path}',
      );
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to save blocks for page $pageId: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
