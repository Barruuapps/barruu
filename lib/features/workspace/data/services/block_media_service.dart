import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/services/media_path_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../presentation/services/audio_file_service.dart';
import '../../presentation/services/video_file_service.dart';

/// Service for handling media file operations for blocks.
///
/// Responsibilities:
/// - Picking and saving images from file, URL, and camera
/// - Picking and saving videos from file, URL, and camera
/// - Picking and saving audio from file, URL, and recording
/// - Managing media file storage in document directories
/// - Generating unique file names and validating paths
class BlockMediaService {
  final Directory docDir;
  final MediaPathValidator pathValidator;
  final Uuid _uuid = const Uuid();
  final VideoFileService _videoFileService = VideoFileService();

  BlockMediaService(this.docDir, this.pathValidator);

  // ========== Image Operations ==========

  /// Picks an image file from the device and saves it locally.
  ///
  /// Opens a file picker to select an image file, then saves it to
  /// the document's media/images directory with a unique name.
  ///
  /// Returns a map with image metadata (path, caption, crop settings, etc.)
  /// or null if picking was cancelled or failed.
  Future<Map<String, dynamic>?> handleImageFromFile() async {
    if (!pathValidator.isFileOperationSupported) return null;
    try {
      final picker = FilePicker.platform;
      final result = await picker.pickFiles(type: FileType.image);
      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null) {
        logger.w('Image picking cancelled');
        return null;
      }
      final file = File(result.files.first.path!);
      final originalName = result.files.first.name;
      return await _saveImageFile(file, originalName);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to handle image block',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Downloads an image from URL and saves it locally.
  ///
  /// [url] - The URL of the image to download
  ///
  /// Returns a map with image metadata or null if download failed.
  Future<Map<String, dynamic>?> handleImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        logger.w('Failed to download image from URL: ${response.statusCode}');
        return null;
      }

      final imagesDir = Directory('${docDir.path}/media/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = url.split('/').last.split('?').first;
      final sanitizedName = pathValidator.sanitizeFileName(
        fileName.isEmpty ? 'image.jpg' : fileName,
      );
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final imagePath = '${imagesDir.path}/$uniqueName';

      if (!await pathValidator.isValidMediaPath(imagePath)) {
        logger.w('Invalid image path generated: $imagePath');
        return null;
      }

      final file = File(imagePath);
      await file.writeAsBytes(response.bodyBytes);
      logger.i('Image downloaded from URL: $imagePath');

      return {
        'path': 'media/images/$uniqueName',
        'caption': '',
        'cropTop': 0.0,
        'cropBottom': 0.0,
        'fit': 'cover',
        'fileName': sanitizedName,
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to download image from URL',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Captures an image from the device camera.
  ///
  /// Returns a map with image metadata or null if capture was cancelled or failed.
  Future<Map<String, dynamic>?> handleImageFromCamera() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile == null) {
        logger.w('Image capture cancelled');
        return null;
      }

      final file = File(pickedFile.path);
      final originalName = pickedFile.name;
      return await _saveImageFile(file, originalName);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to capture image from camera',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Internal helper to save an image file to the document's media directory.
  ///
  /// [file] - The image file to save
  /// [originalName] - The original filename
  ///
  /// Returns a map with image metadata or null if saving failed.
  Future<Map<String, dynamic>?> _saveImageFile(
    File file,
    String originalName,
  ) async {
    try {
      final imagesDir = Directory('${docDir.path}/media/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final sanitizedName = pathValidator.sanitizeFileName(originalName);
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final imagePath = '${imagesDir.path}/$uniqueName';

      if (!await pathValidator.isValidMediaPath(imagePath)) {
        logger.w('Invalid image path generated: $imagePath');
        return null;
      }

      await file.copy(imagePath);
      logger.i('Image saved: $imagePath');

      return {
        'path': 'media/images/$uniqueName',
        'caption': '',
        'cropTop': 0.0,
        'cropBottom': 0.0,
        'fit': 'cover',
        'fileName': originalName,
      };
    } catch (e, stackTrace) {
      logger.e('Failed to save image file', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ========== Video Operations ==========

  /// Picks a video file from the device and saves it locally.
  ///
  /// Uses ImagePicker on mobile for better UX, FilePicker on desktop.
  ///
  /// Returns a map with video metadata (path, caption, etc.)
  /// or null if picking was cancelled or failed.
  Future<Map<String, dynamic>?> handleVideoFromFile() async {
    if (!pathValidator.isFileOperationSupported) return null;
    try {
      File? file;
      String? originalName;

      // Use ImagePicker (gallery) on mobile platforms for better UX
      if (Platform.isAndroid || Platform.isIOS) {
        final imagePicker = ImagePicker();
        final pickedFile = await imagePicker.pickVideo(
          source: ImageSource.gallery,
        );

        if (pickedFile == null) {
          logger.w('Video picking cancelled');
          return null;
        }

        file = File(pickedFile.path);
        originalName = pickedFile.name;
      } else {
        // Use FilePicker for desktop/web platforms
        final picker = FilePicker.platform;
        final result = await picker.pickFiles(type: FileType.video);

        if (result == null ||
            result.files.isEmpty ||
            result.files.first.path == null) {
          logger.w('Video picking cancelled');
          return null;
        }

        file = File(result.files.first.path!);
        originalName = result.files.first.name;
      }

      return await _saveVideoFile(file, originalName);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to handle video block',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Processes a video URL and returns appropriate video information.
  ///
  /// [url] - The URL of the video (YouTube or direct video URL)
  ///
  /// This method handles:
  /// - YouTube URLs (extracts video ID for embedding)
  /// - Network video URLs (stores URL for streaming)
  ///
  /// Returns a map with video metadata or null if URL processing failed.
  Future<Map<String, dynamic>?> handleVideoFromUrl(String url) async {
    if (url.isEmpty) return null;

    try {
      final videoInfo = await _videoFileService.processVideoUrl(url);

      if (videoInfo != null) {
        final newYoutubeId = videoInfo['youtubeId'] ?? '';
        final newPath = videoInfo['path'] ?? '';
        final fileName = videoInfo['fileName'] ?? '';
        final sourceType = videoInfo['sourceType'] ?? 'network';

        // Update content with new video (following _addVideoFromUrl logic)
        final result = <String, dynamic>{
          'youtubeId': newYoutubeId,
          'path': newPath,
          'fileName': fileName,
          'sourceType': sourceType,
          'caption': '',
        };

        logger.i(
          'Video processed - sourceType: $sourceType, youtubeId: $newYoutubeId, path: $newPath',
        );
        return result;
      }

      logger.w('Failed to process video URL: $url');
      return null;
    } catch (e, stackTrace) {
      logger.e('Failed to process video URL', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Captures a video from the device camera.
  ///
  /// Returns a map with video metadata or null if capture was cancelled or failed.
  Future<Map<String, dynamic>?> handleVideoFromCamera() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickVideo(
        source: ImageSource.camera,
      );

      if (pickedFile == null) {
        logger.w('Video capture cancelled');
        return null;
      }

      final file = File(pickedFile.path);
      final originalName = pickedFile.name;
      return await _saveVideoFile(file, originalName);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to capture video from camera',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Internal helper to save a video file to the document's media directory.
  ///
  /// [file] - The video file to save
  /// [originalName] - The original filename
  ///
  /// Returns a map with video metadata or null if saving failed.
  Future<Map<String, dynamic>?> _saveVideoFile(
    File file,
    String originalName,
  ) async {
    try {
      final videosDir = Directory('${docDir.path}/media/videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final sanitizedName = pathValidator.sanitizeFileName(originalName);
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final videoPath = '${videosDir.path}/$uniqueName';

      if (!await pathValidator.isValidMediaPath(videoPath)) {
        logger.w('Invalid video path generated: $videoPath');
        return null;
      }

      await file.copy(videoPath);
      logger.i('Video saved: $videoPath');

      return {
        'path': 'media/videos/$uniqueName',
        'caption': '',
        'fileName': originalName,
      };
    } catch (e, stackTrace) {
      logger.e('Failed to save video file', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ========== Audio Operations ==========

  /// Picks an audio file from the device and saves it locally.
  ///
  /// Opens a file picker to select an audio file, then saves it to
  /// the document's media/audios directory with a unique name.
  ///
  /// Returns a map with audio metadata (path, title, caption, etc.)
  /// or null if picking was cancelled or failed.
  Future<Map<String, dynamic>?> handleAudioFromFile() async {
    if (!pathValidator.isFileOperationSupported) return null;
    try {
      final picker = FilePicker.platform;
      final result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioFileService.validAudioExtensions,
        dialogTitle: 'Select an Audio File',
      );
      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null) {
        logger.w('Audio picking cancelled');
        return null;
      }
      final file = File(result.files.first.path!);
      final originalName = result.files.first.name;
      return await _saveAudioFile(file, originalName);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to handle audio block',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Downloads an audio file from URL and saves it locally.
  ///
  /// [url] - The URL of the audio to download
  ///
  /// Returns a map with audio metadata or null if download failed.
  Future<Map<String, dynamic>?> handleAudioFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        logger.w('Failed to download audio from URL: ${response.statusCode}');
        return null;
      }

      final audiosDir = Directory('${docDir.path}/media/audios');
      if (!await audiosDir.exists()) {
        await audiosDir.create(recursive: true);
      }

      final fileName = url.split('/').last.split('?').first;
      final sanitizedName = pathValidator.sanitizeFileName(
        fileName.isEmpty ? 'audio.mp3' : fileName,
      );
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final audioPath = '${audiosDir.path}/$uniqueName';

      if (!await pathValidator.isValidMediaPath(audioPath)) {
        logger.w('Invalid audio path generated: $audioPath');
        return null;
      }

      final file = File(audioPath);
      await file.writeAsBytes(response.bodyBytes);
      logger.i('Audio downloaded from URL: $audioPath');

      return {
        'path': 'media/audios/$uniqueName',
        'customTitle': '',
        'caption': '',
        'fileName': sanitizedName,
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to download audio from URL',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Records audio from microphone.
  ///
  /// TODO: Currently falls back to file picker - needs audio recording package implementation.
  ///
  /// Returns a map with audio metadata or null if recording failed.
  Future<Map<String, dynamic>?> handleAudioFromRecording() async {
    try {
      // Fallback to file picker until audio recording is implemented
      // This would require an audio recording package like record or audio_recorder
      logger.w(
        'Audio recording not yet implemented - using file picker instead',
      );
      return await handleAudioFromFile();
    } catch (e, stackTrace) {
      logger.e(
        'Failed to record audio from microphone',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Internal helper to save an audio file to the document's media directory.
  ///
  /// [file] - The audio file to save
  /// [originalName] - The original filename
  ///
  /// Returns a map with audio metadata or null if saving failed.
  Future<Map<String, dynamic>?> _saveAudioFile(
    File file,
    String originalName,
  ) async {
    try {
      final audiosDir = Directory('${docDir.path}/media/audios');
      if (!await audiosDir.exists()) {
        await audiosDir.create(recursive: true);
      }

      final sanitizedName = pathValidator.sanitizeFileName(originalName);
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final audioPath = '${audiosDir.path}/$uniqueName';

      if (!await pathValidator.isValidMediaPath(audioPath)) {
        logger.w('Invalid audio path generated: $audioPath');
        return null;
      }

      await file.copy(audioPath);
      logger.i('Audio saved: $audioPath');

      return {
        'path': 'media/audios/$uniqueName',
        'customTitle': '',
        'caption': '',
        'fileName': originalName,
      };
    } catch (e, stackTrace) {
      logger.e('Failed to save audio file', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
