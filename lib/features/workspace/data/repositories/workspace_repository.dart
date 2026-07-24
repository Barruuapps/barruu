import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sqflite/sqflite.dart';

// Provider for document repository
final documentRepositoryProvider =
    Provider.family<IDocumentRepository, Directory>((ref, docDir) {
      return DocumentRepository(docDir);
    });

class DocumentRepository implements IDocumentRepository {
  final Directory docDir;
  Database? _database;

  DocumentRepository(this.docDir);

  /// Opens or returns cached database
  Future<Database> _openDb() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    try {
      final dbPath = '${docDir.path}/${BlockConstants.fileName}';
      _database = await openDatabase(
        dbPath,
        version: BlockConstants.databaseVersion,
        onCreate: (db, version) async {
          await db.execute(BlockConstants.createTableSql);
          // Create indexes for query optimization
          await _createIndexes(db);
          logger.i('Created block table with indexes in database: $dbPath');
        },
        onUpgrade: _performDatabaseMigration,
      );
      logger.i('Database opened: $dbPath');
      return _database!;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to open database: ${docDir.path}/${BlockConstants.fileName}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Closes the database
  Future<void> _closeDb() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      logger.i('Database closed: ${docDir.path}/${BlockConstants.fileName}');
    }
  }

  /// Fetches all blocks, ordered by position
  @override
  Future<List<Block>> getBlocks() async {
    final db = await _openDb();
    try {
      final maps = await db.query(
        BlockConstants.tableName,
        orderBy: 'position ASC',
      );
      final blocks = maps.map((m) => Block.fromDatabaseMap(m)).toList();
      logger.i('Fetched ${blocks.length} blocks from ${docDir.path}');
      await _closeDb();
      return blocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to fetch blocks from ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Fetches a paginated list of blocks
  @override
  Future<List<Block>> getBlocksPaginated({
    required int limit,
    required int offset,
  }) async {
    final db = await _openDb();
    try {
      final maps = await db.query(
        BlockConstants.tableName,
        orderBy: 'position ASC',
        limit: limit,
        offset: offset,
      );
      final blocks = maps.map((m) => Block.fromDatabaseMap(m)).toList();
      logger.i(
        'Fetched ${blocks.length} blocks (limit: $limit, offset: $offset) from ${docDir.path}',
      );
      await _closeDb();
      return blocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to fetch paginated blocks from ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Gets the total count of blocks
  @override
  Future<int> getBlocksCount() async {
    final db = await _openDb();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${BlockConstants.tableName}',
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      logger.i('Block count: $count in ${docDir.path}');
      await _closeDb();
      return count;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to get block count from ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds a new block and returns its ID
  @override
  Future<String> addBlock(Block block) async {
    final db = await _openDb();
    try {
      final id = await db.insert(
        BlockConstants.tableName,
        block.toDatabaseMap(),
      );
      logger.i('Block added: ID $id in ${docDir.path}');
      await _closeDb();
      return id.toString();
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add block in ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates an existing block
  @override
  Future<bool> updateBlock(Block block) async {
    final db = await _openDb();
    try {
      final rowsAffected = await db.update(
        BlockConstants.tableName,
        block.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [block.id],
      );
      if (rowsAffected == 0) {
        logger.w('No block updated for ID ${block.id} in ${docDir.path}');
        return false;
      }
      logger.i('Block updated: ID ${block.id} in ${docDir.path}');
      await _closeDb();
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update block: ID ${block.id} in ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes a block by ID
  @override
  Future<bool> deleteBlock(String id) async {
    final db = await _openDb();
    try {
      final rowsAffected = await db.delete(
        BlockConstants.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        logger.w('No block deleted for ID $id in ${docDir.path}');
        return false;
      }
      logger.i('Block deleted: ID $id in ${docDir.path}');
      await _closeDb();
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to delete block: ID $id in ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Fetches document tags from meta.json
  @override
  Future<String> getTags() async {
    if (kIsWeb) {
      logger.w('Reading meta.json not supported on web: ${docDir.path}');
      return '';
    }
    try {
      final file = File('${docDir.path}/${MetaFile.fileName}');
      if (!await file.exists()) {
        logger.w('${MetaFile.fileName} not found: ${docDir.path}');
        return '';
      }
      final metaJson = await file.readAsString();
      final meta = jsonDecode(metaJson);
      final tags = meta[MetaFile.tagsKey] as String? ?? '';
      logger.i('Tags fetched: $tags from ${docDir.path}');
      return tags;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to fetch tags from ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return '';
    }
  }

  /// Updates multiple blocks in a transaction
  @override
  Future<void> updateBlocks(List<Block> blocks) async {
    final db = await _openDb();
    try {
      await db.transaction((txn) async {
        for (final block in blocks) {
          final rowsAffected = await txn.update(
            BlockConstants.tableName,
            block.toDatabaseMap(),
            where: 'id = ?',
            whereArgs: [block.id],
          );
          if (rowsAffected == 0) {
            logger.w('No block updated for ID ${block.id} in ${docDir.path}');
          }
        }
      });
      logger.i('Updated ${blocks.length} blocks in ${docDir.path}');
      await _closeDb();
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update blocks in ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Creates indexes for query optimization
  Future<void> _createIndexes(Database db) async {
    try {
      for (final indexSql in BlockConstants.allIndexesSql) {
        await db.execute(indexSql);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to create indexes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Performs database migration from old version to new version
  Future<void> _performDatabaseMigration(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    logger.i('Migrating database from version $oldVersion to $newVersion');

    try {
      // Migration from version 1 to 2: Add indexes
      if (oldVersion < 2 && newVersion >= 2) {
        await _createIndexes(db);
        logger.i('Successfully migrated to version 2');
      }

      // Future migrations can be added here
      // if (oldVersion < 3 && newVersion >= 3) { ... }
    } catch (e, stackTrace) {
      logger.e('Database migration failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

// Extension for easy access to document repository
extension DocumentRepositoryExtension on WidgetRef {
  IDocumentRepository documentRepository(Directory docDir) =>
      read(documentRepositoryProvider(docDir));
}

// Provider for document blocks
final documentBlocksProvider = FutureProvider.family<List<Block>, Directory>((
  ref,
  docDir,
) async {
  final repository = ref.read(documentRepositoryProvider(docDir));
  return repository.getBlocks();
});

// Provider for document tags
final documentTagsProvider = FutureProvider.family<String, Directory>((
  ref,
  docDir,
) async {
  final repository = ref.read(documentRepositoryProvider(docDir));
  return repository.getTags();
});

// Notifier for managing blocks state
class BlocksNotifier extends StateNotifier<List<Block>> {
  final IDocumentRepository _repository;

  BlocksNotifier(this._repository, List<Block> initialBlocks)
    : super(initialBlocks);

  Future<void> addBlock(Block block) async {
    final id = await _repository.addBlock(block);
    final newBlock = block.copyWith(id: id);
    state = [...state, newBlock];
  }

  Future<void> updateBlock(Block block) async {
    await _repository.updateBlock(block);
    state = state.map((b) => b.id == block.id ? block : b).toList();
  }

  Future<void> deleteBlock(String id) async {
    await _repository.deleteBlock(id);
    state = state.where((block) => block.id != id).toList();
  }

  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<Block> blocks = List.from(state);
    final Block item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    for (int i = 0; i < blocks.length; i++) {
      blocks[i] = blocks[i].copyWith(position: i);
    }
    await _repository.updateBlocks(blocks);
    state = blocks;
  }
}

// Provider for blocks notifier
final blocksNotifierProvider =
    StateNotifierProvider.family<BlocksNotifier, List<Block>, Directory>((
      ref,
      docDir,
    ) {
      final repository = ref.read(documentRepositoryProvider(docDir));
      final initialBlocks =
          ref.watch(documentBlocksProvider(docDir)).value ?? [];
      return BlocksNotifier(repository, initialBlocks);
    });

// Provider for page repository
final pageRepositoryProvider =
    Provider.family<PageRepository, ({Directory docDir, String pageId})>((
      ref,
      params,
    ) {
      return PageRepository(params.docDir, params.pageId);
    });

class PageRepository {
  final Directory docDir;
  final String pageId;
  Database? _database;

  PageRepository(this.docDir, this.pageId);

  /// Creates indexes for query optimization
  Future<void> _createIndexes(Database db) async {
    try {
      for (final indexSql in BlockConstants.allIndexesSql) {
        await db.execute(indexSql);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to create indexes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Performs database migration from old version to new version
  Future<void> _performDatabaseMigration(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    logger.i('Migrating page database from version $oldVersion to $newVersion');

    try {
      // Migration from version 1 to 2: Add indexes
      if (oldVersion < 2 && newVersion >= 2) {
        await _createIndexes(db);
        logger.i('Successfully migrated to version 2');
      }

      // Future migrations can be added here
      // if (oldVersion < 3 && newVersion >= 3) { ... }
    } catch (e, stackTrace) {
      logger.e('Database migration failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Opens or returns cached database for a specific page
  Future<Database> _openDb() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    try {
      final dbPath = '${docDir.path}/${PageConstants.getPageFileName(pageId)}';
      _database = await openDatabase(
        dbPath,
        version: BlockConstants.databaseVersion,
        onCreate: (db, version) async {
          await db.execute(BlockConstants.createTableSql);
          // Create indexes for query optimization
          await _createIndexes(db);
          logger.i(
            'Created block table with indexes in page database: $dbPath',
          );
        },
        onUpgrade: _performDatabaseMigration,
      );
      logger.i('Page database opened: $dbPath');
      return _database!;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to open page database: ${docDir.path}/${PageConstants.getPageFileName(pageId)}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Closes the database
  Future<void> _closeDb() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      logger.i(
        'Page database closed: ${PageConstants.getPageFileName(pageId)}',
      );
    }
  }

  /// Fetches all blocks for this page, ordered by position
  Future<List<Block>> getBlocks() async {
    final db = await _openDb();
    try {
      final maps = await db.query(
        BlockConstants.tableName,
        orderBy: '${BlockConstants.positionKey} ASC',
      );
      final blocks = maps.map((m) => Block.fromDatabaseMap(m)).toList();
      logger.i('Fetched ${blocks.length} blocks from page $pageId');
      await _closeDb();
      return blocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to fetch blocks from page $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds a new block and returns its ID
  @override
  Future<String> addBlock(Block block) async {
    final db = await _openDb();
    try {
      final id = await db.insert(
        BlockConstants.tableName,
        block.toDatabaseMap(),
      );
      logger.i('Block added: ID $id in page $pageId');
      await _closeDb();
      return id.toString();
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add block in page $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates an existing block
  @override
  Future<bool> updateBlock(Block block) async {
    final db = await _openDb();
    try {
      final rowsAffected = await db.update(
        BlockConstants.tableName,
        block.toDatabaseMap(),
        where: '${BlockConstants.idKey} = ?',
        whereArgs: [block.id],
      );
      if (rowsAffected == 0) {
        logger.w('No block updated for ID ${block.id} in page $pageId');
        return false;
      }
      logger.i('Block updated: ID ${block.id} in page $pageId');
      await _closeDb();
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update block: ID ${block.id} in page $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes a block by ID
  @override
  Future<bool> deleteBlock(String id) async {
    final db = await _openDb();
    try {
      final rowsAffected = await db.delete(
        BlockConstants.tableName,
        where: '${BlockConstants.idKey} = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        logger.w('No block deleted for ID $id in page $pageId');
        return false;
      }
      logger.i('Block deleted: ID $id in page $pageId');
      await _closeDb();
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to delete block: ID $id in page $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates multiple blocks in a transaction
  @override
  Future<void> updateBlocks(List<Block> blocks) async {
    final db = await _openDb();
    try {
      await db.transaction((txn) async {
        for (final block in blocks) {
          final rowsAffected = await txn.update(
            BlockConstants.tableName,
            block.toDatabaseMap(),
            where: '${BlockConstants.idKey} = ?',
            whereArgs: [block.id],
          );
          if (rowsAffected == 0) {
            logger.w('No block updated for ID ${block.id} in page $pageId');
          }
        }
      });
      logger.i('Updated ${blocks.length} blocks in page $pageId');
      await _closeDb();
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update blocks in page $pageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
