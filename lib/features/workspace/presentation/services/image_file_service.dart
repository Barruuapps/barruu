import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Service for handling image file operations.
///
/// Provides functionality for:
/// - Picking images from gallery (single or multiple)
/// - Validating image files (format and size)
/// - Saving images to document directories
/// - Generating unique filenames
/// - Managing network image URLs
///
/// Example:
/// ```dart
/// final service = ImageFileService();
/// final images = await service.pickAndSaveImages(docDir);
/// if (images != null) {
///   // Use images list
/// }
/// ```
class ImageFileService {
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Valid image file extensions
  static const List<String> validImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
  ];

  /// Maximum file size in bytes (50MB)
  static const int maxSizeBytes = 50 * 1024 * 1024;

  /// Picks multiple images from the device gallery and saves them to the document directory.
  ///
  /// Returns a list of image data maps or null if no valid images were selected.
  /// Each map contains:
  /// - 'path': Relative path within the document directory
  /// - 'fileName': Original filename
  /// - 'type': 'local'
  Future<List<Map<String, dynamic>>?> pickAndSaveImages(
    Directory docDir,
  ) async {
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);

      if (picked.isEmpty) return null;

      // Validate image files
      final validImages = await _validateImages(picked);

      if (validImages.isEmpty) {
        return null;
      }

      // Create images directory if it doesn't exist
      final imagesDir = Directory('${docDir.path}/media/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Save images and create data list
      final imageDataList = <Map<String, dynamic>>[];

      for (final pickedImage in validImages) {
        final imageData = await _saveImage(pickedImage, imagesDir);
        if (imageData != null) {
          imageDataList.add(imageData);
        }
      }

      return imageDataList.isNotEmpty ? imageDataList : null;
    } catch (e) {
      return null;
    }
  }

  /// Validates a list of picked images based on extension and file size.
  ///
  /// Returns only the images that pass validation.
  Future<List<XFile>> _validateImages(List<XFile> picked) async {
    final validImages = <XFile>[];

    for (final image in picked) {
      if (await _isValidImage(image)) {
        validImages.add(image);
      }
    }

    return validImages;
  }

  /// Checks if an image file is valid based on extension and size.
  Future<bool> _isValidImage(XFile image) async {
    final fileName = image.name;
    final extension = fileName.split('.').last.toLowerCase();

    if (!validImageExtensions.contains(extension)) {
      return false;
    }

    final file = File(image.path);
    final fileSize = await file.length();

    if (fileSize > maxSizeBytes) {
      return false;
    }

    return true;
  }

  /// Saves an image file to the images directory with a unique name.
  ///
  /// Returns a map with image data or null if saving failed.
  Future<Map<String, dynamic>?> _saveImage(
    XFile pickedImage,
    Directory imagesDir,
  ) async {
    try {
      final filePath = pickedImage.path;
      final fileName = pickedImage.name;
      final file = File(filePath);

      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final newPath = '${imagesDir.path}/$uniqueName';

      await file.copy(newPath);

      return {
        'path': 'media/images/$uniqueName',
        'fileName': fileName,
        'type': 'local',
      };
    } catch (e) {
      return null;
    }
  }

  /// Creates a network image data map from a URL.
  ///
  /// Returns the image data map or null if the URL is invalid.
  Map<String, dynamic>? createNetworkImageData(String url) {
    if (url.isEmpty) return null;

    // Validate URL format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }

    return {'path': url, 'fileName': url.split('/').last, 'type': 'network'};
  }

  /// Validates if a URL is a valid image URL.
  bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
