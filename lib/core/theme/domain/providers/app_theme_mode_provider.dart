import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/theme/domain/models/app_theme_mode.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a Riverpod state notifier for managing the application's system theme mode.
///
/// This controls the overall app appearance (light/dark/system) and is separate
/// from minibook themes which are used for content reading.
final appThemeModeProvider = StateNotifierProvider.autoDispose<AppThemeModeNotifier, AppThemeMode>(
  (ref) => AppThemeModeNotifier(),
);

/// Manages the application's system theme mode state and persists the selection.
///
/// This class handles loading and saving the selected app theme mode using [SharedPreferences]
/// and updates the application's overall appearance accordingly.
class AppThemeModeNotifier extends StateNotifier<AppThemeMode> {
  /// Creates a new [AppThemeModeNotifier] with system mode as default.
  AppThemeModeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  /// Key used to store the app theme mode preference in [SharedPreferences].
  static const _themeModeKey = 'app_theme_mode';

  /// Loads the saved theme mode from [SharedPreferences].
  ///
  /// If no valid theme mode is found, falls back to [AppThemeMode.system].
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeName = prefs.getString(_themeModeKey);
      final themeMode = _parseThemeMode(themeModeName);
      state = themeMode;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to load app theme mode from preferences',
        error: e,
        stackTrace: stackTrace,
      );
      state = AppThemeMode.system; // Fallback to default
    }
  }

  /// Sets and persists a new app theme mode.
  ///
  /// [themeMode] The theme mode to apply.
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, themeMode.name);
      state = themeMode;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to set app theme mode: $themeMode',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parses a theme mode name string into an [AppThemeMode].
  ///
  /// [themeModeName] The name of the theme mode from preferences.
  /// Returns the corresponding [AppThemeMode], or [AppThemeMode.system] if invalid.
  AppThemeMode _parseThemeMode(String? themeModeName) {
    if (themeModeName == null) {
      return AppThemeMode.system;
    }
    try {
      return AppThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeName,
        orElse: () {
          logger.w('Invalid theme mode name in preferences: $themeModeName, using default');
          return AppThemeMode.system;
        },
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse theme mode name: $themeModeName',
        error: e,
        stackTrace: stackTrace,
      );
      return AppThemeMode.system;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
