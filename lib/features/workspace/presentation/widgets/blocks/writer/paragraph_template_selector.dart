import 'package:flutter/material.dart';

/// Visual template selector for paragraph blocks.
/// Shows visual previews of each paragraph template.
class ParagraphTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const ParagraphTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Paragraph Template'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.70,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            _buildTemplateOption('default', 'Default', _buildDefaultPreview()),
            _buildTemplateOption(
              'drop_cap',
              'Drop Cap',
              _buildDropCapPreview(),
            ),
            _buildTemplateOption(
              'image_left',
              'Image Left',
              _buildImageLeftPreview(),
            ),
            _buildTemplateOption(
              'image_right',
              'Image Right',
              _buildImageRightPreview(),
            ),
            _buildTemplateOption(
              'image_float_left',
              'Float Left',
              _buildImageFloatLeftPreview(),
            ),
            _buildTemplateOption(
              'image_float_right',
              'Float Right',
              _buildImageFloatRightPreview(),
            ),
            _buildTemplateOption('zigzag', 'Zigzag', _buildZigzagPreview()),
            _buildTemplateOption('note', 'Note', _buildNotePreview()),
            _buildTemplateOption('warning', 'Warning', _buildWarningPreview()),
            _buildTemplateOption('success', 'Success', _buildSuccessPreview()),
            _buildTemplateOption(
              'highlight',
              'Highlight',
              _buildHighlightPreview(),
            ),
            _buildTemplateOption(
              'pull_quote',
              'Pull Quote',
              _buildPullQuotePreview(),
            ),
            _buildTemplateOption(
              'quote_card',
              'Quote Card',
              _buildQuoteCardPreview(),
            ),
            _buildTemplateOption(
              'centered',
              'Centered',
              _buildCenteredPreview(),
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

  // ─── Template preview widgets ─────────────────────────────────────────────

  Widget _buildDefaultPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 2,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 3),
        Container(
          height: 2,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 3),
        Container(
          height: 2,
          width: 40,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _buildDropCapPreview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'A',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: 30,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageLeftPreview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.image_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: 25,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageRightPreview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: 25,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 28,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.image_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildZigzagPreview() {
    return CustomPaint(
      painter: _ZigzagBorderPainter(color: theme.colorScheme.primary),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 2,
              width: double.infinity,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2,
              width: 30,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotePreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 10,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 3,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 2),
          Container(
            height: 2,
            width: 25,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 2,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: 30,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPullQuotePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '\u201C',
              style: TextStyle(
                fontSize: 28,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 2,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 2),
        Container(
          height: 2,
          width: 30,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '\u201D',
              style: TextStyle(
                fontSize: 28,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── New template previews ─────────────────────────────────────────────────

  Widget _buildImageFloatLeftPreview() {
    return Stack(
      children: [
        // Text fills right side (with left padding for image)
        Positioned(
          left: 30,
          top: 0,
          right: 0,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              // Text continues BELOW image at full width
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
        // Image top-left (float)
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 26,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageFloatRightPreview() {
    return Stack(
      children: [
        // Text with right padding for image
        Positioned(
          left: 0,
          top: 0,
          right: 30,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Container(
                height: 2,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
        // Image top-right (float)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 26,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningPreview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
            width: 3,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 10,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 3,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 2),
          Container(
            height: 2,
            width: 25,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessPreview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.10),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF10B981).withValues(alpha: 0.85),
            width: 3,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 10,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 3,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 2),
          Container(
            height: 2,
            width: 25,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCardPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 10,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 2,
                        width: 20,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredPreview() {
    const rulerColor = Color(0xFF6366F1);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 1,
              color: rulerColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: rulerColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 10,
              height: 1,
              color: rulerColor.withValues(alpha: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 40,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 2),
        Container(
          height: 2,
          width: 30,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 1,
              color: rulerColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: rulerColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 10,
              height: 1,
              color: rulerColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Custom painter for zigzag border preview ─────────────────────────────────

class _ZigzagBorderPainter extends CustomPainter {
  final Color color;

  const _ZigzagBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const step = 6.0;
    const amplitude = 3.0;

    // Top zigzag
    final topPath = Path();
    topPath.moveTo(0, amplitude);
    for (double x = 0; x < size.width; x += step) {
      topPath.lineTo(x + step / 2, 0);
      topPath.lineTo(x + step, amplitude);
    }
    canvas.drawPath(topPath, paint);

    // Bottom zigzag
    final bottomPath = Path();
    bottomPath.moveTo(0, size.height - amplitude);
    for (double x = 0; x < size.width; x += step) {
      bottomPath.lineTo(x + step / 2, size.height);
      bottomPath.lineTo(x + step, size.height - amplitude);
    }
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(_ZigzagBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
