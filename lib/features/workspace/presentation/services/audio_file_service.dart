import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/presentation/services/audio_recorder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

/// Service for handling audio file operations in audio blocks.
///
/// This service manages:
/// - Audio file selection and validation
/// - Audio file upload and storage
/// - Audio duration extraction
/// - File reference tracking to prevent data loss
///
/// The service ensures that audio files are properly validated,
/// stored in the correct location, and that old files are cleaned up
/// only when no longer referenced by other blocks.
class AudioFileService {
  static const Uuid _uuid = Uuid();

  /// Valid audio file extensions supported by the application
  static const List<String> validAudioExtensions = [
    'mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac', 'wma', 'opus'
  ];

  /// Maximum allowed audio file size in bytes (100 MB)
  static const int maxFileSizeBytes = 100 * 1024 * 1024;

  /// Shows a dialog for selecting the audio source.
  ///
  /// Provides options to:
  /// - Record audio using the device microphone
  /// - Choose an existing audio file from device storage
  static Future<void> showAudioSourceDialog({
    required BuildContext context,
    required VoidCallback onFileSelected,
    required VoidCallback onRecordAudio,
  }) async {
    final theme = Theme.of(context);
    
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Audio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.mic),
                  title: const Text('Record Audio'),
                  subtitle: const Text('Record audio using your microphone'),
                  onTap: () {
                    Navigator.pop(context);
                    onRecordAudio();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.audio_file),
                  title: const Text('Choose from Device'),
                  subtitle: const Text('Select an audio file from your device storage'),
                  onTap: () {
                    Navigator.pop(context);
                    onFileSelected();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handles audio recording using the device microphone.
  ///
  /// This method:
  /// - Requests microphone permission
  /// - Shows a recording dialog with controls
  /// - Saves the recorded audio to the document's media/audios directory
  /// - Deletes old audio if not referenced by other blocks
  /// - Returns the audio metadata including path and duration
  ///
  /// [context] is used for showing the recording dialog.
  /// [ref] provides access to the Riverpod providers.
  /// [docDir] is the document directory where audio will be stored.
  /// [currentContent] is the current block content (to get old audio path).
  /// [currentBlock] is the current block (for reference checking).
  /// [showSuccess] callback to show success message.
  /// [showError] callback to show error message.
  ///
  /// Returns a map with 'path', 'fileName', and 'duration' if successful,
  /// or null if the user cancels or an error occurs.
  static Future<Map<String, dynamic>?> recordAndSaveAudio({
    required BuildContext context,
    required WidgetRef ref,
    required Directory docDir,
    required Map<String, dynamic> currentContent,
    required Block currentBlock,
    required Function(String) showSuccess,
    required Function(String) showError,
  }) async {
    try {
      // Record audio
      final result = await AudioRecorderService.recordAudio(
        context: context,
        docDir: docDir,
      );

      if (result == null) {
        return null; // User cancelled
      }

      // Delete old audio if it exists and is not referenced by other blocks
      await _deleteOldAudioIfUnused(
        docDir: docDir,
        ref: ref,
        oldPath: currentContent['path'] as String? ?? '',
        currentBlock: currentBlock,
      );

      // Get audio duration
      final duration = await _getAudioDuration('${docDir.path}/${result['path']}');

      showSuccess('Audio recorded successfully');

      return {
        'path': result['path'],
        'fileName': result['fileName'],
        'duration': duration,
      };
    } catch (e) {
      showError('Error recording audio: ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    }
  }

  /// Handles audio file selection, validation, and upload.
  ///
  /// This method:
  /// - Prompts user to select an audio file
  /// - Validates file type and size
  /// - Rejects system ringtones and notification sounds
  /// - Deletes old audio if not referenced by other blocks
  /// - Copies the new audio file to the document's media/audios directory
  /// - Returns the audio metadata including path and duration
  ///
  /// [context] is used for showing progress indicators and error messages.
  /// [ref] provides access to the Riverpod providers.
  /// [docDir] is the document directory where audio will be stored.
  /// [currentContent] is the current block content (to get old audio path).
  /// [currentBlock] is the current block (for reference checking).
  /// [showSuccess] callback to show success message.
  /// [showError] callback to show error message.
  ///
  /// Returns a map with 'path', 'fileName', and 'duration' if successful,
  /// or null if the user cancels or an error occurs.
  static Future<Map<String, dynamic>?> selectAndUploadAudioFile({
    required BuildContext context,
    required WidgetRef ref,
    required Directory docDir,
    required Map<String, dynamic> currentContent,
    required Block currentBlock,
    required Function(String) showSuccess,
    required Function(String) showError,
  }) async {
    try {
      // Show file picker
      final picker = FilePicker.platform;
      final result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: validAudioExtensions,
        dialogTitle: 'Select an Audio File',
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return null;
      }

      final pickedFile = result.files.first;
      final filePath = pickedFile.path!;
      final fileName = pickedFile.name;

      // Reject system ringtone paths (common on Android)
      if (_isSystemAudioPath(filePath)) {
        showError('System ringtones and notification sounds cannot be used. Please select music or voice recordings from your device storage.');
        return null;
      }

      // Validate audio file type by extension
      final extension = fileName.split('.').last.toLowerCase();
      if (!validAudioExtensions.contains(extension)) {
        showError('Invalid audio format. Supported formats: ${validAudioExtensions.join(", ")}');
        return null;
      }

      // Validate file size
      final file = File(filePath);
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        showError('Audio file is too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum size is 100MB');
        return null;
      }

      // Show progress indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: ShimmerInlineLoading(size: 20),
                ),
                const SizedBox(width: 12),
                Text('Uploading audio (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)...'),
              ],
            ),
            duration: const Duration(hours: 1), // Will be dismissed manually
          ),
        );
      }

      // Delete old audio if it exists and is not referenced by other blocks
      await _deleteOldAudioIfUnused(
        docDir: docDir,
        ref: ref,
        oldPath: currentContent['path'] as String? ?? '',
        currentBlock: currentBlock,
      );

      // Create audios directory if it doesn't exist
      final audiosDir = Directory('${docDir.path}/media/audios');
      if (!await audiosDir.exists()) {
        await audiosDir.create(recursive: true);
      }

      // Sanitize filename to prevent path traversal
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final newPath = '${audiosDir.path}/$uniqueName';

      // Copy new audio
      await file.copy(newPath);

      // Get audio duration
      final duration = await _getAudioDuration(newPath);

      // Dismiss progress
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showSuccess('Audio uploaded successfully');
      }

      return {
        'path': 'media/audios/$uniqueName',
        'fileName': fileName,
        'duration': duration,
      };
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      showError('Error uploading audio: ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    }
  }

  /// Checks if the given file path is a system audio path.
  ///
  /// System paths include ringtones, notifications, alarms, and UI sounds.
  static bool _isSystemAudioPath(String filePath) {
    final invalidPaths = [
      '/system/media/audio/ringtones',
      '/system/media/audio/notifications',
      '/system/media/audio/alarms',
      '/system/media/audio/ui',
    ];

    for (final invalidPath in invalidPaths) {
      if (filePath.toLowerCase().contains(invalidPath.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Deletes the old audio file if it's not referenced by other blocks.
  ///
  /// This prevents accidental data loss by checking all blocks in the document
  /// to see if any other block references the same audio file.
  static Future<void> _deleteOldAudioIfUnused({
    required Directory docDir,
    required WidgetRef ref,
    required String oldPath,
    required Block currentBlock,
  }) async {
    if (oldPath.isEmpty) return;

    final oldFile = File('${docDir.path}/$oldPath');
    if (!oldFile.existsSync()) return;

    // Check if other blocks reference this file
    if (_isFileReferencedByOtherBlocks(ref, docDir, oldPath, currentBlock)) {
      // Don't delete, it's still in use
      return;
    }

    await oldFile.delete();
  }

  /// Checks if the given file path is referenced by other blocks.
  ///
  /// Returns true if any block (other than the current block) references
  /// the same file path.
  static bool _isFileReferencedByOtherBlocks(
    WidgetRef ref,
    Directory docDir,
    String filePath,
    Block currentBlock,
  ) {
    final controller = ref.read(editDocumentControllerProvider(docDir).notifier);
    final allBlocks = controller.state;

    return allBlocks.any((block) {
      if (block.id == currentBlock.id) return false; // Skip current block
      
      // Only check media blocks
      final mediaTypes = ['video', 'audio', 'image'];
      if (!mediaTypes.contains(block.type.name)) return false;

      try {
        final jsonConverter = JsonStringConverter();
        final blockContent = jsonConverter.convertFromJsonString(block.content);
        final blockPath = blockContent['path'] as String? ?? '';
        return blockPath == filePath;
      } catch (e) {
        return false;
      }
    });
  }

  /// Extracts the duration of an audio file.
  ///
  /// Returns the duration in seconds, or 0.0 if unable to determine.
  static Future<double> _getAudioDuration(String absolutePath) async {
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setFilePath(absolutePath).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Audio initialization timed out');
        },
      );

      final duration = player.duration;
      if (duration != null) {
        return duration.inMilliseconds / 1000.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    } finally {
      await player?.dispose();
    }
  }

  /// Initializes an audio file and returns its duration.
  ///
  /// This is a convenience method for getting audio metadata without
  /// maintaining a persistent player instance.
  ///
  /// [docDir] is the document directory.
  /// [relativePath] is the path relative to the document directory.
  ///
  /// Returns the duration in seconds, or 0.0 if the file doesn't exist
  /// or an error occurs.
  static Future<double> initializeAndGetDuration({
    required Directory docDir,
    required String relativePath,
  }) async {
    if (relativePath.isEmpty) return 0.0;

    final absolutePath = '${docDir.path}/$relativePath';
    final file = File(absolutePath);

    if (!file.existsSync()) return 0.0;

    return await _getAudioDuration(absolutePath);
  }
}
