/// Represents the overall app theme mode (system settings level)
/// This is separate from minibook themes which are for content reading
enum AppThemeMode {
  /// Light mode for the entire app
  light,
  
  /// Dark mode for the entire app
  dark,
  
  /// Follow system settings
  system,
}

extension AppThemeModeExtension on AppThemeMode {
  /// Get display name for the theme mode
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
  
  /// Get description for the theme mode
  String get description {
    switch (this) {
      case AppThemeMode.light:
        return 'Use light theme for the app';
      case AppThemeMode.dark:
        return 'Use dark theme for the app';
      case AppThemeMode.system:
        return 'Follow system theme settings';
    }
  }
}
