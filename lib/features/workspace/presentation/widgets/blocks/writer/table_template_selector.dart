import 'package:flutter/material.dart';

/// Visual template selector for table blocks.
/// Shows visual previews of each table template instead of text labels.
class TableTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const TableTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Table Template'),
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
            _buildTemplateOption('striped', 'Striped', _buildStripedPreview()),
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption(
              'bordered',
              'Bordered',
              _buildBorderedPreview(),
            ),
            _buildTemplateOption('modern', 'Modern', _buildModernPreview()),
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

  // Template preview widgets

  Widget _buildDefaultPreview() {
    return _buildTablePreview(
      headerColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      rowColors: [null, null, null],
      borderColor: theme.colorScheme.outline.withValues(alpha: 0.4),
    );
  }

  Widget _buildStripedPreview() {
    return _buildTablePreview(
      headerColor: theme.colorScheme.primary.withValues(alpha: 0.8),
      headerTextColor: theme.colorScheme.onPrimary,
      rowColors: [
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        null,
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ],
      borderColor: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildMinimalPreview() {
    return _buildTablePreview(
      headerColor: null,
      rowColors: [null, null, null],
      borderColor: Colors.transparent,
      showHorizontalDividers: true,
    );
  }

  Widget _buildBorderedPreview() {
    return _buildTablePreview(
      headerColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      rowColors: [null, null, null],
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.6),
      borderWidth: 1.5,
    );
  }

  Widget _buildModernPreview() {
    return _buildTablePreview(
      headerColor: theme.colorScheme.primary,
      headerTextColor: theme.colorScheme.onPrimary,
      rowColors: [null, null, null],
      borderColor: Colors.transparent,
      showHorizontalDividers: true,
      rounded: true,
    );
  }

  Widget _buildCardPreview() {
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
      child: _buildTablePreview(
        headerColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        rowColors: [null, null, null],
        borderColor: Colors.transparent,
        showHorizontalDividers: true,
      ),
    );
  }

  Widget _buildTablePreview({
    required Color? headerColor,
    Color? headerTextColor,
    required List<Color?> rowColors,
    required Color borderColor,
    double borderWidth = 1.0,
    bool showHorizontalDividers = false,
    bool rounded = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rounded ? 4 : 2),
      child: Table(
        border: TableBorder(
          top: BorderSide(color: borderColor, width: borderWidth),
          bottom: BorderSide(color: borderColor, width: borderWidth),
          left: BorderSide(color: borderColor, width: borderWidth),
          right: BorderSide(color: borderColor, width: borderWidth),
          horizontalInside: showHorizontalDividers
              ? BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                )
              : BorderSide.none,
          verticalInside: BorderSide(color: borderColor, width: borderWidth),
        ),
        columnWidths: const {
          0: FlexColumnWidth(0.35),
          1: FlexColumnWidth(0.35),
          2: FlexColumnWidth(0.3),
        },
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(color: headerColor),
            children: List.generate(
              3,
              (c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: Container(
                  height: 3,
                  color: (headerTextColor ?? theme.colorScheme.onSurface)
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          // Data rows
          ...rowColors.asMap().entries.map(
            (entry) => TableRow(
              decoration: BoxDecoration(color: entry.value),
              children: List.generate(
                3,
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  child: Container(
                    height: 2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
