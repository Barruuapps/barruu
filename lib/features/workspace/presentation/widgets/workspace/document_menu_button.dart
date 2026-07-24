import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// A popup menu button widget for document actions.
/// 
/// Provides actions for:
/// - Editing document info
/// - Publishing the document
/// - Exporting the document
/// - Deleting the document
class DocumentMenuButton extends ConsumerWidget {
  /// The directory containing the document
  final Directory doc;
  
  /// Callback for showing edit info dialog
  final Future<void> Function(Directory doc) onEditInfo;
  
  /// Callback for showing publish dialog
  final Future<void> Function(Directory doc) onPublish;
  
  /// Callback for showing snackbar messages
  final void Function(String message, {bool isError}) onShowSnackBar;
  
  /// Callback for reloading documents
  final VoidCallback onReloadDocuments;

  const DocumentMenuButton({
    super.key,
    required this.doc,
    required this.onEditInfo,
    required this.onPublish,
    required this.onShowSnackBar,
    required this.onReloadDocuments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(
        IconsaxPlusLinear.more,
        size: 22,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      onSelected: (value) => _handleMenuAction(context, ref, value),
      itemBuilder: (context) => _buildMenuItems(context, ref),
      offset: const Offset(0, 36),
    );
  }

  /// Builds the menu items
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, WidgetRef ref) {
    final menuTheme = Theme.of(context);
    
    return [
      PopupMenuItem(
        value: 'edit',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menuTheme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconsaxPlusLinear.edit,
                size: 16,
                color: menuTheme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Info',
              style: menuTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: menuTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'publish',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menuTheme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconsaxPlusLinear.share,
                size: 16,
                color: menuTheme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Publish',
              style: menuTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: menuTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'export',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menuTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconsaxPlusLinear.export,
                size: 16,
                color: menuTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Export',
              style: menuTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: menuTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'export_pdf',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menuTheme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                size: 16,
                color: menuTheme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Export as PDF',
              style: menuTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: menuTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menuTheme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconsaxPlusLinear.trash,
                size: 16,
                color: menuTheme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete',
              style: menuTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: menuTheme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Handles menu action selection
  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, String value) async {
    final documentService = ref.read(documentServiceProvider);
    try {
      if (value == 'edit') {
        await onEditInfo(doc);
      } else if (value == 'delete') {
        final confirmed = await _showDeleteConfirmation(context);
        if (confirmed && context.mounted) {
          final success = await documentService.deleteDocument(doc);
          if (success) {
            onReloadDocuments();
            onShowSnackBar('Document deleted');
          } else {
            onShowSnackBar('Failed to delete document');
          }
        }
      } else if (value == 'export') {
        if (kIsWeb) {
          onShowSnackBar('Export not supported on web');
          return;
        }
        await _handleExport(context, documentService);
      } else if (value == 'export_pdf') {
        if (kIsWeb) {
          onShowSnackBar('PDF export not supported on web');
          return;
        }
        await _handleExportPdf(context, documentService);
      } else if (value == 'publish') {
        await onPublish(doc);
      }
    } catch (e, stackTrace) {
      logger.e('Action $value failed', error: e, stackTrace: stackTrace);
      onShowSnackBar('Action failed');
    }
  }

  /// Shows delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: dialogTheme.colorScheme.surfaceContainerLowest,
          title: Text(
            'Delete Document',
            style: dialogTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: dialogTheme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure? This action cannot be undone.',
            style: dialogTheme.textTheme.bodyMedium?.copyWith(
              color: dialogTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: dialogTheme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: dialogTheme.colorScheme.error,
                foregroundColor: dialogTheme.colorScheme.onError,
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: dialogTheme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dialogTheme.colorScheme.onError,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Handles document export
  Future<void> _handleExport(BuildContext context, DocumentService documentService) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: dialogTheme.colorScheme.surfaceContainerLowest,
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerCircularProgress(
                  size: 56,
                  color: dialogTheme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Exporting...',
                  style: dialogTheme.textTheme.titleMedium?.copyWith(
                    color: dialogTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: dialogTheme.textTheme.bodySmall?.copyWith(
                    color: dialogTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    final bipyFilePath = await documentService.exportDocumentEncrypted(doc);
    if (context.mounted) {
      Navigator.of(context).pop();
      if (bipyFilePath != null) {
        onShowSnackBar('Document exported');
      } else {
        onShowSnackBar('Failed to export document');
      }
    }
  }

  /// Handles document export as PDF
  Future<void> _handleExportPdf(BuildContext context, DocumentService documentService) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: dialogTheme.colorScheme.surfaceContainerLowest,
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerCircularProgress(
                  size: 56,
                  color: dialogTheme.colorScheme.secondary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Generating PDF...',
                  style: dialogTheme.textTheme.titleMedium?.copyWith(
                    color: dialogTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: dialogTheme.textTheme.bodySmall?.copyWith(
                    color: dialogTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final success = await documentService.exportAsPdf(doc);
    if (context.mounted) {
      Navigator.of(context).pop();
      if (success) {
        onShowSnackBar('PDF exported successfully');
      } else {
        onShowSnackBar('Failed to export PDF', isError: true);
      }
    }
  }

}
