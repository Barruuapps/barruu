import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/theme/app_theme.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a Riverpod state notifier for managing minibook themes.
///
/// Minibook themes are used for content reading and can be selected by
/// content creators when writing and by users when reading.
/// This is separate from the app system theme (light/dark/system).
final minibookThemeProvider = StateNotifierProvider.autoDispose<MinibookThemeNotifier, AppThemeType>(
      (ref) => MinibookThemeNotifier(),
);

/// Manages the minibook theme state and persists theme selection.
///
/// This class handles loading and saving the selected minibook theme using [SharedPreferences].
/// Minibook themes are the ~20 themed options for content reading.
class MinibookThemeNotifier extends StateNotifier<AppThemeType> {
  /// Creates a new [MinibookThemeNotifier] with the professional brand theme as default.
  MinibookThemeNotifier() : super(AppThemeType.professionalTeal) {
    _loadTheme();
  }

  /// Key used to store the minibook theme preference in [SharedPreferences].
  static const _themeKey = 'minibook_theme';

  /// Loads the saved minibook theme from [SharedPreferences].
  ///
  /// If no valid theme is found, falls back to [AppThemeType.professionalTeal].
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      final themeType = _parseThemeType(themeName);
      state = themeType;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to load minibook theme from preferences',
        error: e,
        stackTrace: stackTrace,
      );
      state = AppThemeType.professionalTeal; // Fallback to default
    }
  }

  /// Sets and persists a new minibook theme.
  ///
  /// [themeType] The minibook theme to apply.
  /// If the theme is invalid or saving fails, the state remains unchanged.
  Future<void> setTheme(AppThemeType themeType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeType.name);
      state = themeType;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to set minibook theme: $themeType',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parses a theme name string into an [AppThemeType].
  ///
  /// [themeName] The name of the theme from preferences.
  /// Returns the corresponding [AppThemeType], or [AppThemeType.professionalTeal] if invalid.
  AppThemeType _parseThemeType(String? themeName) {
    if (themeName == null) {
      return AppThemeType.professionalTeal;
    }
    try {
      return AppThemeType.values.firstWhere(
            (type) => type.name == themeName,
        orElse: () {
          logger.w('Invalid theme name in preferences: $themeName, using default');
          return AppThemeType.professionalTeal;
        },
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse theme name: $themeName',
        error: e,
        stackTrace: stackTrace,
      );
      return AppThemeType.professionalTeal;
    }
  }

  /// Disposes of the notifier, cleaning up resources.
  @override
  void dispose() {
    // No additional resources to clean up, but included for completeness.
    super.dispose();
  }
}