import 'dart:io';
import 'dart:async';
import 'dart:math' show pi;

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/presentation/services/youtube_url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path/path.dart' as path;

enum _VideoSourceType { local, network, youtube }

class VideoReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const VideoReaderBlock({
    super.key,
    required this.block,
    required this.docDir,
  });

  @override
  ConsumerState<VideoReaderBlock> createState() => _VideoReaderBlockState();
}

class _VideoReaderBlockState extends ConsumerState<VideoReaderBlock> with WidgetsBindingObserver {
  String _videoSource = '';
  String _caption = '';
  bool _hasError = false;
  double _rotation = 0;
  bool _isInitialized = false;
  _VideoSourceType _sourceType = _VideoSourceType.local;

  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;

  bool _isPlaying = false;
  double _startTime = 0.0;
  double _endTime = 0.0;
  bool _showControls = true;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  final FocusNode _focusNode = FocusNode();

  Map<String, dynamic> content = {
    'path': '',
    'caption': '',
    'fileName': '',
    'startTime': 0.0,
    'endTime': 0.0,
    'sourceType': 'local',
    'youtubeId': '',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logger.i('Initializing VideoReaderBlock with block ID: ${widget.block.id}');
    _parseContent();
    _rotation = widget.block.style.rotation ?? 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
        _isInitialized &&
        _controller != null &&
        _controller!.value.isPlaying) {
      _controller!.pause();
      logger.d('Video paused due to app lifecycle change');
    }
  }

  void _parseContent() {
    logger.d('Parsing block content for block ID: ${widget.block.id}');

    if (widget.block.content.isEmpty) {
      logger.w('Block content is empty');
      setState(() => _hasError = true);
      return;
    }

    try {
      content = JsonStringConverter().convertFromJsonString(widget.block.content);
      logger.d('Successfully parsed JSON content: $content');
    } catch (e) {
      logger.e('Failed to parse JSON content: $e');
      setState(() => _hasError = true);
      return;
    }

    final sourceTypeStr = content['sourceType'] as String? ?? 'local';
    _sourceType = _VideoSourceType.values.firstWhere(
          (e) => e.name == sourceTypeStr,
      orElse: () {
        final pathStr = content['path'] as String? ?? '';
        final youtubeId = content['youtubeId'] as String? ?? '';

        if (youtubeId.isNotEmpty || YouTubeUrlHelper.isYouTubeUrl(pathStr)) {
          return _VideoSourceType.youtube;
        }
        if (pathStr.startsWith('http://') || pathStr.startsWith('https://')) {
          return _VideoSourceType.network;
        }
        return _VideoSourceType.local;
      },
    );

    _caption = content['caption'] as String? ?? '';
    _startTime = (content['startTime'] as num?)?.toDouble() ?? 0.0;
    _endTime = (content['endTime'] as num?)?.toDouble() ?? 0.0;

    _initializeController();
  }

  void _initializeController() {
    if (_sourceType == _VideoSourceType.youtube) {
      String? youtubeId = content['youtubeId'] as String?;
      if (youtubeId == null || youtubeId.isEmpty) {
        final pathStr = content['path'] as String? ?? '';
        youtubeId = YouTubeUrlHelper.extractVideoId(pathStr);
      }

      if (youtubeId != null && youtubeId.isNotEmpty) {
        _initializeYoutubePlayer(youtubeId);
      } else {
        setState(() => _hasError = true);
      }
    } else {
      _initializeVideoPlayer();
    }
  }

  void _initializeYoutubePlayer(String videoId) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false),
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _videoSource = videoId;
      });
    }
    logger.i('YouTube player initialized for video: $videoId');
  }

  Future<void> _initializeVideoPlayer() async {
    final pathStr = content['path'] as String? ?? '';
    if (pathStr.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final isNetwork = _sourceType == _VideoSourceType.network;
    String sourcePath;

    if (isNetwork) {
      try {
        final uri = Uri.parse(pathStr);
        if (!uri.hasScheme || !uri.hasAuthority) throw const FormatException();
        sourcePath = pathStr;
      } catch (e) {
        logger.e('Invalid network URL: $pathStr');
        setState(() => _hasError = true);
        return;
      }
    } else {
      final absolutePath = path.join(widget.docDir.path, pathStr);
      final file = File(absolutePath);

      if (!absolutePath.startsWith(widget.docDir.path) || !file.existsSync()) {
        logger.e('Invalid or missing local file: $absolutePath');
        setState(() => _hasError = true);
        return;
      }
      sourcePath = absolutePath;
    }

    _videoSource = sourcePath;

    try {
      _controller = isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(sourcePath))
          : VideoPlayerController.file(File(sourcePath));

      await _controller!.initialize().timeout(const Duration(seconds: 30));

      if (!mounted || _controller!.value.hasError || !_controller!.value.isInitialized) {
        setState(() => _hasError = true);
        return;
      }

      if (_startTime > 0) {
        await _controller!.seekTo(Duration(milliseconds: (_startTime * 1000).round()));
      }

      _controller!
        ..addListener(_videoPlayerListener)
        ..setVolume(_volume)
        ..setPlaybackSpeed(_playbackSpeed);

      if (mounted) {
        setState(() => _isInitialized = true);
      }

      logger.i('Video player initialized successfully');
    } catch (e) {
      logger.e('Failed to initialize video player: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _videoPlayerListener() {
    if (!mounted || _controller == null) return;

    final playing = _controller!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }

    if (_endTime > 0 && playing) {
      final pos = _controller!.value.position.inMilliseconds / 1000.0;
      if (pos >= _endTime) {
        _controller!.seekTo(Duration(milliseconds: (_startTime * 1000).round()));
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoReaderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block != oldWidget.block) {
      _disposeControllers();
      setState(() {
        _isInitialized = false;
        _hasError = false;
      });
      _parseContent();
    }
    if (widget.block.style.rotation != oldWidget.block.style.rotation) {
      setState(() => _rotation = widget.block.style.rotation ?? 0);
    }
  }

  void _disposeControllers() {
    _controller?.removeListener(_videoPlayerListener);
    _controller?.dispose();
    _controller = null;
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _controller == null) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
        _togglePlayPause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyJ:
        _seekRelative(-10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyL:
        _seekRelative(10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _changeVolume((_volume + 0.1).clamp(0.0, 1.0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _changeVolume((_volume - 0.1).clamp(0.0, 1.0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        _changeVolume(_volume > 0 ? 0.0 : 1.0);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      _isPlaying = !_isPlaying;
      _showControls = true;
    });
  }

  void _changeVolume(double volume) {
    if (_controller == null) return;
    setState(() {
      _volume = volume.clamp(0.0, 1.0);
      _controller!.setVolume(_volume);
    });
  }

  void _changePlaybackSpeed(double speed) {
    if (_controller == null) return;
    setState(() {
      _playbackSpeed = speed;
      _controller!.setPlaybackSpeed(speed);
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final duration = _controller!.value.duration;

    _controller!.seekTo(target.inMilliseconds < 0
        ? Duration.zero
        : target > duration
        ? duration
        : target);
  }

  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
  }

  Widget _buildYoutubePlayer(ThemeData theme) {
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

  Widget _buildVideoPlayer(ThemeData theme, double width, double height) {
    final aspectRatio = _controller!.value.aspectRatio > 0
        ? _controller!.value.aspectRatio
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          children: [
            // Video layer - maintains aspect ratio without black bars
            Center(
              child: Transform.rotate(
                angle: _rotation * pi / 180,
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

            // Buffering overlay
            if (_controller!.value.isBuffering)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: const Center(
                    child: ShimmerCircularProgress(size: 40),
                  ),
                ),
              ),

            // Tap to show/hide controls
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControlsVisibility,
                child: Container(color: Colors.transparent),
              ),
            ),

            // Controls overlay
            if (_showControls) ...[
              // Center play/pause button
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: theme.colorScheme.primary,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                                onPressed: _togglePlayPause,
                                tooltip: _isPlaying ? 'Pause' : 'Play',
                              ),
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white),
                                onPressed: () => _seekRelative(-10),
                                tooltip: 'Rewind 10 seconds',
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white),
                                onPressed: () => _seekRelative(10),
                                tooltip: 'Forward 10 seconds',
                              ),
                              PopupMenuButton<double>(
                                icon: Icon(
                                  _volume > 0.5
                                      ? Icons.volume_up
                                      : _volume > 0
                                      ? Icons.volume_down
                                      : Icons.volume_off,
                                  color: Colors.white,
                                ),
                                onSelected: _changeVolume,
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 1.0, child: Text('100%')),
                                  const PopupMenuItem(value: 0.5, child: Text('50%')),
                                  const PopupMenuItem(value: 0.0, child: Text('Mute')),
                                ],
                              ),
                            ],
                          ),
                          PopupMenuButton<double>(
                            icon: const Icon(Icons.speed, color: Colors.white),
                            onSelected: _changePlaybackSpeed,
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                              const PopupMenuItem(value: 1.0, child: Text('Normal')),
                              const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                              const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final widthPercent = widget.block.style.widthPercent ?? 0.95;
    final heightPercent = widget.block.style.heightPercent ?? 0.4;
    final displayWidth = screenWidth * widthPercent;
    final displayHeight = (MediaQuery.of(context).size.height * heightPercent).clamp(200.0, 600.0);

    final padding = ResponsiveUtils.isMobile(context)
        ? const EdgeInsets.symmetric(vertical: 8)
        : const EdgeInsets.symmetric(vertical: 12);

    if (_hasError || _videoSource.isEmpty) {
      return Padding(
        padding: padding,
        child: Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error loading video',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Padding(
        padding: padding,
        child: Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: ShimmerCircularProgress(color: theme.colorScheme.primary)),
        ),
      );
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: displayWidth,
                maxHeight: displayHeight,
              ),
              child: _sourceType == _VideoSourceType.youtube && _youtubeController != null
                  ? _buildYoutubePlayer(theme)
                  : _buildVideoPlayer(theme, displayWidth, displayHeight),
            ),
            if (_caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _caption,
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
      ),
    );
  }
}