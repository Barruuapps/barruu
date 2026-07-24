import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/constants/quote_types.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Reader widget for displaying block quote content with admonition support
class BlockQuoteReaderBlock extends ConsumerWidget {
  final Block block;
  final Directory? docDir;
  final bool allowSelection;

  const BlockQuoteReaderBlock({
    super.key,
    required this.block,
    this.docDir,
    this.allowSelection = true,
  });

  WrapAlignment _getWrapAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
        return WrapAlignment.start;
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.right:
        return WrapAlignment.end;
      case TextAlign.justify:
        return WrapAlignment.spaceBetween;
      default:
        return WrapAlignment.start;
    }
  }

  Widget _buildAvatar(String? avatarPath, double size, ThemeData theme, Directory? docDir) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if it's a network URL
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircleAvatar(
            radius: size / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const ShimmerInlineLoading(size: 20),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: size / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(Icons.person, size: size * 0.6),
          ),
        ),
      );
    }

    // Local file
    if (docDir != null) {
      final file = File('${docDir.path}/$avatarPath');
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => CircleAvatar(
              radius: size / 2,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.person, size: size * 0.6),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final quoteType = block.style.quoteType ?? 'quote';
    final quoteTemplate = block.style.quoteTemplate ?? 'basic';
    final config = QuoteTypes.getConfig(quoteType);

    final fontSize = block.style.fontSize;
    
    // Use config colors unless user has customized them
    final borderColor = styleUtils.parseHex(block.style.borderColor) ?? 
                        config.getBorderColor(isDark);
    final backgroundColor = styleUtils.parseHex(block.style.background) ?? 
                           config.getBackgroundColor(isDark);
    final iconColor = config.getIconColor(isDark);
    final parsedColor = styleUtils.parseHex(block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;

    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    // Platform-aware padding using spacing constants
    final horizontalPadding = isDesktop 
        ? ResponsiveUtils.spacing20 
        : (isWide ? ResponsiveUtils.spacing16 : ResponsiveUtils.spacing8);
    final verticalPadding = isDesktop 
        ? ResponsiveUtils.spacing16 
        : (isWide ? ResponsiveUtils.spacing12 : ResponsiveUtils.spacing8);
    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
    final margin = EdgeInsets.symmetric(vertical: verticalMargin);
    final lineHeight = ResponsiveUtils.getLineHeight(context, baseHeight: 1.5);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    
    Map<String, dynamic> content = {'content': '', 'author': ''};
    try {
      if (block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(block.content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse block content', error: e, stackTrace: stackTrace);
    }

    final quoteText = content['content'] ?? '';
    final authorText = content['author'] ?? '';
    final hasAuthor = authorText.isNotEmpty;
    final authorAvatar = block.style.authorAvatar;

    final baseStyle = styleUtils.applyStyle(block.style).copyWith(
      fontSize: fontSize * textMultiplier,
      color: color,
      height: lineHeight,
    );

    final linkStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w500,
    );


    // Build the content widget based on quote template
    Widget contentWidget = _buildContentForTemplate(
      context,
      quoteTemplate,
      quoteType,
      quoteText,
      authorText,
      hasAuthor,
      authorAvatar,
      baseStyle,
      linkStyle,
      config,
      theme,
      borderColor,
      backgroundColor,
      iconColor,
      padding,
      margin,
      styleUtils,
      textMultiplier,
    );

    return contentWidget;
  }

  Widget _buildContentForTemplate(
    BuildContext context,
    String template,
    String quoteType,
    String quoteText,
    String authorText,
    bool hasAuthor,
    String? authorAvatar,
    TextStyle baseStyle,
    TextStyle linkStyle,
    dynamic config,
    ThemeData theme,
    Color borderColor,
    Color backgroundColor,
    Color iconColor,
    EdgeInsets padding,
    EdgeInsets margin,
    dynamic styleUtils,
    double textMultiplier,
  ) {
    final quoteContent = _buildQuoteContent(
      quoteType,
      quoteText,
      baseStyle,
      linkStyle,
      styleUtils,
    );

    final authorWidget = hasAuthor
        ? _buildAuthorWidget(authorText, authorAvatar, theme, textMultiplier)
        : const SizedBox.shrink();

    switch (template) {
      case 'basic':
        return _buildBasicTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          quoteType,
          config,
          theme,
          borderColor,
          backgroundColor,
          iconColor,
          padding,
          margin,
          styleUtils,
          textMultiplier,
        );
      case 'bordered':
        return _buildBorderedTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          quoteType,
          config,
          theme,
          borderColor,
          backgroundColor,
          iconColor,
          padding,
          margin,
          textMultiplier,
        );
      case 'highlighted':
        return _buildHighlightedTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          theme,
          borderColor,
          padding,
          margin,
        );
      case 'modern':
        return _buildModernTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          quoteType,
          config,
          theme,
          borderColor,
          iconColor,
          padding,
          margin,
        );
      case 'testimonial':
        return _buildTestimonialTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          theme,
          borderColor,
          padding,
          margin,
        );
      case 'callout':
        return _buildCalloutTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          theme,
          borderColor,
          padding,
          margin,
        );
      case 'sidebar':
        return _buildSidebarTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          quoteType,
          config,
          theme,
          borderColor,
          padding,
          margin,
        );
      case 'featured':
        return _buildFeaturedTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          quoteType,
          config,
          theme,
          borderColor,
          iconColor,
          padding,
          margin,
        );
      case 'card':
        return _buildCardTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          theme,
          borderColor,
          padding,
          margin,
        );
      default:
        return _buildBasicTemplate(
          context,
          quoteContent,
          authorWidget,
          hasAuthor,
          quoteType,
          config,
          theme,
          borderColor,
          backgroundColor,
          iconColor,
          padding,
          margin,
          styleUtils,
          textMultiplier,
        );
    }
  }

  Widget _buildQuoteContent(
    String quoteType,
    String quoteText,
    TextStyle baseStyle,
    TextStyle linkStyle,
    dynamic styleUtils,
  ) {
    if (quoteType == 'quote') {
      return Semantics(
        label: 'Block quote text',
        child: MarkdownBody(
          data: quoteText,
          styleSheet: MarkdownStyleSheet(
            p: baseStyle.copyWith(fontStyle: FontStyle.italic),
            strong: baseStyle.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            em: baseStyle.copyWith(fontStyle: FontStyle.italic),
            a: linkStyle.copyWith(fontStyle: FontStyle.italic),
            code: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: linkStyle.backgroundColor,
            ),
            listBullet: baseStyle.copyWith(fontStyle: FontStyle.italic),
            textAlign: _getWrapAlignment(styleUtils.textAlignFromStyle(block.style)),
          ),
          selectable: allowSelection,
          onTapLink: (text, href, title) async {
            if (href != null) {
              await LinkUtils.launchURL(href);
            }
          },
        ),
      );
    } else {
      return Semantics(
        label: 'Message',
        child: MarkdownBody(
          data: quoteText,
          styleSheet: MarkdownStyleSheet(
            p: baseStyle,
            strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
            em: baseStyle.copyWith(fontStyle: FontStyle.italic),
            a: linkStyle,
            code: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: linkStyle.backgroundColor,
            ),
            listBullet: baseStyle,
            h1: baseStyle.copyWith(fontSize: baseStyle.fontSize! * 1.3, fontWeight: FontWeight.bold),
            h2: baseStyle.copyWith(fontSize: baseStyle.fontSize! * 1.2, fontWeight: FontWeight.bold),
            h3: baseStyle.copyWith(fontSize: baseStyle.fontSize! * 1.1, fontWeight: FontWeight.bold),
            textAlign: _getWrapAlignment(styleUtils.textAlignFromStyle(block.style)),
          ),
          selectable: allowSelection,
          onTapLink: (text, href, title) async {
            if (href != null) {
              await LinkUtils.launchURL(href);
            }
          },
        ),
      );
    }
  }

  Widget _buildAuthorWidget(String authorText, String? authorAvatar, ThemeData theme, double textMultiplier) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (authorAvatar != null && authorAvatar.isNotEmpty) ...[
            _buildAvatar(authorAvatar, 24, theme, docDir),
            const SizedBox(width: 6),
          ],
          Text(
            '— $authorText',
            style: TextStyle(
              fontSize: 12 * textMultiplier,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    String quoteType,
    dynamic config,
    ThemeData theme,
    Color borderColor,
    Color backgroundColor,
    Color iconColor,
    EdgeInsets padding,
    EdgeInsets margin,
    dynamic styleUtils,
    double textMultiplier,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 8.0),
        ),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: PlatformThemeHelper.isAndroid ? 4.0 : 3.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quoteType != 'quote' && block.style.showIcon) ...[
            Row(
              children: [
                Icon(
                  config.icon,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 20.0),
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  config.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14 * textMultiplier,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (quoteType == 'quote') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  color: borderColor.withValues(alpha: 0.5),
                  size: ResponsiveUtils.getIconSize(context),
                ),
                const SizedBox(width: 12),
                Expanded(child: quoteContent),
              ],
            ),
          ] else ...[
            quoteContent,
          ],
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildBorderedTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    String quoteType,
    dynamic config,
    ThemeData theme,
    Color borderColor,
    Color backgroundColor,
    Color iconColor,
    EdgeInsets padding,
    EdgeInsets margin,
    double textMultiplier,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 24,
            color: borderColor,
          ),
          const SizedBox(height: 6),
          quoteContent,
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    ThemeData theme,
    Color borderColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quoteContent,
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildModernTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    String quoteType,
    dynamic config,
    ThemeData theme,
    Color borderColor,
    Color iconColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quoteType != 'quote') ...[
                  Icon(config.icon, size: 20, color: iconColor),
                  const SizedBox(height: 6),
                ],
                quoteContent,
                if (hasAuthor) ...[
                  authorWidget,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    ThemeData theme,
    Color borderColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 28,
            color: borderColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 6),
          quoteContent,
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildCalloutTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    ThemeData theme,
    Color borderColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Note',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          quoteContent,
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    String quoteType,
    dynamic config,
    ThemeData theme,
    Color borderColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      margin: margin,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quoteType == 'quote')
                      Icon(
                        Icons.format_quote,
                        size: 20,
                        color: borderColor,
                      ),
                    if (quoteType == 'quote') const SizedBox(height: 6),
                    quoteContent,
                    if (hasAuthor) ...[
                      authorWidget,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    String quoteType,
    dynamic config,
    ThemeData theme,
    Color borderColor,
    Color iconColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.3),
            theme.colorScheme.tertiary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 24,
                color: borderColor,
              ),
              const SizedBox(width: 12),
              if (quoteType != 'quote')
                Text(
                  config.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: iconColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          quoteContent,
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildCardTemplate(
    BuildContext context,
    Widget quoteContent,
    Widget authorWidget,
    bool hasAuthor,
    ThemeData theme,
    Color borderColor,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote,
              size: 24,
              color: borderColor,
            ),
          ),
          const SizedBox(height: 12),
          quoteContent,
          if (hasAuthor) ...[
            authorWidget,
          ],
        ],
      ),
    );
  }
}
