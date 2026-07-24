/// Common animation durations used throughout the application.
///
/// Using consistent animation durations helps maintain a cohesive user experience
/// and makes it easier to adjust timing globally if needed.
class AnimationDurations {
  // Private constructor to prevent instantiation
  AnimationDurations._();

  /// Standard duration for quick UI transitions (e.g., toolbar fade in/out)
  static const Duration fast = Duration(milliseconds: 200);

  /// Standard duration for medium-speed animations (e.g., page transitions)
  static const Duration medium = Duration(milliseconds: 300);

  /// Standard duration for slower, more deliberate animations
  static const Duration slow = Duration(milliseconds: 500);

  /// Duration for search debouncing and other user input debouncing
  static const Duration debounce = Duration(milliseconds: 250);

  /// Duration for save operations debouncing
  static const Duration saveDebounce = Duration(milliseconds: 500);
}

/// Common padding and spacing values used throughout the application.
class Spacing {
  // Private constructor to prevent instantiation
  Spacing._();

  /// Extra small spacing (4px)
  static const double xs = 4.0;

  /// Small spacing (8px)
  static const double sm = 8.0;

  /// Medium spacing (12px)
  static const double md = 12.0;

  /// Large spacing (16px)
  static const double lg = 16.0;

  /// Extra large spacing (24px)
  static const double xl = 24.0;

  /// Extra extra large spacing (32px)
  static const double xxl = 32.0;
}

/// Common border radius values used throughout the application.
class BorderRadii {
  // Private constructor to prevent instantiation
  BorderRadii._();

  /// Small border radius (4px)
  static const double sm = 4.0;

  /// Medium border radius (8px)
  static const double md = 8.0;

  /// Large border radius (12px)
  static const double lg = 12.0;

  /// Extra large border radius (16px)
  static const double xl = 16.0;

  /// Extra extra large border radius (20px)
  static const double xxl = 20.0;
}

/// Breakpoints for responsive design.
class Breakpoints {
  // Private constructor to prevent instantiation
  Breakpoints._();

  /// Small screen breakpoint (phones in portrait)
  static const double sm = 360.0;

  /// Medium screen breakpoint (tablets in portrait, phones in landscape)
  static const double md = 600.0;

  /// Large screen breakpoint (tablets in landscape, small desktops)
  static const double lg = 900.0;

  /// Extra large screen breakpoint (desktops)
  static const double xl = 1200.0;

  /// Extra extra large screen breakpoint (large desktops)
  static const double xxl = 1536.0;
}

/// Common opacity values for consistent UI.
class OpacityValues {
  // Private constructor to prevent instantiation
  OpacityValues._();

  /// Disabled state opacity
  static const double disabled = 0.38;

  /// Secondary content opacity
  static const double secondary = 0.60;

  /// Medium opacity for overlays
  static const double medium = 0.70;

  /// High opacity for semi-transparent elements
  static const double high = 0.87;

  /// Full opacity
  static const double full = 1.0;
}
