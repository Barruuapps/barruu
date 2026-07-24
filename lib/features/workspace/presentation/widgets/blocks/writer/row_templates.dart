import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Row template styles for the rows block.
///
/// Provides different visual templates for displaying rows:
/// - standard: Horizontal layout with optional images (default)
/// - stacked: Vertical compact layout
/// - highlight: Rows with background emphasis
/// - timeline: Vertical layout with connector lines
/// - feature: Large prominent row design

/// Standard horizontal row template (default).
/// Content displayed horizontally with optional images.
/// Best for: General content cards, feature lists, product showcases
Widget buildStandardRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  Widget stdPlaceholder() => Container(
    width: double.infinity,
    height: 100,
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 36))),
  );
  return Container(
    width: 220,
    padding: const EdgeInsets.all(16),
    decoration: _getRowDecoration(theme, rowStyle),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => stdPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          stdPlaceholder(),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
          ),
        ),
      ],
    ),
  );
}

/// Stacked vertical row template.
/// Compact horizontal layout for space efficiency.
/// Best for: Lists with images, news items, compact summaries
Widget buildStackedRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: _getRowDecoration(theme, rowStyle),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
        ] else ...[
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.article_outlined,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: MarkdownBody(
            data: row['content']?.toString() ?? '',
            styleSheet: MarkdownStyleSheet(
              p: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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
        ),
      ],
    ),
  );
}

/// Highlight row template with emphasized background.
/// Rows with colored background for emphasis.
/// Best for: Important announcements, featured content, call-to-actions
Widget buildHighlightRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    width: 260,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
          theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: rowStyle == 'outlined'
          ? Border.all(color: theme.colorScheme.primary, width: 2)
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                strong: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                em: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontStyle: FontStyle.italic,
                ),
                code: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Timeline row template with connector lines.
/// Vertical layout with visual connectors between items.
/// Best for: Step-by-step processes, historical events, roadmaps
Widget buildTimelineRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
  required bool isFirst,
  required bool isLast,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator column
        SizedBox(
          width: 40,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                        theme.colorScheme.primary.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.6),
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 28),
            padding: const EdgeInsets.all(16),
            decoration: _getRowDecoration(theme, rowStyle),
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
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                MarkdownBody(
                  data: row['content']?.toString() ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
          ),
        ),
      ],
    ),
  );
}

/// Feature row template with large prominent design.
/// Large rows with emphasis for key content.
/// Best for: Hero sections, main features, key selling points
Widget buildFeatureRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    width: 340,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: rowStyle == 'filled'
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: rowStyle == 'outlined'
          ? Border.all(color: theme.colorScheme.outline, width: 2)
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.tertiaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                strong: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                em: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                code: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper methods

BoxDecoration _getRowDecoration(ThemeData theme, String rowStyle) {
  switch (rowStyle) {
    case 'elevated':
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      );
    case 'outlined':
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
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

double getRowHeightForTemplate(String template) {
  switch (template) {
    case 'stacked':
      return 110;
    case 'highlight':
      return 220;
    case 'timeline':
      return 220; // Base height per item, actual height varies
    case 'feature':
      return 320;
    case 'compact':
      return 120;
    case 'overlay':
      return 250;
    case 'magazine':
      return 180;
    case 'split':
      return 200;
    case 'banner':
      return 150;
    case 'avatar':
      return 180;
    case 'icon':
      return 160;
    case 'horizontal':
      return 200;
    case 'standard':
    default:
      return 200;
  }
}

/// Compact row template with minimal spacing.
/// Best for: Lists with many items, dense information displays
Widget buildCompactRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return LayoutBuilder(
    builder: (context, constraints) {
      final availH = constraints.maxHeight.isFinite
          ? constraints.maxHeight - 20
          : 80.0;
      return Container(
        width: 200,
        padding: const EdgeInsets.all(10),
        decoration: _getRowDecoration(theme, rowStyle),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File('${docDir.path}/$imagePath'),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: availH,
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: row['content']?.toString() ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                      strong: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      em: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      code: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Overlay row template with text overlaid on image.
/// Best for: Eye-catching designs, promotional content
Widget buildOverlayRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 240,
    height: 250,
    child: Stack(
      children: [
        Container(
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
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
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
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
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
  );
}

/// Magazine row template with side-by-side image and text.
/// Best for: Editorial content, articles, news items
Widget buildMagazineRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return LayoutBuilder(
    builder: (context, constraints) {
      final availH = constraints.maxHeight.isFinite
          ? constraints.maxHeight - 24
          : 140.0;
      return Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: _getRowDecoration(theme, rowStyle),
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
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            if (hasImage) const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: SizedBox(
                height: availH,
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: row['content']?.toString() ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
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
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Split row template with divided sections.
/// Best for: Comparing content, before/after displays
Widget buildSplitRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;
  final content = row['content']?.toString() ?? '';
  final parts = content.split('|');

  return SizedBox(
    width: 260,
    height: 200,
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File('${docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  parts.isNotEmpty ? parts[0] : content,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 3,
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
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                parts.length > 1 ? parts[1] : content,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Banner row template with gradient background.
/// Best for: Announcements, promotions, call-to-actions
Widget buildBannerRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    width: 280,
    height: 150,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: 100,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
        ),
      ],
    ),
  );
}

/// Avatar row template with circular profile images.
/// Best for: Team members, user profiles, testimonials
Widget buildAvatarRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    width: 200,
    padding: const EdgeInsets.all(16),
    decoration: _getRowDecoration(theme, rowStyle),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
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
            child: Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
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
                textAlign: WrapAlignment.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Icon row template with circular icon badges.
/// Best for: Features, benefits, services
Widget buildIconRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    width: 180,
    padding: const EdgeInsets.all(16),
    decoration: _getRowDecoration(theme, rowStyle),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
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
            child: Icon(Icons.star, size: 30, color: theme.colorScheme.primary),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: row['content']?.toString() ?? '',
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
                textAlign: WrapAlignment.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Horizontal row template with side-by-side layout.
/// Best for: Product showcases, image-heavy content
Widget buildHorizontalRowTemplate({
  required ThemeData theme,
  required Map<String, dynamic> row,
  required String rowStyle,
  required Directory? docDir,
  required double gap,
}) {
  final imagePath = row['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return LayoutBuilder(
    builder: (context, constraints) {
      final availH = constraints.maxHeight.isFinite
          ? constraints.maxHeight - 24
          : 152.0;
      return Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: _getRowDecoration(theme, rowStyle),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasImage)
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File('${docDir.path}/$imagePath'),
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              )
            else
              Expanded(
                flex: 3,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: availH,
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: row['content']?.toString() ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
