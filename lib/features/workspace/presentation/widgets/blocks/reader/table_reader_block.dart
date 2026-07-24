
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Reader widget for displaying table content
class TableReaderBlock extends ConsumerWidget {
  final Block block;
  const TableReaderBlock({
    super.key,
    required this.block,
  });

  Widget _buildEmptyTable(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Empty table',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('No table data available'),
      ),
    );
  }

  Widget _buildErrorTable(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Table error',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(4),
          color: theme.colorScheme.error.withOpacity(0.1),
        ),
        child: Text(
          'Error displaying table. Please check your table format.',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final isFirstRowHeader = block.style.headerStyle != 'none';
    final textAlign = styleUtils.textAlignFromStyle(block.style);
    final textStyle = styleUtils.applyStyle(block.style);

    Map<String, dynamic> content = {'header': '', 'rows': []};
    try {
      if (block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(block.content);
        if (content['rows'] == null || content['rows'] is! List) {
          content['rows'] = [];
        }
        if (content['header'] == null) {
          content['header'] = '';
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse JSON block content', error: e, stackTrace: stackTrace);
      // Fallback for backward compatibility with CSV or pipe-separated content
      try {
        // First try pipe separator (new format)
        if (block.content.contains('|')) {
          final rows = block.content
              .split('\n')
              .map((r) => r.split('|').map((c) => c.trim()).toList())
              .toList();
          content = {'header': '', 'rows': rows};
        } else {
          // Fall back to CSV (old format)
          final rows = block.content
              .split('\n')
              .map((r) => r.split(',').map((c) => c.trim()).toList())
              .toList();
          content = {'header': '', 'rows': rows};
        }
      } catch (e, stackTrace) {
        logger.e('Failed to parse block content', error: e, stackTrace: stackTrace);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading table content: $e')),
          );
        }
      }
    }

    try {
      final rows = content['rows'] as List<dynamic>;
      final header = content['header']?.toString() ?? '';
      final tableTemplate = block.style.tableTemplate ?? 'default';

      if (rows.isEmpty) {
        return _buildEmptyTable(context, ref);
      }

      // Find the maximum number of columns
      final maxColumns = rows.isNotEmpty
          ? rows.map((row) => (row as List<dynamic>).length).reduce((a, b) => a > b ? a : b)
          : 0;

      // Pad rows with fewer columns
      final paddedRows = rows.map((row) {
        final currentRow = row as List<dynamic>;
        if (currentRow.length < maxColumns) {
          return [...currentRow, ...List.filled(maxColumns - currentRow.length, '')];
        }
        return currentRow;
      }).toList();

      final isWide = MediaQuery.of(context).size.width > 600;
      final padding = isWide
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
      const margin = EdgeInsets.symmetric(vertical: 8);

      // Make table horizontally scrollable on mobile devices for better mobile-friendliness
      final shouldScroll = !isWide;

      // Determine styles based on template
      Color? containerBgColor;
      BoxBorder? containerBorder;
      BorderRadius containerRadius = BorderRadius.circular(4);
      List<BoxShadow>? containerShadow;
      Color? headerBgColor;
      Color headerTextColor = theme.colorScheme.onPrimary;
      Color Function(int index) rowBgColor = (_) => Colors.transparent;
      TableBorder tableBorder = TableBorder(
        horizontalInside: BorderSide(color: theme.colorScheme.outline),
        verticalInside: BorderSide(color: theme.colorScheme.outline),
      );

      switch (tableTemplate) {
        case 'striped':
          containerBgColor = theme.colorScheme.surface;
          containerBorder = Border.all(color: theme.colorScheme.outline.withOpacity(0.3));
          headerBgColor = theme.colorScheme.primary;
          rowBgColor = (i) => i % 2 == 0
              ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
              : Colors.transparent;
          tableBorder = TableBorder(
            horizontalInside: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
          );
          break;
        case 'minimal':
          containerBgColor = null;
          containerBorder = null;
          headerBgColor = null;
          headerTextColor = theme.colorScheme.onSurface;
          rowBgColor = (_) => Colors.transparent;
          tableBorder = TableBorder(
            horizontalInside: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
          );
          break;
        case 'bordered':
          containerBgColor = theme.colorScheme.surface;
          containerBorder = Border.all(color: theme.colorScheme.primary, width: 1.5);
          containerRadius = BorderRadius.circular(8);
          headerBgColor = theme.colorScheme.primaryContainer.withOpacity(0.5);
          headerTextColor = theme.colorScheme.onSurface;
          rowBgColor = (_) => Colors.transparent;
          tableBorder = TableBorder.all(
            color: theme.colorScheme.primary.withOpacity(0.5),
            width: 1,
          );
          break;
        case 'modern':
          containerBgColor = theme.colorScheme.surface;
          containerBorder = Border.all(color: theme.colorScheme.outline.withOpacity(0.1));
          containerRadius = BorderRadius.circular(12);
          containerShadow = [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
          headerBgColor = theme.colorScheme.primary;
          rowBgColor = (_) => Colors.transparent;
          tableBorder = TableBorder(
            horizontalInside: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
          );
          break;
        case 'card':
          containerBgColor = theme.colorScheme.surface;
          containerBorder = null;
          containerRadius = BorderRadius.circular(12);
          containerShadow = [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ];
          headerBgColor = theme.colorScheme.primaryContainer.withOpacity(0.7);
          headerTextColor = theme.colorScheme.onSurface;
          rowBgColor = (i) => i % 2 == 0
              ? theme.colorScheme.surfaceVariant.withOpacity(0.15)
              : Colors.transparent;
          tableBorder = TableBorder(
            horizontalInside: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
          );
          break;
        default: // 'default'
          containerBgColor = theme.colorScheme.surface;
          containerBorder = Border.all(color: theme.colorScheme.outline);
          headerBgColor = isFirstRowHeader ? theme.colorScheme.primary : null;
          headerTextColor = isFirstRowHeader ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
          rowBgColor = (i) => i % 2 == 0
              ? theme.colorScheme.surfaceVariant.withOpacity(0.1)
              : Colors.transparent;
          tableBorder = TableBorder(
            horizontalInside: BorderSide(color: theme.colorScheme.outline),
            verticalInside: BorderSide(color: theme.colorScheme.outline),
          );
      }

      Widget tableWidget = Container(
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          border: containerBorder,
          borderRadius: containerRadius,
          color: containerBgColor,
          boxShadow: containerShadow,
        ),
        child: Table(
          border: tableBorder,
          columnWidths: {
            for (var i = 0; i < maxColumns; i++) i: const FlexColumnWidth(),
          },
          children: paddedRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isHeaderRow = isFirstRowHeader && index == 0;
            final effectiveHeaderBg = isHeaderRow ? headerBgColor : null;
            final effectiveRowBg = !isHeaderRow ? rowBgColor(index) : null;
            return TableRow(
              decoration: BoxDecoration(
                color: effectiveHeaderBg ?? effectiveRowBg,
                borderRadius: isHeaderRow && tableTemplate != 'minimal'
                    ? const BorderRadius.vertical(top: Radius.circular(4))
                    : (index == paddedRows.length - 1 && tableTemplate != 'minimal'
                    ? const BorderRadius.vertical(bottom: Radius.circular(4))
                    : null),
              ),
              children: row.asMap().entries.map((cellEntry) {
                final cellIndex = cellEntry.key;
                final cell = cellEntry.value.toString();

                final baseStyle = textStyle.copyWith(
                  fontWeight: isHeaderRow ? FontWeight.bold : FontWeight.w400,
                  fontSize: isHeaderRow
                      ? (isWide ? (textStyle.fontSize ?? 14) * 1.05 : (textStyle.fontSize ?? 14) * 0.9)
                      : (isWide ? textStyle.fontSize : (textStyle.fontSize ?? 14) * 0.85),
                  color: isHeaderRow ? headerTextColor : theme.colorScheme.onSurface,
                  letterSpacing: isHeaderRow ? 0.4 : null,
                );
                final linkStyle = baseStyle.copyWith(
                  color: isHeaderRow
                      ? headerTextColor.withOpacity(0.85)
                      : theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: isHeaderRow ? FontWeight.w600 : FontWeight.w500,
                );
                final hoverColor = theme.colorScheme.primary.withOpacity(0.7);

                return Semantics(
                  label: cell.isEmpty
                      ? 'Empty table cell row ${index + 1} column ${cellIndex + 1}'
                      : isHeaderRow
                      ? 'Table header cell row ${index + 1} column ${cellIndex + 1}: $cell'
                      : 'Table cell row ${index + 1} column ${cellIndex + 1}: $cell',
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 16.0 : 8.0, // Increased horizontal padding for readability
                      vertical: isWide ? 12.0 : 8.0, // Slightly more vertical space
                    ),
                    child: RichText(
                      text: LinkUtils.parseTextWithLinks(
                        cell,
                        baseStyle,
                        linkStyle,
                        hoverColor,
                      ),
                      textAlign: textAlign,
                      overflow: TextOverflow.ellipsis, // Handle long text gracefully
                      maxLines: 3, // Limit lines to prevent tall cells
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      );

      // Wrap in horizontal scroll view for mobile devices
      if (shouldScroll) {
        tableWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 1.2, // Slight oversize for scroll hint
            ),
            child: tableWidget,
          ),
        );
      }

      // For large tables, wrap in a vertically scrollable container without a fixed height cap
      if (paddedRows.length > 10) {
        tableWidget = SingleChildScrollView(
          child: tableWidget,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0, bottom: 4.0),
              child: Text(
                header,
                style: textStyle,
                textAlign: textAlign,
              ),
            ),
          tableWidget,
        ],
      );
    } catch (e, stackTrace) {
      logger.e('Unexpected error in TableReaderBlock', error: e, stackTrace: stackTrace);
      return _buildErrorTable(context, ref);
    }
  }
}