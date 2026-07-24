import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:flutter/material.dart';

/// Available themes for the application, redefined for a modern, professional palette.
enum AppThemeType {
  professionalTeal, // PRIMARY BRAND THEME - Modern editorial, deep teal
  purpleCyan,
  softBeige,
  calmBlue,
  softGreen,
  warmDark,
  elegantDark,
  minimalWhite,
  sunsetGlow,
  oceanBreeze,
  royalIndigo,
  graphiteSteel, // Corporate, sleek, tech-forward
  coralReef, // Vibrant yet professional (fintech, creative tech)
  nordicFrost, // Clean, airy, premium minimalism
  emeraldSlate, // Luxury, finance, health tech (dark mode)
  amberNoir, // Dark amber luxury - premium, warm, exclusive
  // Social & Creative themes
  focusStudy, // Warm paper-like for deep concentration
  libraryClassic, // Sepia tones for book-like reading
  nightScholar, // Dark mode optimized for night reading
  freshMint, // Calming green for stress-free reading
}

/// Manages application themes, providing consistent styling across the app.
class AppTheme {
  // Private constructor to prevent instantiation.
  AppTheme._();

  /// Default icon styling for the application.
  static const _defaultIconTheme = IconThemeData(size: 24, weight: 400);

  /// Constructs a text theme with predefined typography styles.
  ///
  /// Implements platform-specific typography following:
  /// - Apple Human Interface Guidelines (iOS/macOS): SF Pro font, larger sizes, negative tracking, bolder weights
  /// - Material Design 3 (Android): Roboto font, larger bold sizes, positive tracking, bolder weights
  ///
  /// Updated to ensure text is more readable with increased sizes and weights across all devices.
  ///
  /// [textColor] The primary color for text elements.
  /// Returns a [TextTheme] with styles for various text categories.
  static TextTheme _buildTextTheme(Color textColor) {
    // Get platform-specific font family
    final fontFamily = PlatformThemeHelper.platformFontFamily;
    final isAndroid = PlatformThemeHelper.isAndroid;

    return TextTheme(
      // Display styles - Used for hero text and major headings
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 48 : 40,
        fontWeight: FontWeight.w800, // Extra-Bold for main titles
        letterSpacing: isAndroid ? -0.25 : -0.4,
        height: isAndroid ? 1.12 : 1.15,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 38 : 34,
        fontWeight: FontWeight.w800, // Extra-Bold for main titles
        letterSpacing: isAndroid ? 0 : -0.36,
        height: isAndroid ? 1.16 : 1.2,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 32 : 28,
        fontWeight: FontWeight.w700, // Bold for headers
        letterSpacing: isAndroid ? 0 : -0.26,
        height: isAndroid ? 1.22 : 1.27,
        color: textColor,
      ),

      // Headline styles - For section headers
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 28 : 24,
        fontWeight: FontWeight.w700, // Bold for headers
        letterSpacing: isAndroid ? 0 : 0,
        height: isAndroid ? 1.25 : 1.25,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 24 : 21,
        fontWeight: FontWeight.w700, // Bold for headers
        letterSpacing: isAndroid ? 0 : -0.24,
        height: isAndroid ? 1.29 : 1.29,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 20 : 19,
        fontWeight: FontWeight.w700, // Bold for headers
        letterSpacing: isAndroid ? 0 : 0,
        height: isAndroid ? 1.33 : 1.33,
        color: textColor,
      ),

      // Title styles - For card titles, list items
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 20 : 20,
        fontWeight: FontWeight.w700, // Bold for titles
        letterSpacing: isAndroid ? 0 : -0.24,
        height: isAndroid ? 1.27 : 1.29,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 16 : 16,
        fontWeight: FontWeight.w600, // Semi-Bold for titles
        letterSpacing: isAndroid ? 0.15 : 0,
        height: isAndroid ? 1.5 : 1.5,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 14 : 15,
        fontWeight: FontWeight.w600, // Semi-Bold for titles
        letterSpacing: isAndroid ? 0.1 : 0,
        height: isAndroid ? 1.43 : 1.43,
        color: textColor,
      ),

      // Body styles - Main text content
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 16 : 17,
        fontWeight: FontWeight.w400, // Regular for body text
        letterSpacing: isAndroid ? 0.5 : -0.24,
        height: isAndroid ? 1.5 : 1.5,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 14 : 15,
        fontWeight: FontWeight.w400, // Regular for body text
        letterSpacing: isAndroid ? 0.25 : 0,
        height: isAndroid ? 1.43 : 1.43,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 12 : 13,
        fontWeight: FontWeight.w400, // Regular for small body text
        letterSpacing: isAndroid ? 0.4 : 0,
        height: isAndroid ? 1.33 : 1.33,
        color: textColor,
      ),

      // Label styles - Buttons, tabs, captions
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 14 : 14,
        fontWeight:
            FontWeight.w600, // Semi-Bold for buttons and interactive labels
        letterSpacing: isAndroid ? 0.1 : 0,
        height: isAndroid ? 1.43 : 1.43,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 12 : 12,
        fontWeight: FontWeight.w500, // Medium for captions
        letterSpacing: isAndroid ? 0.5 : 0,
        height: isAndroid ? 1.33 : 1.33,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: isAndroid ? 11 : 11,
        fontWeight: FontWeight.w500, // Medium for small labels
        letterSpacing: isAndroid ? 0.5 : 0.4,
        height: isAndroid ? 1.45 : 1.45,
        color: textColor,
      ),
    );
  }

  /// Builds a base theme with consistent styling for UI elements.
  static ThemeData _buildBaseTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    double cardElevation = 0, // Flat design - no shadows
    double appBarElevation = 0,
  }) {
    return ThemeData(
      // Removed fixed fontFamily
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,
      iconTheme: _defaultIconTheme.copyWith(color: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.primary, size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0, // Flat design - no elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Slightly rounder
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ), // Thicker border
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor:
            colorScheme.surfaceContainerHighest, // Subtle fill for contrast
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // Flat look is more modern
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        disabledColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary.withValues(alpha: 0.1),
        secondarySelectedColor: colorScheme.secondary.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: textTheme.bodySmall,
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => colorScheme.onPrimary,
        ),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.4);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface.withValues(alpha: 0.9),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        // Updated from DialogThemeData
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
        labelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  // ==================== PRIMARY BRAND THEME ====================

  /// Professional Teal - Primary brand theme for Barruu
  /// Modern editorial style with deep teal, authoritative and trustworthy
  /// Reflects the brand values of credibility, expertise, and professionalism
  static final professionalTeal = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0F766E), // Deep teal - trustworthy, professional
      secondary: Color(0xFF0891B2), // Bright teal accent
      onSecondary: Colors.white,
      tertiary: Color(0xFFD97706), // Amber accent for highlights
      onTertiary: Colors.white,
      surface: Color(0xFFFDFDFD), // Clean white
      onSurface: Color(0xFF1A2E2A), // Deep charcoal-teal for text
      surfaceContainerHighest: Color(0xFFF0FDFA), // Very light teal tint
      error: Color(0xFFDC2626),
      outline: Color(0xFF99F6E4),
      outlineVariant: Color(0xFFCCFBF1),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1A2E2A)),
  );

  // ==================== EXISTING MODERN THEMES (1-10) ====================

  /// Modern purple with vibrant accent - professional and energetic
  static final purpleCyan = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7C3AED), // Vibrant purple
      secondary: Color(0xFF06B6D4), // Cyan accent
      onSecondary: Colors.white,
      surface: Color(0xFFFDFDFD),
      onSurface: Color(0xFF1F2937),
      surfaceContainerHighest: Color(0xFFF5F3FF),
      error: Color(0xFFDC2626),
      outline: Color(0xFFD1D5DB),
      outlineVariant: Color(0xFFE5E7EB),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1F2937)),
  );

  /// Warm neutral theme - sophisticated and timeless
  static final softBeige = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFA16207), // Warm brown
      secondary: Color(0xFFEA580C), // Warm orange accent
      onSecondary: Colors.white,
      surface: Color(0xFFFFFDF7), // Soft cream
      onSurface: Color(0xFF292524),
      error: Color(0xFFDC2626),
      outline: Color(0xFFD6D3D1),
      outlineVariant: Color(0xFFE7E5E4),
      surfaceContainerHighest: Color(0xFFFEF3C7),
    ),
    textTheme: _buildTextTheme(const Color(0xFF292524)),
  );

  /// Fresh blue - clean and trustworthy
  static final calmBlue = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0284C7), // Vibrant sky blue
      secondary: Color(0xFF0EA5E9), // Bright blue accent
      onSecondary: Colors.white,
      surface: Color(0xFFFDFDFF),
      onSurface: Color(0xFF1E293B),
      error: Color(0xFFDC2626),
      outline: Color(0xFFBAE6FD),
      outlineVariant: Color(0xFFE0F2FE),
      surfaceContainerHighest: Color(0xFFF0F9FF),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1E293B)),
  );

  /// Natural green - balanced and calming
  static final softGreen = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF16A34A), // Vibrant green
      secondary: Color(0xFF10B981), // Emerald accent
      onSecondary: Colors.white,
      surface: Color(0xFFFDFFFD),
      onSurface: Color(0xFF1C2B23),
      error: Color(0xFFDC2626),
      outline: Color(0xFFBBF7D0),
      outlineVariant: Color(0xFFDCFCE7),
      surfaceContainerHighest: Color(0xFFF0FDF4),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1C2B23)),
  );

  /// Warm dark mode - rich and inviting
  static final warmDark = _buildBaseTheme(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFB923C), // Warm orange
      onPrimary: Color(0xFF18181B),
      secondary: Color(0xFFFBBF24), // Golden yellow
      onSecondary: Color(0xFF18181B),
      surface: Color(0xFF27241D), // Warm dark surface
      onSurface: Color(0xFFFAFAF9),
      error: Color(0xFFF87171),
      onError: Color(0xFF18181B),
      outline: Color(0xFF52443C),
      outlineVariant: Color(0xFF3A322C),
      surfaceContainerHighest: Color(0xFF332F28),
    ),
    textTheme: _buildTextTheme(const Color(0xFFFAFAF9)),
  );

  /// Premium dark mode - sleek and modern
  static final elegantDark = _buildBaseTheme(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFA78BFA), // Soft purple
      onPrimary: Color(0xFF1E1B4B),
      secondary: Color(0xFFC4B5FD), // Light lavender
      onSecondary: Color(0xFF1E1B4B),
      surface: Color(0xFF0F172A), // Deep navy
      onSurface: Color(0xFFF1F5F9),
      error: Color(0xFFF87171),
      onError: Color(0xFF1E1B4B),
      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF1E293B),
    ),
    textTheme: _buildTextTheme(const Color(0xFFF1F5F9)),
  );

  /// Minimal monochrome - ultra-professional
  static final minimalWhite = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF18181B), // Near black
      secondary: Color(0xFF52525B), // Neutral gray
      onSecondary: Colors.white,
      onSurface: Color(0xFF09090B),
      error: Color(0xFFDC2626),
      outline: Color(0xFFD4D4D8),
      outlineVariant: Color(0xFFE4E4E7),
      surfaceContainerHighest: Color(0xFFFAFAFA),
    ),
    textTheme: _buildTextTheme(const Color(0xFF09090B)),
  );

  /// Vibrant gradient-inspired theme - energetic and modern
  static final sunsetGlow = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFDB2777), // Hot pink
      secondary: Color(0xFFF59E0B), // Vibrant orange
      onSecondary: Colors.white,
      surface: Color(0xFFFFF7ED),
      onSurface: Color(0xFF1C1917),
      error: Color(0xFFDC2626),
      outline: Color(0xFFFED7AA),
      outlineVariant: Color(0xFFFFEDD5),
      surfaceContainerHighest: Color(0xFFFFEDD5),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1C1917)),
  );

  /// Serene teal - professional and refreshing
  static final oceanBreeze = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0F766E), // Deep teal
      secondary: Color(0xFF14B8A6), // Bright teal
      onSecondary: Colors.white,
      surface: Color(0xFFF0FDFA),
      onSurface: Color(0xFF134E4A),
      error: Color(0xFFDC2626),
      outline: Color(0xFF99F6E4),
      outlineVariant: Color(0xFFCCFBF1),
      surfaceContainerHighest: Color(0xFFCCFBF1),
    ),
    textTheme: _buildTextTheme(const Color(0xFF134E4A)),
  );

  /// Classic indigo - elegant and reliable
  static final royalIndigo = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4F46E5), // Modern indigo
      secondary: Color(0xFF818CF8), // Light indigo
      onSecondary: Colors.white,
      surface: Color(0xFFFAFAFF),
      onSurface: Color(0xFF1E1B4B),
      error: Color(0xFFDC2626),
      outline: Color(0xFFC7D2FE),
      outlineVariant: Color(0xFFE0E7FF),
      surfaceContainerHighest: Color(0xFFEEF2FF),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1E1B4B)),
  );

  // ==================== NEW MODERN PROFESSIONAL THEMES (11-15) ====================

  /// Professional graphite & steel - corporate, sleek, tech-forward
  static final graphiteSteel = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF334155), // Slate gray
      secondary: Color(0xFF64748B), // Steel blue-gray
      onSecondary: Colors.white,
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      error: Color(0xFFDC2626),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFFF1F5F9),
    ),
    textTheme: _buildTextTheme(const Color(0xFF0F172A)),
  );

  /// Modern coral & teal - vibrant yet professional (fintech, creative tech)
  static final coralReef = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFDC2626), // Soft red-coral
      secondary: Color(0xFF0891B2), // Rich teal
      onSecondary: Colors.white,
      surface: Color(0xFFFFFBFE),
      onSurface: Color(0xFF1E1B4B),
      error: Color(0xFFB91C1C),
      outline: Color(0xFFFCA5A5),
      outlineVariant: Color(0xFFFECACA),
      surfaceContainerHighest: Color(0xFFFFF1F1),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1E1B4B)),
  );

  /// Nordic-inspired cool minimalism - clean, airy, premium
  static final nordicFrost = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2C5282), // Nordic blue
      secondary: Color(0xFF7DD3FC), // Frost sky
      onSecondary: Color(0xFF0C4A6E),
      surface: Color(0xFFFBFDFF),
      onSurface: Color(0xFF1A202C),
      error: Color(0xFFDC2626),
      outline: Color(0xFFA5F3FC),
      outlineVariant: Color(0xFFE0F2FE),
      surfaceContainerHighest: Color(0xFFF0F9FF),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1A202C)),
  );

  /// Deep emerald with slate - luxury, finance, health tech (dark mode)
  static final emeraldSlate = _buildBaseTheme(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981), // Emerald
      onPrimary: Color(0xFF0F172A),
      secondary: Color(0xFF6EE7B7), // Light emerald
      onSecondary: Color(0xFF0F172A),
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFF1F5F9),
      error: Color(0xFFF87171),
      onError: Color(0xFF0F172A),
      outline: Color(0xFF1E293B),
      outlineVariant: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF1E293B),
    ),
    textTheme: _buildTextTheme(const Color(0xFFF1F5F9)),
  );

  /// Dark amber luxury - premium, warm, exclusive (banking, luxury apps)
  static final amberNoir = _buildBaseTheme(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF59E0B), // Rich amber
      onPrimary: Color(0xFF1A1A1A),
      secondary: Color(0xFFFCBCA8), // Soft peach
      onSecondary: Color(0xFF1A1A1A),
      surface: Color(0xFF17120E),
      onSurface: Color(0xFFFAFAF9),
      error: Color(0xFFF87171),
      onError: Color(0xFF1A1A1A),
      outline: Color(0xFF44403C),
      outlineVariant: Color(0xFF292524),
      surfaceContainerHighest: Color(0xFF292524),
    ),
    textTheme: _buildTextTheme(const Color(0xFFFAFAF9)),
  );

  // ==================== SOCIAL & CREATIVE THEMES (16-19) ====================

  /// Focus Study - warm paper-like for deep concentration
  /// Inspired by aged paper and warm reading lamps
  static final focusStudy = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B5A2B), // Warm sienna brown
      secondary: Color(0xFFD4A574), // Soft tan
      onSecondary: Color(0xFF3D2914),
      tertiary: Color(0xFF6B8E23), // Olive green for highlights
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE8F0D8),
      onTertiaryContainer: Color(0xFF2A3A10),
      surface: Color(0xFFFDF8F3), // Warm cream paper
      onSurface: Color(0xFF2C1810),
      surfaceContainerHighest: Color(0xFFF5EDE3), // Slightly darker cream
      error: Color(0xFFB74C4C),
      outline: Color(0xFFD4C4B0),
      outlineVariant: Color(0xFFE8DED0),
    ),
    textTheme: _buildTextTheme(const Color(0xFF2C1810)),
  );

  /// Library Classic - sepia tones for book-like reading experience
  /// Designed for comfortable long reading sessions
  static final libraryClassic = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF5D4037), // Deep library brown
      secondary: Color(0xFF8D6E63), // Warm taupe
      onSecondary: Colors.white,
      tertiary: Color(0xFF4A6741), // Muted forest green
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD7E8D3),
      onTertiaryContainer: Color(0xFF1A2A16),
      surface: Color(0xFFFAF6F0), // Antique paper white
      onSurface: Color(0xFF1C1610),
      surfaceContainerHighest: Color(0xFFF0E8DC), // Parchment
      error: Color(0xFFC62828),
      outline: Color(0xFFBCAA94),
      outlineVariant: Color(0xFFD4C8B8),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1C1610)),
  );

  /// Night Scholar - dark mode optimized for night reading
  /// Reduces eye strain during late-night reading sessions
  static final nightScholar = _buildBaseTheme(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF90CAF9), // Soft blue for focus
      onPrimary: Color(0xFF0D2137),
      secondary: Color(0xFFCE93D8), // Gentle lavender
      onSecondary: Color(0xFF2A1A30),
      tertiary: Color(0xFFA5D6A7), // Soft green for success
      onTertiary: Color(0xFF0D260F),
      tertiaryContainer: Color(0xFF1B3D1D),
      onTertiaryContainer: Color(0xFFA5D6A7),
      surface: Color(0xFF121820), // Deep navy-black
      onSurface: Color(0xFFE8EDF4), // Soft white for readability
      surfaceContainerHighest: Color(0xFF1E2832),
      error: Color(0xFFEF9A9A),
      onError: Color(0xFF3D1212),
      outline: Color(0xFF3A4A5A),
      outlineVariant: Color(0xFF2A3A4A),
    ),
    textTheme: _buildTextTheme(const Color(0xFFE8EDF4)),
  );

  /// Fresh Mint - calming green for stress-free reading
  /// Inspired by nature, promotes relaxation and focus
  static final freshMint = _buildBaseTheme(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2E7D6B), // Deep mint green
      secondary: Color(0xFF66BB9A), // Fresh mint
      onSecondary: Color(0xFF0A2820),
      tertiary: Color(0xFF4A9079), // Soft teal
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD8F3EC),
      onTertiaryContainer: Color(0xFF0A2820),
      surface: Color(0xFFF5FDFB), // Very light mint
      onSurface: Color(0xFF1A2C28),
      surfaceContainerHighest: Color(0xFFE8F8F4), // Light mint background
      error: Color(0xFFDC2626),
      outline: Color(0xFFB2D8CE),
      outlineVariant: Color(0xFFD4EDE6),
    ),
    textTheme: _buildTextTheme(const Color(0xFF1A2C28)),
  );

  // ==================== THEME MAP & ACCESSOR ====================

  static final Map<AppThemeType, ThemeData> _themes = {
    AppThemeType.professionalTeal: professionalTeal,
    AppThemeType.purpleCyan: purpleCyan,
    AppThemeType.softBeige: softBeige,
    AppThemeType.calmBlue: calmBlue,
    AppThemeType.softGreen: softGreen,
    AppThemeType.warmDark: warmDark,
    AppThemeType.elegantDark: elegantDark,
    AppThemeType.minimalWhite: minimalWhite,
    AppThemeType.sunsetGlow: sunsetGlow,
    AppThemeType.oceanBreeze: oceanBreeze,
    AppThemeType.royalIndigo: royalIndigo,
    AppThemeType.graphiteSteel: graphiteSteel,
    AppThemeType.coralReef: coralReef,
    AppThemeType.nordicFrost: nordicFrost,
    AppThemeType.emeraldSlate: emeraldSlate,
    AppThemeType.amberNoir: amberNoir,
    // Social & Creative themes
    AppThemeType.focusStudy: focusStudy,
    AppThemeType.libraryClassic: libraryClassic,
    AppThemeType.nightScholar: nightScholar,
    AppThemeType.freshMint: freshMint,
  };

  /// Retrieves a theme based on the specified [themeType].
  ///
  /// [themeType] The type of theme to retrieve.
  /// Returns the corresponding [ThemeData], falling back to [professionalTeal] if not found.
  static ThemeData getTheme(AppThemeType themeType) {
    final theme = _themes[themeType] ?? professionalTeal;
    if (themeType != AppThemeType.professionalTeal &&
        !_themes.containsKey(themeType)) {
      logger.w('Theme not found: $themeType, falling back to professionalTeal');
    }
    return theme;
  }

  // ==================== APP SYSTEM THEME (Light/Dark) ====================

  /// Gets a light theme for the app system level.
  /// Pure white/black monochrome — clean, professional, distraction-free.
  static ThemeData getAppLightTheme() {
    return _buildBaseTheme(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000), // Black — primary actions & accents
        onPrimary: Color(0xFFFFFFFF), // White text on black
        primaryContainer: Color(0xFFF5F5F5), // Very light gray container
        onPrimaryContainer: Color(0xFF000000),
        secondary: Color(0xFF404040), // Dark gray — secondary actions
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFF0F0F0),
        onSecondaryContainer: Color(0xFF1A1A1A),
        surface: Color(0xFFFFFFFF), // Pure white surface
        onSurface: Color(0xFF000000), // Pure black text
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF9F9F9),
        surfaceContainer: Color(0xFFF5F5F5),
        surfaceContainerHigh: Color(0xFFEEEEEE),
        surfaceContainerHighest: Color(0xFFE8E8E8),
        outline: Color(0xFFBDBDBD), // Medium gray outlines
        outlineVariant: Color(0xFFE0E0E0), // Light gray dividers
        error: Color(0xFFB00020),
        onError: Color(0xFFFFFFFF),
        inverseSurface: Color(0xFF1A1A1A),
        onInverseSurface: Color(0xFFF5F5F5),
        inversePrimary: Color(0xFFE0E0E0),
      ),
      textTheme: _buildTextTheme(const Color(0xFF000000)),
    );
  }

  /// Gets a dark theme for the app system level.
  /// Pure black/white monochrome — sleek, modern, high-contrast dark mode.
  static ThemeData getAppDarkTheme() {
    return _buildBaseTheme(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF), // White — primary actions & accents
        onPrimary: Color(0xFF000000), // Black text on white
        primaryContainer: Color(0xFF1F1F1F), // Very dark gray container
        onPrimaryContainer: Color(0xFFFFFFFF),
        secondary: Color(0xFFBDBDBD), // Light gray — secondary actions
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF2A2A2A),
        onSecondaryContainer: Color(0xFFE0E0E0),
        surface: Color(0xFF000000), // Pure black surface
        onSurface: Color(0xFFFFFFFF), // Pure white text
        surfaceContainerLowest: Color(0xFF000000),
        surfaceContainerLow: Color(0xFF0A0A0A),
        surfaceContainer: Color(0xFF121212),
        surfaceContainerHigh: Color(0xFF1A1A1A),
        surfaceContainerHighest: Color(0xFF242424),
        outline: Color(0xFF424242), // Dark gray outlines
        outlineVariant: Color(0xFF2A2A2A), // Very dark gray dividers
        error: Color(0xFFCF6679),
        onError: Color(0xFF000000),
        inverseSurface: Color(0xFFF5F5F5),
        onInverseSurface: Color(0xFF1A1A1A),
        inversePrimary: Color(0xFF212121),
      ),
      textTheme: _buildTextTheme(const Color(0xFFFFFFFF)),
    );
  }
}
