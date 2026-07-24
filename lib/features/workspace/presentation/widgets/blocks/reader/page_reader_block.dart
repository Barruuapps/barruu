import 'dart:io';

import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/services/page_icon_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Reader widget for page blocks. Displays the block with all saved styles
/// (bold, italic, underline, strikethrough, alignment, text/background/border
/// colour, font size, font family, display style, custom icon) and navigates
/// to the linked page when tapped.
class PageReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;

  const PageReaderBlock({super.key, required this.block, required this.docDir});

  @override
  ConsumerState<PageReaderBlock> createState() => _PageReaderBlockState();
}

class _PageReaderBlockState extends ConsumerState<PageReaderBlock> {
  Map<String, dynamic> content = {'pageId': '', 'title': ''};

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  void _parseContent() {
    try {
      if (widget.block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse page block content',
        error: e,
        stackTrace: stackTrace,
      );
      content = {'pageId': '', 'title': ''};
    }
  }

  @override
  void didUpdateWidget(PageReaderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      _parseContent();
    }
  }

  void _navigateToPage() {
    final pageId = content['pageId']?.toString() ?? '';
    if (pageId.isEmpty) return;

    final currentPageId = ref.read(currentPageIdProvider(widget.docDir.path));
    final stack = ref.read(pageNavigationStackProvider(widget.docDir.path));
    ref.read(pageNavigationStackProvider(widget.docDir.path).notifier).state = [
      ...stack,
      currentPageId,
    ];
    ref.read(currentPageIdProvider(widget.docDir.path).notifier).state = pageId;
  }

  /// Build [TextDecoration] from the block style's underline / strikethrough flags.
  TextDecoration? _buildDecoration(BlockStyle blockStyle) {
    if (blockStyle.underline && blockStyle.strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    } else if (blockStyle.underline) {
      return TextDecoration.underline;
    } else if (blockStyle.strikethrough) {
      return TextDecoration.lineThrough;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final blockStyle = widget.block.style;
    final pageTitle = content['title']?.toString() ?? 'Untitled';
    final hasLink = content['pageId']?.toString().isNotEmpty == true;
    final displayStyle = blockStyle.displayStyle ?? 'card';
    final showIcon = blockStyle.showIcon;

    switch (displayStyle) {
      case 'button':
        return _buildButtonStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'compact':
        return _buildCompactStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'minimal':
        return _buildMinimalStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'banner':
        return _buildBannerStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'sidebar':
        return _buildSidebarStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'floating':
        return _buildFloatingStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'gradient':
        return _buildGradientStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'outlined':
        return _buildOutlinedStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'hero':
        return _buildHeroStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
      case 'card':
      default:
        return _buildCardStyle(
          theme,
          styleUtils,
          blockStyle,
          pageTitle,
          hasLink,
          showIcon,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Card
  // ---------------------------------------------------------------------------

  Widget _buildCardStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      color: hasLink
          ? (styleUtils.parseHex(blockStyle.color) ??
                theme.colorScheme.onSurface)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Use full opacity when user sets an explicit background color
                (styleUtils.parseHex(blockStyle.background) != null)
                    ? styleUtils
                          .parseHex(blockStyle.background)!
                          .withOpacity(hasLink ? 0.85 : 0.5)
                    : theme.colorScheme.primaryContainer.withValues(
                        alpha: hasLink ? 0.2 : 0.08,
                      ),
                (styleUtils.parseHex(blockStyle.background) != null)
                    ? styleUtils
                          .parseHex(blockStyle.background)!
                          .withOpacity(hasLink ? 0.65 : 0.3)
                    : theme.colorScheme.primaryContainer.withValues(
                        alpha: hasLink ? 0.05 : 0.02,
                      ),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasLink
                  ? (styleUtils.parseHex(blockStyle.borderColor) ??
                        theme.colorScheme.primary.withValues(alpha: 0.4))
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (showIcon) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: hasLink ? 0.15 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasLink
                        ? getPageIcon(blockStyle.customIcon)
                        : IconsaxPlusLinear.link_circle,
                    color: hasLink
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pageTitle, style: titleStyle, textAlign: textAlign),
                    if (!hasLink)
                      Text(
                        'Page not linked',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasLink)
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Button
  // ---------------------------------------------------------------------------

  Widget _buildButtonStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final titleStyle = TextStyle(
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      decoration: _buildDecoration(blockStyle),
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasLink ? _navigateToPage : null,
        icon: showIcon
            ? Icon(getPageIcon(blockStyle.customIcon), size: 20)
            : const SizedBox.shrink(),
        label: Text(pageTitle, style: titleStyle),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasLink
              ? (styleUtils.parseHex(blockStyle.background) ??
                    theme.colorScheme.primary)
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: hasLink
              ? (styleUtils.parseHex(blockStyle.color) ??
                    theme.colorScheme.onPrimary)
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact
  // ---------------------------------------------------------------------------

  Widget _buildCompactStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: hasLink
          ? (styleUtils.parseHex(blockStyle.color) ??
                theme.colorScheme.onSurface)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w500,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: hasLink
                ? (styleUtils.parseHex(blockStyle.background) ??
                      theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.15,
                      ))
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasLink
                  ? (styleUtils.parseHex(blockStyle.borderColor) ??
                        theme.colorScheme.primary.withValues(alpha: 0.4))
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (showIcon) ...[
                Icon(
                  getPageIcon(blockStyle.customIcon),
                  color: hasLink
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(pageTitle, style: titleStyle, textAlign: textAlign),
              ),
              if (hasLink)
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Minimal
  // ---------------------------------------------------------------------------

  Widget _buildMinimalStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    // Minimal always shows underline; add strikethrough if also set
    final TextDecoration decoration = blockStyle.strikethrough
        ? TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ])
        : TextDecoration.underline;

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: hasLink
          ? (styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.primary)
          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w500,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: hasLink ? decoration : null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              if (showIcon) ...[
                Icon(
                  getPageIcon(blockStyle.customIcon),
                  color: hasLink
                      ? (styleUtils.parseHex(blockStyle.color) ??
                            theme.colorScheme.primary)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(pageTitle, style: titleStyle, textAlign: textAlign),
              ),
              if (hasLink)
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color:
                      styleUtils.parseHex(blockStyle.color) ??
                      theme.colorScheme.primary,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  Widget _buildBannerStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final bg =
        styleUtils.parseHex(blockStyle.background) ?? theme.colorScheme.primary;
    final fg =
        styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onPrimary;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: hasLink ? fg : fg.withOpacity(0.5),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w700,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
      decorationColor: fg,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: hasLink ? bg : bg.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showIcon) ...[
                Icon(getPageIcon(blockStyle.customIcon), color: fg, size: 22),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(pageTitle, style: titleStyle, textAlign: textAlign),
              ),
              if (hasLink) ...[
                const SizedBox(width: 8),
                Icon(IconsaxPlusLinear.arrow_right_3, color: fg, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  Widget _buildSidebarStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final accentColor =
        styleUtils.parseHex(blockStyle.borderColor) ??
        theme.colorScheme.primary;
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: hasLink
          ? (styleUtils.parseHex(blockStyle.color) ??
                theme.colorScheme.onSurface)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      if (showIcon) ...[
                        Icon(
                          getPageIcon(blockStyle.customIcon),
                          color: accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          pageTitle,
                          style: titleStyle,
                          textAlign: textAlign,
                        ),
                      ),
                      if (hasLink)
                        Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          color: accentColor,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Floating
  // ---------------------------------------------------------------------------

  Widget _buildFloatingStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      color: hasLink
          ? (styleUtils.parseHex(blockStyle.color) ??
                theme.colorScheme.onSurface)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color:
                styleUtils.parseHex(blockStyle.background) ??
                theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (showIcon) ...[
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    getPageIcon(blockStyle.customIcon),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(pageTitle, style: titleStyle, textAlign: textAlign),
              ),
              if (hasLink)
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gradient
  // ---------------------------------------------------------------------------

  Widget _buildGradientStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final List<Color> gradientColors =
        (blockStyle.gradientColors?.isNotEmpty == true)
        ? blockStyle.gradientColors!
              .map(
                (h) =>
                    styleUtils.parseHex(h) as Color? ??
                    theme.colorScheme.primary,
              )
              .toList()
        : [theme.colorScheme.primary, theme.colorScheme.tertiary];

    const fg = Colors.white;
    final fgColor = styleUtils.parseHex(blockStyle.color) ?? fg;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: hasLink ? fgColor : fgColor.withOpacity(0.5),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
      decorationColor: fgColor,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasLink
                  ? gradientColors
                  : gradientColors
                        .map((c) => c.withValues(alpha: 0.4))
                        .toList(),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (showIcon) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    getPageIcon(blockStyle.customIcon),
                    color: fgColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(pageTitle, style: titleStyle, textAlign: textAlign),
              ),
              if (hasLink)
                Icon(IconsaxPlusLinear.arrow_right_3, color: fgColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Outlined
  // ---------------------------------------------------------------------------

  Widget _buildOutlinedStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final borderColor =
        styleUtils.parseHex(blockStyle.borderColor) ??
        theme.colorScheme.primary.withValues(alpha: 0.6);
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: hasLink
          ? (styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.primary)
          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasLink ? borderColor : borderColor.withOpacity(0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showIcon) ...[
                Icon(
                  getPageIcon(blockStyle.customIcon),
                  color: hasLink ? borderColor : borderColor.withOpacity(0.4),
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(pageTitle, style: titleStyle, textAlign: textAlign),
              ),
              if (hasLink)
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: borderColor,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------------

  Widget _buildHeroStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    String pageTitle,
    bool hasLink,
    bool showIcon,
  ) {
    final textAlign = styleUtils.textAlignFromStyle(blockStyle);
    final accentColor =
        styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.primary;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: hasLink ? accentColor : accentColor.withOpacity(0.4),
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w700,
      fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: blockStyle.fontSize,
      fontFamily: blockStyle.fontFamily,
      decoration: _buildDecoration(blockStyle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? _navigateToPage : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color:
                styleUtils.parseHex(blockStyle.background) ??
                theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              if (showIcon) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(hasLink ? 0.12 : 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getPageIcon(blockStyle.customIcon),
                    color: hasLink ? accentColor : accentColor.withOpacity(0.4),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(pageTitle, style: titleStyle, textAlign: textAlign),
              if (!hasLink) ...[
                const SizedBox(height: 8),
                Text(
                  'Page not linked',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
