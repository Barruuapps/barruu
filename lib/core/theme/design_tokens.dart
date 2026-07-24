import 'package:flutter/material.dart';

/// Design tokens for Barruu content-centric UI
/// Based on the comprehensive UI/UX design system

/// Color tokens - Monochrome black/white theme
class AppColors {
  AppColors._(); // Private constructor

  // Primary palette (Monochrome)
  static const primary = Color(0xFF000000); // Black
  static const secondary = Color(0xFF404040); // Dark gray
  static const tertiary = Color(0xFF757575); // Medium gray

  // Neutral palette
  static const background = Color(0xFFFFFFFF); // Pure white
  static const surface = Color(0xFFF5F5F5); // Very light gray
  static const textPrimary = Color(0xFF000000); // Black text
  static const textMuted = Color(0xFF757575); // Medium gray text
  static const border = Color(0xFFE0E0E0); // Light gray border

  // Semantic colors (kept minimal and desaturated)
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFF5D4037);
  static const error = Color(0xFFB00020);
  static const info = Color(0xFF424242);
}

/// Typography tokens
class AppTypography {
  AppTypography._(); // Private constructor

  // Font families
  static const String headingFont = 'System';
  static const String bodyFont = 'Georgia';
  static const String codeFont = 'JetBrainsMono';

  // Font sizes
  static const double displayLarge = 34.0;
  static const double displayMedium = 28.0;
  static const double displaySmall = 22.0;
  static const double headlineLarge = 20.0;
  static const double headlineMedium = 17.0;
  static const double bodyLarge = 19.0;
  static const double bodyMedium = 15.0;
  static const double bodySmall = 13.0;
  static const double label = 12.0;

  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  /// Build text theme with design tokens
  static TextTheme buildTextTheme(Color textColor) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: displayLarge,
        height: 48 / displayLarge,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: displayMedium,
        height: 36 / displayMedium,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: displaySmall,
        height: 28 / displaySmall,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: headlineLarge,
        height: 28 / headlineLarge,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: headlineMedium,
        height: 24 / headlineMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),

      // Body styles - IMPORTANT: Use serif for article reading
      bodyLarge: const TextStyle(
        fontFamily: bodyFont,
        fontSize: bodyLarge,
        height: lineHeightRelaxed, // Optimal reading line-height
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: bodyMedium,
        height: 24 / bodyMedium,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: bodySmall,
        height: 20 / bodySmall,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: label,
        height: 16 / label,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}

/// Spacing tokens based on 4pt grid
class AppSpacing {
  AppSpacing._(); // Private constructor

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Convenience methods
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
}

/// Border radius tokens
class AppBorders {
  AppBorders._(); // Private constructor

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusFull = 9999.0;

  static BorderRadius get small => BorderRadius.circular(radiusSmall);
  static BorderRadius get medium => BorderRadius.circular(radiusMedium);
  static BorderRadius get large => BorderRadius.circular(radiusLarge);
  static BorderRadius get xLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get circular => BorderRadius.circular(radiusFull);
}

/// Shadow tokens
class AppShadows {
  AppShadows._(); // Private constructor

  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Animation duration tokens
class AppDurations {
  AppDurations._(); // Private constructor

  static const Duration micro = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 400);
}
