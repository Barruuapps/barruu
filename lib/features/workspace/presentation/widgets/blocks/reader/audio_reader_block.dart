import 'dart:io';

import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';

class AudioReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const AudioReaderBlock({
    super.key,
    required this.block,
    required this.docDir,
  });

  @override
  ConsumerState<AudioReaderBlock> createState() => _AudioReaderBlockState();
}

class _AudioReaderBlockState extends ConsumerState<AudioReaderBlock> {
  String _audioSource = '';
  String _fileName = '';
  String _customTitle = '';
  String _caption = '';
  bool _hasError = false;
  double? _width;
  double? _height;
  double _startTime = 0.0;
  double _endTime = 0.0;

  @override
  void initState() {
    super.initState();
    _parseContent();
    _width = widget.block.style.width;
    _height = widget.block.style.height;
  }

  void _parseContent() {
    logger.d('Parsing block content for block ID: ${widget.block.id}');
    Map<String, dynamic> contentData = {
      'path': '',
      'customTitle': '',
      'caption': '',
      'fileName': '',
      'startTime': 0.0,
      'endTime': 0.0,
    };
    if (widget.block.content.isNotEmpty) {
      try {
        contentData = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
        logger.d('Successfully parsed JSON content: $contentData');
      } catch (e) {
        logger.e('Failed to parse JSON content: $e');
        setState(() {
          _hasError = true;
        });
        return;
      }
    } else {
      logger.w('Block content is empty, using default content');
    }

    // Extract trim times
    _startTime = (contentData['startTime'] as num?)?.toDouble() ?? 0.0;
    _endTime = (contentData['endTime'] as num?)?.toDouble() ?? 0.0;

    String pathStr = contentData['path'] as String? ?? '';
    if (pathStr.isEmpty) {
      logger.w('Audio path is empty');
      setState(() {
        _hasError = true;
      });
      return;
    }

    // Validate path doesn't contain path traversal attempts
    if (pathStr.contains('..') || pathStr.contains('~')) {
      logger.e(
        'Invalid audio path detected (path traversal attempt): $pathStr',
      );
      setState(() {
        _hasError = true;
      });
      return;
    }

    _customTitle = contentData['customTitle'] as String? ?? '';
    _caption = contentData['caption'] as String? ?? '';
    String storedFileName = contentData['fileName'] as String? ?? '';

    bool isRemote =
        pathStr.startsWith('http://') || pathStr.startsWith('https://');

    if (isRemote) {
      // Validate remote URL
      try {
        final uri = Uri.parse(pathStr);
        if (!uri.hasScheme || !uri.hasAuthority) {
          throw const FormatException('Invalid URL format');
        }
        _audioSource = pathStr;
        _fileName = storedFileName.isNotEmpty
            ? storedFileName
            : path.basename(uri.path);
      } catch (e) {
        logger.e('Invalid remote audio URL: $pathStr, error: $e');
        setState(() {
          _hasError = true;
        });
        return;
      }
    } else {
      String relativePath = pathStr;
      String absolutePath = path.join(widget.docDir.path, relativePath);

      // Validate file exists and is within docDir
      final file = File(absolutePath);
      if (!absolutePath.startsWith(widget.docDir.path)) {
        logger.e('Audio file path outside document directory: $absolutePath');
        setState(() {
          _hasError = true;
        });
        return;
      }

      if (!file.existsSync()) {
        logger.e('Audio file not found at path: $absolutePath');
        setState(() {
          _hasError = true;
        });
        return;
      }

      // Validate audio file extension
      final extension = path.extension(absolutePath).toLowerCase();
      final validExtensions = [
        '.mp3',
        '.wav',
        '.ogg',
        '.aac',
        '.m4a',
        '.flac',
        '.wma',
        '.opus',
      ];
      if (!validExtensions.contains(extension)) {
        logger.e('Invalid audio file extension: $extension');
        setState(() {
          _hasError = true;
        });
        return;
      }

      _audioSource = absolutePath;
      _fileName = storedFileName.isNotEmpty
          ? storedFileName
          : path.basename(absolutePath);
    }
  }

  @override
  void didUpdateWidget(covariant AudioReaderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block != oldWidget.block) {
      _parseContent();
    }
    if (widget.block.style.width != oldWidget.block.style.width ||
        widget.block.style.height != oldWidget.block.style.height) {
      final styleUtils = ref.read(styleUtilsProvider);
      _width = widget.block.style.width;
      _height = widget.block.style.height;
      logger.d('Style properties updated: width=$_width, height=$_height');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final color =
        styleUtils.parseHex(widget.block.style.color) ??
        theme.colorScheme.primary;

    if (_hasError || _audioSource.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 600;
    final padding = isWide
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
    const margin = EdgeInsets.symmetric(vertical: 3);
    final maxWidth = MediaQuery.of(context).size.width - (isWide ? 32 : 24);

    return Padding(
      padding: padding,
      child: Container(
        margin: margin,
        padding: padding,
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.music_note, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _customTitle.isNotEmpty ? _customTitle : _fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AudioPlayerWidget(
              audioSource: _audioSource,
              startTime: _startTime,
              endTime: _endTime,
            ),
            if (_caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Text(
                    _caption,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerWidget extends ConsumerStatefulWidget {
  final String audioSource;
  final double startTime;
  final double endTime;

  const _AudioPlayerWidget({
    required this.audioSource,
    this.startTime = 0.0,
    this.endTime = 0.0,
  });

  @override
  ConsumerState<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<_AudioPlayerWidget>
    with WidgetsBindingObserver {
  late AudioPlayer _player;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logger.i(
      'Initializing AudioPlayerWidget with audioSource: ${widget.audioSource}',
    );
    _player = AudioPlayer();
    _initializeAudioPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause audio when app goes to background for better resource management
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        _player.pause();
        logger.d('Audio paused due to app lifecycle change');
      }
    }
  }

  Future<void> _initializeAudioPlayer() async {
    logger.d(
      'Attempting to initialize audio player for source: ${widget.audioSource}',
    );
    try {
      bool isLocal =
          !(widget.audioSource.startsWith('http://') ||
              widget.audioSource.startsWith('https://'));

      if (isLocal) {
        final file = File(widget.audioSource);
        if (!file.existsSync()) {
          logger.e('Audio file not found at path: ${widget.audioSource}');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
          return;
        }
        // Add timeout to prevent indefinite hanging
        await _player
            .setFilePath(file.path)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception(
                  'Audio initialization timed out after 30 seconds',
                );
              },
            );
      } else {
        // Add timeout to prevent indefinite hanging
        await _player
            .setUrl(widget.audioSource)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception(
                  'Audio initialization timed out after 30 seconds',
                );
              },
            );
      }
      logger.i('Audio player initialized successfully');

      // Seek to start time if specified
      if (widget.startTime > 0 && mounted) {
        await _player.seek(
          Duration(milliseconds: (widget.startTime * 1000).round()),
        );
      }

      // Set initial volume and speed
      await _player.setVolume(_volume);
      await _player.setSpeed(_playbackSpeed);

      // Set up listeners
      _player.durationStream.listen((duration) {
        if (duration != null && mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Throttle position updates to reduce rebuilds and check for trim loop
      _player.positionStream
          .throttleTime(const Duration(milliseconds: 500))
          .listen((position) {
            if (mounted) {
              setState(() {
                _position = position;
              });

              // Check if we need to loop back to start time
              if (_isPlaying && widget.endTime > 0) {
                final currentPosition = position.inMilliseconds / 1000.0;
                if (currentPosition >= widget.endTime) {
                  _player.seek(
                    Duration(milliseconds: (widget.startTime * 1000).round()),
                  );
                  logger.d(
                    'Audio looped back to start time: ${widget.startTime}',
                  );
                }
              }
            }
          });

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              // Reset to start time instead of zero
              final resetPos = Duration(
                milliseconds: (widget.startTime * 1000).round(),
              );
              _position = resetPos;
              _player.seek(resetPos);
              logger.d('Audio playback completed, resetting to start position');
            }
          });
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize audio player',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioSource != widget.audioSource) {
      logger.i(
        'Audio source changed from ${oldWidget.audioSource} to ${widget.audioSource}, reinitializing',
      );
      // Dispose old player before re-initializing
      _player.dispose();
      setState(() {
        _isInitialized = false;
        _hasError = false;
      });
      _player = AudioPlayer();
      _initializeAudioPlayer();
    }
  }

  @override
  void dispose() {
    logger.i(
      'Disposing AudioPlayerWidget for audioSource: ${widget.audioSource}',
    );
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _player.pause();
        logger.i('Audio paused');
      } else {
        _player.play();
        logger.i('Audio playing');
      }
    });
  }

  void _seek(Duration position) {
    _player.seek(position);
    logger.d('Seek to: ${_formatDuration(position)}');
  }

  void _seekRelative(Duration offset) {
    final newPosition = _position + offset;
    if (newPosition < Duration.zero) {
      _seek(Duration.zero);
    } else if (newPosition > _duration) {
      _seek(_duration);
    } else {
      _seek(newPosition);
    }
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _player.setSpeed(_playbackSpeed);
      logger.d('Playback speed changed to: $_playbackSpeed');
    });
  }

  void _changeVolume(double volume) {
    setState(() {
      _volume = volume.clamp(0.0, 1.0);
      _player.setVolume(_volume);
      logger.d('Volume changed to: $_volume');
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    logger.d(
      'Building AudioPlayerWidget, initialized: $_isInitialized, hasError: $_hasError',
    );

    if (_hasError) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: ShimmerCircularProgress(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds.toDouble() > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _seek(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () => _seekRelative(const Duration(seconds: -10)),
                color: theme.colorScheme.primary,
                tooltip: 'Rewind 10s',
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                  color: theme.colorScheme.primary,
                  iconSize: 32,
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () => _seekRelative(const Duration(seconds: 10)),
                color: theme.colorScheme.primary,
                tooltip: 'Forward 10s',
              ),
              const SizedBox(width: 8),
              // Volume control
              PopupMenuButton<double>(
                icon: Icon(
                  _volume > 0.5
                      ? Icons.volume_up
                      : (_volume > 0 ? Icons.volume_down : Icons.volume_off),
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Volume',
                onSelected: _changeVolume,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 1.0,
                    child: Row(
                      children: [
                        Icon(Icons.volume_up, size: 20),
                        SizedBox(width: 8),
                        Text('100%'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 0.5,
                    child: Row(
                      children: [
                        Icon(Icons.volume_down, size: 20),
                        SizedBox(width: 8),
                        Text('50%'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 0.0,
                    child: Row(
                      children: [
                        Icon(Icons.volume_off, size: 20),
                        SizedBox(width: 8),
                        Text('Mute'),
                      ],
                    ),
                  ),
                ],
              ),
              // Playback speed
              PopupMenuButton<double>(
                icon: Icon(Icons.speed, color: theme.colorScheme.primary),
                tooltip: 'Playback Speed',
                onSelected: _changePlaybackSpeed,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0.5,
                    child: Text(
                      '0.5x',
                      style: TextStyle(
                        fontWeight: _playbackSpeed == 0.5
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 0.75,
                    child: Text(
                      '0.75x',
                      style: TextStyle(
                        fontWeight: _playbackSpeed == 0.75
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1.0,
                    child: Text(
                      'Normal',
                      style: TextStyle(
                        fontWeight: _playbackSpeed == 1.0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1.25,
                    child: Text(
                      '1.25x',
                      style: TextStyle(
                        fontWeight: _playbackSpeed == 1.25
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1.5,
                    child: Text(
                      '1.5x',
                      style: TextStyle(
                        fontWeight: _playbackSpeed == 1.5
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 2.0,
                    child: Text(
                      '2.0x',
                      style: TextStyle(
                        fontWeight: _playbackSpeed == 2.0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
