import 'package:flutter/material.dart';

/// Visual template selector for header blocks.
/// Shows visual previews of each header template instead of text labels.
class HeaderTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const HeaderTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Header Template'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.65,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            _buildTemplateOption('normal', 'Normal', _buildNormalPreview()),
            _buildTemplateOption('underline', 'Underline', _buildUnderlinePreview()),
            _buildTemplateOption('dotted', 'Dotted', _buildDottedPreview()),
            _buildTemplateOption('breakline', 'Breakline', _buildBreaklinePreview()),
            _buildTemplateOption('boxed', 'Boxed', _buildBoxedPreview()),
            _buildTemplateOption('dotted_box', 'Dotted Box', _buildDottedBoxPreview()),
            _buildTemplateOption('gradient', 'Gradient', _buildGradientPreview()),
            _buildTemplateOption('featured', 'Featured', _buildFeaturedPreview()),
            _buildTemplateOption('modern', 'Modern', _buildModernPreview()),
            _buildTemplateOption('hero', 'Hero', _buildHeroPreview()),
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption('accent', 'Accent', _buildAccentPreview()),
            _buildTemplateOption('badge', 'Badge', _buildBadgePreview()),
            _buildTemplateOption('ribbon', 'Ribbon', _buildRibbonPreview()),
            _buildTemplateOption('callout', 'Callout', _buildCalloutPreview()),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                padding: const EdgeInsets.all(6.0),
                child: preview,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
                  fontSize: 10,
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

  Widget _buildNormalPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlinePreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.3),
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              10,
              (index) => Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreaklinePreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => Container(
                width: 5,
                height: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxedPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedBoxPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              8,
              (index) => Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              8,
              (index) => Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.6),
            theme.colorScheme.secondaryContainer.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.tertiary.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPreview() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Center(
          child: Container(
            height: 6,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            width: 35,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Container(
                  height: 3,
                  width: 10,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonPreview() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 8, top: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
            child: Container(
              height: 2,
              width: 6,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalloutPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
