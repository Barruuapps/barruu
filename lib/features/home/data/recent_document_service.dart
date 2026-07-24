import 'dart:io';

import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

const _kLastDocPath = 'continue_learning_doc_path';
const _kLastDocName = 'continue_learning_doc_name';
const _kLastDocPage = 'continue_learning_doc_page';

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Persists the most-recently opened document so the home screen can show
/// a "Continue Learning" card.
class RecentDocumentService {
  /// Saves the document that was just opened by the learner.
  Future<void> save({
    required String docPath,
    required String docName,
    required int pageIndex,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastDocPath, docPath);
      await prefs.setString(_kLastDocName, docName);
      await prefs.setInt(_kLastDocPage, pageIndex);
    } catch (e, st) {
      logger.e('RecentDocumentService.save failed', error: e, stackTrace: st);
    }
  }

  /// Returns [null] when there is no recently-opened document, or the
  /// document directory no longer exists on disk.
  Future<RecentDocumentEntry?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docPath = prefs.getString(_kLastDocPath);
      if (docPath == null) return null;
      // Verify directory still exists (user may have uninstalled the app).
      if (!Directory(docPath).existsSync()) return null;
      return RecentDocumentEntry(
        docDir: Directory(docPath),
        docName: prefs.getString(_kLastDocName) ?? '',
        pageIndex: prefs.getInt(_kLastDocPage) ?? 0,
      );
    } catch (e, st) {
      logger.e('RecentDocumentService.load failed', error: e, stackTrace: st);
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Value object
// ---------------------------------------------------------------------------

class RecentDocumentEntry {
  final Directory docDir;
  final String docName;
  final int pageIndex;

  const RecentDocumentEntry({
    required this.docDir,
    required this.docName,
    required this.pageIndex,
  });
}

// ---------------------------------------------------------------------------
// Riverpod
// ---------------------------------------------------------------------------

final recentDocumentServiceProvider = Provider<RecentDocumentService>((ref) {
  return RecentDocumentService();
});

final recentDocumentProvider = FutureProvider.autoDispose<RecentDocumentEntry?>(
  (ref) async {
    final svc = ref.read(recentDocumentServiceProvider);
    return svc.load();
  },
);
