import 'package:flutter/material.dart';

/// Widget for controlling video size (width and height percentages).
///
/// Provides sliders for:
/// - Width percentage (50% - 100%)
/// - Height percentage (20% - 60%)
///
/// Example:
/// ```dart
/// VideoSizingControls(
///   widthPercent: 0.95,
///   heightPercent: 0.4,
///   onWidthChanged: (value) => updateWidth(value),
///   onHeightChanged: (value) => updateHeight(value),
/// )
/// ```
class VideoSizingControls extends StatelessWidget {
  final double widthPercent;
  final double heightPercent;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;

  const VideoSizingControls({
    required this.widthPercent,
    required this.heightPercent,
    required this.onWidthChanged,
    required this.onHeightChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Width slider
          Row(
            children: [
              const SizedBox(width: 50, child: Text('Width')),
              Expanded(
                child: Slider(
                  value: widthPercent * 100,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '${(widthPercent * 100).round()}%',
                  onChanged: (value) => onWidthChanged(value / 100),
                ),
              ),
              SizedBox(
                width: 45,
                child: Text('${(widthPercent * 100).round()}%'),
              ),
            ],
          ),
          // Height slider
          Row(
            children: [
              const SizedBox(width: 50, child: Text('Height')),
              Expanded(
                child: Slider(
                  value: heightPercent * 100,
                  min: 20,
                  max: 60,
                  divisions: 8,
                  label: '${(heightPercent * 100).round()}%',
                  onChanged: (value) => onHeightChanged(value / 100),
                ),
              ),
              SizedBox(
                width: 45,
                child: Text('${(heightPercent * 100).round()}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
