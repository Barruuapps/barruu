import 'package:flutter/material.dart';

/// Visual template selector for matching question blocks.
class MatchingTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const MatchingTemplateSelector({
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
        height: MediaQuery.of(context).size.height * 0.55,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            _buildTemplateOption('default', 'Default', _buildDefaultPreview()),
            _buildTemplateOption('card', 'Card', _buildCardPreview()),
            _buildTemplateOption('compact', 'Compact', _buildCompactPreview()),
            _buildTemplateOption(
              'numbered',
              'Numbered',
              _buildNumberedPreview(),
            ),
            _buildTemplateOption('list', 'List', _buildListPreview()),
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
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline.withValues(alpha: 0.35);
    Widget col(Color borderColor) => Expanded(
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            height: 10,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: i == 0 && borderColor == primary ? primary : outline,
                width: i == 0 && borderColor == primary ? 1.5 : 1,
              ),
              color: i == 0 && borderColor == primary
                  ? primary.withValues(alpha: 0.08)
                  : null,
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [col(primary), const SizedBox(width: 6), col(outline)],
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    Widget col(bool isLeft) => Expanded(
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            height: 11,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: i == 0 && isLeft
                  ? primary.withValues(alpha: 0.1)
                  : surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: i == 0 && isLeft ? primary : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [col(true), const SizedBox(width: 6), col(false)],
        ),
      ],
    );
  }

  Widget _buildCompactPreview() {
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline.withValues(alpha: 0.3);
    Widget col(bool isLeft) => Expanded(
      child: Column(
        children: List.generate(
          4,
          (i) => Container(
            height: 7,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: i == 0 && isLeft ? primary : outline,
                width: 1,
              ),
              color: i == 0 && isLeft ? primary.withValues(alpha: 0.07) : null,
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 4,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 5),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [col(true), const SizedBox(width: 5), col(false)],
        ),
      ],
    );
  }

  Widget _buildNumberedPreview() {
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline.withValues(alpha: 0.35);
    Widget leftCol() => Expanded(
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            height: 10,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: i == 0 ? primary : outline),
              color: i == 0 ? primary.withValues(alpha: 0.08) : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 3),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0 ? primary : outline.withValues(alpha: 0.6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 4, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Widget rightCol() => Expanded(
      child: Column(
        children: ['A', 'B', 'C']
            .asMap()
            .entries
            .map(
              (e) => Container(
                height: 10,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: outline),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: outline.withValues(alpha: 0.8),
                      ),
                      child: Center(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [leftCol(), const SizedBox(width: 6), rightCol()],
        ),
      ],
    );
  }

  Widget _buildListPreview() {
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
            height: 11,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                left: BorderSide(
                  color: i == 0
                      ? primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 5,
                  color: (i == 0
                      ? primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.arrow_forward_rounded, size: 5),
                ),
                Container(
                  width: 12,
                  height: 5,
                  color: (i == 0
                      ? primary.withValues(alpha: 0.4)
                      : theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
