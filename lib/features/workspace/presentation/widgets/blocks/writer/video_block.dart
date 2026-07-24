import 'dart:io';
import 'dart:async';

import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/core/utils/responsive_utils.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/video_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/services/video_file_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_source_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_url_input_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_caption_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_sizing_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_edit_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_trimming_section.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/video/video_display_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Video block widget with support for:
/// - Local videos from gallery/camera
/// - Network videos (direct URLs)
/// - YouTube videos
/// - Video trimming and splitting
/// - Responsive sizing
/// Extends BaseEditableBlock for consistent behavior.
class VideoBlock extends BaseEditableBlock {
  const VideoBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<VideoBlock> createState() => _VideoBlockState();
}

class _VideoBlockState extends BaseEditableBlockState<VideoBlock> with WidgetsBindingObserver {
  // Block-specific state
  late double rotation;
  late double? widthPercent;
  late double? heightPercent;
  String _caption = '';
  late TextEditingController _captionController;
  late TextEditingController _urlController;
  late Debouncer _saveDebouncer;
  late VideoFileService _videoFileService;
  
  // Video player state
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final double _aspectRatioTolerance = 0.05;
  
  bool _isVideoInitialized = false;
  double _videoDuration = 0;
  bool _isUploading = false;
  bool _showUrlInput = false;
  
  VideoSourceType _sourceType = VideoSourceType.local;
  String _currentVideoPath = '';
  String _currentYoutubeId = '';

  @override
  Map<String, dynamic> getDefaultContent() => {
    'path': '',
    'caption': '',
    'fileName': '',
    'startTime': 0.0,
    'endTime': 0.0,
    'sourceType': 'local',
    'youtubeId': '',
  };

  @override
  void initializeBlockSpecifics() {
    WidgetsBinding.instance.addObserver(this);
    
    rotation = widget.block.style.rotation ?? 0;
    widthPercent = widget.block.style.widthPercent;
    heightPercent = widget.block.style.heightPercent;
    
    _caption = (content['caption'] as String?) ?? '';
    _captionController = TextEditingController(text: _caption);
    _urlController = TextEditingController();
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _videoFileService = VideoFileService();
    
    // Parse source type
    final sourceTypeStr = content['sourceType'] as String? ?? 'local';
    _sourceType = VideoSourceType.values.firstWhere(
      (e) => e.name == sourceTypeStr,
      orElse: () => VideoSourceType.local,
    );
    
    // Ensure startTime and endTime exist
    content['startTime'] = content['startTime'] ?? 0.0;
    content['endTime'] = content['endTime'] ?? 0.0;
    
    // Initialize tracking variables to current state
    _currentVideoPath = content['path'] as String? ?? '';
    _currentYoutubeId = content['youtubeId'] as String? ?? '';
    
    // Initialize video controller if video content exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentVideoPath.isNotEmpty || _currentYoutubeId.isNotEmpty) {
        _initializeVideoController();
      }
    });
  }
  
  @override
  void disposeBlockSpecifics() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    _saveDebouncer.dispose();
    _captionController.dispose();
    _urlController.dispose();
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _videoController = null;
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  Future<void> _initializeVideoController() async {
    _disposeControllers();
    
    if (!mounted) return;
    
    setState(() {
      _isVideoInitialized = false;
    });

    if (_sourceType == VideoSourceType.youtube) {
      final youtubeId = content['youtubeId'] as String? ?? '';
      if (youtubeId.isNotEmpty) {
        _currentYoutubeId = youtubeId;
        _currentVideoPath = '';
        _initializeYoutubePlayer(youtubeId);
      }
    } else {
      final path = content['path'] as String? ?? '';
      if (path.isNotEmpty) {
        _currentVideoPath = path;
        _currentYoutubeId = '';
        await _initializeVideoPlayer(path);
      }
    }
  }

  void _initializeYoutubePlayer(String youtubeId) {
    try {
      _youtubeController = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
        ),
      );
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showError('Failed to load YouTube video');
      }
    }
  }

  Future<void> _initializeVideoPlayer(String path) async {
    if (!mounted) return;
    
    try {
      String videoSource;
      bool isNetwork = false;
      
      if (_sourceType == VideoSourceType.network) {
        videoSource = path;
        isNetwork = true;
      } else {
        videoSource = '${widget.docDir.path}/$path';
        final file = File(videoSource);
        
        if (await FileSystemEntity.type(file.path) == FileSystemEntityType.notFound) {
          if (mounted) {
            showError('Video file not found');
          }
          return;
        }
      }
      
      if (isNetwork) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoSource));
      } else {
        _videoController = VideoPlayerController.file(File(videoSource));
      }
      
      try {
        await _videoController!.initialize().timeout(
          const Duration(seconds: 30),
        );
      } on TimeoutException {
        // Handle timeout gracefully
        if (mounted) {
          showError('Video loading timed out. Please try again or use a different video.');
        }
        return;
      }
      
      if (!mounted) {
        _videoController?.dispose();
        return;
      }
      
      // Check if initialization was successful (with defensive null checks)
      try {
        if (_videoController == null) {
          if (mounted) {
            showError('Video controller was disposed during initialization');
          }
          return;
        }
        
        if (_videoController!.value.hasError) {
          if (mounted) {
            showError('Video player encountered an error: ${_videoController!.value.errorDescription}');
          }
          return;
        }
        
        if (!_videoController!.value.isInitialized) {
          if (mounted) {
            showError('Video player failed to initialize');
          }
          return;
        }
      } catch (e) {
        // Controller might be in an invalid state
        if (mounted) {
          showError('Video player is in an invalid state: $e');
        }
        return;
      }
      
      setState(() {
        _isVideoInitialized = true;
        _videoDuration = _videoController!.value.duration.inMilliseconds / 1000.0;
        
        // Set end time to video duration if not already set
        if (content['endTime'] == 0.0) {
          content['endTime'] = _videoDuration;
        }
      });
    } catch (e) {
      if (mounted) {
        showError('Error loading video: ${e.toString()}');
      }
    }
  }

  @override
  void onContentChanged() {
    final String caption = (content['caption'] as String?) ?? '';
    if (_captionController.text != caption) {
      _captionController.text = caption;
    }
    if (_caption != caption) {
      _caption = caption;
    }
    
    // Sync source type from content
    final sourceTypeStr = content['sourceType'] as String? ?? 'local';
    final contentSourceType = VideoSourceType.values.firstWhere(
      (e) => e.name == sourceTypeStr,
      orElse: () => VideoSourceType.local,
    );
    if (contentSourceType != _sourceType) {
      _sourceType = contentSourceType;
    }
    
    // Check for video source changes
    final path = content['path'] as String? ?? '';
    final youtubeId = content['youtubeId'] as String? ?? '';
    
    // Handle video removal
    if (path.isEmpty && youtubeId.isEmpty && 
        (_currentVideoPath.isNotEmpty || _currentYoutubeId.isNotEmpty)) {
      _disposeControllers();
      _currentVideoPath = '';
      _currentYoutubeId = '';
      setState(() {
        _isVideoInitialized = false;
      });
      return;
    }
    
    // Check if video source has actually changed
    // For YouTube videos, only reinitialize if the youtubeId changed
    // For other videos, only reinitialize if the path changed
    final hasNewVideo = 
        (youtubeId.isNotEmpty && youtubeId != _currentYoutubeId) || 
        (youtubeId.isEmpty && path.isNotEmpty && path != _currentVideoPath);
    
    if (hasNewVideo) {
      _initializeVideoController();
    }
  }

  void _saveVideoContent() {
    content['caption'] = _caption;
    _saveDebouncer.call(() => saveContent());
  }

  void _updateStyle() {
    final controller = ref.read(editDocumentControllerProvider(widget.docDir).notifier);
    final updatedStyle = widget.block.style.copyWith(
      rotation: rotation,
      widthPercent: widthPercent,
      heightPercent: heightPercent,
      videoSource: _sourceType.name,
    );
    final updatedBlock = widget.block.copyWith(style: updatedStyle);
    controller.saveBlock(updatedBlock);
  }

  Future<void> _addVideoFromUrl(String url) async {
    if (url.isEmpty) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final videoInfo = await _videoFileService.processVideoUrl(url);
      
      if (videoInfo != null) {
        final String newYoutubeId = (videoInfo['youtubeId'] as String?) ?? '';
        final String newPath = (videoInfo['path'] as String?) ?? '';
        final newSourceType = VideoSourceType.values.firstWhere(
          (e) => e.name == videoInfo['sourceType'],
          orElse: () => VideoSourceType.network,
        );
        
        // Check if this is the same video that's already loaded
        final isSameVideo = 
            (newYoutubeId.isNotEmpty && newYoutubeId == _currentYoutubeId) ||
            (newPath.isNotEmpty && newPath == _currentVideoPath);
        
        if (isSameVideo) {
          // Video is already loaded, no need to reinitialize
          if (mounted) {
            showSuccess('Video already loaded');
          }
        } else {
          // Update content with new video
          content['youtubeId'] = newYoutubeId;
          content['path'] = newPath;
          content['fileName'] = videoInfo['fileName'] ?? '';
          _sourceType = newSourceType;
          content['sourceType'] = _sourceType.name;
          
          saveContent();
          
          if (mounted) {
            showSuccess(_sourceType == VideoSourceType.youtube 
                ? 'YouTube video added' 
                : 'Network video added');
          }
        }
      } else {
        if (mounted) {
          showError('Please enter a valid video URL');
        }
      }
    } catch (e) {
      if (mounted) {
        showError('Error adding video: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _showUrlInput = false;
          _urlController.clear();
        });
      }
    }
  }

  /// Show dialog to choose video source type
  void _showVideoSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => VideoSourceDialog(
        onGallerySelected: _pickLocalVideo,
        onUrlSelected: () {
          setState(() {
            _showUrlInput = true;
          });
        },
      ),
    );
  }

  Future<void> _pickLocalVideo() async {
    if (_isUploading) return;
    
    try {
      
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      
      if (picked == null) {
        return;
      }
      
      setState(() {
        _isUploading = true;
      });
      
      final filePath = picked.path;
      final fileName = picked.name;
      
      // Validate video file type
      final validVideoExtensions = [
        'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v'
      ];
      final extension = fileName.split('.').last.toLowerCase();
      
      if (!validVideoExtensions.contains(extension)) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          showError('Invalid video format. Supported formats: ${validVideoExtensions.join(", ")}');
        }
        return;
      }
      
      // Validate file size
      final file = File(filePath);
      final fileSize = await file.length();
      const maxSizeBytes = 500 * 1024 * 1024; // 500MB
      
      if (fileSize > maxSizeBytes) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          showError('Video file is too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum size is 500MB');
        }
        return;
      }
      
      // Dispose existing controllers
      _disposeControllers();
      
      // Delete old video if exists
      final oldPath = content['path'] as String? ?? '';
      if (oldPath.isNotEmpty && !oldPath.startsWith('http')) {
        final oldFile = File('${widget.docDir.path}/$oldPath');
        if (await FileSystemEntity.type(oldFile.path) != FileSystemEntityType.notFound) {
          await oldFile.delete();
        }
      }
      
      // Create videos directory
      final videosDir = Directory('${widget.docDir.path}/media/videos');
      if (await FileSystemEntity.type(videosDir.path) == FileSystemEntityType.notFound) {
        await videosDir.create(recursive: true);
      }
      
      // Copy video
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final newPath = '${videosDir.path}/$uniqueName';
      
      await file.copy(newPath);
      
      // Update content
      content['path'] = 'media/videos/$uniqueName';
      content['fileName'] = fileName;
      content['youtubeId'] = '';
      content['startTime'] = 0.0;
      content['endTime'] = 0.0;
      _sourceType = VideoSourceType.local;
      content['sourceType'] = _sourceType.name;
      
      saveContent();
      await _initializeVideoController();
      
      if (mounted) {
        showSuccess('Video uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        showError('Error uploading video: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.$millis';
  }

  Widget _buildVideoPlayer(ThemeData theme, double displayWidth, double displayHeight) {
    if (_sourceType == VideoSourceType.youtube && _youtubeController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: theme.colorScheme.primary,
          progressColors: ProgressBarColors(
            playedColor: theme.colorScheme.primary,
            handleColor: theme.colorScheme.primary,
          ),
        ),
      );
    }
    
    if (_videoController != null && _isVideoInitialized) {
      final videoAspectRatio = _videoController!.value.aspectRatio > 0 
          ? _videoController!.value.aspectRatio 
          : 16 / 9;
      
      // Calculate the container aspect ratio
      final containerAspectRatio = displayWidth / displayHeight;
      
      // Determine if we should use BoxFit.contain or BoxFit.cover
      // If video aspect ratio differs significantly from container, use cover to fill space
      final shouldCover = (videoAspectRatio > containerAspectRatio * (1.0 + _aspectRatioTolerance)) || 
                         (videoAspectRatio < containerAspectRatio * (1.0 - _aspectRatioTolerance));
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: FittedBox(
            fit: shouldCover ? BoxFit.cover : BoxFit.contain,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: GestureDetector(
                onTap: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  setState(() {});
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    if (!_videoController!.value.isPlaying)
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: theme.colorScheme.primary,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Placeholder when no video - show add video button with source options
    return GestureDetector(
      onTap: widget.isEditing ? _showVideoSourceDialog : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isEditing ? 'Tap to add video' : 'No video',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 8),
                Text(
                  'Choose from gallery, YouTube, or URL',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return VideoReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final relativePath = content['path'] as String? ?? '';
    final youtubeId = content['youtubeId'] as String? ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final hasVideo = relativePath.isNotEmpty || youtubeId.isNotEmpty;
    
    // Calculate responsive dimensions
    final displayWidth = (widthPercent ?? 0.95) * screenWidth;
    final displayHeight = (heightPercent ?? 0.4) * screenHeight;

    // Instagram-style minimal padding
    final padding = ResponsiveUtils.isMobile(context) 
        ? const EdgeInsets.symmetric(vertical: 8) 
        : const EdgeInsets.symmetric(vertical: 12);


    return Padding(
      padding: padding,
      child: Column(
        children: [
          Toolbar(block: widget.block, docDir: widget.docDir),
          
          // URL input field
          if (_showUrlInput)
            VideoUrlInputWidget(
              controller: _urlController,
              onSubmit: _addVideoFromUrl,
              onCancel: () {
                setState(() {
                  _showUrlInput = false;
                  _urlController.clear();
                });
              },
              theme: theme,
            ),
          
          // Video display with controls
          Stack(
            children: [
              VideoDisplaySection(
                theme: theme,
                isEditing: widget.isEditing,
                isUploading: _isUploading,
                rotation: rotation,
                displayWidth: displayWidth,
                displayHeight: displayHeight,
                sourceType: _sourceType,
                videoController: _videoController,
                youtubeController: _youtubeController,
                isVideoInitialized: _isVideoInitialized,
                onTap: _showVideoSourceDialog,
              ),
              
              // Edit controls overlay
              if (widget.isEditing && !_isUploading)
                VideoEditControls(
                  theme: theme,
                  hasVideo: hasVideo,
                  onGalleryTap: _pickLocalVideo,
                  onUrlTap: () {
                    setState(() {
                      _showUrlInput = !_showUrlInput;
                    });
                  },
                  onRotateTap: hasVideo ? () {
                    setState(() {
                      rotation = (rotation + 90) % 360;
                      _updateStyle();
                    });
                  } : null,
                ),
            ],
          ),
          
          // Caption
          VideoCaptionWidget(
            controller: _captionController,
            isEditing: widget.isEditing,
            caption: _caption,
            theme: theme,
            onChanged: (value) {
              setState(() {
                _caption = value;
                _saveVideoContent();
              });
            },
          ),
          
          // Sizing controls for edit mode
          if (widget.isEditing && hasVideo) ...[
            const SizedBox(height: 16),
            VideoSizingControls(
              widthPercent: widthPercent ?? 0.95,
              heightPercent: heightPercent ?? 0.4,
              onWidthChanged: (value) {
                setState(() {
                  widthPercent = value;
                  _updateStyle();
                });
              },
              onHeightChanged: (value) {
                setState(() {
                  heightPercent = value;
                  _updateStyle();
                });
              },
            ),
          ],
          
          // Trimming controls for local/network videos (not YouTube)
          if (widget.isEditing && _isVideoInitialized && 
              _videoDuration > 0 && _sourceType != VideoSourceType.youtube) ...[
            const SizedBox(height: 16),
            VideoTrimmingSection(
              theme: theme,
              videoDuration: _videoDuration,
              startTime: content['startTime'] as double,
              endTime: content['endTime'] as double,
              onStartTimeChanged: (value) {
                setState(() {
                  content['startTime'] = value;
                  _saveVideoContent();
                });
              },
              onEndTimeChanged: (value) {
                setState(() {
                  content['endTime'] = value;
                  _saveVideoContent();
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
