import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Helper class for platform-specific theme adaptations.
///
/// Provides utilities to detect the current platform and return
/// appropriate design values for Apple (iOS/macOS) vs Android platforms,
/// following their respective Human Interface Guidelines and Material Design.
class PlatformThemeHelper {
  // Private constructor to prevent instantiation
  PlatformThemeHelper._();

  /// Returns true if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Returns true if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Returns true if running on Apple platforms (iOS or macOS)
  static bool get isApplePlatform => isIOS || isMacOS;

  /// Returns true if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Returns true if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Returns platform-appropriate font family.
  ///
  /// - iOS/macOS: Uses SF Pro system font
  /// - Android: Uses Roboto (system default)
  /// - Web: Uses system font stack with SF Pro priority
  /// - Other: Uses system default
  static String get platformFontFamily {
    if (kIsWeb) {
      return '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Roboto", system-ui';
    }
    if (isApplePlatform) {
      return '.SF Pro Display'; // iOS uses .SF notation for system fonts
    }
    if (isAndroid) {
      return 'Roboto';
    }
    return ''; // Use default system font for other platforms
  }

  /// Returns platform-appropriate font weight.
  ///
  /// Android typically uses bolder weights for prominence,
  /// while Apple platforms prefer lighter weights for refinement.
  static FontWeight getPlatformWeight({
    required FontWeight androidWeight,
    required FontWeight appleWeight,
  }) {
    return isAndroid ? androidWeight : appleWeight;
  }

  /// Returns platform-appropriate font size.
  ///
  /// Android Material Design uses larger type sizes for boldness,
  /// while Apple HIG uses more conservative sizes for refinement.
  static double getPlatformFontSize({
    required double androidSize,
    required double appleSize,
  }) {
    return isAndroid ? androidSize : appleSize;
  }

  /// Returns platform-appropriate elevation/shadow depth.
  ///
  /// Material Design uses more pronounced elevation (2-4dp),
  /// while Apple design uses minimal elevation (0-2pt).
  static double getPlatformElevation({
    required double androidElevation,
    required double appleElevation,
  }) {
    return isAndroid ? androidElevation : appleElevation;
  }

  /// Returns platform-appropriate border radius.
  ///
  /// Android uses larger, more dramatic radius (16-20pt),
  /// while Apple uses subtle radius (8-12pt).
  static double getPlatformRadius({
    required double androidRadius,
    required double appleRadius,
  }) {
    return isAndroid ? androidRadius : appleRadius;
  }

  /// Returns platform-appropriate letter spacing (tracking).
  ///
  /// Apple uses negative tracking for large text and positive for small text,
  /// while Android uses positive tracking throughout.
  static double getPlatformLetterSpacing({
    required double fontSize,
    required double androidSpacing,
    required double appleSpacing,
  }) {
    return isAndroid ? androidSpacing : appleSpacing;
  }

  /// Returns platform-appropriate line height.
  ///
  /// Both platforms have specific line height requirements based on text size.
  static double getPlatformLineHeight({
    required double androidHeight,
    required double appleHeight,
  }) {
    return isAndroid ? androidHeight : appleHeight;
  }

  /// Returns platform-appropriate animation duration.
  ///
  /// Material Design emphasizes more dramatic, longer animations,
  /// while Apple prefers quick, subtle animations.
  static Duration getPlatformAnimationDuration({
    required Duration androidDuration,
    required Duration appleDuration,
  }) {
    return isAndroid ? androidDuration : appleDuration;
  }

  /// Returns platform-appropriate shadow for the given level.
  ///
  /// Material Design uses stronger shadows with spread,
  /// while Apple uses subtle shadows without spread.
  static BoxShadow getPlatformShadow(BuildContext context, {int level = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isAndroid) {
      // Material Design shadows (more pronounced)
      return BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
        blurRadius: level * 3.0,
        offset: Offset(0, level * 2.0),
        spreadRadius: level > 2 ? 1.0 : 0.0,
      );
    } else {
      // Apple subtle shadows
      return BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
        blurRadius: level == 1 ? 3.0 : level == 2 ? 6.0 : 20.0,
        offset: Offset(0, level == 1 ? 1.0 : level == 2 ? 4.0 : 10.0),
      );
    }
  }

  /// Returns a list of platform-appropriate shadows.
  static List<BoxShadow> getPlatformShadows(BuildContext context,
      {int level = 1}) {
    return [getPlatformShadow(context, level: level)];
  }

  /// Returns platform-appropriate border radius for a given base radius.
  ///
  /// Automatically scales radius based on platform conventions:
  /// - Android: Uses larger, more dramatic radius
  /// - Apple: Uses subtle, refined radius
  static double getScaledPlatformRadius(
      {required double baseRadius, BuildContext? context}) {
    if (isAndroid) {
      // Android uses larger, more dramatic radius
      if (baseRadius <= 8.0) return 12.0;
      if (baseRadius <= 12.0) return 16.0;
      return 20.0;
    } else {
      // Apple uses subtle radius
      if (baseRadius <= 8.0) return 8.0;
      if (baseRadius <= 10.0) return 10.0;
      if (baseRadius <= 12.0) return 12.0;
      return 16.0;
    }
  }
}
