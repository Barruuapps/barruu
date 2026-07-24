import 'package:flutter/material.dart';

/// Visual template selector for reorder (math equation order) question blocks.
class ReorderTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const ReorderTemplateSelector({
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
            _buildTemplateOption('bubble', 'Bubble', _buildBubblePreview()),
            _buildTemplateOption('tile', 'Tile', _buildTilePreview()),
            _buildTemplateOption('numbered', 'Numbered', _buildNumberedPreview()),
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption('highlight', 'Highlight', _buildHighlightPreview()),
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

  // ---------------------------------------------------------------------------
  // Preview builders
  // ---------------------------------------------------------------------------

  Widget _buildDefaultPreview() {
    final outline = theme.colorScheme.outline.withOpacity(0.4);
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          margin: const EdgeInsets.only(bottom: 7),
        ),
        // Word pool area - wrap layout
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pillBox(color: primary.withOpacity(0.12), border: primary.withOpacity(0.4), width: 22),
            _pillBox(color: null, border: outline, width: 18),
            _pillBox(color: null, border: outline, width: 24),
            _pillBox(color: null, border: outline, width: 16),
          ],
        ),
        const SizedBox(height: 6),
        // Available words
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pillBox(color: null, border: outline, width: 20),
            _pillBox(color: null, border: outline, width: 26),
            _pillBox(color: null, border: outline, width: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final surface = theme.colorScheme.surfaceContainerHighest;
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 5, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 7)),
        // Selected cards
        ...List.generate(2, (i) => Container(
          height: 11,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: i == 0 ? primary.withOpacity(0.1) : surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: i == 0 ? primary : Colors.transparent, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 2, offset: const Offset(0, 1))],
          ),
        )),
        const SizedBox(height: 4),
        // Available cards
        Wrap(
          spacing: 3,
          children: List.generate(3, (i) => Container(
            width: 20, height: 9,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1)],
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildBubblePreview() {
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 5, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 7)),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pillBox(color: primary.withOpacity(0.18), border: Colors.transparent, width: 24, radius: 12),
            _pillBox(color: secondary.withOpacity(0.15), border: Colors.transparent, width: 18, radius: 12),
            _pillBox(color: primary.withOpacity(0.1), border: Colors.transparent, width: 20, radius: 12),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pillBox(color: theme.colorScheme.surfaceVariant, border: Colors.transparent, width: 22, radius: 12),
            _pillBox(color: theme.colorScheme.surfaceVariant, border: Colors.transparent, width: 16, radius: 12),
            _pillBox(color: theme.colorScheme.surfaceVariant, border: Colors.transparent, width: 26, radius: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildTilePreview() {
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline.withOpacity(0.5);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 5, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 7)),
        ...List.generate(2, (i) => Container(
          height: 10, width: double.infinity,
          margin: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: i == 0 ? primary : outline, width: i == 0 ? 2 : 1.5),
            color: i == 0 ? primary.withOpacity(0.07) : null,
          ),
        )),
        const SizedBox(height: 4),
        Wrap(
          spacing: 3,
          children: List.generate(3, (i) => Container(
            width: 20, height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: outline, width: 1.5),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildNumberedPreview() {
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline.withOpacity(0.4);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 5, width: double.infinity, color: theme.colorScheme.onSurface.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 7)),
        ...List.generate(3, (i) => Container(
          height: 10, width: double.infinity,
          margin: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: i == 0 ? primary : outline, width: 1),
            color: i == 0 ? primary.withOpacity(0.07) : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 3),
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0 ? primary : outline.withOpacity(0.7),
                ),
                child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 4, color: Colors.white))),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMinimalPreview() {
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          width: double.infinity,
          color: onSurface.withOpacity(0.5),
          margin: const EdgeInsets.only(bottom: 7),
        ),
        // Selected words: plain coloured text with thin underline
        Wrap(
          spacing: 4,
          runSpacing: 5,
          children: [
            _textWord('The', primary),
            _textWord('quick', primary),
            _textWord('fox', primary),
          ],
        ),
        const SizedBox(height: 6),
        // Available words: dimmed text, no underline
        Wrap(
          spacing: 4,
          runSpacing: 5,
          children: [
            _textWord('brown', onSurface.withOpacity(0.55)),
            _textWord('jumps', onSurface.withOpacity(0.55)),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightPreview() {
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          width: double.infinity,
          color: onSurface.withOpacity(0.5),
          margin: const EdgeInsets.only(bottom: 7),
        ),
        // Selected words: marker-highlight (no border)
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pillBox(color: primary.withOpacity(0.2), border: Colors.transparent, width: 22, radius: 3),
            _pillBox(color: primary.withOpacity(0.2), border: Colors.transparent, width: 16, radius: 3),
            _pillBox(color: primary.withOpacity(0.2), border: Colors.transparent, width: 26, radius: 3),
          ],
        ),
        const SizedBox(height: 5),
        // Available words: secondary highlight
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pillBox(color: secondary.withOpacity(0.15), border: Colors.transparent, width: 20, radius: 3),
            _pillBox(color: secondary.withOpacity(0.15), border: Colors.transparent, width: 24, radius: 3),
          ],
        ),
      ],
    );
  }

  /// Tiny text-line widget used in the minimal preview.
  Widget _textWord(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _pillBox({required double width, Color? color, required Color border, double radius = 4}) {
    return Container(
      width: width,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
    );
  }
}
