import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:barruu/features/workspace/presentation/services/video_file_service.dart';

/// Widget for displaying video player with rotation and sizing.
///
/// Handles:
/// - YouTube videos via YoutubePlayerController
/// - Local/network videos via VideoPlayerController
/// - Placeholder when no video
/// - Uploading state with progress indicator
///
/// Example:
/// ```dart
/// VideoDisplaySection(
///   theme: theme,
///   isEditing: true,
///   isUploading: false,
///   rotation: 0.0,
///   displayWidth: 400.0,
///   displayHeight: 300.0,
///   sourceType: VideoSourceType.local,
///   videoController: videoController,
///   youtubeController: null,
///   isVideoInitialized: true,
///   onTap: () => showVideoSourceDialog(),
/// )
/// ```
class VideoDisplaySection extends StatelessWidget {
  final ThemeData theme;
  final bool isEditing;
  final bool isUploading;
  final double rotation;
  final double displayWidth;
  final double displayHeight;
  final VideoSourceType sourceType;
  final VideoPlayerController? videoController;
  final YoutubePlayerController? youtubeController;
  final bool isVideoInitialized;
  final VoidCallback? onTap;
  final double aspectRatioTolerance;

  const VideoDisplaySection({
    required this.theme,
    required this.isEditing,
    required this.isUploading,
    required this.rotation,
    required this.displayWidth,
    required this.displayHeight,
    required this.sourceType,
    required this.videoController,
    required this.youtubeController,
    required this.isVideoInitialized,
    this.onTap,
    this.aspectRatioTolerance = 0.05,
    super.key,
  });

  Widget _buildVideoPlayer() {
    if (sourceType == VideoSourceType.youtube && youtubeController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: theme.colorScheme.primary,
          progressColors: ProgressBarColors(
            playedColor: theme.colorScheme.primary,
            handleColor: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (videoController != null && isVideoInitialized) {
      final videoAspectRatio = videoController!.value.aspectRatio > 0
          ? videoController!.value.aspectRatio
          : 16 / 9;

      final containerAspectRatio = displayWidth / displayHeight;

      final shouldCover =
          (videoAspectRatio > containerAspectRatio * (1.0 + aspectRatioTolerance)) ||
          (videoAspectRatio < containerAspectRatio * (1.0 - aspectRatioTolerance));

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: FittedBox(
            fit: shouldCover ? BoxFit.cover : BoxFit.contain,
            child: SizedBox(
              width: videoController!.value.size.width,
              height: videoController!.value.size.height,
              child: _VideoPlayerWithControls(
                controller: videoController!,
                theme: theme,
              ),
            ),
          ),
        ),
      );
    }

    // Placeholder when no video
    return GestureDetector(
      onTap: isEditing ? onTap : null,
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
                isEditing ? 'Tap to add video' : 'No video',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              if (isEditing) ...[
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
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: isEditing
            ? BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: SizedBox(
          width: displayWidth,
          height: displayHeight.clamp(200.0, 600.0),
          child: isUploading
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerCircularProgress(
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Uploading video...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : Transform.rotate(
                  angle: rotation * 3.141592653589793 / 180,
                  child: _buildVideoPlayer(),
                ),
        ),
      ),
    );
  }
}

/// Internal widget for video player with play/pause controls
class _VideoPlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final ThemeData theme;

  const _VideoPlayerWithControls({
    required this.controller,
    required this.theme,
  });

  @override
  State<_VideoPlayerWithControls> createState() => _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.value.isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(widget.controller),
          if (!widget.controller.value.isPlaying)
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
              widget.controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: widget.theme.colorScheme.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}
