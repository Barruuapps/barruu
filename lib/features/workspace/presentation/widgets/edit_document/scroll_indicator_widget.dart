import 'package:flutter/material.dart';

/// A custom scroll indicator widget that shows scroll progress.
///
/// This widget displays a vertical scroll indicator that fades in when
/// scrolling and shows the current scroll position within the content.
///
/// The indicator is styled with the theme's primary color and includes
/// a subtle shadow effect.
class ScrollIndicatorWidget extends StatelessWidget {
  /// The current scroll progress as a value between 0.0 and 1.0.
  final double scrollProgress;

  /// The opacity animation for fading the indicator in and out.
  final Animation<double> opacityAnimation;

  /// Creates a scroll indicator widget.
  ///
  /// [scrollProgress] should be a value between 0.0 (top) and 1.0 (bottom).
  /// [opacityAnimation] controls when the indicator is visible.
  const ScrollIndicatorWidget({
    super.key,
    required this.scrollProgress,
    required this.opacityAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight - 80; // Approx safe area
        const thumbHeight = 40.0;
        final trackHeight = availableHeight - thumbHeight;
        final topOffset = scrollProgress * trackHeight;

        return FadeTransition(
          opacity: opacityAnimation,
          child: Container(
            width: 8,
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Completely transparent background - no background container
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  top: topOffset.clamp(0.0, trackHeight),
                  child: Container(
                    width: 8,
                    height: thumbHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
