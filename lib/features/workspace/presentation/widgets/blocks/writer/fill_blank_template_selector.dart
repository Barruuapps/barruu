import 'package:flutter/material.dart';

/// Visual template selector for fill-in-the-blank question blocks.
class FillBlankTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const FillBlankTemplateSelector({
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
            _buildTemplateOption('exam', 'Exam', _buildExamPreview()),
            _buildTemplateOption(
              'boxed_blank',
              'Boxed',
              _buildBoxedBlankPreview(),
            ),
            _buildTemplateOption(
              'highlighted_blank',
              'Highlighted',
              _buildHighlightedBlankPreview(),
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
    final primary = theme.colorScheme.primary;
    final lineColor = theme.colorScheme.outline;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sentence row with inline blank
        Row(
          children: [
            Container(
              height: 4,
              width: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 3),
            Container(
              width: 22,
              height: 13,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: primary, width: 1.5)),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              height: 4,
              width: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              height: 4,
              width: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 3),
            Container(
              width: 18,
              height: 13,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: lineColor, width: 1)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: primary, width: 3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 4,
                    width: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 18,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                width: 30,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sentence with numbered blanks
        Row(
          children: [
            Container(
              height: 4,
              width: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text('1', style: TextStyle(fontSize: 6, color: primary)),
            ),
            const SizedBox(width: 2),
            Container(
              height: 4,
              width: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Divider
        Divider(
          height: 4,
          thickness: 0.5,
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 4),
        // Numbered input fields below
        Row(
          children: [
            Text(
              '1.',
              style: TextStyle(
                fontSize: 7,
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '2.',
              style: TextStyle(
                fontSize: 7,
                color: theme.colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoxedBlankPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 4,
              width: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 2),
            Container(
              width: 22,
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(
                  color: primary.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              height: 4,
              width: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Container(
              height: 4,
              width: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 2),
            Container(
              width: 18,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightedBlankPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 4,
              width: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 2),
            Container(
              width: 22,
              height: 14,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
                border: Border(bottom: BorderSide(color: primary, width: 2)),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              height: 4,
              width: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Container(
              height: 4,
              width: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 2),
            Container(
              width: 18,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.secondary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
