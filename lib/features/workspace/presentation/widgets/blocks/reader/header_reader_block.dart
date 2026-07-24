import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/painters/custom_border_painter.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class HeaderBlockReader extends ConsumerStatefulWidget {
  final Block block;
  final bool allowSelection;

  const HeaderBlockReader({
    super.key,
    required this.block,
    this.allowSelection = true,
  });

  @override
  ConsumerState<HeaderBlockReader> createState() => _HeaderBlockReaderState();
}

class _HeaderBlockReaderState extends ConsumerState<HeaderBlockReader>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

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
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: ResponsiveUtils.getPlatformAnimationDuration(),
    );

    // Platform-specific hover effects
    // Apple: Very subtle (0-2pt elevation, 1.01 scale)
    // Android: More noticeable (0-4dp elevation, 1.02 scale)
    final maxElevation = PlatformThemeHelper.isAndroid ? 4.0 : 2.0;
    final maxScale = ResponsiveUtils.getPlatformHoverScale();

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: maxScale,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);

    final fontSize = widget.block.style.fontSize;
    final headerStyle = widget.block.style.headerStyle ?? 'normal';
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final parsedBorderColor = styleUtils.parseHex(
      widget.block.style.borderColor,
    );
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final borderColor = parsedBorderColor ?? theme.colorScheme.primary;

    // Platform-aware border width (Apple: 0.5-1pt, Android: 1-2dp)
    final borderWidth = ResponsiveUtils.getPlatformBorderWidth(
      isEmphasized: widget.block.style.borderWidth > 2,
    );

    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final alignment = textAlign == TextAlign.center
        ? Alignment.center
        : textAlign == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Platform-aware padding using spacing constants
    final horizontalPadding = isDesktop
        ? ResponsiveUtils.spacing20
        : (isWide ? ResponsiveUtils.spacing12 : ResponsiveUtils.spacing8);
    final verticalPadding = isDesktop
        ? ResponsiveUtils.spacing12
        : (isWide ? ResponsiveUtils.spacing8 : ResponsiveUtils.spacing4);
    final padding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
    final margin = EdgeInsets.symmetric(vertical: verticalMargin);
    const maxWidth = double.infinity;

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
          SnackBar(content: Text('Error loading header content: $e')),
        );
      }
    }

    // Platform-specific typography
    // Headers use platform-specific font weights and tracking
    final lineHeight = PlatformThemeHelper.isAndroid ? 1.29 : 1.25;
    final letterSpacing = PlatformThemeHelper.isAndroid ? 0.0 : -0.24;

    final baseStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(
          fontSize: fontSize * ResponsiveUtils.getTextSizeMultiplier(context),
          fontWeight: PlatformThemeHelper.isAndroid
              ? FontWeight
                    .w700 // Android: Bold headers
              : FontWeight.w600, // Apple: Semibold headers
          color: color,
          letterSpacing: letterSpacing,
          height: lineHeight,
        );

    final linkStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w600,
    );

    final hoverColor = theme.colorScheme.primary.withOpacity(0.7);

    final headerTextWidget = Container(
      width: maxWidth,
      alignment: alignment,
      child: Semantics(
        label: 'Header text',
        child: MarkdownBody(
          data: content['content'] ?? '',
          styleSheet: MarkdownStyleSheet(
            p: baseStyle,
            strong: baseStyle.copyWith(fontWeight: FontWeight.w900),
            em: baseStyle.copyWith(fontStyle: FontStyle.italic),
            a: linkStyle,
            code: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            h1: baseStyle,
            h2: baseStyle,
            h3: baseStyle,
            h4: baseStyle,
            h5: baseStyle,
            h6: baseStyle,
            textAlign: _getWrapAlignment(textAlign),
          ),
          selectable: widget.allowSelection,
          onTapLink: (text, href, title) async {
            if (href != null) {
              await LinkUtils.launchURL(href);
            }
          },
        ),
      ),
    );

    Widget contentWidget;

    switch (headerStyle) {
      case 'underline':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                // Only show background if user has set one - no default styling
                decoration:
                    styleUtils.parseHex(widget.block.style.background) != null
                    ? BoxDecoration(
                        color: styleUtils.parseHex(
                          widget.block.style.background,
                        ),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerTextWidget,
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: borderWidth,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            borderColor.withOpacity(0.3),
                            borderColor.withOpacity(_isHovering ? 1.0 : 0.8),
                            borderColor.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        break;
      case 'dotted':
        contentWidget = Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerTextWidget,
              const SizedBox(height: 4),
              CustomPaint(
                painter: CustomBorderPainter(
                  color: borderColor,
                  style: 'dotted',
                  position: 'bottom',
                  strokeWidth: borderWidth,
                ),
                size: Size(maxWidth, borderWidth),
              ),
            ],
          ),
        );
        break;
      case 'breakline':
        contentWidget = Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: styleUtils.parseHex(widget.block.style.background),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerTextWidget,
              const SizedBox(height: 4),
              CustomPaint(
                painter: CustomBorderPainter(
                  color: borderColor,
                  style: 'dashed',
                  position: 'bottom',
                  strokeWidth: borderWidth,
                ),
                size: Size(maxWidth, borderWidth),
              ),
            ],
          ),
        );
        break;
      case 'boxed':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                child: CustomPaint(
                  painter: CustomBorderPainter(
                    color: borderColor.withOpacity(_isHovering ? 1.0 : 0.7),
                    style: 'solid',
                    strokeWidth: borderWidth + (_isHovering ? 0.5 : 0),
                  ),
                  child: Container(
                    width: maxWidth,
                    padding: const EdgeInsets.all(6),
                    child: headerTextWidget,
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case 'dotted_box':
        contentWidget = Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          child: CustomPaint(
            painter: CustomBorderPainter(
              color: borderColor,
              style: 'dotted',
              strokeWidth: borderWidth,
            ),
            child: Container(
              width: maxWidth,
              padding: const EdgeInsets.all(6),
              child: headerTextWidget,
            ),
          ),
        );
        break;
      case 'gradient':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: () {
                      try {
                        return widget.block.style.gradientColors
                                ?.map(
                                  (hex) =>
                                      styleUtils.parseHex(hex) ?? borderColor,
                                )
                                .toList() ??
                            [
                              theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              theme.colorScheme.secondaryContainer.withValues(
                                alpha: 0.1,
                              ),
                            ];
                      } catch (e, stackTrace) {
                        logger.e(
                          'Failed to parse gradient colors',
                          error: e,
                          stackTrace: stackTrace,
                        );
                        return [
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          ),
                          theme.colorScheme.secondaryContainer.withValues(
                            alpha: 0.1,
                          ),
                        ];
                      }
                    }(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: borderColor.withOpacity(_isHovering ? 1.0 : 0.7),
                    width: borderWidth,
                  ),
                ),
                child: SizedBox(width: maxWidth, child: headerTextWidget),
              ),
            ),
          ),
        );
        break;
      case 'featured':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.tertiary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: borderColor, width: 4),
                  ),
                ),
                child: headerTextWidget,
              ),
            ),
          ),
        );
        break;
      case 'modern':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 35,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: headerTextWidget),
                  ],
                ),
              ),
            ),
          ),
        );
        break;
      case 'hero':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: headerTextWidget,
              ),
            ),
          ),
        );
        break;
      case 'minimal':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerTextWidget,
                    const SizedBox(height: 6),
                    Container(
                      height: 1,
                      width: 60,
                      color: borderColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        break;
      case 'accent':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: headerTextWidget),
                  ],
                ),
              ),
            ),
          ),
        );
        break;
      case 'badge':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.star,
                        color: theme.colorScheme.onPrimary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: headerTextWidget),
                  ],
                ),
              ),
            ),
          ),
        );
        break;
      case 'ribbon':
        contentWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(),
              padding: padding.copyWith(top: padding.top + 16),
              margin: margin.copyWith(top: margin.top + 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: headerTextWidget,
            ),
            Positioned(
              left: 0,
              top: margin.top,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Featured',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
        break;
      case 'callout':
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: borderColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: headerTextWidget),
                  ],
                ),
              ),
            ),
          ),
        );
        break;
      default:
        contentWidget = MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _hoverController.reverse();
          },
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(),
                padding: padding,
                margin: margin,
                // Only show background if user has set one - no default styling for minimal look
                decoration:
                    styleUtils.parseHex(widget.block.style.background) != null
                    ? BoxDecoration(
                        color: styleUtils.parseHex(
                          widget.block.style.background,
                        ),
                      )
                    : null,
                child: headerTextWidget,
              ),
            ),
          ),
        );
    }

    return contentWidget;
  }
}
