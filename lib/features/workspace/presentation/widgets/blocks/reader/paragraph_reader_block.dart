import 'dart:io';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ParagraphReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final bool allowSelection;
  final Directory? docDir;

  const ParagraphReaderBlock({
    super.key,
    required this.block,
    this.allowSelection = true,
    this.docDir,
  });

  @override
  ConsumerState<ParagraphReaderBlock> createState() =>
      _ParagraphReaderBlockState();
}

class _ParagraphReaderBlockState extends ConsumerState<ParagraphReaderBlock> {
  bool _isHovering = false;

  // Standard side-image dimensions (image_left / image_right)
  static const double _sideImageWidth = 120.0;
  static const double _sideImageHeight = 90.0;

  // Float-image dimensions (image_float_left / image_float_right)
  // Slightly taller so the wrap-around effect is clearly visible
  static const double _floatImageWidth = 130.0;
  static const double _floatImageHeight = 140.0;
  static const double _floatImageGap = 12.0;

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

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);

    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;

    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Platform-aware padding using spacing constants
    final horizontalPadding = isDesktop
        ? ResponsiveUtils.spacing24
        : (isWide ? ResponsiveUtils.spacing16 : ResponsiveUtils.spacing8);
    final verticalPadding = isDesktop
        ? ResponsiveUtils.spacing12
        : (isWide ? ResponsiveUtils.spacing8 : ResponsiveUtils.spacing4);
    final padding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
    final margin = EdgeInsets.symmetric(vertical: verticalMargin);

    Map<String, dynamic> content = {'content': ''};
    try {
      if (widget.block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse block content',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading paragraph content: $e')),
        );
      }
    }

    final textContent = content['content'] ?? '';
    final imagePath = content['imagePath'] as String?;

    // Platform-specific typography (Apple: 17pt body, Android: 16pt body)
    final lineHeight = PlatformThemeHelper.isAndroid ? 1.5 : 1.29;
    final letterSpacing = PlatformThemeHelper.isAndroid ? 0.5 : -0.24;

    final baseStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(
          fontSize: fontSize * ResponsiveUtils.getTextSizeMultiplier(context),
          color: color,
          height: lineHeight,
          letterSpacing: letterSpacing,
        );

    final linkStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w500,
    );

    final markdownStyleSheet = MarkdownStyleSheet(
      p: baseStyle,
      strong: baseStyle.copyWith(
        fontWeight: PlatformThemeHelper.isAndroid
            ? FontWeight.w700
            : FontWeight.w600,
      ),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      a: linkStyle,
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      blockquote: baseStyle.copyWith(fontStyle: FontStyle.italic),
      listBullet: baseStyle,
      h1: baseStyle.copyWith(
        fontSize: fontSize * 1.5,
        fontWeight: FontWeight.bold,
      ),
      h2: baseStyle.copyWith(
        fontSize: fontSize * 1.3,
        fontWeight: FontWeight.bold,
      ),
      h3: baseStyle.copyWith(
        fontSize: fontSize * 1.2,
        fontWeight: FontWeight.bold,
      ),
      h4: baseStyle.copyWith(
        fontSize: fontSize * 1.1,
        fontWeight: FontWeight.bold,
      ),
      h5: baseStyle.copyWith(
        fontSize: fontSize * 1.05,
        fontWeight: FontWeight.bold,
      ),
      h6: baseStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
      textAlign: _getWrapAlignment(
        styleUtils.textAlignFromStyle(widget.block.style),
      ),
    );

    void onTapLink(String text, String? href, String title) async {
      if (href != null) {
        await LinkUtils.launchURL(href);
      }
    }

    final template = widget.block.style.paragraphTemplate ?? 'default';

    Widget body;
    switch (template) {
      case 'drop_cap':
        body = _buildDropCap(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      case 'image_left':
        body = _buildImageSide(
          context,
          theme,
          textContent,
          imagePath,
          imageOnLeft: true,
          baseStyle: baseStyle,
          markdownStyleSheet: markdownStyleSheet,
          onTapLink: onTapLink,
          padding: padding,
          margin: margin,
        );
        break;
      case 'image_right':
        body = _buildImageSide(
          context,
          theme,
          textContent,
          imagePath,
          imageOnLeft: false,
          baseStyle: baseStyle,
          markdownStyleSheet: markdownStyleSheet,
          onTapLink: onTapLink,
          padding: padding,
          margin: margin,
        );
        break;
      case 'image_float_left':
        body = _buildImageFloat(
          context,
          theme,
          textContent,
          imagePath,
          imageOnLeft: true,
          markdownStyleSheet: markdownStyleSheet,
          onTapLink: onTapLink,
          padding: padding,
          margin: margin,
        );
        break;
      case 'image_float_right':
        body = _buildImageFloat(
          context,
          theme,
          textContent,
          imagePath,
          imageOnLeft: false,
          markdownStyleSheet: markdownStyleSheet,
          onTapLink: onTapLink,
          padding: padding,
          margin: margin,
        );
        break;
      case 'zigzag':
        body = _buildZigzag(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      case 'note':
        body = _buildNote(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      case 'warning':
        body = _buildAdmonition(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
          icon: Icons.warning_amber_rounded,
          label: 'Warning',
          accentColor: const Color(0xFFF59E0B),
        );
        break;
      case 'success':
        body = _buildAdmonition(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
          icon: Icons.check_circle_outline_rounded,
          label: 'Success',
          accentColor: const Color(0xFF10B981),
        );
        break;
      case 'highlight':
        body = _buildHighlight(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      case 'pull_quote':
        body = _buildPullQuote(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      case 'quote_card':
        body = _buildQuoteCard(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      case 'centered':
        body = _buildCentered(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
        break;
      default:
        body = _buildDefault(
          context,
          theme,
          textContent,
          baseStyle,
          markdownStyleSheet,
          onTapLink,
          padding,
          margin,
        );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedOpacity(
        // Apple HIG: Very subtle hover (opacity change only, no shadows for text)
        opacity: _isHovering ? 0.92 : 1.0,
        duration: ResponsiveUtils.getPlatformAnimationDuration(),
        child: body,
      ),
    );
  }

  // ─── Template builders ────────────────────────────────────────────────────

  Widget _buildDefault(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
        color: styleUtils.parseHex(widget.block.style.background),
      ),
      child: MarkdownBody(
        data: textContent,
        styleSheet: sheet,
        selectable: widget.allowSelection,
        onTapLink: onTapLink,
      ),
    );
  }

  /// Drop cap: first letter displayed large, spanning ~2 lines.
  Widget _buildDropCap(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    if (textContent.isEmpty) {
      return _buildDefault(
        context,
        theme,
        textContent,
        baseStyle,
        sheet,
        onTapLink,
        padding,
        margin,
      );
    }

    final firstChar = textContent.substring(0, 1);
    final rest = textContent.substring(firstChar.length);
    final dropCapSize = (baseStyle.fontSize ?? 18.0) * 2.8;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
        color: styleUtils.parseHex(widget.block.style.background),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop cap letter
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            child: Text(
              firstChar,
              style: baseStyle.copyWith(
                fontSize: dropCapSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                height: 0.85,
              ),
            ),
          ),
          // Remaining text
          Expanded(
            child: MarkdownBody(
              data: rest,
              styleSheet: sheet,
              selectable: widget.allowSelection,
              onTapLink: onTapLink,
            ),
          ),
        ],
      ),
    );
  }

  /// Image on one side with text on the other side.
  Widget _buildImageSide(
    BuildContext context,
    ThemeData theme,
    String textContent,
    String? imagePath, {
    required bool imageOnLeft,
    required TextStyle baseStyle,
    required MarkdownStyleSheet markdownStyleSheet,
    required Function(String, String?, String) onTapLink,
    required EdgeInsets padding,
    required EdgeInsets margin,
  }) {
    final styleUtils = ref.read(styleUtilsProvider);
    final imageWidget = _resolveImage(imagePath, theme);
    final textWidget = Expanded(
      child: MarkdownBody(
        data: textContent,
        styleSheet: markdownStyleSheet,
        selectable: widget.allowSelection,
        onTapLink: onTapLink,
      ),
    );

    final children = imageOnLeft
        ? <Widget>[imageWidget, const SizedBox(width: 12), textWidget]
        : <Widget>[textWidget, const SizedBox(width: 12), imageWidget];

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
        color: styleUtils.parseHex(widget.block.style.background),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Image floated to one side; text flows beside the image AND continues
  /// below it at full width (CSS-float approximation using Stack layout).
  Widget _buildImageFloat(
    BuildContext context,
    ThemeData theme,
    String textContent,
    String? imagePath, {
    required bool imageOnLeft,
    required MarkdownStyleSheet markdownStyleSheet,
    required Function(String, String?, String) onTapLink,
    required EdgeInsets padding,
    required EdgeInsets margin,
  }) {
    final styleUtils = ref.read(styleUtilsProvider);
    final imageWidget = _resolveImageSized(
      imagePath,
      theme,
      _floatImageWidth,
      _floatImageHeight,
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
        color: styleUtils.parseHex(widget.block.style.background),
      ),
      child: Stack(
        children: [
          // Text fills the full width, with padding on the image side.
          // The padding creates room beside the image while text extends
          // freely below it once the image height is passed.
          Padding(
            padding: EdgeInsets.only(
              left: imageOnLeft ? _floatImageWidth + _floatImageGap : 0.0,
              right: imageOnLeft ? 0.0 : _floatImageWidth + _floatImageGap,
            ),
            child: MarkdownBody(
              data: textContent,
              styleSheet: markdownStyleSheet,
              selectable: widget.allowSelection,
              onTapLink: onTapLink,
            ),
          ),
          // Image anchored to the top corner
          Positioned(
            left: imageOnLeft ? 0.0 : null,
            right: imageOnLeft ? null : 0.0,
            top: 0.0,
            child: imageWidget,
          ),
        ],
      ),
    );
  }

  Widget _resolveImage(String? imagePath, ThemeData theme) {
    return _resolveImageSized(
      imagePath,
      theme,
      _sideImageWidth,
      _sideImageHeight,
    );
  }

  Widget _resolveImageSized(
    String? imagePath,
    ThemeData theme,
    double width,
    double height,
  ) {
    if (imagePath == null || imagePath.isEmpty) {
      return _imagePlaceholder(theme, width, height);
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => _imagePlaceholder(theme, width, height),
          errorWidget: (_, __, ___) => _imagePlaceholder(theme, width, height),
        ),
      );
    }

    if (widget.docDir != null) {
      final file = File('${widget.docDir!.path}/$imagePath');
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _imagePlaceholder(theme, width, height),
          ),
        );
      }
    }

    return _imagePlaceholder(theme, width, height);
  }

  Widget _imagePlaceholder(ThemeData theme, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  /// Paragraph surrounded by a decorative zigzag border.
  Widget _buildZigzag(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    final borderColor =
        styleUtils.parseHex(widget.block.style.borderColor) ??
        theme.colorScheme.primary;

    return Container(
      margin: margin,
      child: CustomPaint(
        painter: _ZigzagBorderPainter(
          color: borderColor,
          amplitude: 5.0,
          step: 10.0,
        ),
        child: Padding(
          padding: padding.add(const EdgeInsets.symmetric(vertical: 8)),
          child: Container(
            color: styleUtils.parseHex(widget.block.style.background),
            child: MarkdownBody(
              data: textContent,
              styleSheet: sheet,
              selectable: widget.allowSelection,
              onTapLink: onTapLink,
            ),
          ),
        ),
      ),
    );
  }

  /// Note/info box with a left accent border and a subtle background.
  Widget _buildNote(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    final accentColor =
        styleUtils.parseHex(widget.block.style.borderColor) ??
        theme.colorScheme.primary;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color:
            styleUtils.parseHex(widget.block.style.background) ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  'Note',
                  style: baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            MarkdownBody(
              data: textContent,
              styleSheet: sheet,
              selectable: widget.allowSelection,
              onTapLink: onTapLink,
            ),
          ],
        ),
      ),
    );
  }

  /// Paragraph with a soft gradient highlight background.
  Widget _buildHighlight(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    final hasCustomBg =
        styleUtils.parseHex(widget.block.style.background) != null;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: hasCustomBg
            ? null
            : LinearGradient(
                colors: [
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
                  theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
                ],
              ),
        color: hasCustomBg
            ? styleUtils.parseHex(widget.block.style.background)
            : null,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
      ),
      child: MarkdownBody(
        data: textContent,
        styleSheet: sheet,
        selectable: widget.allowSelection,
        onTapLink: onTapLink,
      ),
    );
  }

  /// Pull quote: text with large decorative quotation marks.
  Widget _buildPullQuote(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    final accentColor =
        styleUtils.parseHex(widget.block.style.borderColor) ??
        theme.colorScheme.primary;

    final quoteMarkStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 18.0) * 3.5,
      color: accentColor.withValues(alpha: 0.35),
      height: 0.8,
      fontWeight: FontWeight.bold,
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: styleUtils.parseHex(widget.block.style.background),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text('\u201C', style: quoteMarkStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MarkdownBody(
              data: textContent,
              styleSheet: MarkdownStyleSheet(
                p: baseStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: (baseStyle.fontSize ?? 18.0) * 1.1,
                ),
              ),
              selectable: widget.allowSelection,
              onTapLink: onTapLink,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text('\u201D', style: quoteMarkStyle),
          ),
        ],
      ),
    );
  }

  /// Shared admonition builder used by `note`, `warning`, `success`.
  Widget _buildAdmonition(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin, {
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    final styleUtils = ref.read(styleUtilsProvider);
    final resolvedAccent =
        styleUtils.parseHex(widget.block.style.borderColor) ?? accentColor;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color:
            styleUtils.parseHex(widget.block.style.background) ??
            resolvedAccent.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: resolvedAccent, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: resolvedAccent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: resolvedAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            MarkdownBody(
              data: textContent,
              styleSheet: sheet,
              selectable: widget.allowSelection,
              onTapLink: onTapLink,
            ),
          ],
        ),
      ),
    );
  }

  /// Elevated card-style quote with a thick top divider.
  Widget _buildQuoteCard(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    final accentColor =
        styleUtils.parseHex(widget.block.style.borderColor) ??
        theme.colorScheme.primary;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color:
            styleUtils.parseHex(widget.block.style.background) ??
            theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 12.0),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thick top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 22,
                  color: accentColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MarkdownBody(
                    data: textContent,
                    styleSheet: MarkdownStyleSheet(
                      p: baseStyle.copyWith(fontStyle: FontStyle.italic),
                    ),
                    selectable: widget.allowSelection,
                    onTapLink: onTapLink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Centered text with thin ornamental rules above and below.
  Widget _buildCentered(
    BuildContext context,
    ThemeData theme,
    String textContent,
    TextStyle baseStyle,
    MarkdownStyleSheet sheet,
    Function(String, String?, String) onTapLink,
    EdgeInsets padding,
    EdgeInsets margin,
  ) {
    final styleUtils = ref.read(styleUtilsProvider);
    final rulerColor =
        styleUtils.parseHex(widget.block.style.borderColor) ??
        theme.colorScheme.primary.withValues(alpha: 0.4);

    final centeredSheet = MarkdownStyleSheet(
      p: baseStyle.copyWith(
        letterSpacing: (baseStyle.letterSpacing ?? 0) + 0.3,
      ),
      textAlign: WrapAlignment.center,
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPlatformRadius(context, baseRadius: 10.0),
        ),
        color: styleUtils.parseHex(widget.block.style.background),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top ornamental rule
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 24, height: 1, color: rulerColor),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: rulerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 24, height: 1, color: rulerColor),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: textContent,
            styleSheet: centeredSheet,
            selectable: widget.allowSelection,
            onTapLink: onTapLink,
          ),
          const SizedBox(height: 10),
          // Bottom ornamental rule (mirrored)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 24, height: 1, color: rulerColor),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: rulerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 24, height: 1, color: rulerColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Custom painter for zigzag border ─────────────────────────────────────────

class _ZigzagBorderPainter extends CustomPainter {
  final Color color;
  final double amplitude;
  final double step;

  const _ZigzagBorderPainter({
    required this.color,
    this.amplitude = 5.0,
    this.step = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

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
      oldDelegate.color != color ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.step != step;
}
