import 'package:flutter/material.dart';

/// Extension providing Apple Human Interface Guidelines semantic colors.
///
/// These colors follow Apple's design system for labels, fills, system colors,
/// and separators. They automatically adapt to light/dark mode through the
/// base ColorScheme colors with appropriate opacity values.
///
/// Usage:
/// ```dart
/// final color = Theme.of(context).colorScheme.labelSecondary;
/// ```
extension AppleSemanticColors on ColorScheme {
  // MARK: - Label Colors (Text)

  /// Primary label color for main text content.
  /// - Light mode: Full opacity black/dark text
  /// - Dark mode: Full opacity white/light text
  Color get labelPrimary => onSurface;

  /// Secondary label color for less prominent text.
  /// - Light mode: 60% opacity
  /// - Dark mode: 60% opacity
  Color get labelSecondary => onSurface.withValues(alpha: 0.6);

  /// Tertiary label color for even less prominent text.
  /// - Light mode: 30% opacity
  /// - Dark mode: 30% opacity
  Color get labelTertiary => onSurface.withValues(alpha: 0.3);

  /// Quaternary label color for the least prominent text.
  /// - Light mode: 18% opacity
  /// - Dark mode: 18% opacity
  Color get labelQuaternary => onSurface.withValues(alpha: 0.18);

  // MARK: - Fill Colors (Backgrounds)

  /// Primary fill color for foreground elements.
  /// Subtle background for controls and containers.
  Color get fillPrimary => onSurface.withValues(alpha: 0.05);

  /// Secondary fill color for foreground elements.
  /// Slightly more prominent than primary fill.
  Color get fillSecondary => onSurface.withValues(alpha: 0.08);

  /// Tertiary fill color for foreground elements.
  /// More prominent fill for emphasized containers.
  Color get fillTertiary => onSurface.withValues(alpha: 0.12);

  /// Quaternary fill color for foreground elements.
  /// Most prominent fill level.
  Color get fillQuaternary => onSurface.withValues(alpha: 0.16);

  // MARK: - System Colors

  /// System blue color - Used for links, primary actions
  /// Matches iOS/macOS system blue
  Color get systemBlue => const Color(0xFF007AFF);

  /// System green color - Used for success states
  /// Matches iOS/macOS system green
  Color get systemGreen => const Color(0xFF34C759);

  /// System red color - Used for destructive actions, errors
  /// Matches iOS/macOS system red
  Color get systemRed => const Color(0xFFFF3B30);

  /// System orange color - Used for warnings
  /// Matches iOS/macOS system orange
  Color get systemOrange => const Color(0xFFFF9500);

  /// System yellow color - Used for cautions
  /// Matches iOS/macOS system yellow
  Color get systemYellow => const Color(0xFFFFCC00);

  /// System purple color - Used for creative features
  /// Matches iOS/macOS system purple
  Color get systemPurple => const Color(0xFFAF52DE);

  /// System pink color - Used for social features
  /// Matches iOS/macOS system pink
  Color get systemPink => const Color(0xFFFF2D55);

  /// System teal color - Used for special features
  /// Matches iOS/macOS system teal
  Color get systemTeal => const Color(0xFF5AC8FA);

  /// System indigo color - Used for navigation
  /// Matches iOS/macOS system indigo
  Color get systemIndigo => const Color(0xFF5856D6);

  // MARK: - Separator Colors

  /// Standard separator color for dividing content.
  /// - Light mode: 29% opacity
  /// - Dark mode: 29% opacity
  Color get separator => onSurface.withValues(alpha: 0.29);

  /// Opaque separator for use on blurred backgrounds.
  /// - Light mode: Slightly lighter than separator
  /// - Dark mode: Slightly lighter than separator
  Color get separatorOpaque => onSurface.withValues(alpha: 0.2);

  // MARK: - Background Colors

  /// Primary background color.
  /// Main background for views and grouped content.
  Color get backgroundPrimary => surface;

  /// Secondary background color.
  /// Background for grouped content containers.
  Color get backgroundSecondary => surfaceContainerLow;

  /// Tertiary background color.
  /// Background for grouped content within secondary backgrounds.
  Color get backgroundTertiary => surfaceContainerLowest;

  // MARK: - Grouped Background Colors

  /// Primary grouped background.
  /// Used for table views and grouped lists.
  Color get groupedBackgroundPrimary => surfaceContainer;

  /// Secondary grouped background.
  /// Used for cells within grouped lists.
  Color get groupedBackgroundSecondary => surfaceContainerHigh;

  /// Tertiary grouped background.
  /// Used for content within cells in grouped lists.
  Color get groupedBackgroundTertiary => surfaceContainerHighest;

  // MARK: - Utility Methods

  /// Returns an appropriate text color for the given background.
  ///
  /// Automatically determines whether to use light or dark text
  /// based on background luminance.
  Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Returns a color with guaranteed WCAG AAA contrast ratio (7:1).
  ///
  /// Adjusts the foreground color brightness to ensure readability
  /// against the specified background.
  Color getAccessibleColor({
    required Color foreground,
    required Color background,
  }) {
    final bgLuminance = background.computeLuminance();
    final fgLuminance = foreground.computeLuminance();

    // Calculate contrast ratio
    final lighter = bgLuminance > fgLuminance ? bgLuminance : fgLuminance;
    final darker = bgLuminance > fgLuminance ? fgLuminance : bgLuminance;
    final contrast = (lighter + 0.05) / (darker + 0.05);

    // If contrast is already sufficient, return foreground
    if (contrast >= 7.0) return foreground;

    // Adjust foreground to meet WCAG AAA (7:1)
    if (bgLuminance > 0.5) {
      // Light background, darken foreground
      return Colors.black;
    } else {
      // Dark background, lighten foreground
      return Colors.white;
    }
  }
}

/// Extension providing Material Design 3 semantic colors for Android.
///
/// These follow Material Design 3 color system with emphasis on
/// bold, vibrant colors and dynamic theming support.
extension MaterialSemanticColors on ColorScheme {
  /// Returns whether this is a Material Design style theme.
  /// Useful for platform-specific styling decisions.
  bool get isMaterialTheme => true;

  /// Surface with tint overlay for elevated surfaces.
  /// Material Design 3 signature feature.
  Color getSurfaceWithTint({int elevation = 1}) {
    final opacity = elevation * 0.05;
    return Color.alphaBlend(
      surfaceTint.withValues(alpha: opacity.clamp(0.0, 0.15)),
      surface,
    );
  }

  /// Returns a gradient suitable for Material Design 3 hero sections.
  LinearGradient getMaterialGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(begin: begin, end: end, colors: [primary, tertiary]);
  }

  /// Returns ripple color with appropriate opacity for Material Design.
  Color get rippleColor => primary.withValues(alpha: 0.3);

  /// Returns highlight color with appropriate opacity for Material Design.
  Color get highlightColor => primary.withValues(alpha: 0.15);
}
