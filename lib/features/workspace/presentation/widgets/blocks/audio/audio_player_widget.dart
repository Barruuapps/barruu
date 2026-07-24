import 'dart:io';

import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// A widget that provides a complete audio player interface with playback controls.
///
/// This widget displays an audio player with:
/// - Play/pause button
/// - Progress slider
/// - Skip forward/backward buttons (10 seconds)
/// - Volume control
/// - Playback speed control
/// - Time display (current position / total duration)
///
/// The widget automatically handles:
/// - Audio initialization and loading
/// - Error states
/// - Loading states with shimmer effect
/// - Lifecycle management (pauses when app goes to background)
///
/// Example usage:
/// ```dart
/// AudioPlayerWidget(
///   audioPath: '/path/to/audio.mp3',
///   autoPlay: false,
/// )
/// ```
class AudioPlayerWidget extends ConsumerStatefulWidget {
  /// The absolute path to the audio file to play
  final String audioPath;

  /// Whether to automatically start playing when the audio is loaded
  final bool autoPlay;

  const AudioPlayerWidget({
    required this.audioPath,
    this.autoPlay = false,
    super.key,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget>
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
      }
    }
  }

  /// Initializes the audio player and sets up event listeners.
  ///
  /// This method:
  /// - Validates the audio file exists
  /// - Loads the audio file with a 30-second timeout
  /// - Sets up listeners for duration, position, and player state changes
  /// - Configures initial volume and playback speed
  /// - Auto-plays if configured
  Future<void> _initializeAudioPlayer() async {
    try {
      final file = File(widget.audioPath);
      if (!file.existsSync()) {
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

      // Set up listeners
      _player.durationStream.listen((duration) {
        if (duration != null && mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _position = Duration.zero;
              _player.seek(Duration.zero);
            }
          });
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Set initial volume and speed
      await _player.setVolume(_volume);
      await _player.setSpeed(_playbackSpeed);

      if (widget.autoPlay) {
        _player.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
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
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  /// Toggles between play and pause states
  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _player.pause();
      } else {
        _player.play();
      }
    });
  }

  /// Seeks to a specific position in the audio
  void _seek(Duration position) {
    _player.seek(position);
  }

  /// Seeks relative to the current position by the given offset
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

  /// Changes the playback speed
  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _player.setSpeed(_playbackSpeed);
    });
  }

  /// Changes the volume level (0.0 to 1.0)
  void _changeVolume(double volume) {
    setState(() {
      _volume = volume.clamp(0.0, 1.0);
      _player.setVolume(_volume);
    });
  }

  /// Formats a duration to MM:SS format
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  inactiveColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
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
