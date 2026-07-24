import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/theme/domain/models/theme_option.dart';
import 'package:barruu/core/theme/domain/providers/minibook_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeOptionCard extends ConsumerWidget {
  final ThemeOption themeOption;
  final bool isPopular;
  final bool isSelected;

  const ThemeOptionCard({
    super.key,
    required this.themeOption,
    this.isPopular = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = themeOption.theme.colorScheme;

    return GestureDetector(
      onTap: () => _onSelect(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colors.surface,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surface,
              colors.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Subtle background pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      colors.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme preview area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          colors.secondary,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // App UI mockup
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: 40,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          top: 26,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 3),
                                decoration: BoxDecoration(
                                  color: colors.surface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 3),
                                decoration: BoxDecoration(
                                  color: colors.surface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Theme name and info
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              themeOption.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          if (isSelected)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: colors.onPrimary,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Tags row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (themeOption.isDark)
                            _buildTag(
                              icon: Icons.dark_mode_rounded,
                              label: 'Dark',
                              color: colors.primary,
                            ),

                          if (themeOption.category == ThemeCategory.study)
                            _buildTag(
                              icon: Icons.menu_book_rounded,
                              label: 'Study',
                              color: colors.secondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _onSelect(BuildContext context, WidgetRef ref) {
    try {
      ref.read(minibookThemeProvider.notifier).setTheme(themeOption.id);

      // Subtle feedback
      final snackBar = SnackBar(
        content: Text('Switched to ${themeOption.name} minibook theme'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to set minibook theme: ${themeOption.id}',
        error: e,
        stackTrace: stackTrace,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to switch minibook theme'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
