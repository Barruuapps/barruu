import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';

/// A widget that lazy loads its child only when it becomes visible in the viewport.
/// This helps optimize memory usage and performance by deferring resource-intensive
/// widget builds until they're actually needed.
///
/// Features:
/// - Visibility detection using RenderObject
/// - Configurable visibility threshold
/// - Placeholder widget while not visible
/// - Automatic resource management
///
/// Usage:
/// ```dart
/// LazyLoadWidget(
///   builder: (context) => ExpensiveWidget(),
///   placeholder: LoadingPlaceholder(),
/// )
/// ```
class LazyLoadWidget extends StatefulWidget {
  /// Builder function that creates the actual content widget.
  /// This is only called once when the widget becomes visible.
  final Widget Function(BuildContext context) builder;

  /// Placeholder widget shown while the content is not yet loaded.
  /// Defaults to an empty SizedBox if not provided.
  final Widget? placeholder;

  /// The fraction of the widget that must be visible before loading.
  /// Value between 0.0 and 1.0, where:
  /// - 0.0 means load as soon as any pixel is visible
  /// - 0.5 means load when 50% of the widget is visible
  /// - 1.0 means load only when fully visible
  ///
  /// Default is 0.1 (load when 10% visible).
  final double visibilityThreshold;

  /// Whether to keep the widget loaded once it has been built.
  /// If true (default), the widget stays loaded even after scrolling out of view.
  /// If false, it will be unloaded when scrolled out of view.
  final bool keepAlive;

  const LazyLoadWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.visibilityThreshold = 0.1,
    this.keepAlive = true,
  }) : assert(
         visibilityThreshold >= 0.0 && visibilityThreshold <= 1.0,
         'visibilityThreshold must be between 0.0 and 1.0',
       );

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isVisible = false;
  bool _hasBuilt = false;

  @override
  void initState() {
    super.initState();
    // Schedule visibility check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibilityOnce();
    });
  }

  /// Check visibility once initially. If not in scrollable, mark as visible.
  void _checkVisibilityOnce() {
    if (!mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) {
      return;
    }

    try {
      RenderAbstractViewport.of(renderObject);
    } catch (e) {
      // Not in a scrollable viewport (RenderAbstractViewport.of throws AssertionError/FlutterError)
      // Assume visible since we can't check viewport
      if (e is AssertionError || e is FlutterError) {
        setState(() {
          _isVisible = true;
        });
        return;
      } else {
        rethrow;
      }
    }

    // If we get here, we're in a scrollable, perform normal visibility check
    _checkVisibility();
  }

  @override
  void didUpdateWidget(LazyLoadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recheck visibility when widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) {
      return;
    }

    try {
      final viewport = RenderAbstractViewport.of(renderObject);

      // Get the widget's position and size
      final size = renderObject.size;
      final viewportHeight = viewport.paintBounds.height;

      // Calculate reveal offsets for top and bottom of widget
      // The reveal offset indicates how much we need to scroll to bring that point into view
      // Negative means scroll up, positive means scroll down, 0 means it's visible
      final topReveal = viewport.getOffsetToReveal(renderObject, 0.0);
      final bottomReveal = viewport.getOffsetToReveal(renderObject, 1.0);

      // A widget is visible if the reveal offset is near zero (within viewport)
      // The reveal offset indicates how far we'd need to scroll to bring that edge into view
      // When offset is negative, the edge is above the viewport (need to scroll up)
      // When offset is positive, the edge is below the viewport (need to scroll down)
      // When offset is 0, the edge is at the top of the viewport
      final topOffset = topReveal.offset;
      final bottomOffset = bottomReveal.offset;

      // Widget is visible if either edge is within the viewport bounds
      // We check if offset is between -viewportHeight and 0:
      // - Top edge visible: between -viewportHeight and 0 (below viewport top, above viewport bottom)
      // - Bottom edge visible: between -viewportHeight and 0 (same range)
      final topEdgeVisible = topOffset >= -viewportHeight && topOffset <= 0;
      final bottomEdgeVisible =
          bottomOffset >= -viewportHeight && bottomOffset <= 0;

      // Widget is visible if any part of it is in the viewport
      final isInViewport = topEdgeVisible || bottomEdgeVisible;

      if (isInViewport != _isVisible) {
        setState(() {
          _isVisible = isInViewport;
        });
      }
    } catch (e) {
      // Not in a scrollable viewport (RenderAbstractViewport.of throws AssertionError/FlutterError)
      // Assume visible to be safe
      if ((e is AssertionError || e is FlutterError) && !_isVisible) {
        setState(() {
          _isVisible = true;
        });
      } else {
        // Rethrow unexpected exceptions
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the widget if:
    // 1. Currently visible
    // 2. keepAlive is true and has been built before
    final shouldBuild = _isVisible || (widget.keepAlive && _hasBuilt);

    if (shouldBuild) {
      _hasBuilt = true;
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Check visibility on scroll
          if (!widget.keepAlive) {
            _checkVisibility();
          }
          return false;
        },
        child: widget.builder(context),
      );
    }

    // Show placeholder while not visible
    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// A widget that provides a smooth loading experience for lazy-loaded content.
/// Shows a shimmer effect or simple placeholder while content loads.
class LazyLoadPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showShimmer;
  final Color? backgroundColor;

  const LazyLoadPlaceholder({
    super.key,
    this.width,
    this.height,
    this.showShimmer = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    if (!showShimmer) {
      return Container(width: width, height: height, color: color);
    }

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
