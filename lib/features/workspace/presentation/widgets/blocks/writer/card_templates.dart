import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/card_constants.dart';

/// Card template styles for the cards block.
///
/// Provides different visual templates for displaying cards:
/// - standard: Vertical layout with image on top (default)
/// - horizontal: Image on left, content on right
/// - compact: Minimal, space-efficient design
/// - featured: Large, prominent hero-style card
/// - overlay: Image background with text overlay on top
/// - magazine: Photo with prominent title underneath (editorial style)
/// - split: Image taking 60% with content on 40%
/// - banner: Wide card with full-width image and centered text overlay
/// - avatar: Circular avatar/profile card with centered image
/// - imageRight: Image on right, text on left (reverse horizontal)
/// - icon: Minimal icon-based card with colored background
/// - social: Social media style card with engagement metrics
/// - product: Product card with price and action button

/// Standard vertical card template (default).
/// Image on top, title and description below.
Widget buildStandardCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image or emoji header
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackHeader(theme, emoji),
            ),
          )
        else
          _buildFallbackHeader(theme, emoji),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
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
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Horizontal card template with image on the side.
Widget buildHorizontalCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 280,
    height: 140,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image or emoji section (left side)
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: 100,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCompactFallback(theme, emoji, 100),
            ),
          )
        else
          _buildCompactFallback(theme, emoji, 100),

        // Content section (right side)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 12,
                      ),
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
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Compact card template with minimal design.
Widget buildCompactCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final emoji = card['emoji'] as String? ?? '📄';

  return Container(
    width: 160,
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon/Emoji
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 12),

        // Title
        Text(
          card['title'] ?? 'Untitled',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Description
        MarkdownBody(
          data: card['description'] ?? '',
          styleSheet: MarkdownStyleSheet(
            p: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            strong: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            em: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            code: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    ),
  );
}

/// Featured card template with large prominent design.
Widget buildFeaturedCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large image or emoji header
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFeaturedFallback(theme, emoji),
            ),
          )
        else
          _buildFeaturedFallback(theme, emoji),

        // Content with extra padding
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
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
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Overlay card template with image background and text overlay.
/// Perfect for hero sections and promotional content.
Widget buildOverlayCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 280,
    height: 200,
    child: Stack(
      children: [
        // Background image or gradient
        if (hasImage)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File('${docDir.path}/$imagePath'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildGradientBackground(theme),
              ),
            ),
          )
        else
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildGradientBackground(theme),
            ),
          ),

        // Dark gradient overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ),

        // Text overlay at bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card['title'] ?? 'Untitled',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              MarkdownBody(
                data: card['description'] ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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
            ],
          ),
        ),
      ],
    ),
  );
}

/// Magazine-style card template with image and prominent text below.
/// Editorial design with large title underneath the image.
Widget buildMagazineCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 240,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large image
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildMagazineFallback(theme),
            ),
          )
        else
          _buildMagazineFallback(theme),

        // Content below with prominent title
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large prominent title
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Description
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        height: 1.4,
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
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Split card template with image taking 60% and content 40%.
/// Asymmetric layout for visual interest.
Widget buildSplitCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 300,
    height: 180,
    child: Row(
      children: [
        // Image section (60%)
        Expanded(
          flex: 6,
          child: hasImage
              ? ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: Image.file(
                    File('${docDir.path}/$imagePath'),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildSplitFallback(theme),
                  ),
                )
              : _buildSplitFallback(theme),
        ),

        // Content section (40%)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
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
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Banner card template with full-width image and centered text overlay.
/// Perfect for wide promotional banners.
Widget buildBannerCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle,
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 350,
    height: 140,
    child: Stack(
      children: [
        // Background image or gradient
        if (hasImage)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File('${docDir.path}/$imagePath'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildBannerFallback(theme),
              ),
            ),
          )
        else
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildBannerFallback(theme),
            ),
          ),

        // Semi-transparent overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),

        // Centered text
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: card['description'] ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
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
                    textAlign: WrapAlignment.center,
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

// Helper methods

Widget _buildFallbackHeader(ThemeData theme, String? emoji) {
  return Container(
    width: double.infinity,
    height: 100,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 40))
          : Icon(
              Icons.article_outlined,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildCompactFallback(ThemeData theme, String? emoji, double width) {
  return Container(
    width: width,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
    ),
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 32))
          : Icon(
              Icons.article_outlined,
              size: 32,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildFeaturedFallback(ThemeData theme, String? emoji) {
  return Container(
    width: double.infinity,
    height: 160,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 56))
          : Icon(
              Icons.article_outlined,
              size: 56,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildGradientBackground(ThemeData theme) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.8),
          theme.colorScheme.secondary.withValues(alpha: 0.8),
        ],
      ),
    ),
  );
}

Widget _buildMagazineFallback(ThemeData theme) {
  return Container(
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
      ),
    ),
  );
}

Widget _buildSplitFallback(ThemeData theme) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
    ),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
      ),
    ),
  );
}

Widget _buildBannerFallback(ThemeData theme) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
      ),
    ),
  );
}

/// Avatar/Profile card template with circular image.
/// Perfect for user profiles, team members, testimonials.
///
/// Note: The [cardStyle] parameter is used by the parent _buildCard function
/// to wrap this content with the appropriate card widget (elevated, outlined, or filled).
Widget buildAvatarCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle, // Used by parent wrapper, not internally
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return Container(
    width: 180,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular avatar
        if (hasImage)
          ClipOval(
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCircularFallback(theme, emoji, 80),
            ),
          )
        else
          _buildCircularFallback(theme, emoji, 80),

        const SizedBox(height: 12),

        // Title (name/username)
        Text(
          card['title'] ?? 'Untitled',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Description (role/bio)
        MarkdownBody(
          data: card['description'] ?? '',
          styleSheet: MarkdownStyleSheet(
            p: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            strong: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            em: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            code: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            textAlign: WrapAlignment.center,
          ),
        ),
      ],
    ),
  );
}

/// Image-right card template (reverse of horizontal).
/// Image on right, content on left.
///
/// Note: The [cardStyle] parameter is used by the parent _buildCard function
/// to wrap this content with the appropriate card widget (elevated, outlined, or filled).
Widget buildImageRightCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle, // Used by parent wrapper, not internally
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 280,
    height: 140,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Content section (left side)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 12,
                      ),
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
              ],
            ),
          ),
        ),

        // Image or emoji section (right side)
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: 100,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCompactFallbackRight(theme, emoji, 100),
            ),
          )
        else
          _buildCompactFallbackRight(theme, emoji, 100),
      ],
    ),
  );
}

/// Icon card template with large icon and colored background.
/// Minimal design perfect for features, services, categories.
///
/// Note: The [cardStyle] parameter is used by the parent _buildCard function
/// to wrap this content with the appropriate card widget (elevated, outlined, or filled).
Widget buildIconCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle, // Used by parent wrapper, not internally
  required Directory? docDir,
}) {
  final emoji = card['emoji'] as String? ?? kDefaultIconEmoji;

  return Container(
    width: 160,
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large icon/emoji with colored circle background
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 12),

        // Title
        Text(
          card['title'] ?? 'Untitled',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Description
        MarkdownBody(
          data: card['description'] ?? '',
          styleSheet: MarkdownStyleSheet(
            p: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            strong: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            em: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            code: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            textAlign: WrapAlignment.center,
          ),
        ),
      ],
    ),
  );
}

/// Social media style card with engagement metrics placeholder.
/// Shows likes, comments, shares - perfect for social content.
///
/// Note: The [cardStyle] parameter is used by the parent _buildCard function
/// to wrap this content with the appropriate card widget (elevated, outlined, or filled).
Widget buildSocialCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle, // Used by parent wrapper, not internally
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image header
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildSocialFallback(theme, emoji),
            ),
          )
        else
          _buildSocialFallback(theme, emoji),

        // Content
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card['title'] ?? 'Untitled',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              MarkdownBody(
                data: card['description'] ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
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
              const SizedBox(height: 8),

              // Social metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(theme, kDefaultLikeIcon, '0'),
                  _buildMetric(theme, kDefaultCommentIcon, '0'),
                  _buildMetric(theme, kDefaultShareIcon, '0'),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Product card template with price and action button.
/// Perfect for e-commerce, services, pricing.
///
/// Note: The [cardStyle] parameter is used by the parent _buildCard function
/// to wrap this content with the appropriate card widget (elevated, outlined, or filled).
Widget buildProductCardTemplate({
  required ThemeData theme,
  required Map<String, dynamic> card,
  required String cardStyle, // Used by parent wrapper, not internally
  required Directory? docDir,
}) {
  final imagePath = card['imagePath'] as String?;
  final emoji = card['emoji'] as String?;
  final hasImage = imagePath != null && imagePath.isNotEmpty && docDir != null;

  return SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File('${docDir.path}/$imagePath'),
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildProductFallback(theme, emoji),
            ),
          )
        else
          _buildProductFallback(theme, emoji),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  card['title'] ?? 'Untitled',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Expanded(
                  child: MarkdownBody(
                    data: card['description'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 11,
                      ),
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

                const SizedBox(height: 8),

                // Price and button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      kDefaultProductPrice,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Additional helper methods

Widget _buildCircularFallback(ThemeData theme, String? emoji, double size) {
  return Container(
    width: size,
    height: size,
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
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: TextStyle(fontSize: size * 0.4))
          : Icon(
              Icons.person_outline,
              size: size * 0.5,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildCompactFallbackRight(
  ThemeData theme,
  String? emoji,
  double width,
) {
  return Container(
    width: width,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
    ),
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 32))
          : Icon(
              Icons.article_outlined,
              size: 32,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildSocialFallback(ThemeData theme, String? emoji) {
  return Container(
    width: double.infinity,
    height: 140,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.tertiaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 40))
          : Icon(
              Icons.image_outlined,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildProductFallback(ThemeData theme, String? emoji) {
  return Container(
    width: double.infinity,
    height: 120,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Center(
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 36))
          : Icon(
              Icons.shopping_bag_outlined,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
    ),
  );
}

Widget _buildMetric(ThemeData theme, String icon, String value) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(
        value,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    ],
  );
}
