import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// Service for checking and managing document edit access authorization.
///
/// This service handles the complete authorization workflow for editing documents,
/// including:
/// - Edit permission checks
/// - User feedback for authorization failures
///
/// The service ensures that only authorized users can edit documents.
class DocumentAuthService {
  /// Checks if the user has edit access to the document.
  ///
  /// This method performs the following checks:
  /// 1. Verifies document metadata exists
  /// 2. Verifies edit permissions
  ///
  /// [context] is the build context for navigation and showing dialogs.
  /// [ref] is the widget ref for accessing providers.
  /// [docDir] is the document directory to check access for.
  ///
  /// Returns a [DocumentAuthResult] indicating whether access was granted
  /// and whether the check is complete.
  static Future<DocumentAuthResult> checkEditAccess(
    BuildContext context,
    WidgetRef ref,
    Directory docDir,
  ) async {
    try {
      final documentService = ref.read(documentServiceProvider);

      // Check if user can edit
      final canEdit = await documentService.canEditDocument(docDir);

      if (canEdit) {
        // Initialize the edit controller
        ref.read(editDocumentControllerProvider(docDir));
        return const DocumentAuthResult(isAuthorized: true, isChecking: false);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have permission to edit this document'),
            ),
          );
          context.go('/');
        }
        return const DocumentAuthResult(isAuthorized: false, isChecking: false);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to check edit access', error: e, stackTrace: stackTrace);
      return const DocumentAuthResult(isAuthorized: false, isChecking: false);
    }
  }
}

/// Result of a document authorization check.
///
/// This class encapsulates the state of the authorization check,
/// indicating both whether access was granted and whether the
/// check process has completed.
class DocumentAuthResult {
  /// Whether the user is authorized to edit the document.
  final bool isAuthorized;

  /// Whether the authorization check is still in progress.
  final bool isChecking;

  /// Creates a document auth result.
  ///
  /// [isAuthorized] indicates if access was granted.
  /// [isChecking] indicates if the check is still in progress.
  const DocumentAuthResult({
    required this.isAuthorized,
    required this.isChecking,
  });
}
