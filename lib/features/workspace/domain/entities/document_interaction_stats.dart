
/// Statistics for a specific topic within a document
class TopicPerformance {
  final String topicId;
  final String topicName;
  final int questionsAttempted;
  final int questionsCorrect;
  final int questionsIncorrect;
  final Duration timeSpent;
  final DateTime lastPracticed;

  TopicPerformance({
    required this.topicId,
    required this.topicName,
    this.questionsAttempted = 0,
    this.questionsCorrect = 0,
    this.questionsIncorrect = 0,
    this.timeSpent = Duration.zero,
    DateTime? lastPracticed,
  }) : lastPracticed = lastPracticed ?? DateTime.now();

  /// Calculate accuracy percentage
  double get accuracy {
    if (questionsAttempted == 0) return 0.0;
    return (questionsCorrect / questionsAttempted) * 100;
  }

  /// Determine mastery level (0-3: beginner, intermediate, proficient, mastered)
  int get masteryLevel {
    if (questionsAttempted < 5) return 0; // Beginner - not enough data
    if (accuracy >= 90) return 3; // Mastered
    if (accuracy >= 70) return 2; // Proficient
    if (accuracy >= 50) return 1; // Intermediate
    return 0; // Beginner
  }

  /// Get mastery level as a string
  String get masteryLevelString {
    switch (masteryLevel) {
      case 3:
        return 'Mastered';
      case 2:
        return 'Proficient';
      case 1:
        return 'Intermediate';
      default:
        return 'Beginner';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'questionsIncorrect': questionsIncorrect,
      'timeSpent': timeSpent.inSeconds,
      'lastPracticed': lastPracticed.toIso8601String(),
    };
  }

  factory TopicPerformance.fromJson(Map<String, dynamic> json) {
    return TopicPerformance(
      topicId: json['topicId'] ?? '',
      topicName: json['topicName'] ?? '',
      questionsAttempted: json['questionsAttempted'] ?? 0,
      questionsCorrect: json['questionsCorrect'] ?? 0,
      questionsIncorrect: json['questionsIncorrect'] ?? 0,
      timeSpent: Duration(seconds: json['timeSpent'] ?? 0),
      lastPracticed: json['lastPracticed'] != null
          ? DateTime.parse(json['lastPracticed'])
          : DateTime.now(),
    );
  }

  /// Create a copy with updated values
  TopicPerformance copyWith({
    String? topicId,
    String? topicName,
    int? questionsAttempted,
    int? questionsCorrect,
    int? questionsIncorrect,
    Duration? timeSpent,
    DateTime? lastPracticed,
  }) {
    return TopicPerformance(
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      questionsAttempted: questionsAttempted ?? this.questionsAttempted,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      questionsIncorrect: questionsIncorrect ?? this.questionsIncorrect,
      timeSpent: timeSpent ?? this.timeSpent,
      lastPracticed: lastPracticed ?? this.lastPracticed,
    );
  }
}

/// Daily interaction statistics for a document
class DailyDocumentInteraction {
  final DateTime date;
  final Duration timeSpent;
  final int questionsAttempted;
  final int questionsCorrect;
  final int questionsIncorrect;
  final Map<String, int> blocksInteractedWith; // blockId -> interaction count

  DailyDocumentInteraction({
    required this.date,
    this.timeSpent = Duration.zero,
    this.questionsAttempted = 0,
    this.questionsCorrect = 0,
    this.questionsIncorrect = 0,
    Map<String, int>? blocksInteractedWith,
  }) : blocksInteractedWith = blocksInteractedWith ?? {};

  /// Calculate accuracy percentage
  double get accuracy {
    if (questionsAttempted == 0) return 0.0;
    return (questionsCorrect / questionsAttempted) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'timeSpent': timeSpent.inSeconds,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'questionsIncorrect': questionsIncorrect,
      'blocksInteractedWith': blocksInteractedWith,
    };
  }

  factory DailyDocumentInteraction.fromJson(Map<String, dynamic> json) {
    return DailyDocumentInteraction(
      date: DateTime.parse(json['date']),
      timeSpent: Duration(seconds: json['timeSpent'] ?? 0),
      questionsAttempted: json['questionsAttempted'] ?? 0,
      questionsCorrect: json['questionsCorrect'] ?? 0,
      questionsIncorrect: json['questionsIncorrect'] ?? 0,
      blocksInteractedWith: json['blocksInteractedWith'] != null
          ? Map<String, int>.from(json['blocksInteractedWith'])
          : {},
    );
  }

  /// Merge with another daily interaction
  DailyDocumentInteraction merge(DailyDocumentInteraction other) {
    final mergedBlocks = Map<String, int>.from(blocksInteractedWith);
    other.blocksInteractedWith.forEach((key, value) {
      mergedBlocks[key] = (mergedBlocks[key] ?? 0) + value;
    });

    return DailyDocumentInteraction(
      date: date,
      timeSpent: timeSpent + other.timeSpent,
      questionsAttempted: questionsAttempted + other.questionsAttempted,
      questionsCorrect: questionsCorrect + other.questionsCorrect,
      questionsIncorrect: questionsIncorrect + other.questionsIncorrect,
      blocksInteractedWith: mergedBlocks,
    );
  }
}

/// Comprehensive statistics for a document
class DocumentInteractionStats {
  final String documentId;
  final Duration totalTimeSpent;
  final int totalQuestionsAttempted;
  final int totalQuestionsCorrect;
  final int totalQuestionsIncorrect;
  final Map<String, TopicPerformance> topicPerformances;
  final List<DailyDocumentInteraction> dailyInteractions;
  final DateTime firstOpened;
  final DateTime lastAccessed;
  final int totalSessions;

  DocumentInteractionStats({
    required this.documentId,
    this.totalTimeSpent = Duration.zero,
    this.totalQuestionsAttempted = 0,
    this.totalQuestionsCorrect = 0,
    this.totalQuestionsIncorrect = 0,
    Map<String, TopicPerformance>? topicPerformances,
    List<DailyDocumentInteraction>? dailyInteractions,
    DateTime? firstOpened,
    DateTime? lastAccessed,
    this.totalSessions = 0,
  })  : topicPerformances = topicPerformances ?? {},
        dailyInteractions = dailyInteractions ?? [],
        firstOpened = firstOpened ?? DateTime.now(),
        lastAccessed = lastAccessed ?? DateTime.now();

  /// Calculate overall accuracy
  double get overallAccuracy {
    if (totalQuestionsAttempted == 0) return 0.0;
    return (totalQuestionsCorrect / totalQuestionsAttempted) * 100;
  }

  /// Get average time per session
  Duration get averageTimePerSession {
    if (totalSessions == 0) return Duration.zero;
    return Duration(seconds: totalTimeSpent.inSeconds ~/ totalSessions);
  }

  /// Get weak topics (accuracy < 60%)
  List<TopicPerformance> get weakTopics {
    return topicPerformances.values
        .where((topic) => topic.accuracy < 60 && topic.questionsAttempted >= 3)
        .toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
  }

  /// Get strong topics (accuracy >= 80%)
  List<TopicPerformance> get strongTopics {
    return topicPerformances.values
        .where((topic) => topic.accuracy >= 80 && topic.questionsAttempted >= 3)
        .toList()
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));
  }

  /// Get topics that need practice (not practiced in 7+ days)
  List<TopicPerformance> get topicsNeedingPractice {
    final now = DateTime.now();
    return topicPerformances.values
        .where((topic) =>
            now.difference(topic.lastPracticed).inDays >= 7 &&
            topic.masteryLevel < 3)
        .toList()
      ..sort((a, b) => a.lastPracticed.compareTo(b.lastPracticed));
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'totalTimeSpent': totalTimeSpent.inSeconds,
      'totalQuestionsAttempted': totalQuestionsAttempted,
      'totalQuestionsCorrect': totalQuestionsCorrect,
      'totalQuestionsIncorrect': totalQuestionsIncorrect,
      'topicPerformances':
          topicPerformances.map((key, value) => MapEntry(key, value.toJson())),
      'dailyInteractions':
          dailyInteractions.map((e) => e.toJson()).toList(),
      'firstOpened': firstOpened.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'totalSessions': totalSessions,
    };
  }

  factory DocumentInteractionStats.fromJson(Map<String, dynamic> json) {
    final Map<String, TopicPerformance> topics = {};
    if (json['topicPerformances'] != null) {
      (json['topicPerformances'] as Map<String, dynamic>).forEach((key, value) {
        topics[key] = TopicPerformance.fromJson(value);
      });
    }

    return DocumentInteractionStats(
      documentId: json['documentId'] ?? '',
      totalTimeSpent: Duration(seconds: json['totalTimeSpent'] ?? 0),
      totalQuestionsAttempted: json['totalQuestionsAttempted'] ?? 0,
      totalQuestionsCorrect: json['totalQuestionsCorrect'] ?? 0,
      totalQuestionsIncorrect: json['totalQuestionsIncorrect'] ?? 0,
      topicPerformances: topics,
      dailyInteractions: (json['dailyInteractions'] as List<dynamic>?)
              ?.map((e) => DailyDocumentInteraction.fromJson(e))
              .toList() ??
          [],
      firstOpened: json['firstOpened'] != null
          ? DateTime.parse(json['firstOpened'])
          : DateTime.now(),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : DateTime.now(),
      totalSessions: json['totalSessions'] ?? 0,
    );
  }

  /// Create a copy with updated values
  DocumentInteractionStats copyWith({
    String? documentId,
    Duration? totalTimeSpent,
    int? totalQuestionsAttempted,
    int? totalQuestionsCorrect,
    int? totalQuestionsIncorrect,
    Map<String, TopicPerformance>? topicPerformances,
    List<DailyDocumentInteraction>? dailyInteractions,
    DateTime? firstOpened,
    DateTime? lastAccessed,
    int? totalSessions,
  }) {
    return DocumentInteractionStats(
      documentId: documentId ?? this.documentId,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      totalQuestionsAttempted:
          totalQuestionsAttempted ?? this.totalQuestionsAttempted,
      totalQuestionsCorrect:
          totalQuestionsCorrect ?? this.totalQuestionsCorrect,
      totalQuestionsIncorrect:
          totalQuestionsIncorrect ?? this.totalQuestionsIncorrect,
      topicPerformances: topicPerformances ?? this.topicPerformances,
      dailyInteractions: dailyInteractions ?? this.dailyInteractions,
      firstOpened: firstOpened ?? this.firstOpened,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}
