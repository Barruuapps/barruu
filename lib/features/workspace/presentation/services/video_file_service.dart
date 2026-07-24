import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:barruu/features/workspace/presentation/services/youtube_url_helper.dart';

/// Video source types supported by the application
enum VideoSourceType { local, network, youtube }

/// Service for handling video file operations.
///
/// Provides functionality for:
/// - Picking videos from gallery or camera
/// - Processing video URLs (direct and YouTube)
/// - Extracting YouTube video IDs
/// - Generating unique filenames
/// - Saving videos to document directories
///
/// Example:
/// ```dart
/// final service = VideoFileService();
/// final videoInfo = await service.pickVideoFromGallery(docDir);
/// if (videoInfo != null) {
///   // Use videoInfo['path'], videoInfo['fileName'], etc.
/// }
/// ```
class VideoFileService {
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Picks a video from the device gallery.
  ///
  /// Returns a map with video information:
  /// - 'path': Relative path within the document directory
  /// - 'fileName': Generated unique filename
  /// - 'sourceType': 'local'
  ///
  /// Returns null if no video was selected or if an error occurred.
  Future<Map<String, dynamic>?> pickVideoFromGallery(Directory docDir) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      
      if (pickedFile == null) return null;
      
      return await _saveVideoFile(pickedFile, docDir);
    } catch (e) {
      return null;
    }
  }

  /// Records a new video using the device camera.
  ///
  /// Returns a map with video information:
  /// - 'path': Relative path within the document directory
  /// - 'fileName': Generated unique filename
  /// - 'sourceType': 'local'
  ///
  /// Returns null if recording was cancelled or if an error occurred.
  Future<Map<String, dynamic>?> recordVideo(Directory docDir) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
      );
      
      if (pickedFile == null) return null;
      
      return await _saveVideoFile(pickedFile, docDir);
    } catch (e) {
      return null;
    }
  }

  /// Processes a video URL and returns appropriate video information.
  ///
  /// Supports:
  /// - YouTube URLs (extracts video ID)
  /// - Direct video URLs (network videos)
  ///
  /// Returns a map with:
  /// - For YouTube: 'youtubeId', 'path' (empty), 'fileName', 'sourceType': 'youtube'
  /// - For network: 'path' (URL), 'fileName', 'sourceType': 'network'
  ///
  /// Returns null if the URL is empty.
  Future<Map<String, dynamic>?> processVideoUrl(String url) async {
    if (url.isEmpty) return null;
    
    // Check if it's a YouTube URL
    final youtubeId = extractYoutubeId(url);
    
    if (youtubeId != null) {
      return {
        'youtubeId': youtubeId,
        'path': '', // Don't store URL in path for YouTube videos to avoid confusion
        'fileName': 'YouTube Video',
        'sourceType': VideoSourceType.youtube.name,
      };
    } else {
      // Treat as network video
      return {
        'path': url,
        'fileName': 'Network Video',
        'sourceType': VideoSourceType.network.name,
      };
    }
  }

  /// Extracts YouTube video ID from a YouTube URL.
  ///
  /// Uses enhanced YouTube URL detection that handles various URL formats
  /// including youtube-nocookie.com and other variations.
  ///
  /// Examples:
  /// - https://www.youtube.com/watch?v=VIDEO_ID → VIDEO_ID
  /// - https://youtu.be/VIDEO_ID → VIDEO_ID
  /// - https://www.youtube-nocookie.com/embed/VIDEO_ID → VIDEO_ID
  ///
  /// Returns null if the URL is not a valid YouTube URL.
  String? extractYoutubeId(String url) {
    return YouTubeUrlHelper.extractVideoId(url);
  }

  /// Generates a unique filename for a video file.
  ///
  /// Creates a filename in the format: video_[UUID].mp4
  String generateUniqueFilename() {
    return 'video_${_uuid.v4()}.mp4';
  }

  /// Saves a video file to the document directory.
  ///
  /// Copies the picked video file to the document's media directory
  /// with a unique filename.
  ///
  /// Returns a map with:
  /// - 'path': Relative path within document directory
  /// - 'fileName': Generated filename
  /// - 'sourceType': 'local'
  ///
  /// Returns null if saving fails.
  Future<Map<String, dynamic>?> _saveVideoFile(
    XFile pickedFile,
    Directory docDir,
  ) async {
    try {
      final fileName = generateUniqueFilename();
      final relativePath = 'media/$fileName';
      final destinationPath = '${docDir.path}/$relativePath';
      
      // Ensure media directory exists
      final mediaDir = Directory('${docDir.path}/media');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      // Copy the video file
      final File sourceFile = File(pickedFile.path);
      await sourceFile.copy(destinationPath);
      
      return {
        'path': relativePath,
        'fileName': fileName,
        'sourceType': VideoSourceType.local.name,
      };
    } catch (e) {
      return null;
    }
  }

  /// Deletes a video file from the document directory.
  ///
  /// Only deletes local files (sourceType == 'local').
  /// Network and YouTube videos are not deleted.
  ///
  /// Returns true if the file was successfully deleted or if it didn't exist.
  /// Returns false if deletion failed.
  Future<bool> deleteVideoFile(
    String relativePath,
    Directory docDir,
    String sourceType,
  ) async {
    try {
      // Only delete local files
      if (sourceType != VideoSourceType.local.name) {
        return true; // Nothing to delete for network/youtube videos
      }
      
      if (relativePath.isEmpty) return true;
      
      final file = File('${docDir.path}/$relativePath');
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
