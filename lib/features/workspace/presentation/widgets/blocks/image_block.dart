import 'dart:io';

import 'package:barruu/core/constants/media_constants.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/image_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/services/image_file_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/image_carousel_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/image_edit_controls_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/image_sizing_controls_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/image_url_input_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/image_caption_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Image block widget with support for:
/// - Local images from device
/// - Network images (URLs)
/// - Multiple images with carousel
/// - Responsive sizing using percentage-based dimensions
/// - Caption and various image fit options
/// Extends BaseEditableBlock for consistent behavior.
class ImageBlock extends BaseEditableBlock {
  const ImageBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<ImageBlock> createState() => _ImageBlockState();
}

class _ImageBlockState extends BaseEditableBlockState<ImageBlock> {
  // Block-specific state
  late double rotation;
  late double? width;
  late double? height;
  late double? widthPercent;
  late double? heightPercent;

  // Fields for caption and cropping
  String _caption = '';
  late TextEditingController _captionController;
  late TextEditingController _urlController;
  late Debouncer _saveDebouncer;
  late ImageFileService _imageFileService;
  double _cropTop = 0.0;
  double _cropBottom = 0.0;
  BoxFit _imageFit = BoxFit.cover;
  final Alignment _alignment = Alignment.center;

  // Multi-image support
  int _currentImageIndex = 0;
  late PageController _pageController;

  // Image source mode
  bool _showUrlInput = false;

  /// Safely retrieves the images list from content, handling type mismatches.
  ///
  /// This method handles edge cases during JSON deserialization where:
  /// - Normal case: Returns a mutable copy of the List<dynamic> of image data maps
  /// - Edge case: Converts a single Map to a List (when only one image was stored)
  /// - Fallback: Returns an empty List for null or other invalid types
  ///
  /// @return List<dynamic> containing Map<String, dynamic> image data objects
  ///
  /// Example usage:
  /// ```dart
  /// final images = _getImagesList();
  /// for (var imageData in images) {
  ///   final path = imageData['path'];
  /// }
  /// ```
  List<dynamic> _getImagesList() {
    final imagesRaw = content['images'];

    if (imagesRaw is List) {
      // Return a mutable copy to avoid issues with fixed-length or typed lists
      return List<dynamic>.from(imagesRaw);
    } else if (imagesRaw is Map) {
      // Handle case where a single Map was stored instead of a List
      return [imagesRaw];
    } else {
      // Fallback to empty list for any other type
      return [];
    }
  }

  @override
  Map<String, dynamic> getDefaultContent() => {
    'images': [],
    'caption': '',
    'cropTop': 0.0,
    'cropBottom': 0.0,
    'fit': 'cover',
  };

  @override
  void initializeBlockSpecifics() {
    rotation = widget.block.style.rotation ?? 0;
    width = widget.block.style.width;
    height = widget.block.style.height;
    widthPercent = widget.block.style.widthPercent;
    heightPercent = widget.block.style.heightPercent;

    _imageFileService = ImageFileService();
    _pageController = PageController();
    _caption = content['caption'] ?? '';
    _captionController = TextEditingController(text: _caption);
    _urlController = TextEditingController();
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

    // Handle migration from old single-image format to new multi-image format
    if (content.containsKey('path') && !content.containsKey('images')) {
      final oldPath = content['path'] as String? ?? '';
      final oldFileName = content['fileName'] as String? ?? '';
      if (oldPath.isNotEmpty) {
        final isNetwork =
            oldPath.startsWith('http://') || oldPath.startsWith('https://');
        content['images'] = [
          {
            'path': oldPath,
            'fileName': oldFileName,
            'type': isNetwork ? 'network' : 'local',
          },
        ];
      } else {
        content['images'] = [];
      }
      content.remove('path');
      content.remove('fileName');
    }

    // Ensure images field exists and has type field
    if (!content.containsKey('images')) {
      content['images'] = [];
    }

    // Use helper to get images list (handles type mismatches)
    final images = _getImagesList();

    // Migrate old images without type field
    for (int i = 0; i < images.length; i++) {
      if (images[i] is Map<String, dynamic>) {
        final img = images[i] as Map<String, dynamic>;
        if (!img.containsKey('type')) {
          final path = img['path'] as String? ?? '';
          img['type'] =
              (path.startsWith('http://') || path.startsWith('https://'))
              ? 'network'
              : 'local';
        }
      }
    }

    // Update content with normalized list
    content['images'] = images;

    _cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    _cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    final fitStr = content['fit'] as String?;
    try {
      _imageFit = BoxFit.values.firstWhere(
        (e) => e.toString().split('.').last == fitStr,
        orElse: () => BoxFit.cover,
      );
    } catch (e) {
      _imageFit = BoxFit.cover;
    }
  }

  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    _captionController.dispose();
    _urlController.dispose();
    _pageController.dispose();
  }

  @override
  void onContentChanged() {
    final caption = content['caption'] ?? '';
    if (_captionController.text != caption) {
      _captionController.text = caption;
    }
    if (_caption != caption) {
      _caption = caption;
    }
  }

  void _saveImageContent() {
    content['caption'] = _caption;
    content['cropTop'] = _cropTop;
    content['cropBottom'] = _cropBottom;
    content['fit'] = _imageFit.toString().split('.').last;
    _saveDebouncer.call(() => saveContent());
  }

  void _updateStyle() {
    final controller = ref.read(
      editDocumentControllerProvider(widget.docDir).notifier,
    );
    final updatedStyle = widget.block.style.copyWith(
      rotation: rotation,
      width: width,
      height: height,
      widthPercent: widthPercent,
      heightPercent: heightPercent,
    );
    final updatedBlock = widget.block.copyWith(style: updatedStyle);
    controller.saveBlock(updatedBlock);
  }

  Future<void> _addNetworkImage(String url) async {
    final imageData = _imageFileService.createNetworkImageData(url);

    if (imageData == null) {
      showError('Please enter a valid URL starting with http:// or https://');
      return;
    }

    // Get current images list safely
    final images = _getImagesList();

    // Add network image
    images.add(imageData);

    setState(() {
      content['images'] = images;
      _currentImageIndex = images.length - 1;
      _urlController.clear();
      _showUrlInput = false;
    });
    _saveImageContent();

    // Jump to last image
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentImageIndex);
    }

    showSuccess('Network image added');
  }

  /// Show dialog to choose image source type
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select images from your device'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickLocalImages();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.link, color: theme.colorScheme.secondary),
                  title: const Text('Image URL'),
                  subtitle: const Text('Enter a direct image URL'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _showUrlInput = true;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLocalImages() async {
    try {
      final imageDataList = await _imageFileService.pickAndSaveImages(
        widget.docDir,
      );

      if (imageDataList == null || imageDataList.isEmpty) {
        showError('No valid images selected');
        return;
      }

      final images = _getImagesList();

      // Add new images
      images.addAll(imageDataList);

      setState(() {
        content['images'] = images;
        _currentImageIndex = images.length - 1;
      });
      _saveImageContent();

      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentImageIndex);
      }

      showSuccess('${imageDataList.length} image(s) uploaded successfully');
    } catch (e) {
      showError(
        'Error uploading images: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  Future<void> _removeCurrentImage() async {
    try {
      final images = _getImagesList();

      if (images.isEmpty || _currentImageIndex >= images.length) return;

      final imageToRemove = images[_currentImageIndex] as Map<String, dynamic>;
      final imagePath = imageToRemove['path'] as String? ?? '';
      final imageType = imageToRemove['type'] as String? ?? 'local';

      // Only delete local files
      if (imageType == 'local' && imagePath.isNotEmpty) {
        final file = File('${widget.docDir.path}/$imagePath');
        if (file.existsSync()) {
          await file.delete();
        }
      }

      images.removeAt(_currentImageIndex);

      if (_currentImageIndex >= images.length && images.isNotEmpty) {
        _currentImageIndex = images.length - 1;
      } else if (images.isEmpty) {
        _currentImageIndex = 0;
      }

      setState(() {
        content['images'] = images;
      });
      _saveImageContent();

      showSuccess('Image removed');
    } catch (e) {
      showError('Error removing image: ${e.toString()}');
    }
  }

  Widget _buildImage(
    Map<String, dynamic> imageData,
    double displayWidth,
    double displayHeight,
  ) {
    final imagePath = imageData['path'] as String? ?? '';
    final imageType = imageData['type'] as String? ?? 'local';

    if (imagePath.isEmpty) {
      return _buildPlaceholder(Theme.of(context));
    }

    // Network image with memory optimization (no lazy loading in carousel)
    if (imageType == 'network') {
      // Calculate optimal cache dimensions (limit max size to save memory)
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final cacheWidth = ((displayWidth * devicePixelRatio).round()).clamp(
        MediaConstants.minImageCacheSize,
        MediaConstants.maxImageCacheWidth,
      );
      final cacheHeight = ((displayHeight * devicePixelRatio).round()).clamp(
        MediaConstants.minImageCacheSize,
        MediaConstants.maxImageCacheHeight,
      );

      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: _imageFit,
        alignment: Alignment(0, -1 + _cropTop * 2),
        width: displayWidth,
        height: displayHeight,
        maxWidthDiskCache: MediaConstants.maxImageCacheWidth,
        maxHeightDiskCache: MediaConstants.maxImageCacheHeight,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        placeholder: (context, url) => ShimmerLoading(
          child: Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 80, color: Colors.red),
              SizedBox(height: 8),
              Text('Failed to load image', style: TextStyle(color: Colors.red)),
            ],
          );
        },
      );
    }

    // Local image with memory optimization (no lazy loading in carousel)
    final absolutePath = '${widget.docDir.path}/$imagePath';
    final file = File(absolutePath);
    final fileExists = file.existsSync();

    if (!fileExists) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 80, color: Colors.red),
          SizedBox(height: 8),
          Text('Image not found', style: TextStyle(color: Colors.red)),
        ],
      );
    }

    // Calculate optimal cache dimensions (limit max size to save memory)
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = ((displayWidth * devicePixelRatio).round()).clamp(
      MediaConstants.minImageCacheSize,
      MediaConstants.maxImageCacheSize,
    );
    final cacheHeight = ((displayHeight * devicePixelRatio).round()).clamp(
      MediaConstants.minImageCacheSize,
      MediaConstants.maxImageCacheSize,
    );

    return Image.file(
      file,
      fit: _imageFit,
      alignment: Alignment(0, -1 + _cropTop * 2),
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (c, e, s) {
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 80, color: Colors.red),
            SizedBox(height: 8),
            Text('Error loading image', style: TextStyle(color: Colors.red)),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: widget.isEditing ? _showImageSourceDialog : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEditing ? 'Tap to add images' : 'No images',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 8),
            Text(
              'Choose from gallery or enter URL',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return ImageReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final images = _getImagesList();
    final hasImages = images.isNotEmpty;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    final displayWidth = widthPercent != null
        ? screenWidth * widthPercent!
        : (width ?? screenWidth * 0.9);

    // For BoxFit.contain, use a smaller default height to avoid excessive whitespace
    double calculatedHeight;
    if (_imageFit == BoxFit.contain) {
      // Use aspect ratio friendly height for contain mode
      calculatedHeight = heightPercent != null
          ? screenHeight * heightPercent!
          : (height ??
                displayWidth * 0.7); // Use width-based calculation for contain
    } else {
      calculatedHeight = heightPercent != null
          ? screenHeight * heightPercent!
          : (height ?? 400.0);
    }
    final displayHeight = calculatedHeight;

    // Instagram-style minimal padding
    final padding = ResponsiveUtils.isMobile(context)
        ? const EdgeInsets.symmetric(vertical: 8)
        : const EdgeInsets.symmetric(vertical: 12);

    return Padding(
      padding: padding,
      child: Column(
        children: [
          Toolbar(block: widget.block, docDir: widget.docDir),

          // URL input field (when adding network image)
          if (_showUrlInput)
            ImageUrlInputWidget(
              theme: theme,
              controller: _urlController,
              onSubmit: _addNetworkImage,
              onCancel: () {
                setState(() {
                  _showUrlInput = false;
                  _urlController.clear();
                });
              },
            ),

          Stack(
            alignment: Alignment.center,
            children: [
              hasImages
                  ? ImageCarouselWidget(
                      images: images,
                      pageController: _pageController,
                      currentIndex: _currentImageIndex,
                      width: displayWidth,
                      height: displayHeight,
                      rotation: rotation,
                      cropTop: _cropTop,
                      cropBottom: _cropBottom,
                      alignment: _alignment,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      imageBuilder: _buildImage,
                    )
                  : ClipRect(
                      child: Align(
                        alignment: _alignment,
                        heightFactor: 1.0 - _cropTop - _cropBottom,
                        child: Transform.rotate(
                          angle: rotation * 3.141592653589793 / 180,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: SizedBox(
                              width: displayWidth,
                              height: displayHeight,
                              child: _buildPlaceholder(theme),
                            ),
                          ),
                        ),
                      ),
                    ),
              if (widget.isEditing)
                ImageEditControlsWidget(
                  theme: theme,
                  hasImages: hasImages,
                  onRemove: _removeCurrentImage,
                  onAddLocal: _pickLocalImages,
                  onAddNetwork: () {
                    setState(() {
                      _showUrlInput = !_showUrlInput;
                    });
                  },
                  onRotate: () {
                    setState(() {
                      rotation = (rotation + 90) % 360;
                      _updateStyle();
                    });
                  },
                ),
            ],
          ),
          // Caption
          ImageCaptionWidget(
            theme: theme,
            isEditing: widget.isEditing,
            caption: _caption,
            controller: _captionController,
            onChanged: (value) {
              setState(() {
                _caption = value;
                _saveImageContent();
              });
            },
          ),
          // Responsive sizing controls (edit mode)
          if (widget.isEditing) ...[
            const SizedBox(height: 16),
            ImageSizingControlsWidget(
              widthPercent: widthPercent ?? 0.9,
              heightPercent: heightPercent ?? 0.4,
              imageFit: _imageFit,
              onWidthChanged: (value) {
                setState(() {
                  widthPercent = value;
                  width = null; // Clear absolute width
                  _updateStyle();
                });
              },
              onHeightChanged: (value) {
                setState(() {
                  heightPercent = value;
                  height = null; // Clear absolute height
                  _updateStyle();
                });
              },
              onFitChanged: (fit) {
                setState(() {
                  _imageFit = fit;
                  _saveImageContent();
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
