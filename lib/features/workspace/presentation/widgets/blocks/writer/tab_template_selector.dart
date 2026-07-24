import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/tab_templates.dart';

/// Visual template selector for tab blocks.
/// Shows visual previews of each tab template instead of text labels.
class TabTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const TabTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Tab Template'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: [
            _buildTemplateOption(kTabTemplateStandard, kTabTemplateNames[kTabTemplateStandard]!, _buildStandardPreview()),
            _buildTemplateOption(kTabTemplatePills, kTabTemplateNames[kTabTemplatePills]!, _buildPillsPreview()),
            _buildTemplateOption(kTabTemplateUnderline, kTabTemplateNames[kTabTemplateUnderline]!, _buildUnderlinePreview()),
            _buildTemplateOption(kTabTemplateBoxed, kTabTemplateNames[kTabTemplateBoxed]!, _buildBoxedPreview()),
            _buildTemplateOption(kTabTemplateMinimal, kTabTemplateNames[kTabTemplateMinimal]!, _buildMinimalPreview()),
            _buildTemplateOption(kTabTemplateSidebar, kTabTemplateNames[kTabTemplateSidebar]!, _buildSidebarPreview()),
            _buildTemplateOption(kTabTemplateVertical, kTabTemplateNames[kTabTemplateVertical]!, _buildVerticalPreview()),
            _buildTemplateOption(kTabTemplateSegmented, kTabTemplateNames[kTabTemplateSegmented]!, _buildSegmentedPreview()),
            _buildTemplateOption(kTabTemplateCards, kTabTemplateNames[kTabTemplateCards]!, _buildCardsPreview()),
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
    return Column(
      children: [
        // Tab bar
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content area
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillsPreview() {
    return Column(
      children: [
        // Pills tab bar
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Container(
                width: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Content area
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnderlinePreview() {
    return Column(
      children: [
        // Underline tabs
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 2,
                        width: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 2,
                        width: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content area
        Expanded(
          flex: 3,
          child: Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoxedPreview() {
    return Column(
      children: [
        // Boxed tabs
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 10,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Container(
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Content area
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalPreview() {
    return Column(
      children: [
        // Minimal tabs
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 2,
                width: 15,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                color: theme.colorScheme.primary,
              ),
              Container(
                height: 2,
                width: 15,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Content area
        Expanded(
          flex: 3,
          child: Container(
            color: theme.colorScheme.surface.withOpacity(0.5),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
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
        // Sidebar tabs
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content area
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                const SizedBox(height: 2),
                Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Vertical stacked tabs
          Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
            child: Center(
              child: Container(
                height: 2,
                width: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Container(
                height: 2,
                width: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Content area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 2),
                  Container(height: 2, width: 25, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedPreview() {
    return Column(
      children: [
        // Segmented control
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Container(
                        height: 1.5,
                        width: 8,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Center(
                    child: Container(
                      height: 1.5,
                      width: 8,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Content area
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 2),
                Container(height: 2, width: 30, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsPreview() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
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
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Container(height: 2, width: 18, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
