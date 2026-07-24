import 'package:flutter/material.dart';

/// Helper class for managing scroll-related functionality.
///
/// This class provides utilities for setting up scroll listeners,
/// tracking scroll progress, and managing scroll indicator animations.
/// It encapsulates common scroll handling patterns used in document
/// editing interfaces.
class ScrollHelper {
  /// Sets up scroll listeners on a scroll controller.
  ///
  /// This method adds two listeners:
  /// 1. One for updating scroll progress
  /// 2. One for toggling the scroll indicator visibility
  ///
  /// [scrollController] is the controller to add listeners to.
  /// [onScrollProgressUpdate] callback invoked when scroll position changes.
  /// [onScrollIndicatorToggle] callback invoked when scrolling starts/stops.
  static void setupScrollListeners({
    required ScrollController scrollController,
    required VoidCallback onScrollProgressUpdate,
    required VoidCallback onScrollIndicatorToggle,
  }) {
    scrollController.addListener(onScrollProgressUpdate);
    scrollController.addListener(onScrollIndicatorToggle);
  }

  /// Removes scroll listeners from a scroll controller.
  ///
  /// This method should be called during disposal to prevent memory leaks.
  ///
  /// [scrollController] is the controller to remove listeners from.
  /// [onScrollProgressUpdate] the progress update callback to remove.
  /// [onScrollIndicatorToggle] the toggle callback to remove.
  static void removeScrollListeners({
    required ScrollController scrollController,
    required VoidCallback onScrollProgressUpdate,
    required VoidCallback onScrollIndicatorToggle,
  }) {
    scrollController.removeListener(onScrollProgressUpdate);
    scrollController.removeListener(onScrollIndicatorToggle);
  }

  /// Calculates the current scroll progress as a value between 0.0 and 1.0.
  ///
  /// [scrollController] is the controller to read position from.
  ///
  /// Returns a value between 0.0 (top) and 1.0 (bottom), or 0.0 if
  /// the controller has no clients.
  static double calculateScrollProgress(ScrollController scrollController) {
    if (!scrollController.hasClients) return 0.0;

    final position = scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    return maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
  }

  /// Determines whether the scroll indicator should be visible.
  ///
  /// The indicator should be visible when the user is actively scrolling.
  ///
  /// [scrollController] is the controller to check scrolling state.
  ///
  /// Returns true if currently scrolling, false otherwise.
  static bool shouldShowScrollIndicator(ScrollController scrollController) {
    if (!scrollController.hasClients) return false;
    return scrollController.position.isScrollingNotifier.value;
  }

  /// Creates an animation controller for scroll indicator fade in/out.
  ///
  /// [vsync] is the ticker provider for the animation.
  ///
  /// Returns a configured animation controller with standard duration.
  static AnimationController createScrollIndicatorController({
    required TickerProvider vsync,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Creates an opacity animation for scroll indicator fade in/out.
  ///
  /// [controller] is the animation controller driving the animation.
  ///
  /// Returns an animation that interpolates from 0.0 to 1.0 opacity.
  static Animation<double> createScrollIndicatorOpacityAnimation({
    required AnimationController controller,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }
}
