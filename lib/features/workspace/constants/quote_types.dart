import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Quote type configuration with colors and icons for admonitions
/// This is a shared configuration used by both writer and reader blockquote blocks
class QuoteTypeConfig {
  final String type;
  final String label;
  final IconData icon;
  final Color lightBorderColor;
  final Color lightBackgroundColor;
  final Color lightIconColor;
  final Color darkBorderColor;
  final Color darkBackgroundColor;
  final Color darkIconColor;

  const QuoteTypeConfig({
    required this.type,
    required this.label,
    required this.icon,
    required this.lightBorderColor,
    required this.lightBackgroundColor,
    required this.lightIconColor,
    required this.darkBorderColor,
    required this.darkBackgroundColor,
    required this.darkIconColor,
  });

  Color getBorderColor(bool isDark) => isDark ? darkBorderColor : lightBorderColor;
  Color getBackgroundColor(bool isDark) => isDark ? darkBackgroundColor : lightBackgroundColor;
  Color getIconColor(bool isDark) => isDark ? darkIconColor : lightIconColor;
}

/// Predefined quote types for admonitions
/// Supports: quote, note, tip, warning, danger, success, info
class QuoteTypes {
  static const List<QuoteTypeConfig> all = [
    QuoteTypeConfig(
      type: 'quote',
      label: 'Quote',
      icon: Icons.format_quote,
      lightBorderColor: Color(0xFF6B7280),
      lightBackgroundColor: Colors.transparent,
      lightIconColor: Color(0xFF6B7280),
      darkBorderColor: Color(0xFF9CA3AF),
      darkBackgroundColor: Colors.transparent,
      darkIconColor: Color(0xFF9CA3AF),
    ),
    QuoteTypeConfig(
      type: 'note',
      label: 'Note',
      icon: IconsaxPlusLinear.note_1,
      lightBorderColor: Color(0xFF3B82F6),
      lightBackgroundColor: Color(0xFFEFF6FF),
      lightIconColor: Color(0xFF3B82F6),
      darkBorderColor: Color(0xFF60A5FA),
      darkBackgroundColor: Color(0xFF1E3A5F),
      darkIconColor: Color(0xFF60A5FA),
    ),
    QuoteTypeConfig(
      type: 'tip',
      label: 'Tip',
      icon: IconsaxPlusLinear.lamp_on,
      lightBorderColor: Color(0xFF10B981),
      lightBackgroundColor: Color(0xFFECFDF5),
      lightIconColor: Color(0xFF10B981),
      darkBorderColor: Color(0xFF34D399),
      darkBackgroundColor: Color(0xFF064E3B),
      darkIconColor: Color(0xFF34D399),
    ),
    QuoteTypeConfig(
      type: 'warning',
      label: 'Warning',
      icon: IconsaxPlusLinear.warning_2,
      lightBorderColor: Color(0xFFF59E0B),
      lightBackgroundColor: Color(0xFFFFFBEB),
      lightIconColor: Color(0xFFF59E0B),
      darkBorderColor: Color(0xFFFBBF24),
      darkBackgroundColor: Color(0xFF78350F),
      darkIconColor: Color(0xFFFBBF24),
    ),
    QuoteTypeConfig(
      type: 'danger',
      label: 'Danger',
      icon: IconsaxPlusLinear.danger,
      lightBorderColor: Color(0xFFEF4444),
      lightBackgroundColor: Color(0xFFFEF2F2),
      lightIconColor: Color(0xFFEF4444),
      darkBorderColor: Color(0xFFF87171),
      darkBackgroundColor: Color(0xFF7F1D1D),
      darkIconColor: Color(0xFFF87171),
    ),
    QuoteTypeConfig(
      type: 'success',
      label: 'Success',
      icon: IconsaxPlusLinear.tick_circle,
      lightBorderColor: Color(0xFF22C55E),
      lightBackgroundColor: Color(0xFFF0FDF4),
      lightIconColor: Color(0xFF22C55E),
      darkBorderColor: Color(0xFF4ADE80),
      darkBackgroundColor: Color(0xFF14532D),
      darkIconColor: Color(0xFF4ADE80),
    ),
    QuoteTypeConfig(
      type: 'info',
      label: 'Info',
      icon: IconsaxPlusLinear.info_circle,
      lightBorderColor: Color(0xFF6366F1),
      lightBackgroundColor: Color(0xFFEEF2FF),
      lightIconColor: Color(0xFF6366F1),
      darkBorderColor: Color(0xFF818CF8),
      darkBackgroundColor: Color(0xFF312E81),
      darkIconColor: Color(0xFF818CF8),
    ),
  ];

  /// Get the configuration for a specific quote type
  /// Falls back to the first type (quote) if not found
  static QuoteTypeConfig getConfig(String? type) {
    return all.firstWhere(
      (config) => config.type == type,
      orElse: () => all.first,
    );
  }
}
