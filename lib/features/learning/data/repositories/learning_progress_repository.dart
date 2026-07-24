import 'package:barruu/core/utils/app_logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Persists per-block assessment attempt data for learning progress tracking.
///
/// Schema: `learning_progress` table with columns:
///   document_id, block_id, block_type, attempt_count, correct_count,
///   last_attempted_at, next_review_at
///
/// The database file lives at `<appDocDir>/learning_progress.db` so it is
/// shared across all documents (joined on `document_id`).
class LearningProgressRepository {
  static const String _dbName = 'learning_progress.db';
  static const String _tableName = 'learning_progress';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> _database() async {
    if (_db != null && _db!.isOpen) return _db!;
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDir.path, _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        document_id       TEXT    NOT NULL,
        block_id          TEXT    NOT NULL,
        block_type        TEXT    NOT NULL,
        attempt_count     INTEGER NOT NULL DEFAULT 0,
        correct_count     INTEGER NOT NULL DEFAULT 0,
        last_attempted_at TEXT,
        next_review_at    TEXT,
        PRIMARY KEY (document_id, block_id)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lp_doc ON $_tableName (document_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lp_review ON $_tableName (next_review_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No-op for v1 → v1.
  }

  /// Records one attempt for [blockId] in [documentId].
  ///
  /// Upserts the row and bumps [attempt_count], optionally [correct_count].
  /// Sets [last_attempted_at] to now.
  Future<void> recordAttempt({
    required String documentId,
    required String blockId,
    required String blockType,
    required bool isCorrect,
  }) async {
    try {
      final db = await _database();
      final now = DateTime.now().toIso8601String();

      final existing = await db.query(
        _tableName,
        where: 'document_id = ? AND block_id = ?',
        whereArgs: [documentId, blockId],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(_tableName, {
          'document_id': documentId,
          'block_id': blockId,
          'block_type': blockType,
          'attempt_count': 1,
          'correct_count': isCorrect ? 1 : 0,
          'last_attempted_at': now,
          'next_review_at': null,
        });
      } else {
        final row = existing.first;
        final attempts = (row['attempt_count'] as int? ?? 0) + 1;
        final correct = (row['correct_count'] as int? ?? 0) + (isCorrect ? 1 : 0);
        await db.update(
          _tableName,
          {
            'attempt_count': attempts,
            'correct_count': correct,
            'last_attempted_at': now,
          },
          where: 'document_id = ? AND block_id = ?',
          whereArgs: [documentId, blockId],
        );
      }
    } catch (e, st) {
      logger.e('LearningProgressRepository.recordAttempt failed', error: e, stackTrace: st);
    }
  }

  /// Returns all progress rows for [documentId], ordered by [block_id].
  Future<List<LearningProgressEntry>> getProgressForDocument(
      String documentId) async {
    try {
      final db = await _database();
      final rows = await db.query(
        _tableName,
        where: 'document_id = ?',
        whereArgs: [documentId],
        orderBy: 'block_id ASC',
      );
      return rows.map(LearningProgressEntry.fromMap).toList();
    } catch (e, st) {
      logger.e('LearningProgressRepository.getProgressForDocument failed',
          error: e, stackTrace: st);
      return [];
    }
  }

  /// Deletes all progress rows for [documentId] (e.g. when the app is deleted).
  Future<void> deleteProgressForDocument(String documentId) async {
    try {
      final db = await _database();
      await db.delete(_tableName,
          where: 'document_id = ?', whereArgs: [documentId]);
    } catch (e, st) {
      logger.e('LearningProgressRepository.deleteProgressForDocument failed',
          error: e, stackTrace: st);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// A value-object representing one row in [LearningProgressRepository].
class LearningProgressEntry {
  final String documentId;
  final String blockId;
  final String blockType;
  final int attemptCount;
  final int correctCount;
  final DateTime? lastAttemptedAt;
  final DateTime? nextReviewAt;

  const LearningProgressEntry({
    required this.documentId,
    required this.blockId,
    required this.blockType,
    required this.attemptCount,
    required this.correctCount,
    this.lastAttemptedAt,
    this.nextReviewAt,
  });

  /// Accuracy as a value between 0.0 and 1.0, or null if no attempts.
  double? get accuracy =>
      attemptCount == 0 ? null : correctCount / attemptCount;

  factory LearningProgressEntry.fromMap(Map<String, dynamic> map) {
    return LearningProgressEntry(
      documentId: map['document_id'] as String,
      blockId: map['block_id'] as String,
      blockType: map['block_type'] as String,
      attemptCount: map['attempt_count'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
      lastAttemptedAt: map['last_attempted_at'] != null
          ? DateTime.tryParse(map['last_attempted_at'] as String)
          : null,
      nextReviewAt: map['next_review_at'] != null
          ? DateTime.tryParse(map['next_review_at'] as String)
          : null,
    );
  }
}
