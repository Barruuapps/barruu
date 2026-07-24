import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// A widget that provides audio trimming controls.
///
/// This widget allows users to:
/// - Set start and end times for audio playback
/// - Preview trim points by seeking to them
/// - See the segment duration
/// - Create a new block with the remaining portion of audio
///
/// The widget displays:
/// - Two sliders for start and end time selection
/// - Buttons to jump to start/end points for preview
/// - A button to create a new block with the remaining audio
///
/// Example usage:
/// ```dart
/// AudioTrimmingWidget(
///   audioPlayer: _audioPlayer,
///   audioDuration: 120.5,
///   content: contentMap,
///   block: currentBlock,
///   docDir: documentDirectory,
///   onContentChanged: () => saveContent(),
///   onError: (msg) => showError(msg),
///   onSuccess: (msg) => showSuccess(msg),
/// )
/// ```
class AudioTrimmingWidget extends ConsumerStatefulWidget {
  /// The audio player instance used for seeking to preview points
  final AudioPlayer audioPlayer;

  /// The total duration of the audio file in seconds
  final double audioDuration;

  /// The content map containing startTime and endTime
  final Map<String, dynamic> content;

  /// The current block being edited
  final Block block;

  /// The document directory
  final Directory docDir;

  /// Callback when content is modified
  final VoidCallback onContentChanged;

  /// Callback to show error messages
  final Function(String) onError;

  /// Callback to show success messages
  final Function(String) onSuccess;

  const AudioTrimmingWidget({
    required this.audioPlayer,
    required this.audioDuration,
    required this.content,
    required this.block,
    required this.docDir,
    required this.onContentChanged,
    required this.onError,
    required this.onSuccess,
    super.key,
  });

  @override
  ConsumerState<AudioTrimmingWidget> createState() =>
      _AudioTrimmingWidgetState();
}

class _AudioTrimmingWidgetState extends ConsumerState<AudioTrimmingWidget> {
  bool _isProcessing = false;

  /// Formats a duration value in seconds to MM:SS.D format
  String _formatDuration(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.$millis';
  }

  /// Creates a new audio block with the remaining portion of the audio.
  ///
  /// The new block will start from the current end time and go to the
  /// end of the audio file.
  Future<void> _createNextBlock() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentEndTime = widget.content['endTime'] as double;

      // Check if there's remaining audio after current end time
      if (currentEndTime >= widget.audioDuration - 0.5) {
        widget.onError('No remaining audio to create next block');
        return;
      }

      // Create a new block with the remaining portion
      final controller = ref.read(
        editDocumentControllerProvider(widget.docDir).notifier,
      );

      final newContent = {
        'path': widget.content['path'],
        'fileName': widget.content['fileName'],
        'customTitle': '',
        'caption': '',
        'startTime': currentEndTime,
        'endTime': widget.audioDuration,
      };

      // Use the addBlockWithContent method
      final jsonConverter = JsonStringConverter();
      await controller.addBlockWithContent(
        content: jsonConverter.convertToJsonString(newContent),
        type: widget.block.type,
        style: widget.block.style,
      );

      widget.onSuccess('New audio block created with remaining portion');
    } catch (e) {
      widget.onError(
        'Error creating next block: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = widget.content['startTime'] as double;
    final endTime = widget.content['endTime'] as double;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.content_cut, size: 20),
              const SizedBox(width: 8),
              Text(
                'Audio Trimming',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_formatDuration(widget.audioDuration)}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Start time slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_formatDuration(startTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 20),
                tooltip: 'Jump to start time',
                onPressed: () async {
                  await widget.audioPlayer.seek(
                    Duration(milliseconds: (startTime * 1000).round()),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
          Slider(
            value: startTime.clamp(0.0, widget.audioDuration),
            max: widget.audioDuration > 0 ? widget.audioDuration : 1.0,
            divisions: widget.audioDuration > 0
                ? ((widget.audioDuration * 10).toInt()).clamp(1, 10000)
                : null,
            label: _formatDuration(startTime),
            onChanged: (value) {
              if (!mounted || widget.audioDuration <= 0) return;

              setState(() {
                // Ensure start time is before end time
                if (value < endTime - 0.5 || endTime == 0.0) {
                  widget.content['startTime'] = value.clamp(
                    0.0,
                    widget.audioDuration,
                  );
                  widget.onContentChanged();
                }
              });
            },
            onChangeEnd: (value) async {
              // Seek to the new start time for visual feedback
              await widget.audioPlayer.seek(
                Duration(milliseconds: (value * 1000).round()),
              );
            },
          ),
          const SizedBox(height: 12),

          // End time slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'End: ${_formatDuration(endTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20),
                tooltip: 'Jump to end time',
                onPressed: () async {
                  await widget.audioPlayer.seek(
                    Duration(milliseconds: (endTime * 1000).round()),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
          Slider(
            value: endTime.clamp(
              0.0,
              widget.audioDuration > 0 ? widget.audioDuration : 1.0,
            ),
            max: widget.audioDuration > 0 ? widget.audioDuration : 1.0,
            divisions: widget.audioDuration > 0
                ? ((widget.audioDuration * 10).toInt()).clamp(1, 10000)
                : null,
            label: _formatDuration(endTime),
            onChanged: (value) {
              if (!mounted || widget.audioDuration <= 0) return;

              setState(() {
                // Ensure end time is after start time
                if (value > startTime + 0.5) {
                  widget.content['endTime'] = value.clamp(
                    0.0,
                    widget.audioDuration,
                  );
                  widget.onContentChanged();
                }
              });
            },
            onChangeEnd: (value) async {
              // Seek to the new end time for visual feedback
              await widget.audioPlayer.seek(
                Duration(milliseconds: (value * 1000).round()),
              );
            },
          ),
          const SizedBox(height: 8),

          // Segment duration display
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.audiotrack,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Segment Duration: ${_formatDuration(endTime - startTime)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Create next block button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _createNextBlock,
              icon: _isProcessing
                  ? ShimmerInlineLoading(
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : const Icon(Icons.add_box),
              label: Text(
                _isProcessing ? 'Creating...' : 'Cut & Create Next Block',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Creates a new audio block with remaining portion (${_formatDuration(endTime)} to ${_formatDuration(widget.audioDuration)})',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
