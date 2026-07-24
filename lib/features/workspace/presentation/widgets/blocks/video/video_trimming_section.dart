import 'package:flutter/material.dart';

/// Widget for displaying video trimming controls in edit mode.
///
/// Shows:
/// - Trim header with duration
/// - Start time slider with display
/// - End time slider with display
/// - Segment duration
///
/// Only shown for local/network videos (not YouTube) when video is initialized.
///
/// Example:
/// ```dart
/// VideoTrimmingSection(
///   theme: theme,
///   videoDuration: 120.0,
///   startTime: 0.0,
///   endTime: 120.0,
///   onStartTimeChanged: (value) => updateStartTime(value),
///   onEndTimeChanged: (value) => updateEndTime(value),
/// )
/// ```
class VideoTrimmingSection extends StatelessWidget {
  final ThemeData theme;
  final double videoDuration;
  final double startTime;
  final double endTime;
  final ValueChanged<double> onStartTimeChanged;
  final ValueChanged<double> onEndTimeChanged;

  const VideoTrimmingSection({
    required this.theme,
    required this.videoDuration,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    super.key,
  });

  String _formatDuration(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.$millis';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.content_cut,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Video Trimming',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Duration: ${_formatDuration(videoDuration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Start: ${_formatDuration(startTime)}'),
            Slider(
              value: startTime.clamp(0.0, videoDuration),
              max: videoDuration,
              onChanged: (value) {
                if (value < endTime - 0.5) {
                  onStartTimeChanged(value);
                }
              },
            ),
            Text('End: ${_formatDuration(endTime)}'),
            Slider(
              value: endTime.clamp(0.0, videoDuration),
              max: videoDuration,
              onChanged: (value) {
                if (value > startTime + 0.5) {
                  onEndTimeChanged(value);
                }
              },
            ),
            Text(
              'Segment: ${_formatDuration(endTime - startTime)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
