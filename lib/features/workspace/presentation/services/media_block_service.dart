import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/presentation/widgets/dialogs/media_source_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/dialogs/url_input_dialog.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// Service for handling media block additions to documents.
///
/// This service manages the workflow of adding image, video, and audio blocks
/// to a document. It handles:
/// - Presenting source selection dialogs (camera, file, URL)
/// - Processing different media sources
/// - Downloading media from URLs
/// - Error handling and user feedback
///
/// The service coordinates between the UI layer and the document controller
/// to ensure a smooth user experience when adding media content.
class MediaBlockService {
  /// Handles adding a media block (image, video, or audio) to a document.
  ///
  /// This method presents a dialog to the user to select the media source
  /// (camera, file, or URL), then processes the selection and adds the
  /// appropriate block to the document.
  ///
  /// [context] is the build context for showing dialogs and snackbars.
  /// [ref] is the widget ref for accessing providers.
  /// [docDir] is the document directory where the block will be added.
  /// [type] is the type of media block to add (image, video, or audio).
  ///
  /// Throws an exception if the block type is not a media type.
  static Future<void> handleMediaBlockAdd(
    BuildContext context,
    WidgetRef ref,
    Directory docDir,
    BlockType type,
  ) async {
    final controller = ref.read(editDocumentControllerProvider(docDir).notifier);

    String dialogTitle;
    String? cameraLabel;

    if (type == BlockType.image) {
      dialogTitle = 'Add Image';
      cameraLabel = 'Take';
    } else if (type == BlockType.video) {
      dialogTitle = 'Add Video';
      cameraLabel = 'Record';
    } else if (type == BlockType.audio) {
      dialogTitle = 'Add Audio';
      cameraLabel = 'Record';
    } else {
      return;
    }

    final source = await MediaSourceDialog.show(
      context,
      title: dialogTitle,
      cameraLabel: cameraLabel,
    );

    if (source == null || !context.mounted) return;

    try {
      switch (source) {
        case MediaSource.url:
          await _handleUrlSource(context, ref, docDir, type, controller);
          break;

        case MediaSource.file:
          await _handleFileSource(type, controller);
          break;

        case MediaSource.camera:
          await _handleCameraSource(type, controller);
          break;
      }
    } catch (e, stackTrace) {
      logger.e('Failed to add media block', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        UIUtils.showSnackBar(
          context,
          'Failed to add ${type.displayName}: $e',
          isError: true,
        );
      }
    }
  }

  /// Handles adding media from a URL source.
  ///
  /// Prompts the user for a URL, validates it, and downloads the media.
  static Future<void> _handleUrlSource(
    BuildContext context,
    WidgetRef ref,
    Directory docDir,
    BlockType type,
    dynamic controller,
  ) async {
    final url = await UrlInputDialog.show(
      context,
      title: 'Enter ${type.displayName} URL',
      hint: 'https://example.com/${type.displayName.toLowerCase()}',
    );

    if (url == null || !context.mounted) return;

    // Show loading indicator with proper capitalization
    String mediaType = type == BlockType.image
        ? 'Image'
        : type == BlockType.video
        ? 'Video'
        : 'Audio';
    UIUtils.showSnackBar(context, 'Downloading $mediaType...');

    if (type == BlockType.image) {
      await controller.addImageFromUrl(url);
    } else if (type == BlockType.video) {
      await controller.addVideoFromUrl(url);
    } else if (type == BlockType.audio) {
      await controller.addAudioFromUrl(url);
    }
  }

  /// Handles adding media from a file source.
  ///
  /// Opens the file picker and allows the user to select a media file.
  static Future<void> _handleFileSource(
    BlockType type,
    dynamic controller,
  ) async {
    if (type == BlockType.image) {
      await controller.addImageFromFile();
    } else if (type == BlockType.video) {
      await controller.addVideoFromFile();
    } else if (type == BlockType.audio) {
      await controller.addAudioFromFile();
    }
  }

  /// Handles adding media from camera/recording source.
  ///
  /// Opens the camera or recording interface based on the media type.
  static Future<void> _handleCameraSource(
    BlockType type,
    dynamic controller,
  ) async {
    if (type == BlockType.image) {
      await controller.addImageFromCamera();
    } else if (type == BlockType.video) {
      await controller.addVideoFromCamera();
    } else if (type == BlockType.audio) {
      await controller.addAudioFromRecording();
    }
  }
}
