import 'package:barruu/core/theme/app_theme.dart';
import 'package:barruu/core/theme/domain/models/theme_option.dart';

/// Repository for managing available theme options in the application.
///
/// Provides a centralized source for retrieving the list of supported themes.
class ThemeRepository {
  /// Returns an immutable list of available theme options.
  ///
  /// Each [ThemeOption] contains a unique identifier, display name, and associated [ThemeData].
  List<ThemeOption> getAvailableThemes() {
    return [
      // ── Light Themes ──
      ThemeOption(
        id: AppThemeType.professionalTeal,
        name: 'Teal Pro',
        theme: AppTheme.professionalTeal,
        description: 'Modern editorial — clean, trustworthy, distraction-free',
      ),
      ThemeOption(
        id: AppThemeType.calmBlue,
        name: 'Calm Blue',
        theme: AppTheme.calmBlue,
        description: 'Cool blue tones — perfect for focused work',
      ),
      ThemeOption(
        id: AppThemeType.minimalWhite,
        name: 'Minimal White',
        theme: AppTheme.minimalWhite,
        description: 'Ultra-clean monochrome for maximum clarity',
      ),
      ThemeOption(
        id: AppThemeType.nordicFrost,
        name: 'Nordic Frost',
        theme: AppTheme.nordicFrost,
        description: 'Airy, premium Scandinavian minimalism',
      ),
      ThemeOption(
        id: AppThemeType.softBeige,
        name: 'Warm Paper',
        theme: AppTheme.softBeige,
        description: 'Warm paper tones — gentle on the eyes',
      ),
      ThemeOption(
        id: AppThemeType.softGreen,
        name: 'Soft Mint',
        theme: AppTheme.softGreen,
        description: 'Natural green — calming and refreshing',
      ),

      // ── Dark Themes ──
      ThemeOption(
        id: AppThemeType.elegantDark,
        name: 'Midnight Ink',
        theme: AppTheme.elegantDark,
        description: 'Rich dark blue — premium night reading',
        category: ThemeCategory.dark,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.graphiteSteel,
        name: 'Deep Charcoal',
        theme: AppTheme.graphiteSteel,
        description: 'Sleek charcoal — modern dark workspace',
        category: ThemeCategory.dark,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.nightScholar,
        name: 'Night Scholar',
        theme: AppTheme.nightScholar,
        description: 'Optimized for late-night reading',
        category: ThemeCategory.study,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.emeraldSlate,
        name: 'Dark Emerald',
        theme: AppTheme.emeraldSlate,
        description: 'Luxurious green on dark background',
        category: ThemeCategory.dark,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.warmDark,
        name: 'Obsidian Warm',
        theme: AppTheme.warmDark,
        description: 'Deep black with warm amber accents',
        category: ThemeCategory.dark,
        isDark: true,
      ),

      // ── Reading / Study Themes ──
      ThemeOption(
        id: AppThemeType.libraryClassic,
        name: 'Library Classic',
        theme: AppTheme.libraryClassic,
        description: 'Sepia book-like tones for immersive reading',
        category: ThemeCategory.study,
      ),
      ThemeOption(
        id: AppThemeType.focusStudy,
        name: 'Focus Study',
        theme: AppTheme.focusStudy,
        description: 'Warm paper — deep concentration mode',
        category: ThemeCategory.study,
      ),
    ];
  }

  /// Returns themes filtered by category.
  List<ThemeOption> getThemesByCategory(ThemeCategory category) {
    return getAvailableThemes().where((t) => t.category == category).toList();
  }

  /// Returns only dark themes.
  List<ThemeOption> getDarkThemes() {
    return getAvailableThemes().where((t) => t.isDark).toList();
  }

  /// Returns only light themes.
  List<ThemeOption> getLightThemes() {
    return getAvailableThemes().where((t) => !t.isDark).toList();
  }
}