import 'package:barruu/core/theme/data/repositories/theme_repository.dart';
import 'package:barruu/core/theme/domain/models/theme_option.dart';
import 'package:barruu/core/theme/domain/presentation/widget/theme_option_card.dart';
import 'package:barruu/core/theme/domain/providers/minibook_theme_provider.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

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

    final displayedThemes = _selectedCategory == null
        ? allThemes
        : allThemes.where((t) => t.category == _selectedCategory).toList();

    final crossAxisCount = ResponsiveUtils.getGridColumns(context).clamp(2, 4);
    final spacing = ResponsiveUtils.getGridSpacing(context);
    final padding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Minibook Themes',
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
        child: ResponsiveUtils.centerContent(
          context,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Choose a theme for reading minibook content. Content creators can set a default theme, but you can always change it when reading.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category filter chips
                _buildCategoryChips(),
                const SizedBox(height: 12),

                // Themes grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 0.75,
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
            onSelected: () => setState(() => _selectedCategory = ThemeCategory.light),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            isSelected: _selectedCategory == ThemeCategory.dark,
            onSelected: () => setState(() => _selectedCategory = ThemeCategory.dark),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Study',
            icon: Icons.menu_book_outlined,
            isSelected: _selectedCategory == ThemeCategory.study,
            onSelected: () => setState(() => _selectedCategory = ThemeCategory.study),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
