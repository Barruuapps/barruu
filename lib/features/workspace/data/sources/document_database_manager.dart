import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:sqflite/sqflite.dart';

/// Manages database operations for document storage.
///
/// This class handles:
/// - Database schema creation
/// - Index management for query optimization
/// - Database migrations between versions
/// - Database opening/closing with proper configuration
///
/// All database operations are centralized here to ensure consistency
/// and make it easier to maintain database logic across the application.
class DocumentDatabaseManager {
  /// Creates indexes for query optimization.
  ///
  /// Indexes significantly improve query performance for common operations
  /// like finding blocks by position or type.
  ///
  /// Throws an exception if index creation fails.
  Future<void> createIndexes(Database db) async {
    try {
      for (final indexSql in BlockConstants.allIndexesSql) {
        await db.execute(indexSql);
      }
      logger.i('Successfully created database indexes');
    } catch (e, stackTrace) {
      logger.e('Failed to create indexes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Performs database migration from old version to new version.
  ///
  /// This method handles incremental migrations, allowing the database
  /// to be upgraded smoothly without data loss.
  ///
  /// Parameters:
  /// - [db]: The database to migrate
  /// - [oldVersion]: The current database version
  /// - [newVersion]: The target database version
  ///
  /// Throws an exception if migration fails.
  Future<void> performDatabaseMigration(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    logger.i('Migrating database from version $oldVersion to $newVersion');

    try {
      // Migration from version 1 to 2: Add indexes
      if (oldVersion < 2 && newVersion >= 2) {
        await createIndexes(db);
        logger.i('Successfully migrated to version 2');
      }

      // Future migrations can be added here
      // if (oldVersion < 3 && newVersion >= 3) { ... }
    } catch (e, stackTrace) {
      logger.e('Database migration failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Creates the database schema for a page with optimized indexes.
  ///
  /// This sets up the necessary tables and indexes for storing page blocks.
  /// Called when creating new page databases.
  ///
  /// Parameters:
  /// - [db]: The database to initialize
  ///
  /// Throws an exception if schema creation fails.
  Future<void> createPageDatabaseSchema(Database db) async {
    try {
      // Create the main table
      await db.execute(BlockConstants.createTableSql);

      // Create indexes for query optimization
      await createIndexes(db);

      logger.i('Created page database schema with indexes');
    } catch (e, stackTrace) {
      logger.e('Failed to create database schema',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Opens a page database with proper configuration.
  ///
  /// This method opens a page database file with the correct version,
  /// schema creation, and migration handlers.
  ///
  /// Parameters:
  /// - [path]: Full path to the database file
  ///
  /// Returns the opened database instance.
  ///
  /// Throws an exception if the database cannot be opened.
  Future<Database> openPageDatabase(String path) async {
    try {
      final db = await openDatabase(
        path,
        version: BlockConstants.databaseVersion,
        onCreate: (db, version) async {
          await createPageDatabaseSchema(db);
        },
        onUpgrade: performDatabaseMigration,
      );
      logger.i('Opened page database: $path');
      return db;
    } catch (e, stackTrace) {
      logger.e('Failed to open page database: $path',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Safely closes a database connection.
  ///
  /// Parameters:
  /// - [db]: The database to close
  ///
  /// Logs any errors but doesn't throw to avoid disrupting cleanup operations.
  Future<void> closeDatabase(Database db) async {
    try {
      await db.close();
      logger.i('Closed database connection');
    } catch (e, stackTrace) {
      logger.e('Failed to close database', error: e, stackTrace: stackTrace);
      // Don't rethrow - closing errors should not disrupt other operations
    }
  }
}
