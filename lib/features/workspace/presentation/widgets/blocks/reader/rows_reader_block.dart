import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/row_templates.dart';

/// Read-only display of rows block with horizontal layout.
class RowsReaderBlock extends ConsumerWidget {
  final Block block;
  final Directory? docDir;

  const RowsReaderBlock({required this.block, this.docDir, super.key});

  Map<String, dynamic> _parseContent() {
    final converter = JsonStringConverter();
    try {
      return converter.convertFromJsonString(block.content);
    } catch (e) {
      return {
        'rows': [
          {'height': 100.0, 'content': '', 'imagePath': ''},
          {'height': 100.0, 'content': '', 'imagePath': ''},
        ],
        'gap': 16.0,
        'rowStyle': 'elevated',
        'rowTemplate': 'standard',
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final content = _parseContent();
    final rows = content['rows'] as List? ?? [];
    final gap = (content['gap'] as num?)?.toDouble() ?? 16.0;
    final rowStyle = content['rowStyle']?.toString() ?? 'elevated';
    final rowTemplate = content['rowTemplate']?.toString() ?? 'standard';

    // Apply block styles
    final fontSize = block.style.fontSize;
    final parsedColor = styleUtils.parseHex(block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final parsedBackground = styleUtils.parseHex(block.style.background);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final baseTextStyle = styleUtils
        .applyStyle(block.style)
        .copyWith(fontSize: fontSize * textMultiplier, color: color);

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          'No rows available',
          style: baseTextStyle.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return DefaultTextStyle(
      style: baseTextStyle,
      child: Container(
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: _buildRowsContent(theme, rows, gap, rowStyle, rowTemplate),
      ),
    );
  }

  Widget _buildRowsContent(
    ThemeData theme,
    List rows,
    double gap,
    String rowStyle,
    String rowTemplate,
  ) {
    // Timeline template uses vertical layout
    if (rowTemplate == 'timeline') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(rows.length, (index) {
            final row = rows[index] as Map<String, dynamic>;
            return buildTimelineRowTemplate(
              theme: theme,
              row: row,
              rowStyle: rowStyle,
              docDir: docDir,
              gap: gap,
              isFirst: index == 0,
              isLast: index == rows.length - 1,
            );
          }),
        ),
      );
    }

    // Stacked template uses vertical scrolling
    if (rowTemplate == 'stacked') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(rows.length, (index) {
            final row = rows[index] as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < rows.length - 1 ? gap : 0,
                left: 16,
                right: 16,
              ),
              child: buildStackedRowTemplate(
                theme: theme,
                row: row,
                rowStyle: rowStyle,
                docDir: docDir,
                gap: gap,
              ),
            );
          }),
        ),
      );
    }

    // Other templates use horizontal scrolling
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: getRowHeightForTemplate(rowTemplate),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (context, index) {
          final row = rows[index] as Map<String, dynamic>;
          return _buildRowContent(theme, row, rowStyle, rowTemplate, gap);
        },
      ),
    );
  }

  Widget _buildRowContent(
    ThemeData theme,
    Map<String, dynamic> row,
    String rowStyle,
    String rowTemplate,
    double gap,
  ) {
    switch (rowTemplate) {
      case 'stacked':
        return buildStackedRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'highlight':
        return buildHighlightRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'feature':
        return buildFeatureRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'compact':
        return buildCompactRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'overlay':
        return buildOverlayRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'magazine':
        return buildMagazineRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'split':
        return buildSplitRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'banner':
        return buildBannerRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'avatar':
        return buildAvatarRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'icon':
        return buildIconRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'horizontal':
        return buildHorizontalRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'standard':
      default:
        return buildStandardRowTemplate(
          theme: theme,
          row: row,
          rowStyle: rowStyle,
          docDir: docDir,
          gap: gap,
        );
    }
  }
}
