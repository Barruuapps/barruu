import 'package:barruu/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Theme categories for organizing themes in the selection UI.
enum ThemeCategory {
  /// Light themes for daytime use
  light,
  /// Dark themes for nighttime or low-light use
  dark,
  /// Themes optimized for studying and reading
  study,
}

/// Represents a theme option with an identifier, display name, and associated theme data.
///
/// This class is immutable and provides equality comparison for theme options.
@immutable
class ThemeOption {
  /// The unique identifier for the theme, corresponding to [AppThemeType].
  final AppThemeType id;

  /// The human-readable name of the theme.
  final String name;

  /// The associated [ThemeData] for the theme.
  final ThemeData theme;

  /// Optional description of the theme's purpose or style.
  final String? description;

  /// The category this theme belongs to.
  final ThemeCategory category;

  /// Whether this is a dark theme.
  final bool isDark;

  /// Creates a [ThemeOption] with the given [id], [name], and [theme].
  const ThemeOption({
    required this.id,
    required this.name,
    required this.theme,
    this.description,
    this.category = ThemeCategory.light,
    this.isDark = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ThemeOption &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              theme == other.theme &&
              description == other.description &&
              category == other.category &&
              isDark == other.isDark;

  @override
  int get hashCode => Object.hash(id, name, theme, description, category, isDark);
}