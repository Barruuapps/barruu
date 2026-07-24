import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/string_utils.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:barruu/features/workspace/data/sources/document_database_manager.dart';
import 'package:barruu/features/workspace/data/sources/document_metadata_service.dart';
import 'package:barruu/features/workspace/data/sources/document_page_manager.dart';
import 'package:barruu/features/workspace/data/sources/document_permission_manager.dart';
import 'package:barruu/features/workspace/data/sources/document_import_export_service.dart';
import 'package:barruu/features/workspace/data/sources/encryption_service.dart';
import 'package:barruu/features/workspace/data/sources/pdf_export_service.dart';
import 'package:barruu/features/workspace/data/sources/permission_service.dart';
import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

// Provider for document service components
final _databaseManagerProvider = Provider<DocumentDatabaseManager>((ref) {
  return DocumentDatabaseManager();
});

final _metadataServiceProvider = Provider<DocumentMetadataService>((ref) {
  return DocumentMetadataService();
});

final _pageManagerProvider = Provider<DocumentPageManager>((ref) {
  final databaseManager = ref.read(_databaseManagerProvider);
  return DocumentPageManager(databaseManager);
});

final _permissionManagerProvider = Provider<DocumentPermissionManager>((ref) {
  final permissionService = ref.read(permissionServiceProvider);
  final metadataService = ref.read(_metadataServiceProvider);
  return DocumentPermissionManager(permissionService, metadataService);
});

final _importExportServiceProvider = Provider<DocumentImportExportService>((
  ref,
) {
  final encryptionService = ref.read(encryptionServiceProvider);
  final metadataService = ref.read(_metadataServiceProvider);
  return DocumentImportExportService(encryptionService, metadataService);
});

final _pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

// Provider for document service
final documentServiceProvider = Provider<DocumentService>((ref) {
  final databaseManager = ref.read(_databaseManagerProvider);
  final metadataService = ref.read(_metadataServiceProvider);
  final pageManager = ref.read(_pageManagerProvider);
  final permissionManager = ref.read(_permissionManagerProvider);
  final importExportService = ref.read(_importExportServiceProvider);
  final pdfExportService = ref.read(_pdfExportServiceProvider);
  final permissionService = ref.read(permissionServiceProvider);
  final userIdentityService = ref.read(userIdentityServiceProvider);

  return DocumentService(
    databaseManager,
    metadataService,
    pageManager,
    permissionManager,
    importExportService,
    pdfExportService,
    permissionService,
    userIdentityService,
  );
});

/// Core document service that coordinates document operations.
///
/// This service manages high-level document operations and delegates
/// specialized tasks to dedicated service components:
/// - Database operations → DocumentDatabaseManager
/// - Metadata management → DocumentMetadataService
/// - Page operations → DocumentPageManager
/// - Permission management → DocumentPermissionManager
/// - Import/Export → DocumentImportExportService
///
/// The service maintains the public API for document operations while
/// keeping implementation details encapsulated in specialized services.
class DocumentService {
  final DocumentDatabaseManager _databaseManager;
  final DocumentMetadataService _metadataService;
  final DocumentPageManager _pageManager;
  final DocumentPermissionManager _permissionManager;
  final DocumentImportExportService _importExportService;
  final PdfExportService _pdfExportService;
  final PermissionService _permissionService;
  final UserIdentityService _userIdentityService;
  final Uuid _uuid = const Uuid();

  DocumentService(
    this._databaseManager,
    this._metadataService,
    this._pageManager,
    this._permissionManager,
    this._importExportService,
    this._pdfExportService,
    this._permissionService,
    this._userIdentityService,
  );

  /// Validates if a directory is within the app's document directory.
  bool _isValidDocumentDirectory(Directory dir, Directory appDocDir) {
    return _metadataService.isValidDocumentDirectory(dir, appDocDir);
  }

  /// Creates a new document folder with meta and book databases.
  ///
  /// Parameters:
  /// - [name]: Document name (required, cannot be empty)
  /// - [description]: Document description
  /// - [tags]: Document tags
  /// - [coverImage]: Optional cover image file
  /// - [coverImageOriginalName]: Original name of cover image
  ///
  /// Returns the created document directory, or null if creation fails.
  Future<Directory?> createDocument(
    String name,
    String description,
    String tags, {
    File? coverImage,
    String? coverImageOriginalName,
  }) async {
    try {
      if (name.trim().isEmpty) {
        logger.w('Document name cannot be empty');
        return null;
      }

      final String documentId = StringUtils.generateSafeId();
      final Directory mainDir = await createFolder(documentId);

      // Validate the created directory is within app boundaries
      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(mainDir, appDir)) {
        logger.e('Document directory outside app boundaries: ${mainDir.path}');
        await mainDir.delete(recursive: true);
        return null;
      }

      // --- Save cover image ---
      String coverPath = '';
      String storedCoverName = '';
      final coverDir = Directory('${mainDir.path}/${AppFile.imageFolder}');
      await coverDir.create(recursive: true);
      if (coverImage != null) {
        if (coverImage.path.contains('..')) {
          logger.w('Invalid cover image path: ${coverImage.path}');
          await mainDir.delete(recursive: true);
          return null;
        }
        final sanitizedName = StringUtils.sanitizeFileName(
          coverImageOriginalName ?? 'cover.jpg',
        );
        storedCoverName = coverImageOriginalName ?? sanitizedName;
        coverPath = '${coverDir.path}/${_uuid.v4()}_$sanitizedName';
        await coverImage.copy(coverPath);
      }

      // Initialize permissions for the new document
      final permissions = await _permissionService.initializePermissions();

      // Get current user ID for authorId field
      final userId = await _userIdentityService.getUserId();

      final metaJson = {
        MetaFile.idKey: documentId,
        MetaFile.nameKey: StringUtils.limitLength(name.trim()),
        MetaFile.descriptionKey: StringUtils.limitLength(description),
        MetaFile.tagsKey: StringUtils.limitLength(tags),
        MetaFile.coverKey: coverPath,
        MetaFile.coverOriginalNameKey: StringUtils.limitLength(storedCoverName),
        MetaFile.createdAtKey: DateTime.now().toIso8601String(),
        MetaFile.updatedAtKey: DateTime.now().toIso8601String(),
        MetaFile.authorKey: 'Barruu',
        ...permissions,
        // Social metadata (Phase 2 preparation)
        MetaFile.authorIdKey: userId,
        MetaFile.visibilityKey: MetaFile.defaultVisibility,
        MetaFile.publishedKey: MetaFile.defaultPublished,
        MetaFile.publishedAtKey: null,
        MetaFile.viewsKey: MetaFile.defaultViews,
        MetaFile.likesKey: MetaFile.defaultLikes,
        MetaFile.commentsKey: MetaFile.defaultComments,
        MetaFile.sharesKey: MetaFile.defaultShares,
      };

      await _metadataService.writeDocumentMetadata(mainDir, metaJson);

      // --- Create first page database ---
      final firstPageDbPath =
          '${mainDir.path}/${PageConstants.getPageFileName(PageConstants.defaultPageId)}';
      final firstPageDb = await _databaseManager.openPageDatabase(
        firstPageDbPath,
      );

      // Start with an empty page - no initial block
      await _databaseManager.closeDatabase(firstPageDb);

      // Create pages.json to track pages
      final firstPage = DocumentPage(
        id: PageConstants.defaultPageId,
        title: PageConstants.defaultPageTitle,
        order: 0,
        createdAt: DateTime.now(),
      );

      final pagesFile = File('${mainDir.path}/${PageConstants.pagesFileName}');
      final pagesData = {
        PageConstants.pagesKey: [firstPage.toJson()],
      };
      await pagesFile.writeAsString(jsonEncode(pagesData));

      logger.i('Created document: ${name.trim()} with ID: $documentId');
      return mainDir;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to create document: $name',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Deletes a document directory with security validation.
  Future<bool> deleteDocument(Directory doc) async {
    try {
      if (kIsWeb) {
        logger.w('Document deletion not supported on web');
        return false;
      }

      // Validate the directory is within app boundaries
      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to delete directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      if (await doc.exists()) {
        await doc.delete(recursive: true);
        logger.i('Deleted document: ${doc.path}');
        return true;
      }
      logger.w('Document not found: ${doc.path}');
      return false;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to delete document: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Creates a new folder for a document using safe UUID.
  Future<Directory> createFolder(String documentId) async {
    try {
      if (kIsWeb) {
        throw Exception('Folder creation not supported on web');
      }
      if (documentId.contains('..')) {
        throw Exception('Invalid document ID: $documentId');
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final mainDir = Directory('${appDir.path}/documents/$documentId');

      if (!await mainDir.exists()) {
        await mainDir.create(recursive: true);
        // Create media subdirectories
        await Directory(
          '${mainDir.path}/${AppFile.imageFolder}',
        ).create(recursive: true);
        await Directory(
          '${mainDir.path}/${AppFile.videoFolder}',
        ).create(recursive: true);
        await Directory(
          '${mainDir.path}/${AppFile.audioFolder}',
        ).create(recursive: true);
        logger.i('Created folder: ${mainDir.path}');
      } else {
        logger.w('Folder already exists: ${mainDir.path}');
      }
      return mainDir;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to create folder for ID: $documentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Lists all document directories with security validation.
  Future<List<Directory>> listDocuments() async {
    try {
      if (kIsWeb) {
        logger.w('Document listing not supported on web');
        return [];
      }

      final rootDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${rootDir.path}/documents');

      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
        return [];
      }

      final entities = await documentsDir.list().toList();
      final folders = <Directory>[];

      for (var entity in entities.whereType<Directory>()) {
        if (!_isValidDocumentDirectory(entity, rootDir)) {
          logger.w('Skipping invalid document directory: ${entity.path}');
          continue;
        }

        final metaDb = File('${entity.path}/${MetaFile.fileName}');
        if (await metaDb.exists()) {
          folders.add(entity);
        }
      }
      logger.i('Listed ${folders.length} documents');
      return folders;
    } catch (e, stackTrace) {
      logger.e('Failed to list documents', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Lists all document directories from the library folder.
  Future<List<Directory>> listLibraryDocuments() async {
    try {
      if (kIsWeb) {
        logger.w('Library document listing not supported on web');
        return [];
      }

      final rootDir = await getApplicationDocumentsDirectory();
      final libraryDir = Directory('${rootDir.path}/library');

      if (!await libraryDir.exists()) {
        await libraryDir.create(recursive: true);
        logger.i('Created library directory: ${libraryDir.path}');
        return [];
      }

      final entities = await libraryDir.list().toList();
      final folders = <Directory>[];

      for (var entity in entities.whereType<Directory>()) {
        if (!_isValidDocumentDirectory(entity, rootDir)) {
          logger.w('Skipping invalid library directory: ${entity.path}');
          continue;
        }

        final metaDb = File('${entity.path}/${MetaFile.fileName}');
        if (await metaDb.exists()) {
          folders.add(entity);
        }
      }
      logger.i('Listed ${folders.length} library documents');
      return folders;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to list library documents',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Updates document meta info.
  ///
  /// Delegates to DocumentMetadataService.
  Future<bool> updateDocumentInfo(
    Directory doc,
    String name,
    String description,
    String tags,
    String coverPath, {
    String coverOriginalName = '',
  }) async {
    return await _metadataService.updateDocumentInfo(
      doc,
      name,
      description,
      tags,
      coverPath,
      coverOriginalName: coverOriginalName,
    );
  }

  /// Gets document metadata.
  ///
  /// Delegates to DocumentMetadataService.
  Future<Map<String, dynamic>?> getDocumentMetadata(Directory doc) async {
    return await _metadataService.getDocumentMetadata(doc);
  }

  /// Batch loads metadata for multiple documents efficiently.
  ///
  /// Delegates to DocumentMetadataService.
  Future<Map<Directory, Map<String, dynamic>>> batchGetDocumentMetadata(
    List<Directory> docs,
  ) async {
    return await _metadataService.batchGetDocumentMetadata(docs);
  }

  /// Gets all blocks from a document (uses first page in multi-page documents).
  Future<List<Block>> getDocumentBlocks(Directory doc) async {
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

      // Try to get pages (triggers migration if needed)
      final pages = await getDocumentPages(doc);
      if (pages.isNotEmpty) {
        // Use the first page
        return await getPageBlocks(doc, pages.first.id);
      }

      // Fallback to old book.db if migration failed
      final bookDb = File('${doc.path}/${BlockConstants.fileName}');
      if (!await bookDb.exists()) {
        logger.w('No database found: ${bookDb.path}');
        return [];
      }

      final dbBook = await openDatabase(bookDb.path);
      final results = await dbBook.query(
        BlockConstants.tableName,
        orderBy: BlockConstants.positionKey,
      );
      await dbBook.close();

      final blocks = results.map((row) {
        return Block.fromDatabaseMap(Map<String, dynamic>.from(row));
      }).toList();

      logger.i('Retrieved ${blocks.length} blocks for: ${doc.path}');
      return blocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to retrieve blocks: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Saves blocks to a document (uses first page in multi-page documents).
  Future<bool> saveDocumentBlocks(Directory doc, List<Block> blocks) async {
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

      // Try to get pages (triggers migration if needed)
      final pages = await getDocumentPages(doc);
      if (pages.isNotEmpty) {
        // Use the first page
        return await savePageBlocks(doc, pages.first.id, blocks);
      }

      // Fallback to old book.db if migration failed
      final bookDb = File('${doc.path}/${BlockConstants.fileName}');
      final dbBook = await openDatabase(bookDb.path);

      await dbBook.delete(BlockConstants.tableName);
      for (final block in blocks) {
        await dbBook.insert(BlockConstants.tableName, {
          BlockConstants.contentKey: block.content,
          BlockConstants.blockTypeKey: block.serialisedBlockType,
          BlockConstants.styleKey: jsonEncode(block.style.toJson()),
          BlockConstants.positionKey: block.position,
        });
      }
      await dbBook.close();

      final meta = await getDocumentMetadata(doc);
      if (meta != null) {
        await updateDocumentInfo(
          doc,
          meta[MetaFile.nameKey] as String? ?? 'Untitled',
          meta[MetaFile.descriptionKey] as String? ?? '',
          meta[MetaFile.tagsKey] as String? ?? '',
          meta[MetaFile.coverKey] as String? ?? '',
        );
      }

      logger.i('Saved ${blocks.length} blocks for: ${doc.path}');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to save blocks: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Gets all pages from a document.
  ///
  /// Delegates to DocumentPageManager.
  Future<List<DocumentPage>> getDocumentPages(Directory doc) async {
    return await _pageManager.getDocumentPages(doc);
  }

  /// Creates a new page in the document.
  ///
  /// Delegates to DocumentPageManager.
  Future<DocumentPage?> createPage(Directory doc, String title) async {
    return await _pageManager.createPage(doc, title);
  }

  /// Creates a new nested page as a child of a parent page.
  ///
  /// Delegates to DocumentPageManager.
  Future<DocumentPage?> createNestedPage(
    Directory doc,
    String title,
    String parentPageId,
  ) async {
    return await _pageManager.createNestedPage(doc, title, parentPageId);
  }

  /// Creates a new tab page in the document.
  ///
  /// Tab pages appear in the AppBar as tabs and are not shown in the drawer.
  /// Delegates to DocumentPageManager.
  Future<DocumentPage?> createTabPage(Directory doc, String title) async {
    return await _pageManager.createTabPage(doc, title);
  }

  /// Creates a new nested tab page as a child of a parent drawer page.
  ///
  /// This creates a tab page that belongs to a specific drawer page,
  /// allowing each drawer page to have its own set of tabs.
  /// Delegates to DocumentPageManager.
  Future<DocumentPage?> createNestedTabPage(
    Directory doc,
    String title,
    String parentPageId,
  ) async {
    return await _pageManager.createNestedTabPage(doc, title, parentPageId);
  }

  /// Deletes a page from the document.
  ///
  /// Delegates to DocumentPageManager.
  Future<bool> deletePage(Directory doc, String pageId) async {
    return await _pageManager.deletePage(doc, pageId);
  }

  /// Updates the title of an existing page.
  ///
  /// Delegates to DocumentPageManager.
  Future<bool> updatePageTitle(
    Directory doc,
    String pageId,
    String newTitle,
  ) async {
    return await _pageManager.updatePageTitle(doc, pageId, newTitle);
  }

  /// Updates a tab title without modifying page content.
  ///
  /// This method ONLY updates the title in pages.json and does NOT:
  /// - Add or modify any header blocks in the page content
  /// - Add content to any tables
  /// - Change the page structure
  ///
  /// Use this for renaming tabs in the tab bar.
  ///
  /// Delegates to DocumentPageManager.
  Future<bool> updateTabTitleOnly(
    Directory doc,
    String pageId,
    String newTitle,
  ) async {
    return await _pageManager.updateTabTitleOnly(doc, pageId, newTitle);
  }

  /// Updates the icon of an existing page.
  ///
  /// Delegates to DocumentPageManager.
  Future<bool> updatePageIcon(
    Directory doc,
    String pageId,
    String? iconName,
  ) async {
    return await _pageManager.updatePageIcon(doc, pageId, iconName);
  }

  /// Gets blocks for a specific page.
  ///
  /// Delegates to DocumentPageManager.
  Future<List<Block>> getPageBlocks(Directory doc, String pageId) async {
    return await _pageManager.getPageBlocks(doc, pageId);
  }

  /// Saves blocks for a specific page.
  ///
  /// Delegates to DocumentPageManager, then updates document metadata.
  Future<bool> savePageBlocks(
    Directory doc,
    String pageId,
    List<Block> blocks,
  ) async {
    final success = await _pageManager.savePageBlocks(doc, pageId, blocks);

    if (success) {
      // Update document metadata timestamp
      final meta = await getDocumentMetadata(doc);
      if (meta != null) {
        await updateDocumentInfo(
          doc,
          meta[MetaFile.nameKey] as String? ?? 'Untitled',
          meta[MetaFile.descriptionKey] as String? ?? '',
          meta[MetaFile.tagsKey] as String? ?? '',
          meta[MetaFile.coverKey] as String? ?? '',
        );
      }
    }

    return success;
  }

  /// Shares an exported file.
  ///
  /// Delegates to DocumentImportExportService.
  Future<bool> shareExportedFile(String filePath) async {
    return await _importExportService.shareExportedFile(filePath);
  }

  /// Exports a document as an encrypted .bipy file.
  ///
  /// Delegates to DocumentImportExportService.
  Future<String?> exportDocumentEncrypted(
    Directory docDir, {
    bool shareAfter = true,
  }) async {
    return await _importExportService.exportDocumentEncrypted(
      docDir,
      shareAfter: shareAfter,
    );
  }

  /// Exports the document as a PDF file and shares it.
  ///
  /// Iterates over all pages in the document, converts each block to PDF
  /// content, and calls [Printing.sharePdf] so the user can save or share
  /// the resulting file.  Returns `true` on success.
  Future<bool> exportAsPdf(Directory docDir) async {
    if (kIsWeb) {
      logger.w('PDF export not supported on web');
      return false;
    }

    final appDir = await getApplicationDocumentsDirectory();
    if (!_isValidDocumentDirectory(docDir, appDir)) {
      logger.e(
        'Attempt to export directory outside app boundaries: ${docDir.path}',
      );
      return false;
    }

    final meta = await getDocumentMetadata(docDir);
    final title = (meta?[MetaFile.nameKey] as String? ?? '').trim();
    final documentTitle = title.isEmpty ? 'Document' : title;

    final pages = await getDocumentPages(docDir);
    if (pages.isEmpty) {
      logger.w('No pages found for PDF export: ${docDir.path}');
      return false;
    }

    final pdfFile = await _pdfExportService.exportDocumentAsPdf(
      docDir,
      documentTitle,
      pages,
      (pageId) => getPageBlocks(docDir, pageId),
    );

    if (pdfFile == null) return false;
    return await shareExportedFile(pdfFile.path);
  }

  /// Imports a .bipy file using file picker.
  ///
  /// Delegates to DocumentImportExportService with necessary callbacks.
  Future<Directory?> importDocumentFromBipy() async {
    return await _importExportService.importDocumentFromBipy(
      getDocumentBlocks: getDocumentBlocks,
      saveDocumentBlocks: saveDocumentBlocks,
    );
  }

  /// Imports a .bipy file to a specific document name.
  ///
  /// Delegates to DocumentImportExportService with necessary callbacks.
  Future<Directory?> importDocumentFromBipyFile(
    File bipyFile,
    String suggestedName,
  ) async {
    return await _importExportService.importDocumentFromBipyFile(
      bipyFile,
      suggestedName,
      getDocumentBlocks: getDocumentBlocks,
      saveDocumentBlocks: saveDocumentBlocks,
    );
  }

  /// Updates document permissions.
  ///
  /// Updates metadata with new permission information.
  Future<bool> updateDocumentPermissions(
    Directory doc,
    Map<String, dynamic> updatedMetadata,
  ) async {
    try {
      if (kIsWeb) {
        logger.w('Permission update not supported on web');
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (!_isValidDocumentDirectory(doc, appDir)) {
        logger.e(
          'Attempt to update directory outside app boundaries: ${doc.path}',
        );
        return false;
      }

      final metaFile = File('${doc.path}/${MetaFile.fileName}');
      if (!await metaFile.exists()) {
        logger.w('Metadata file not found: ${metaFile.path}');
        return false;
      }

      // Update timestamp
      updatedMetadata[MetaFile.updatedAtKey] = DateTime.now().toIso8601String();

      await metaFile.writeAsString(jsonEncode(updatedMetadata));
      logger.i('Updated document permissions: ${doc.path}');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update document permissions: ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Checks if user can edit a document.
  ///
  /// Delegates to DocumentPermissionManager.
  Future<bool> canEditDocument(Directory doc) async {
    return await _permissionManager.canEditDocument(doc);
  }

  /// Checks if user can delete a document.
  ///
  /// Delegates to DocumentPermissionManager.
  Future<bool> canDeleteDocument(Directory doc) async {
    return await _permissionManager.canDeleteDocument(doc);
  }

  /// Gets the user's permission level for a document.
  ///
  /// Delegates to DocumentPermissionManager.
  Future<PermissionLevel?> getUserPermissionLevel(Directory doc) async {
    return await _permissionManager.getUserPermissionLevel(doc);
  }
}

// Extension for easy access to document service
extension DocumentServiceExtension on WidgetRef {
  DocumentService get documentService => read(documentServiceProvider);
}

// Provider for the current document state
final currentDocumentProvider = StateProvider<Directory?>((ref) => null);
final importStateProvider = StateProvider<AsyncValue<void>>(
  (ref) => const AsyncValue.data(null),
);

// Provider for document blocks
final documentBlocksProvider = FutureProvider.family<List<Block>, Directory>((
  ref,
  doc,
) async {
  final documentService = ref.read(documentServiceProvider);
  return documentService.getDocumentBlocks(doc);
});
// Provider for document pages
final documentPagesProvider =
    FutureProvider.family<List<DocumentPage>, Directory>((ref, doc) async {
      final documentService = ref.read(documentServiceProvider);
      return documentService.getDocumentPages(doc);
    });

// Provider for current page ID per document (keyed by directory path string for cross-screen sharing)
final currentPageIdProvider = StateProvider.family<String, String>((
  ref,
  docPath,
) {
  return PageConstants.defaultPageId;
});

// Provider for page navigation stack (keyed by directory path string for cross-screen sharing)
final pageNavigationStackProvider = StateProvider.family<List<String>, String>((
  ref,
  docPath,
) {
  return [PageConstants.defaultPageId];
});

// Provider for page blocks
final pageBlocksProvider =
    FutureProvider.family<List<Block>, ({Directory doc, String pageId})>((
      ref,
      params,
    ) async {
      final documentService = ref.read(documentServiceProvider);
      return documentService.getPageBlocks(params.doc, params.pageId);
    });
