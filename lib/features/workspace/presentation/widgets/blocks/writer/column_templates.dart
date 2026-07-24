import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Column template styles for the columns block.
/// 
/// Provides different visual templates for displaying columns:
/// - standard: Equal width columns (default)
/// - sidebar: Narrow sidebar + wide content layout
/// - hero: One large featured column with smaller ones
/// - grid: Equal height card-style boxes
/// - card: Column items displayed as cards

/// Standard equal-width column template (default).
/// All columns have equal width with consistent spacing.
/// Best for: Equal importance content, balanced layouts, feature comparisons
Widget buildStandardColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final width = (column['width'] as num?)?.toDouble() ?? (1.0 / columns.length);
      
      return Expanded(
        flex: (width * 100).toInt(),
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap / 2 : 0,
            left: index > 0 ? gap / 2 : 0,
          ),
          child: _buildColumnContent(theme, column, columnStyle, docDir),
        ),
      );
    }),
  );
}

/// Sidebar column template with narrow sidebar and wide content.
/// First column is narrower (30%), rest share remaining space.
/// Best for: Navigation menus, table of contents, filters + main content
Widget buildSidebarColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      // First column gets 30%, rest evenly share 70%
      // For single column, use 100%
      final flex = columns.length == 1 
        ? 100 
        : (index == 0 ? 30 : (70.0 / (columns.length - 1)).round());
      
      return Expanded(
        flex: flex,
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: _buildColumnContent(theme, column, columnStyle, docDir),
        ),
      );
    }),
  );
}

/// Hero column template with one large featured column.
/// First column takes 60%, others share 40%.
/// Best for: Main content + sidebar details, article + related items
Widget buildHeroColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      // First column gets 60%, rest evenly share 40%
      // For single column, use 100%
      final flex = columns.length == 1 
        ? 100 
        : (index == 0 ? 60 : (40.0 / (columns.length - 1)).round());
      
      return Expanded(
        flex: flex,
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: index == 0 
              ? _getHeroDecoration(theme, columnStyle)
              : _getColumnDecoration(theme, columnStyle),
            child: _buildRawColumnContent(theme, column, docDir),
          ),
        ),
      );
    }),
  );
}

/// Grid column template with equal-height card boxes.
/// All columns displayed as uniform grid items.
/// Best for: Dashboards, pricing tables, feature grids
Widget buildGridColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _getGridDecoration(theme, columnStyle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                MarkdownBody(
                  data: column['content']?.toString() ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

/// Card column template with columns as individual cards.
/// Each column displayed as a prominent card with shadow.
/// Best for: Product showcases, team members, service offerings
Widget buildCardColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Card(
            elevation: columnStyle == 'elevated' ? 6 : 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: columnStyle == 'outlined'
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
            ),
            color: columnStyle == 'filled' 
              ? theme.colorScheme.surfaceContainerHighest 
              : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.tertiaryContainer,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: MarkdownBody(
                    data: column['content']?.toString() ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

// Helper methods

Widget _buildColumnContent(ThemeData theme, Map<String, dynamic> column, String columnStyle, Directory? docDir) {
  final imagePath = column['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  Widget imagePlaceholder() => Container(
    width: double.infinity,
    height: 120,
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 40))),
  );
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: _getColumnDecoration(theme, columnStyle),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => imagePlaceholder(),
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
            strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRawColumnContent(ThemeData theme, Map<String, dynamic> column, Directory? docDir) {
  final imagePath = column['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  Widget imagePlaceholder() => Container(
    width: double.infinity,
    height: 120,
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 40))),
  );
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (hasImage) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File('${docDir.path}/$imagePath'),
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => imagePlaceholder(),
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
          strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    ],
  );
}

BoxDecoration _getColumnDecoration(ThemeData theme, String columnStyle) {
  switch (columnStyle) {
    case 'elevated':
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      );
    case 'outlined':
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      );
    case 'filled':
      return BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      );
    default:
      return BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      );
  }
}

BoxDecoration _getHeroDecoration(ThemeData theme, String columnStyle) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primaryContainer,
        theme.colorScheme.secondaryContainer,
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    border: columnStyle == 'outlined'
      ? Border.all(color: theme.colorScheme.outline, width: 2)
      : null,
  );
}

BoxDecoration _getGridDecoration(ThemeData theme, String columnStyle) {
  switch (columnStyle) {
    case 'elevated':
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      );
    case 'outlined':
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      );
    case 'filled':
      return BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      );
    default:
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      );
  }
}

/// Compact column template with minimal spacing.
/// Columns displayed compactly with reduced padding.
/// Best for: Dense information, space-efficient layouts, data tables
Widget buildCompactColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: _getColumnDecoration(theme, columnStyle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                MarkdownBody(
                  data: column['content']?.toString() ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodySmall,
                    strong: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    em: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    code: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

/// Featured column template with prominent first column.
/// First column highlighted with star icon and gradient.
/// Best for: Highlighting main content, featured items, primary information
Widget buildFeaturedColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      final isFeatured = index == 0;
      
      return Expanded(
        flex: isFeatured ? 60 : (40 ~/ (columns.length - 1)),
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: isFeatured
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : _getColumnDecoration(theme, columnStyle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFeatured) ...[
                  Icon(Icons.star, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(height: 12),
                ],
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: isFeatured ? 150 : 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                MarkdownBody(
                  data: column['content']?.toString() ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: isFeatured
                        ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)
                        : theme.textTheme.bodyMedium,
                    strong: (isFeatured ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
                        ?.copyWith(fontWeight: FontWeight.bold),
                    em: (isFeatured ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
                        ?.copyWith(fontStyle: FontStyle.italic),
                    code: (isFeatured ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

/// Overlay column template with overlaid text on gradient.
/// Best for: Eye-catching designs, promotional content, hero sections
Widget buildOverlayColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              if (hasImage)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: MarkdownBody(
                    data: column['content']?.toString() ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      strong: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      em: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      code: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

/// Magazine column template with image-first layout.
/// Best for: Editorial content, articles, blog posts
Widget buildMagazineColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (hasImage) const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _getColumnDecoration(theme, columnStyle),
                  child: MarkdownBody(
                    data: column['content']?.toString() ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium,
                      strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

/// Split column template with divider between columns.
/// Best for: Comparing content, before/after, pros/cons
Widget buildSplitColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length * 2 - 1, (index) {
      if (index.isOdd) {
        // Divider
        return Container(
          width: 3,
          height: 200,
          margin: EdgeInsets.symmetric(horizontal: gap / 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.3),
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }
      
      final columnIndex = index ~/ 2;
      final column = columns[columnIndex] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _getColumnDecoration(theme, columnStyle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File('${docDir.path}/$imagePath'),
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              MarkdownBody(
                data: column['content']?.toString() ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium,
                  strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

/// Banner column template with gradient background.
/// Best for: Announcements, promotions, call-to-actions
Widget buildBannerColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.tertiary,
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(columns.length, (index) {
        final column = columns[index] as Map<String, dynamic>;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < columns.length - 1 ? gap : 0,
            ),
            child: MarkdownBody(
              data: column['content']?.toString() ?? '',
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                strong: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                em: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                code: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                textAlign: WrapAlignment.center,
              ),
            ),
          ),
        );
      }),
    ),
  );
}

/// Avatar column template with circular avatars.
/// Best for: Team members, user profiles, contact lists
Widget buildAvatarColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _getColumnDecoration(theme, columnStyle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasImage)
                  ClipOval(
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer),
                  ),
                const SizedBox(height: 12),
                MarkdownBody(
                  data: column['content']?.toString() ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium,
                    strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    textAlign: WrapAlignment.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

/// Icon column template with circular icon badges.
/// Best for: Features, services, benefits, quick info
Widget buildIconColumnTemplate({
  required ThemeData theme,
  required List columns,
  required String columnStyle,
  required Directory? docDir,
  required double gap,
}) {
  final icons = [Icons.star, Icons.favorite, Icons.lightbulb, Icons.rocket_launch];
  
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(columns.length, (index) {
      final column = columns[index] as Map<String, dynamic>;
      final imagePath = column['imagePath'] as String?;
      final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < columns.length - 1 ? gap : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _getColumnDecoration(theme, columnStyle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Icon(
                      icons[index % icons.length],
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 12),
                MarkdownBody(
                  data: column['content']?.toString() ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium,
                    strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    code: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    textAlign: WrapAlignment.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}
