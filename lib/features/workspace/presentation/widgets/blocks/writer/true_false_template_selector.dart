import 'package:flutter/material.dart';

/// Visual template selector for true/false question blocks.
class TrueFalseTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const TrueFalseTemplateSelector({
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
            _buildTemplateOption('banner', 'Banner', _buildBannerPreview()),
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption('toggle', 'Toggle', _buildTogglePreview()),
            _buildTemplateOption('spotlight', 'Spotlight', _buildSpotlightPreview()),
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
                : theme.colorScheme.outline.withOpacity(0.3),
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
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
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
    final error = theme.colorScheme.error;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 5, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 8)),
        Row(
          children: [
            Expanded(child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: primary, width: 1.5),
              ),
              child: Center(child: Text('T', style: TextStyle(fontSize: 9, color: primary, fontWeight: FontWeight.bold))),
            )),
            const SizedBox(width: 6),
            Expanded(child: Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: error.withOpacity(0.5)),
              ),
              child: Center(child: Text('F', style: TextStyle(fontSize: 9, color: error.withOpacity(0.6), fontWeight: FontWeight.bold))),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final primary = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 5, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 8)),
        Row(
          children: [
            Expanded(child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: primary, width: 1.5),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 10, color: primary),
                  Text('TRUE', style: TextStyle(fontSize: 7, color: primary, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const SizedBox(width: 6),
            Expanded(child: Container(
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: error.withOpacity(0.4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, size: 10, color: error.withOpacity(0.6)),
                  Text('FALSE', style: TextStyle(fontSize: 7, color: error.withOpacity(0.7), fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerPreview() {
    final primary = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 5, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 6)),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: primary, width: 1.5),
          ),
          child: Center(child: Text('TRUE', style: TextStyle(fontSize: 7, color: primary, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 4),
        Container(
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: error.withOpacity(0.4)),
          ),
          child: Center(child: Text('FALSE', style: TextStyle(fontSize: 7, color: error.withOpacity(0.7), fontWeight: FontWeight.bold))),
        ),
      ],
    );
  }

  Widget _buildMinimalPreview() {
    final primary = theme.colorScheme.primary;
    final dotColor = theme.colorScheme.outline.withOpacity(0.5);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 5, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 8)),
        Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: primary)),
            const SizedBox(width: 5),
            Text('True', style: TextStyle(fontSize: 9, color: primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: dotColor))),
            const SizedBox(width: 5),
            Text('False', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ],
    );
  }

  Widget _buildTogglePreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 5, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 8)),
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(9)),
                  child: Center(child: Text('T', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))),
                ),
              ),
              Expanded(
                child: Center(child: Text('F', style: TextStyle(fontSize: 8, color: theme.colorScheme.onSurface.withOpacity(0.5)))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlightPreview() {
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 5, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 8)),
        Row(
          children: [
            Expanded(child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: primary, width: 2),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, spreadRadius: 1)],
              ),
              child: Center(child: Text('T', style: TextStyle(fontSize: 9, color: primary, fontWeight: FontWeight.bold))),
            )),
            const SizedBox(width: 6),
            Expanded(child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Center(child: Text('F', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.25)))),
            )),
          ],
        ),
      ],
    );
  }
}
