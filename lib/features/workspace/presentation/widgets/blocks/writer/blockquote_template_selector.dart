import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Visual template selector for blockquote blocks.
/// Shows visual previews of each blockquote template.
class BlockquoteTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const BlockquoteTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Blockquote Template'),
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
            _buildTemplateOption('basic', 'Basic', _buildBasicPreview()),
            _buildTemplateOption('bordered', 'Bordered', _buildBorderedPreview()),
            _buildTemplateOption('highlighted', 'Highlighted', _buildHighlightedPreview()),
            _buildTemplateOption('modern', 'Modern', _buildModernPreview()),
            _buildTemplateOption('testimonial', 'Testimonial', _buildTestimonialPreview()),
            _buildTemplateOption('callout', 'Callout', _buildCalloutPreview()),
            _buildTemplateOption('sidebar', 'Sidebar', _buildSidebarPreview()),
            _buildTemplateOption('featured', 'Featured', _buildFeaturedPreview()),
            _buildTemplateOption('card', 'Card', _buildCardPreview()),
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
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
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
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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

  Widget _buildBasicPreview() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Icon(Icons.format_quote, size: 12, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderedPreview() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_quote, size: 14, color: theme.colorScheme.primary),
          const SizedBox(height: 3),
          Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 2),
          Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildHighlightedPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 3, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(height: 2),
          Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildModernPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            width: 2,
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
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconsaxPlusLinear.message_text, size: 10, color: theme.colorScheme.primary),
                const SizedBox(height: 3),
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(height: 2),
                Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_quote, size: 12, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 3),
          Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 2),
          Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 3),
              Container(height: 2, width: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, size: 8, color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(height: 3, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 2),
          Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildSidebarPreview() {
    return Row(
      children: [
        Container(
          width: 5,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, size: 10, color: theme.colorScheme.primary),
                const SizedBox(height: 3),
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(height: 2),
                Container(height: 2, width: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.3),
            theme.colorScheme.tertiary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(IconsaxPlusBold.quote_up, size: 12, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Container(height: 3, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 2),
          Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.format_quote, size: 10, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 2),
          Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
