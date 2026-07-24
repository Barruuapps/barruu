import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/column_templates.dart';

/// Read-only display of columns block with responsive layout.
class ColumnsReaderBlock extends ConsumerWidget {
  final Block block;
  final Directory? docDir;

  const ColumnsReaderBlock({required this.block, this.docDir, super.key});

  Map<String, dynamic> _parseContent() {
    final converter = JsonStringConverter();
    try {
      return converter.convertFromJsonString(block.content);
    } catch (e) {
      return {
        'columns': [
          {'width': 0.5, 'content': ''},
          {'width': 0.5, 'content': ''},
        ],
        'gap': 16.0,
        'columnStyle': 'elevated',
        'columnTemplate': 'standard',
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final content = _parseContent();
    final columns = content['columns'] as List? ?? [];
    final gap = (content['gap'] as num?)?.toDouble() ?? 16.0;
    final columnStyle = content['columnStyle']?.toString() ?? 'elevated';
    final columnTemplate = content['columnTemplate']?.toString() ?? 'standard';

    // Apply block styles
    final fontSize = block.style.fontSize;
    final parsedColor = styleUtils.parseHex(block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final parsedBackground = styleUtils.parseHex(block.style.background);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final baseTextStyle = styleUtils
        .applyStyle(block.style)
        .copyWith(fontSize: fontSize * textMultiplier, color: color);

    if (columns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          'No columns available',
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use column layout on mobile (< 600px), row on larger screens
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return _buildMobileLayout(theme, columns, gap, columnStyle);
            } else {
              return _buildDesktopLayout(
                theme,
                columns,
                gap,
                columnStyle,
                columnTemplate,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    ThemeData theme,
    List columns,
    double gap,
    String columnStyle,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(columns.length, (index) {
          final column = columns[index] as Map<String, dynamic>;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < columns.length - 1 ? gap : 0,
            ),
            child: _buildColumnContent(theme, column, index, columnStyle),
          );
        }),
      ),
    );
  }

  Widget _buildDesktopLayout(
    ThemeData theme,
    List columns,
    double gap,
    String columnStyle,
    String columnTemplate,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: _buildTemplateLayout(
        theme,
        columns,
        gap,
        columnStyle,
        columnTemplate,
      ),
    );
  }

  Widget _buildTemplateLayout(
    ThemeData theme,
    List columns,
    double gap,
    String columnStyle,
    String columnTemplate,
  ) {
    switch (columnTemplate) {
      case 'sidebar':
        return buildSidebarColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'hero':
        return buildHeroColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'grid':
        return buildGridColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'card':
        return buildCardColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'compact':
        return buildCompactColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'featured':
        return buildFeaturedColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'overlay':
        return buildOverlayColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'magazine':
        return buildMagazineColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'split':
        return buildSplitColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'banner':
        return buildBannerColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'avatar':
        return buildAvatarColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'icon':
        return buildIconColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
      case 'standard':
      default:
        return buildStandardColumnTemplate(
          theme: theme,
          columns: columns,
          columnStyle: columnStyle,
          docDir: docDir,
          gap: gap,
        );
    }
  }

  Widget _buildColumnContent(
    ThemeData theme,
    Map<String, dynamic> column,
    int index,
    String columnStyle,
  ) {
    final imagePath = column['imagePath'] as String?;

    // Check if image exists and is valid
    bool hasImage = false;
    if (imagePath != null && imagePath.isNotEmpty && docDir != null) {
      final file = File('${docDir!.path}/$imagePath');
      hasImage = file.existsSync();
    }

    BoxDecoration decoration;
    switch (columnStyle) {
      case 'elevated':
        decoration = BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        );
        break;
      case 'outlined':
        decoration = BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        );
        break;
      case 'filled':
        decoration = BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        );
        break;
      default:
        decoration = BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        );
    }

    Widget imagePlaceholder() => Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 36))),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File('${docDir!.path}/$imagePath'),
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    imagePlaceholder(),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            imagePlaceholder(),
            const SizedBox(height: 12),
          ],
          MarkdownBody(
            data: column['content']?.toString() ?? '',
            styleSheet: MarkdownStyleSheet(
              p: theme.textTheme.bodyMedium,
              strong: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              em: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              code: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
