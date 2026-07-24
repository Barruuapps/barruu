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
      // Primary Brand Theme
      ThemeOption(
        id: AppThemeType.professionalTeal,
        name: 'Professional (Default)',
        theme: AppTheme.professionalTeal,
        description: 'Modern editorial style - trustworthy and professional',
      ),
      
      // Light Themes
      ThemeOption(
        id: AppThemeType.purpleCyan,
        name: 'Purple Cyan',
        theme: AppTheme.purpleCyan,
        description: 'Vibrant purple with cyan accents',
      ),
      ThemeOption(
        id: AppThemeType.softBeige,
        name: 'Soft Beige',
        theme: AppTheme.softBeige,
        description: 'Warm and sophisticated neutral tones',
      ),
      ThemeOption(
        id: AppThemeType.calmBlue,
        name: 'Calm Blue',
        theme: AppTheme.calmBlue,
        description: 'Clean and trustworthy blue palette',
      ),
      ThemeOption(
        id: AppThemeType.softGreen,
        name: 'Soft Green',
        theme: AppTheme.softGreen,
        description: 'Natural green for balance and calm',
      ),
      ThemeOption(
        id: AppThemeType.minimalWhite,
        name: 'Minimal White',
        theme: AppTheme.minimalWhite,
        description: 'Ultra-professional monochrome style',
      ),
      ThemeOption(
        id: AppThemeType.sunsetGlow,
        name: 'Sunset Glow',
        theme: AppTheme.sunsetGlow,
        description: 'Vibrant gradient-inspired warmth',
      ),
      ThemeOption(
        id: AppThemeType.oceanBreeze,
        name: 'Ocean Breeze',
        theme: AppTheme.oceanBreeze,
        description: 'Serene teal for refreshing focus',
      ),
      ThemeOption(
        id: AppThemeType.royalIndigo,
        name: 'Royal Indigo',
        theme: AppTheme.royalIndigo,
        description: 'Classic indigo for elegance',
      ),
      ThemeOption(
        id: AppThemeType.graphiteSteel,
        name: 'Graphite Steel',
        theme: AppTheme.graphiteSteel,
        description: 'Corporate sleek tech-forward style',
      ),
      ThemeOption(
        id: AppThemeType.coralReef,
        name: 'Coral Reef',
        theme: AppTheme.coralReef,
        description: 'Vibrant coral with teal accents',
      ),
      ThemeOption(
        id: AppThemeType.nordicFrost,
        name: 'Nordic Frost',
        theme: AppTheme.nordicFrost,
        description: 'Clean Nordic-inspired minimalism',
      ),

      // Dark Themes
      ThemeOption(
        id: AppThemeType.warmDark,
        name: 'Warm Dark',
        theme: AppTheme.warmDark,
        description: 'Rich and inviting dark mode',
        category: ThemeCategory.dark,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.elegantDark,
        name: 'Elegant Dark',
        theme: AppTheme.elegantDark,
        description: 'Premium sleek dark experience',
        category: ThemeCategory.dark,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.emeraldSlate,
        name: 'Emerald Slate',
        theme: AppTheme.emeraldSlate,
        description: 'Luxurious emerald on dark slate',
        category: ThemeCategory.dark,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.amberNoir,
        name: 'Amber Noir',
        theme: AppTheme.amberNoir,
        description: 'Premium warm amber luxury',
        category: ThemeCategory.dark,
        isDark: true,
      ),

      // Study-Focused Themes
      ThemeOption(
        id: AppThemeType.focusStudy,
        name: 'Focus Study',
        theme: AppTheme.focusStudy,
        description: 'Warm paper-like for concentration',
        category: ThemeCategory.study,
      ),
      ThemeOption(
        id: AppThemeType.libraryClassic,
        name: 'Library Classic',
        theme: AppTheme.libraryClassic,
        description: 'Sepia tones for comfortable reading',
        category: ThemeCategory.study,
      ),
      ThemeOption(
        id: AppThemeType.nightScholar,
        name: 'Night Scholar',
        theme: AppTheme.nightScholar,
        description: 'Dark mode for late-night study',
        category: ThemeCategory.study,
        isDark: true,
      ),
      ThemeOption(
        id: AppThemeType.freshMint,
        name: 'Fresh Mint',
        theme: AppTheme.freshMint,
        description: 'Calming green for stress-free reading',
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