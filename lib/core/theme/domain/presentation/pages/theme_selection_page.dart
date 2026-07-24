import 'package:barruu/core/theme/data/repositories/theme_repository.dart';
import 'package:barruu/core/theme/domain/models/theme_option.dart';
import 'package:barruu/core/theme/domain/presentation/widget/theme_option_card.dart';
import 'package:barruu/core/theme/domain/providers/minibook_theme_provider.dart';
import 'package:barruu/core/theme/domain/providers/app_theme_mode_provider.dart';
import 'package:barruu/core/theme/domain/models/app_theme_mode.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Combined theme selection page for both app UI theme and reader themes.
class ThemeSelectionPage extends ConsumerStatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  ConsumerState<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends ConsumerState<ThemeSelectionPage> {
  ThemeCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final allThemes = ThemeRepository().getAvailableThemes();
    final theme = Theme.of(context);
    final currentMinibookTheme = ref.watch(minibookThemeProvider);
    final appThemeMode = ref.watch(appThemeModeProvider);

    final displayedThemes = _selectedCategory == null
        ? allThemes
        : allThemes.where((t) => t.category == _selectedCategory).toList();

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final crossAxisCount = ResponsiveUtils.getGridColumns(context).clamp(2, 4);
    final spacing = ResponsiveUtils.getGridSpacing(context);
    final padding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Theme Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left_2),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ResponsiveUtils.centerContent(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App Shell Theme Section ──
                Text(
                  'App UI Theme',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Controls the overall app appearance (light or dark)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: AppThemeMode.values.map((mode) {
                    final isSelected = appThemeMode == mode;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _AppThemeCard(
                          mode: mode,
                          isSelected: isSelected,
                          onTap: () => ref
                              .read(appThemeModeProvider.notifier)
                              .setThemeMode(mode),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 20),

                // ── Reader Theme Section ──
                Text(
                  'Reader Themes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how your minibook content looks when reading',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Category filter chips
                _buildCategoryChips(),
                const SizedBox(height: 16),

                // Themes grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: isDesktop ? 0.72 : 0.78,
                  ),
                  itemCount: displayedThemes.length,
                  itemBuilder: (context, index) {
                    final themeOption = displayedThemes[index];
                    return ThemeOptionCard(
                      themeOption: themeOption,
                      isSelected: themeOption.id == currentMinibookTheme,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            icon: Icons.palette_outlined,
            isSelected: _selectedCategory == null,
            onSelected: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Light',
            icon: Icons.light_mode_outlined,
            isSelected: _selectedCategory == ThemeCategory.light,
            onSelected: () =>
                setState(() => _selectedCategory = ThemeCategory.light),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            isSelected: _selectedCategory == ThemeCategory.dark,
            onSelected: () =>
                setState(() => _selectedCategory = ThemeCategory.dark),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Study',
            icon: Icons.menu_book_outlined,
            isSelected: _selectedCategory == ThemeCategory.study,
            onSelected: () =>
                setState(() => _selectedCategory = ThemeCategory.study),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primary,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// Card for selecting the app UI theme mode (Light / Dark / System).
class _AppThemeCard extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppThemeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case AppThemeMode.light:
        return IconsaxPlusLinear.sun_1;
      case AppThemeMode.dark:
        return IconsaxPlusLinear.moon;
      case AppThemeMode.system:
        return IconsaxPlusLinear.mobile;
    }
  }

  String get _label {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 28,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              _label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
