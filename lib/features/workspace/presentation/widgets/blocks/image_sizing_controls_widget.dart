import 'package:flutter/material.dart';

/// Widget for image sizing controls (width, height sliders and fit selector).
///
/// Displays sliders for adjusting width and height percentages,
/// and a segmented button for selecting the image fit mode.
///
/// Example:
/// ```dart
/// ImageSizingControlsWidget(
///   widthPercent: widthPercent ?? 0.9,
///   heightPercent: heightPercent ?? 0.4,
///   imageFit: imageFit,
///   onWidthChanged: (value) => updateWidth(value),
///   onHeightChanged: (value) => updateHeight(value),
///   onFitChanged: (fit) => updateFit(fit),
/// )
/// ```
class ImageSizingControlsWidget extends StatelessWidget {
  final double widthPercent;
  final double heightPercent;
  final BoxFit imageFit;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<BoxFit> onFitChanged;

  const ImageSizingControlsWidget({
    super.key,
    required this.widthPercent,
    required this.heightPercent,
    required this.imageFit,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onFitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Width percentage slider
          Row(
            children: [
              const SizedBox(width: 50, child: Text('Width')),
              Expanded(
                child: Slider(
                  value: widthPercent * 100,
                  min: 20,
                  max: 100,
                  divisions: 16,
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
          // Height percentage slider
          Row(
            children: [
              const SizedBox(width: 50, child: Text('Height')),
              Expanded(
                child: Slider(
                  value: heightPercent * 100,
                  min: 10,
                  max: 80,
                  divisions: 14,
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
          const SizedBox(height: 8),
          // Image fit selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Fit: '),
              const SizedBox(width: 8),
              SegmentedButton<BoxFit>(
                segments: const [
                  ButtonSegment(value: BoxFit.contain, label: Text('Contain')),
                  ButtonSegment(value: BoxFit.cover, label: Text('Cover')),
                  ButtonSegment(value: BoxFit.fill, label: Text('Fill')),
                ],
                selected: {imageFit},
                onSelectionChanged: (Set<BoxFit> newSelection) {
                  onFitChanged(newSelection.first);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
