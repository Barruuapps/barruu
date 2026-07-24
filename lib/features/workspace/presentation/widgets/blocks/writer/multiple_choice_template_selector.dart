import 'package:flutter/material.dart';

/// Visual template selector for multiple choice question blocks.
class MultipleChoiceTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const MultipleChoiceTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Question Template'),
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
            _buildTemplateOption('default', 'Default', _buildDefaultPreview()),
            _buildTemplateOption('card', 'Card', _buildCardPreview()),
            _buildTemplateOption('grid', 'Grid', _buildGridPreview()),
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption('pill', 'Pill', _buildPillPreview()),
            _buildTemplateOption(
              'numbered',
              'Numbered',
              _buildNumberedPreview(),
            ),
            _buildTemplateOption(
              'highlight',
              'Highlight',
              _buildHighlightPreview(),
            ),
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
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
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
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
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

  Widget _buildDefaultPreview() {
    final color = theme.colorScheme.outline.withValues(alpha: 0.4);
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question line
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        // Options with circle indicator
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            height: 10,
            decoration: BoxDecoration(
              border: Border.all(
                color: i == 0 ? primary : color,
                width: i == 0 ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
              color: i == 0 ? primary.withValues(alpha: 0.1) : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: i == 0 ? primary : color),
                    color: i == 0 ? primary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 5),
        ),
        ...List.generate(3, (i) {
          final letters = ['A', 'B', 'C'];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            height: 12,
            decoration: BoxDecoration(
              color: i == 0 ? primary.withValues(alpha: 0.12) : surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: i == 0 ? primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 3),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? primary
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      letters[i],
                      style: TextStyle(
                        fontSize: 5,
                        color: i == 0
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGridPreview() {
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        // 2x2 grid
        Row(
          children: [
            Expanded(
              child: Container(
                height: 18,
                margin: const EdgeInsets.only(right: 3, bottom: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: primary, width: 1.5),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 18,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 18,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalPreview() {
    final primary = theme.colorScheme.primary;
    final divColor = theme.colorScheme.outline.withValues(alpha: 0.25);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        ...List.generate(
          3,
          (i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0
                          ? primary
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: i == 0
                          ? primary.withValues(alpha: 0.5)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
              if (i < 2) Divider(height: 6, thickness: 0.5, color: divColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            height: 11,
            decoration: BoxDecoration(
              color: i == 0 ? primary.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: i == 0
                    ? primary
                    : theme.colorScheme.outline.withValues(alpha: 0.4),
                width: i == 0 ? 1.5 : 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 5),
        ),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(
                color: i == 0
                    ? primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: i == 0 ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(5),
              color: i == 0 ? primary.withValues(alpha: 0.07) : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 3),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0
                        ? primary
                        : theme.colorScheme.outline.withValues(alpha: 0.35),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildHighlightPreview() {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 5),
        ),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            height: 12,
            decoration: BoxDecoration(
              color: i == 0
                  ? colors[i % colors.length].withValues(alpha: 0.85)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    );
  }
}
