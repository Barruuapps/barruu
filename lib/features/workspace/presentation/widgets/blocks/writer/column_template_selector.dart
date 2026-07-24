import 'package:flutter/material.dart';

/// Visual template selector for column blocks.
/// Shows visual previews of each column template instead of text labels.
class ColumnTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const ColumnTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Column Template'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: [
            _buildTemplateOption('standard', 'Standard', _buildStandardPreview()),
            _buildTemplateOption('sidebar', 'Sidebar', _buildSidebarPreview()),
            _buildTemplateOption('hero', 'Hero', _buildHeroPreview()),
            _buildTemplateOption('grid', 'Grid', _buildGridPreview()),
            _buildTemplateOption('card', 'Card', _buildCardPreview()),
            _buildTemplateOption('compact', 'Compact', _buildCompactPreview()),
            _buildTemplateOption('featured', 'Featured', _buildFeaturedPreview()),
            _buildTemplateOption('overlay', 'Overlay', _buildOverlayPreview()),
            _buildTemplateOption('magazine', 'Magazine', _buildMagazinePreview()),
            _buildTemplateOption('split', 'Split', _buildSplitPreview()),
            _buildTemplateOption('banner', 'Banner', _buildBannerPreview()),
            _buildTemplateOption('avatar', 'Avatar', _buildAvatarPreview()),
            _buildTemplateOption('icon', 'Icon', _buildIconPreview()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTemplateOption(String value, String label, Widget preview) {
    final isSelected = selectedTemplate == value;
    return InkWell(
      onTap: () => onTemplateSelected(value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: preview,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Template preview widgets - simplified visual representations

  Widget _buildStandardPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 3, width: 20, color: theme.colorScheme.primary.withOpacity(0.6)),
                const SizedBox(height: 4),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 3, width: 20, color: theme.colorScheme.primary.withOpacity(0.6)),
                const SizedBox(height: 4),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarPreview() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(height: 3),
                Container(height: 2, width: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(height: 3),
                Container(height: 2, width: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 3, width: 40, color: theme.colorScheme.primary.withOpacity(0.6)),
                const SizedBox(height: 4),
                Container(height: 2, width: 50, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPreview() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 4, width: 30, color: theme.colorScheme.primary.withOpacity(0.8)),
                const SizedBox(height: 4),
                Container(height: 2, width: 35, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 15, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(height: 3),
                Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, size: 12, color: theme.colorScheme.primary),
                const SizedBox(height: 2),
                Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, size: 12, color: theme.colorScheme.primary),
                const SizedBox(height: 2),
                Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.tertiaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: Center(
                      child: Icon(Icons.image, size: 12, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.tertiaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: Center(
                      child: Icon(Icons.image, size: 12, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPreview() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 3),
                Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 3),
                Container(height: 2, width: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPreview() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                const SizedBox(height: 3),
                Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 15, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayPreview() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primary.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(height: 3, width: 18, color: Colors.white.withOpacity(0.9)),
              Container(height: 3, width: 18, color: Colors.white.withOpacity(0.9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMagazinePreview() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Center(
              child: Icon(Icons.image, size: 14, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 3, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(height: 3),
                Container(height: 2, width: 35, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 18, color: theme.colorScheme.primary.withOpacity(0.6)),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        Container(
          width: 2,
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 2, width: 18, color: theme.colorScheme.primary.withOpacity(0.6)),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerPreview() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.8),
                theme.colorScheme.tertiary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 3, width: 15, color: Colors.white),
                  const SizedBox(height: 2),
                  Container(height: 2, width: 18, color: Colors.white.withOpacity(0.7)),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 3, width: 15, color: Colors.white),
                  const SizedBox(height: 2),
                  Container(height: 2, width: 18, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Icon(Icons.person, size: 10, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Icon(Icons.person, size: 10, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Center(child: Text('✨', style: const TextStyle(fontSize: 8))),
                ),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Center(child: Text('⭐', style: const TextStyle(fontSize: 8))),
                ),
                const SizedBox(height: 3),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
