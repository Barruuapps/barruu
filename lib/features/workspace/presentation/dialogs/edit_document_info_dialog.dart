import 'dart:io';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/presentation/controllers/documents_controller.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/cover_image_preview.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/document_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// A dialog for editing document information.
/// 
/// Allows the user to:
/// - Change document name
/// - Update description
/// - Select a new cover image
/// 
/// The dialog handles image selection, validation, and updating
/// the document metadata.
class EditDocumentInfoDialog extends ConsumerStatefulWidget {
  /// The directory containing the document
  final Directory doc;
  
  /// Initial metadata for the document
  final Map<String, dynamic> meta;
  
  /// Callback to show snackbar messages
  final void Function(String message) onShowSnackBar;

  const EditDocumentInfoDialog({
    super.key,
    required this.doc,
    required this.meta,
    required this.onShowSnackBar,
  });

  @override
  ConsumerState<EditDocumentInfoDialog> createState() => _EditDocumentInfoDialogState();
}

class _EditDocumentInfoDialogState extends ConsumerState<EditDocumentInfoDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String? _coverPath;
  String? _coverOriginalName;
  File? _coverImage;
  File? _newPickedCover;
  String? _newCoverOriginalName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meta[MetaFile.nameKey]);
    _descController = TextEditingController(text: widget.meta[MetaFile.descriptionKey]);
    _coverPath = widget.meta[MetaFile.coverKey];
    _coverOriginalName = widget.meta[MetaFile.coverOriginalNameKey];
    _coverImage = _coverPath != null && _coverPath!.isNotEmpty ? File(_coverPath!) : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogWidth = MediaQuery.of(context).size.width;
    final maxDialogWidth = dialogWidth > 600 ? 500.0 : dialogWidth * 0.9;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogWidth > 600 ? 40 : 16,
        vertical: 24,
      ),
      title: Text(
        'Edit Document Info',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!kIsWeb)
                GestureDetector(
                  onTap: _handleImagePick,
                  child: CoverImagePreview(
                    image: _newPickedCover ?? _coverImage,
                    originalName: _newCoverOriginalName ?? _coverOriginalName,
                    theme: theme,
                  ),
                ),
              const SizedBox(height: 12),
              DocumentTextField(
                controller: _nameController,
                label: 'Document Name *',
                theme: theme,
              ),
              const SizedBox(height: 12),
              DocumentTextField(
                controller: _descController,
                label: 'Description',
                theme: theme,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Cancel',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
          ),
          child: Text(
            'Save',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Handles image selection from gallery
  Future<void> _handleImagePick() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked != null && mounted) {
        if (picked.path.contains('..')) {
          widget.onShowSnackBar('Invalid image path');
          return;
        }
        setState(() {
          _newPickedCover = File(picked.path);
          _newCoverOriginalName = picked.name;
        });
      }
    } catch (e, stackTrace) {
      logger.e('Image picker failed', error: e, stackTrace: stackTrace);
      widget.onShowSnackBar('Failed to select image');
    }
  }

  /// Handles saving the document information
  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      widget.onShowSnackBar('Document name is required');
      return;
    }
    
    try {
      final documentService = ref.read(documentServiceProvider);
      String newCoverPath = _coverPath ?? '';
      String newCoverOriginalNameFinal = _coverOriginalName ?? '';
      
      if (_newPickedCover != null && !kIsWeb) {
        final imagesDir = Directory('${widget.doc.path}/media/images');
        await imagesDir.create(recursive: true);
        final sanitizedName = _newCoverOriginalName!.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        newCoverPath = '${imagesDir.path}/${const Uuid().v4()}_$sanitizedName';
        newCoverOriginalNameFinal = _newCoverOriginalName!;
        await _newPickedCover!.copy(newCoverPath);
      }
      
      final success = await documentService.updateDocumentInfo(
        widget.doc,
        _nameController.text.trim(),
        _descController.text.trim(),
        '',
        newCoverPath,
        coverOriginalName: newCoverOriginalNameFinal,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        if (success) {
          await ref.read(documentsProvider.notifier).loadDocuments();
          widget.onShowSnackBar('Document updated');
        } else {
          widget.onShowSnackBar('Failed to update document');
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to update document', error: e, stackTrace: stackTrace);
      widget.onShowSnackBar('Error updating document');
    }
  }
}

/// Shows the edit document info dialog
Future<void> showEditDocumentInfoDialog({
  required BuildContext context,
  required Directory doc,
  required Map<String, dynamic> meta,
  required void Function(String message) onShowSnackBar,
}) async {
  final theme = Theme.of(context);
  await showDialog(
    context: context,
    barrierColor: theme.colorScheme.onSurface.withOpacity(0.3),
    builder: (ctx) => EditDocumentInfoDialog(
      doc: doc,
      meta: meta,
      onShowSnackBar: onShowSnackBar,
    ),
  );
}
