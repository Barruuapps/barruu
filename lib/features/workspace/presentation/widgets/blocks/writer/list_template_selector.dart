import 'package:flutter/material.dart';

/// Visual template selector for list blocks.
/// Shows visual previews of each list template instead of text labels.
class ListTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const ListTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose List Template'),
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
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption('outlined', 'Outlined', _buildOutlinedPreview()),
            _buildTemplateOption('gradient', 'Gradient', _buildGradientPreview()),
            _buildTemplateOption('modern', 'Modern', _buildModernPreview()),
            _buildTemplateOption('timeline', 'Timeline', _buildTimelinePreview()),
            _buildTemplateOption('numbered_card', 'Numbered', _buildNumberedCardPreview()),
            _buildTemplateOption('badge', 'Badge', _buildBadgePreview()),
            _buildTemplateOption('priority', 'Priority', _buildPriorityPreview()),
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

  // Template preview widgets

  Widget _buildDefaultPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildCardPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(2, (i) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildMinimalPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildOutlinedPreview() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildGradientPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildModernPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: i == 0 ? 0.1 : 0.0),
            borderRadius: BorderRadius.circular(3),
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildTimelinePreview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (i < 2)
                Container(
                  width: 2,
                  height: 10,
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
            ],
          )),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedCardPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildBadgePreview() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: List.generate(4, (i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Container(
          height: 3,
          width: 18 + (i % 2) * 8.0,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      )),
    );
  }

  Widget _buildPriorityPreview() {
    final colors = [
      Colors.red.withValues(alpha: 0.7),
      Colors.orange.withValues(alpha: 0.7),
      Colors.amber.withValues(alpha: 0.7),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border(left: BorderSide(color: colors[i], width: 3)),
          color: colors[i].withValues(alpha: 0.08),
        ),
        child: Container(
          height: 3,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      )),
    );
  }
}
