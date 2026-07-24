import 'package:flutter/material.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';

/// Utility class for responsive design across mobile, tablet, and desktop platforms.
/// 
/// This class provides helpers to determine the current device type and adapt
/// UI elements accordingly for optimal user experience on all platforms.
/// 
/// Now includes platform-specific design helpers for Apple (iOS/macOS) and 
/// Android Material Design following their respective design guidelines.
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();

  // MARK: - Apple Design System Spacing Constants (8pt Grid)
  
  /// 2pt spacing - Minimal gap
  static const double spacing2 = 2.0;
  
  /// 4pt spacing - Tiny gap
  static const double spacing4 = 4.0;
  
  /// 8pt spacing - Small gap, base unit
  static const double spacing8 = 8.0;
  
  /// 12pt spacing - Medium-small gap
  static const double spacing12 = 12.0;
  
  /// 16pt spacing - Standard gap (minimum edge padding for Apple HIG)
  static const double spacing16 = 16.0;
  
  /// 20pt spacing - Medium gap
  static const double spacing20 = 20.0;
  
  /// 24pt spacing - Large gap
  static const double spacing24 = 24.0;
  
  /// 32pt spacing - Extra large gap
  static const double spacing32 = 32.0;
  
  /// 44pt - Apple minimum touch target size (iOS/macOS)
  static const double minTouchTargetApple = 44.0;
  
  /// 48dp - Material minimum touch target size (Android)
  static const double minTouchTargetMaterial = 48.0;

  /// Breakpoint for small devices (phones)
  static const double mobileBreakpoint = 600.0;
  
  /// Breakpoint for medium devices (tablets)
  static const double tabletBreakpoint = 900.0;
  
  /// Breakpoint for large devices (small desktops)
  static const double desktopBreakpoint = 1200.0;
  
  /// Breakpoint for extra large devices (large desktops)
  static const double largeDesktopBreakpoint = 1536.0;

  /// Returns true if the current screen width is mobile-sized (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Returns true if the current screen width is tablet-sized (600px - 900px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if the current screen width is small desktop-sized (900px - 1200px)
  static bool isSmallDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Returns true if the current screen width is desktop-sized (>= 900px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Returns true if the current screen width is large desktop-sized (>= 1200px)
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Returns true if the current screen width is extra large desktop-sized (>= 1536px)
  static bool isExtraLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  /// Returns the appropriate number of grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return 4;
    if (width >= desktopBreakpoint) return 3;
    if (width >= tabletBreakpoint) return 2;
    if (width >= mobileBreakpoint) return 2;
    return 1;
  }

  /// Returns the appropriate horizontal padding based on screen width
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return 48.0;
    if (width >= desktopBreakpoint) return 32.0;
    if (width >= tabletBreakpoint) return 20.0;
    if (width >= mobileBreakpoint) return 8.0;
    return 8.0;
  }

  /// Returns the appropriate content max width to prevent content from being too wide on large screens
  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return 1400.0;
    if (width >= desktopBreakpoint) return 1200.0;
    if (width >= tabletBreakpoint) return 1000.0;
    return double.infinity;
  }

  /// Returns the appropriate dialog width based on screen size
  static double getDialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 500.0;
    if (width >= tabletBreakpoint) return 450.0;
    return width * 0.9;
  }

  /// Returns the appropriate spacing between grid items based on screen width
  static double getGridSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 24.0;
    if (width >= tabletBreakpoint) return 20.0;
    return 16.0;
  }

  /// Returns the appropriate sidebar width for desktop layouts
  static double getSidebarWidth(BuildContext context) {
    if (isLargeDesktop(context)) return 120.0;
    if (isDesktop(context)) return 100.0;
    return 80.0;
  }

  /// Returns the appropriate card aspect ratio based on screen size
  static double getCardAspectRatio(BuildContext context) {
    if (isLargeDesktop(context)) return 0.9;
    if (isDesktop(context)) return 0.85;
    if (isTablet(context)) return 0.8;
    return 1.3;
  }

  /// Returns the appropriate icon size based on screen size
  /// Mobile icons are now larger for better visibility and touch targets
  static double getIconSize(BuildContext context, {double baseSize = 24.0}) {
    if (isLargeDesktop(context)) return baseSize * 1.3;
    if (isDesktop(context)) return baseSize * 1.15;
    if (isMobile(context)) return baseSize * 1.1; // Increased from 0.9 to 1.1 for better mobile visibility
    return baseSize;
  }
  
  /// Returns whether to use compact layout (useful for mobile)
  static bool useCompactLayout(BuildContext context) {
    return isMobile(context);
  }

  /// Centers content on large screens with appropriate max width
  static Widget centerContent(BuildContext context, Widget child) {
    final maxWidth = getContentMaxWidth(context);
    if (maxWidth == double.infinity) {
      return child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Returns the appropriate text size multiplier for desktop
  static double getTextSizeMultiplier(BuildContext context) {
    if (isLargeDesktop(context)) return 1.12;
    if (isDesktop(context)) return 1.06;
    return 1.0;
  }

  /// Returns the appropriate border radius for components
  static double getBorderRadius(BuildContext context, {double baseRadius = 12.0}) {
    if (isLargeDesktop(context)) return baseRadius * 1.2;
    if (isDesktop(context)) return baseRadius * 1.1;
    return baseRadius;
  }

  /// Returns the appropriate elevation for cards and surfaces
  static double getElevation(BuildContext context, {double baseElevation = 2.0}) {
    if (isLargeDesktop(context)) return baseElevation * 1.5;
    if (isDesktop(context)) return baseElevation * 1.2;
    return baseElevation;
  }

  /// Returns the appropriate line height for text based on screen size
  static double getLineHeight(BuildContext context, {double baseHeight = 1.6}) {
    if (isLargeDesktop(context)) return baseHeight * 1.1;
    if (isDesktop(context)) return baseHeight * 1.05;
    return baseHeight;
  }

  /// Returns the appropriate letter spacing for text based on screen size
  static double getLetterSpacing(BuildContext context, {double baseSpacing = 0.2}) {
    if (isLargeDesktop(context)) return baseSpacing * 1.2;
    if (isDesktop(context)) return baseSpacing * 1.1;
    return baseSpacing;
  }

  /// Returns the appropriate vertical spacing between blocks
  static double getBlockSpacing(BuildContext context) {
    if (isLargeDesktop(context)) return 12.0;
    if (isDesktop(context)) return 10.0;
    return 12.0;
  }

  /// Returns the appropriate maximum width for reading content
  static double getReadingMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return 900.0;
    if (width >= desktopBreakpoint) return 800.0;
    if (width >= tabletBreakpoint) return 700.0;
    return double.infinity;
  }

  /// Returns the appropriate card elevation for hovering state
  static double getHoverElevation(BuildContext context) {
    if (isLargeDesktop(context)) return 16.0;
    if (isDesktop(context)) return 12.0;
    return 8.0;
  }

  /// Returns minimum comfortable width for cards on desktop
  static double getCardMinWidth(BuildContext context) {
    if (isLargeDesktop(context)) return 320.0;
    if (isDesktop(context)) return 280.0;
    return 240.0;
  }

  /// Returns maximum comfortable width for cards on desktop
  static double getCardMaxWidth(BuildContext context) {
    if (isLargeDesktop(context)) return 420.0;
    if (isDesktop(context)) return 380.0;
    return 340.0;
  }

  // MARK: - Platform-Specific Design Helpers

  /// Returns platform-appropriate shadow for the given elevation level.
  ///
  /// - Apple platforms: Subtle shadows (0.12 opacity, no spread)
  /// - Android/Material: Pronounced shadows (0.2 opacity, with spread)
  /// 
  /// [level] Shadow intensity (1-3):
  /// - 1: Small shadow (cards, chips)
  /// - 2: Medium shadow (FAB, navigation)
  /// - 3: Large shadow (dialogs, modals)
  static List<BoxShadow> getPlatformShadow(BuildContext context, {int level = 1}) {
    return PlatformThemeHelper.getPlatformShadows(context, level: level);
  }

  /// Ensures a widget meets the minimum touch target size for the platform.
  ///
  /// - Apple: 44pt minimum (iOS/macOS Human Interface Guidelines)
  /// - Android: 48dp minimum (Material Design Guidelines)
  /// 
  /// Returns a widget wrapped in ConstrainedBox with minimum dimensions.
  static Widget ensureTouchTarget(
    Widget child, {
    double? minWidth,
    double? minHeight,
  }) {
    final targetSize = PlatformThemeHelper.isAndroid 
        ? minTouchTargetMaterial 
        : minTouchTargetApple;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? targetSize,
        minHeight: minHeight ?? targetSize,
      ),
      child: child,
    );
  }

  /// Returns platform-appropriate border radius based on context.
  ///
  /// - Apple: Smaller, subtle radius (8-12pt)
  /// - Android: Larger, dramatic radius (12-20pt)
  static double getPlatformRadius(BuildContext context, {double baseRadius = 12.0}) {
    return PlatformThemeHelper.getScaledPlatformRadius(
      baseRadius: baseRadius,
      context: context,
    );
  }

  /// Returns maximum reading width following Apple HIG.
  ///
  /// Apple recommends 672pt max for comfortable reading.
  /// Material Design is more flexible.
  static double getAppleReadingMaxWidth(BuildContext context) {
    return 672.0; // Apple HIG recommendation
  }

  /// Returns platform-appropriate animation duration.
  ///
  /// - Apple: Quick, subtle (200ms standard, 300ms complex)
  /// - Android: More dramatic (300ms standard, 500-700ms emphasized)
  static Duration getPlatformAnimationDuration({
    bool isComplex = false,
  }) {
    if (PlatformThemeHelper.isAndroid) {
      return isComplex 
          ? const Duration(milliseconds: 500) 
          : const Duration(milliseconds: 300);
    } else {
      // Apple platforms
      return isComplex 
          ? const Duration(milliseconds: 300) 
          : const Duration(milliseconds: 200);
    }
  }

  /// Returns platform-appropriate hover scale factor.
  ///
  /// - Apple: Very subtle (1.01)
  /// - Android: More noticeable (1.02-1.03)
  static double getPlatformHoverScale() {
    return PlatformThemeHelper.isAndroid ? 1.02 : 1.01;
  }

  /// Returns platform-appropriate elevation value.
  ///
  /// - Apple: Minimal (0-2pt)
  /// - Android/Material: Pronounced (2-4dp for cards, up to 12dp for FAB)
  static double getPlatformElevation({
    required double materialElevation,
    required double appleElevation,
  }) {
    return PlatformThemeHelper.getPlatformElevation(
      androidElevation: materialElevation,
      appleElevation: appleElevation,
    );
  }

  /// Returns platform-appropriate card elevation.
  ///
  /// - Apple: 1pt (subtle shadow)
  /// - Android: 4dp (Material Design card elevation)
  static double getCardElevation() {
    return PlatformThemeHelper.isAndroid ? 4.0 : 1.0;
  }

  /// Returns platform-appropriate border width.
  ///
  /// - Apple: 0.5-1pt (refined, subtle)
  /// - Android: 1-2dp (more visible)
  static double getPlatformBorderWidth({bool isEmphasized = false}) {
    if (PlatformThemeHelper.isAndroid) {
      return isEmphasized ? 2.0 : 1.0;
    } else {
      return isEmphasized ? 1.0 : 0.5;
    }
  }
}
