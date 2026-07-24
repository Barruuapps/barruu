import 'dart:convert';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/domain/entities/document_interaction_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking user interactions with documents
///
/// This service tracks:
/// - Time spent on documents
/// - Question attempts and accuracy
/// - Topic-level performance
/// - Daily interaction patterns
class DocumentInteractionService {
  static const String _interactionsKeyPrefix = 'document_interactions_';

  /// Record a session start for a document
  Future<void> startSession(String documentId) async {
    final stats = await getDocumentStats(documentId);

    final updatedStats = stats.copyWith(
      lastAccessed: DateTime.now(),
      totalSessions: stats.totalSessions + 1,
    );

    await _saveDocumentStats(updatedStats);
    logger.i('Started session for document: $documentId');
  }

  /// Record time spent on a document
  Future<void> recordTimeSpent(String documentId, Duration timeSpent) async {
    final stats = await getDocumentStats(documentId);
    final today = _normalizeDate(DateTime.now());

    // Update total time
    final updatedStats = stats.copyWith(
      totalTimeSpent: stats.totalTimeSpent + timeSpent,
      lastAccessed: DateTime.now(),
    );

    // Update daily interaction
    final dailyInteractions = List<DailyDocumentInteraction>.from(
      stats.dailyInteractions,
    );
    final todayIndex = dailyInteractions.indexWhere(
      (d) => _isSameDay(d.date, today),
    );

    if (todayIndex != -1) {
      dailyInteractions[todayIndex] = dailyInteractions[todayIndex].merge(
        DailyDocumentInteraction(date: today, timeSpent: timeSpent),
      );
    } else {
      dailyInteractions.add(
        DailyDocumentInteraction(date: today, timeSpent: timeSpent),
      );
    }

    await _saveDocumentStats(
      updatedStats.copyWith(dailyInteractions: dailyInteractions),
    );
    logger.i('Recorded ${timeSpent.inSeconds}s for document: $documentId');
  }

  /// Record a question attempt
  Future<void> recordQuestionAttempt({
    required String documentId,
    required String? topicId,
    required String? topicName,
    required bool isCorrect,
    String? blockId,
  }) async {
    final stats = await getDocumentStats(documentId);
    final today = _normalizeDate(DateTime.now());

    // Update overall stats
    var updatedStats = stats.copyWith(
      totalQuestionsAttempted: stats.totalQuestionsAttempted + 1,
      totalQuestionsCorrect: stats.totalQuestionsCorrect + (isCorrect ? 1 : 0),
      totalQuestionsIncorrect:
          stats.totalQuestionsIncorrect + (isCorrect ? 0 : 1),
      lastAccessed: DateTime.now(),
    );

    // Update topic performance if topic is provided
    if (topicId != null && topicName != null && topicId.isNotEmpty) {
      final topicPerformances = Map<String, TopicPerformance>.from(
        stats.topicPerformances,
      );
      final existingTopic = topicPerformances[topicId];

      if (existingTopic != null) {
        topicPerformances[topicId] = existingTopic.copyWith(
          questionsAttempted: existingTopic.questionsAttempted + 1,
          questionsCorrect:
              existingTopic.questionsCorrect + (isCorrect ? 1 : 0),
          questionsIncorrect:
              existingTopic.questionsIncorrect + (isCorrect ? 0 : 1),
          lastPracticed: DateTime.now(),
        );
      } else {
        topicPerformances[topicId] = TopicPerformance(
          topicId: topicId,
          topicName: topicName,
          questionsAttempted: 1,
          questionsCorrect: isCorrect ? 1 : 0,
          questionsIncorrect: isCorrect ? 0 : 1,
          lastPracticed: DateTime.now(),
        );
      }

      updatedStats = updatedStats.copyWith(
        topicPerformances: topicPerformances,
      );
    }

    // Update daily interaction
    final dailyInteractions = List<DailyDocumentInteraction>.from(
      stats.dailyInteractions,
    );
    final todayIndex = dailyInteractions.indexWhere(
      (d) => _isSameDay(d.date, today),
    );

    final blocksInteracted = <String, int>{};
    if (blockId != null) {
      blocksInteracted[blockId] = 1;
    }

    final todayInteraction = DailyDocumentInteraction(
      date: today,
      questionsAttempted: 1,
      questionsCorrect: isCorrect ? 1 : 0,
      questionsIncorrect: isCorrect ? 0 : 1,
      blocksInteractedWith: blocksInteracted,
    );

    if (todayIndex != -1) {
      dailyInteractions[todayIndex] = dailyInteractions[todayIndex].merge(
        todayInteraction,
      );
    } else {
      dailyInteractions.add(todayInteraction);
    }

    await _saveDocumentStats(
      updatedStats.copyWith(dailyInteractions: dailyInteractions),
    );
    logger.i(
      'Recorded question attempt (${isCorrect ? 'correct' : 'incorrect'}) for document: $documentId',
    );
  }

  /// Record interaction with a specific block
  Future<void> recordBlockInteraction(String documentId, String blockId) async {
    final stats = await getDocumentStats(documentId);
    final today = _normalizeDate(DateTime.now());

    // Update daily interaction
    final dailyInteractions = List<DailyDocumentInteraction>.from(
      stats.dailyInteractions,
    );
    final todayIndex = dailyInteractions.indexWhere(
      (d) => _isSameDay(d.date, today),
    );

    final blocksInteracted = <String, int>{blockId: 1};
    final todayInteraction = DailyDocumentInteraction(
      date: today,
      blocksInteractedWith: blocksInteracted,
    );

    if (todayIndex != -1) {
      dailyInteractions[todayIndex] = dailyInteractions[todayIndex].merge(
        todayInteraction,
      );
    } else {
      dailyInteractions.add(todayInteraction);
    }

    await _saveDocumentStats(
      stats.copyWith(
        dailyInteractions: dailyInteractions,
        lastAccessed: DateTime.now(),
      ),
    );
  }

  /// Get statistics for a specific document
  Future<DocumentInteractionStats> getDocumentStats(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _interactionsKeyPrefix + documentId;
    final statsJson = prefs.getString(key);

    if (statsJson == null) {
      // Return new stats
      return DocumentInteractionStats(documentId: documentId);
    }

    try {
      return DocumentInteractionStats.fromJson(json.decode(statsJson));
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse document stats',
        error: e,
        stackTrace: stackTrace,
      );
      return DocumentInteractionStats(documentId: documentId);
    }
  }

  /// Get all documents with recorded interactions
  Future<List<String>> getAllTrackedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    return keys
        .where((key) => key.startsWith(_interactionsKeyPrefix))
        .map((key) => key.substring(_interactionsKeyPrefix.length))
        .toList();
  }

  /// Get statistics for multiple documents
  Future<Map<String, DocumentInteractionStats>> getMultipleDocumentStats(
    List<String> documentIds,
  ) async {
    final Map<String, DocumentInteractionStats> statsMap = {};

    for (final documentId in documentIds) {
      statsMap[documentId] = await getDocumentStats(documentId);
    }

    return statsMap;
  }

  /// Clear statistics for a specific document
  Future<void> clearDocumentStats(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _interactionsKeyPrefix + documentId;
    await prefs.remove(key);
    logger.i('Cleared stats for document: $documentId');
  }

  /// Clear all document statistics
  Future<void> clearAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_interactionsKeyPrefix)) {
        await prefs.remove(key);
      }
    }

    logger.i('Cleared all document stats');
  }

  /// Save document statistics
  Future<void> _saveDocumentStats(DocumentInteractionStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _interactionsKeyPrefix + stats.documentId;
    final statsJson = json.encode(stats.toJson());
    await prefs.setString(key, statsJson);
  }

  /// Normalize date to midnight
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
