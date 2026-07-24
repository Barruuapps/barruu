import 'package:barruu/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Singleton repository provider — shared across the whole app.
final learningProgressRepositoryProvider =
    Provider<LearningProgressRepository>((ref) {
  final repo = LearningProgressRepository();
  ref.onDispose(repo.close);
  return repo;
});

/// Notifier that exposes [recordAttempt] and the current list of entries for
/// a document.  Use [learningProgressProvider(documentId)] to watch progress.
class LearningProgressNotifier
    extends StateNotifier<List<LearningProgressEntry>> {
  final LearningProgressRepository _repo;
  final String documentId;

  LearningProgressNotifier(this._repo, this.documentId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final entries = await _repo.getProgressForDocument(documentId);
    if (mounted) state = entries;
  }

  /// Records one attempt and refreshes the local state.
  Future<void> recordAttempt({
    required String blockId,
    required String blockType,
    required bool isCorrect,
  }) async {
    await _repo.recordAttempt(
      documentId: documentId,
      blockId: blockId,
      blockType: blockType,
      isCorrect: isCorrect,
    );
    await _load();
  }

  /// Returns total attempted blocks and overall accuracy for this document.
  ({int attempted, int total, double accuracy}) get summary {
    if (state.isEmpty) return (attempted: 0, total: 0, accuracy: 0.0);
    final attempted = state.where((e) => e.attemptCount > 0).length;
    final totalCorrect = state.fold<int>(0, (s, e) => s + e.correctCount);
    final totalAttempts = state.fold<int>(0, (s, e) => s + e.attemptCount);
    return (
      attempted: attempted,
      total: state.length,
      accuracy: totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts,
    );
  }
}

/// Family provider: one notifier per documentId.
final learningProgressProvider = StateNotifierProvider.family<
    LearningProgressNotifier, List<LearningProgressEntry>, String>(
  (ref, documentId) {
    final repo = ref.watch(learningProgressRepositoryProvider);
    return LearningProgressNotifier(repo, documentId);
  },
);
