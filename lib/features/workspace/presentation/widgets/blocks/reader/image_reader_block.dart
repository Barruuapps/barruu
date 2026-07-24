import 'package:barruu/core/constants/media_constants.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// Reader block for displaying images with support for:
/// - Local images
/// - Network images (URLs)
/// - Multiple images with carousel
/// - Responsive sizing using percentage-based dimensions
/// Note: LazyLoadWidget is not used for PageView images to prevent grey placeholders
class ImageReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory? docDir;

  const ImageReaderBlock({
    super.key,
    required this.block,
    this.docDir,
  });

  @override
  ConsumerState<ImageReaderBlock> createState() => _ImageReaderBlockState();
}

class _ImageReaderBlockState extends ConsumerState<ImageReaderBlock> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildEmptyImage(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Empty image block',
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Image error',
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'Error displaying image',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> imageData, double displayWidth, double displayHeight, BoxFit imageFit, double cropTop) {
    final imagePath = imageData['path'] as String? ?? '';
    final imageType = imageData['type'] as String? ?? 'local';
    
    if (imagePath.isEmpty) {
      return _buildEmptyImage(context, ref);
    }

    // Network image (LazyLoadWidget removed for PageView compatibility)
    // Note: PageView already implements lazy loading by only building nearby pages,
    // so LazyLoadWidget is redundant and causes grey placeholder issues.
    // Memory optimization is maintained through cacheWidth/cacheHeight parameters.
    if (imageType == 'network' || imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
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
        fit: imageFit,
        alignment: Alignment(0, -1 + cropTop * 2),
        width: displayWidth,
        height: displayHeight,
        maxWidthDiskCache: MediaConstants.maxImageCacheWidth,
        maxHeightDiskCache: MediaConstants.maxImageCacheHeight,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        placeholder: (context, url) => ShimmerLoading(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        errorWidget: (context, url, error) {
          logger.e('Failed to load network image: $url, error: $error');
          final theme = Theme.of(context);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          );
        },
      );
    }

    // Local image (LazyLoadWidget removed for PageView compatibility)
    // Note: PageView already implements lazy loading by only building nearby pages,
    // so LazyLoadWidget is redundant and causes grey placeholder issues.
    // Memory optimization is maintained through cacheWidth/cacheHeight parameters.
    final absolutePath = widget.docDir != null 
        ? '${widget.docDir!.path}/$imagePath' 
        : imagePath;
    final file = File(absolutePath);
    
    if (!file.existsSync()) {
      logger.e('Local image not found: $absolutePath');
      final theme = Theme.of(context);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text(
            'Image not found',
            style: TextStyle(color: theme.colorScheme.error),
          ),
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
      fit: imageFit,
      alignment: Alignment(0, -1 + cropTop * 2),
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (c, e, s) {
        logger.e('Failed to load image at path: $absolutePath, error: $e');
        final theme = Theme.of(context);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'Error loading image',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Map<String, dynamic> content = {
      'images': [],
      'caption': '',
      'cropTop': 0.0,
      'cropBottom': 0.0,
      'fit': 'cover',
    };

    try {
      if (widget.block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(widget.block.content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse JSON block content', error: e, stackTrace: stackTrace);
      return _buildErrorImage(context, ref);
    }

    // Handle both old format (path) and new format (images array)
    List<dynamic> images = [];
    if (content.containsKey('images')) {
      final imagesRaw = content['images'];
      if (imagesRaw is List) {
        images = imagesRaw;
        logger.d('Using multi-image format, image count: ${images.length}');
      } else if (imagesRaw is Map) {
        // Handle case where a single Map was stored instead of a List
        images = [imagesRaw];
        logger.d('Converted single Map to List, image count: 1');
      }
    } else if (content.containsKey('path')) {
      // Old single-image format - convert to new format
      final path = content['path'] as String? ?? '';
      final fileName = content['fileName'] as String? ?? '';
      if (path.isNotEmpty) {
        final isNetwork = path.startsWith('http://') || path.startsWith('https://');
        images = [
          {
            'path': path,
            'fileName': fileName,
            'type': isNetwork ? 'network' : 'local',
          }
        ];
        logger.d('Converted old single-image format to new format');
      }
    }

    final hasImages = images.isNotEmpty;

    if (!hasImages) {
      return _buildEmptyImage(context, ref);
    }

    final caption = content['caption'] as String? ?? '';
    final cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    final cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    BoxFit imageFit = BoxFit.cover;
    final fitStr = content['fit'] as String?;
    try {
      imageFit = BoxFit.values.firstWhere(
            (e) => e.toString().split('.').last == fitStr,
        orElse: () => BoxFit.cover,
      );
    } catch (e) {
      logger.e('Error parsing image fit, defaulting to BoxFit.cover: $e');
      imageFit = BoxFit.cover;
    }

    final rotation = widget.block.style.rotation ?? 0;
    final widthPercent = widget.block.style.widthPercent;
    final heightPercent = widget.block.style.heightPercent;
    final width = widget.block.style.width;
    final height = widget.block.style.height;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions (use percentage if available, otherwise fall back to absolute or default)
    final displayWidth = widthPercent != null 
        ? screenWidth * widthPercent 
        : (width ?? screenWidth * 0.9);
    
    // For BoxFit.contain, use a smaller default height to avoid excessive whitespace
    double calculatedHeight;
    if (imageFit == BoxFit.contain) {
      // Use aspect ratio friendly height for contain mode
      calculatedHeight = heightPercent != null 
          ? screenHeight * heightPercent 
          : (height ?? displayWidth * 0.7); // Use width-based calculation for contain
    } else {
      calculatedHeight = heightPercent != null 
          ? screenHeight * heightPercent 
          : (height ?? 400.0);
    }
    final displayHeight = calculatedHeight;

    // Platform-aware padding using spacing constants
    final padding = ResponsiveUtils.isMobile(context) 
        ? EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing8) 
        : EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing12);
    
    try {
      return Padding(
        padding: padding,
        child: Column(
          children: [
            // Wrap in container with platform-appropriate shadow and border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getPlatformRadius(context, baseRadius: 12.0),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRect(
                    child: Align(
                      heightFactor: 1.0 - cropTop - cropBottom,
                      child: Transform.rotate(
                        angle: rotation * 3.141592653589793 / 180,
                        child: SizedBox(
                          width: displayWidth,
                          height: displayHeight,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                              logger.d('Switched to image index: $index');
                            },
                            itemBuilder: (context, index) {
                              if (index >= images.length) {
                                return _buildEmptyImage(context, ref);
                              }
                              final item = images[index];
                              if (item is! Map<String, dynamic>) {
                                logger.e('Invalid image data type at index $index');
                                return _buildErrorImage(context, ref);
                              }
                              final imageData = item;
                              return _buildImage(imageData, displayWidth, displayHeight, imageFit, cropTop);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Image indicator (e.g., "1/5") with platform-aware styling
                  if (images.length > 1)
                    Positioned(
                      top: ResponsiveUtils.spacing8,
                      right: ResponsiveUtils.spacing8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing12,
                          vertical: ResponsiveUtils.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getPlatformRadius(context, baseRadius: 16.0),
                          ),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: PlatformThemeHelper.isAndroid 
                                ? FontWeight.w700  // Android: Bold
                                : FontWeight.w600, // Apple: Semibold
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    caption,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Error building image reader block', error: e, stackTrace: stackTrace);
      return _buildErrorImage(context, ref);
    }
  }
}
