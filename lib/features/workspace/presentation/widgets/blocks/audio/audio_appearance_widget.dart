import 'package:flutter/material.dart';

/// A widget that provides appearance controls for audio blocks.
///
/// This widget allows users to customize:
/// - Width of the audio block (200-500)
/// - Height of the audio block (180-300)
///
/// The widget uses sliders for intuitive adjustment of dimensions.
///
/// Example usage:
/// ```dart
/// AudioAppearanceWidget(
///   width: 300,
///   height: 200,
///   onWidthChanged: (value) => updateWidth(value),
///   onHeightChanged: (value) => updateHeight(value),
/// )
/// ```
class AudioAppearanceWidget extends StatelessWidget {
  /// Current width value (null means default)
  final double? width;

  /// Current height value (null means default)
  final double? height;

  /// Callback when width is changed
  final ValueChanged<double> onWidthChanged;

  /// Callback when height is changed
  final ValueChanged<double> onHeightChanged;

  const AudioAppearanceWidget({
    required this.width,
    required this.height,
    required this.onWidthChanged,
    required this.onHeightChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Appearance',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Width slider
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Width: ${width?.toInt() ?? 'Default'}"),
                  Slider(
                    value: width ?? 300,
                    min: 200,
                    max: 500,
                    divisions: 8,
                    label: (width?.toInt() ?? 300).toString(),
                    onChanged: onWidthChanged,
                  ),
                ],
              ),
            ),
            // Height slider
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Height: ${height?.toInt() ?? 'Default'}"),
                  Slider(
                    value: height ?? 180,
                    min: 180,
                    max: 300,
                    divisions: 11,
                    label: (height?.toInt() ?? 180).toString(),
                    onChanged: onHeightChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
