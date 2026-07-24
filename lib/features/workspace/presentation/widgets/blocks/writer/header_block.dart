import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/header_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/painters/custom_border_painter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// Header block widget that extends BaseEditableBlock.
/// Provides different header styles: normal, underline, dotted, breakline, boxed, dotted_box, gradient.
class HeaderBlock extends BaseEditableBlock {
  const HeaderBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<HeaderBlock> createState() => _HeaderBlockState();
}

class _HeaderBlockState extends BaseEditableBlockState<HeaderBlock> {
  // Block-specific state
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  late Debouncer _saveDebouncer;
  late Animation<double> _scaleAnimation;

  @override
  Map<String, dynamic> getDefaultContent() => {'content': ''};

  @override
  void initializeBlockSpecifics() {
    _textController = TextEditingController(text: content['content'] ?? '');
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
    
    // Additional scale animation for headers
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    _textController.dispose();
    _focusNode.dispose();
  }

  @override
  void onContentChanged() {
    if (_textController.text != (content['content'] ?? '')) {
      _textController.text = content['content'] ?? '';
    }
  }

  Widget _buildHeaderTextField(
    BuildContext context,
    StyleUtils styleUtils,
    ThemeData theme,
  ) {
    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final lineHeight = ResponsiveUtils.getLineHeight(context, baseHeight: 1.3);
    final letterSpacing = ResponsiveUtils.getLetterSpacing(context, baseSpacing: 0.3);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final alignment = textAlign == TextAlign.center
        ? Alignment.center
        : textAlign == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      width: double.infinity,
      alignment: alignment,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        style: styleUtils.applyStyle(widget.block.style).copyWith(
          fontSize: fontSize * textMultiplier,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
        textAlign: textAlign,
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: 'Type header text...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
        onChanged: (value) {
          content['content'] = value;
          _saveDebouncer.call(() => saveContent());
        },
      ),
    );
  }

  Widget _buildStyledContent(
    BuildContext context,
    Widget headerTextWidget,
    StyleUtils styleUtils,
    ThemeData theme,
  ) {
    final headerStyle = widget.block.style.headerStyle ?? 'normal';
    final parsedBorderColor = styleUtils.parseHex(widget.block.style.borderColor);
    final borderColor = parsedBorderColor ?? theme.colorScheme.primary;
    final borderWidth = widget.block.style.borderWidth;
    
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalPadding = isDesktop ? 20.0 : (isWide ? 12.0 : 0.0);
    final verticalPadding = isDesktop ? 12.0 : (isWide ? 8.0 : 6.0);
    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
    final margin = EdgeInsets.symmetric(vertical: verticalMargin);
    const maxWidth = double.infinity;

    switch (headerStyle) {
      case 'underline':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: styleUtils.parseHex(widget.block.style.background),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerTextWidget,
              const SizedBox(height: 6),
              Container(
                height: borderWidth,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      borderColor.withOpacity(0.3),
                      borderColor,
                      borderColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        );
      case 'dotted':
        return Container(
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
      case 'breakline':
        return Container(
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
      case 'boxed':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          child: CustomPaint(
            painter: CustomBorderPainter(
              color: borderColor,
              style: 'solid',
              strokeWidth: borderWidth,
            ),
            child: Container(
              width: maxWidth,
              padding: const EdgeInsets.all(8),
              child: headerTextWidget,
            ),
          ),
        );
      case 'dotted_box':
        return Container(
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
              padding: const EdgeInsets.all(8),
              child: headerTextWidget,
            ),
          ),
        );
      case 'gradient':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: () {
                try {
                  return widget.block.style.gradientColors
                      ?.map((hex) => styleUtils.parseHex(hex) ?? borderColor)
                      .toList() ??
                      [
                        theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                        theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
                      ];
                } catch (e, stackTrace) {
                  logger.e('Failed to parse gradient colors', error: e, stackTrace: stackTrace);
                  return [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
                  ];
                }
              }(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: SizedBox(
            width: maxWidth,
            child: headerTextWidget,
          ),
        );
      case 'featured':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.15),
                theme.colorScheme.tertiary.withOpacity(0.15),
              ],
            ),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          child: headerTextWidget,
        );
      case 'modern':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 35,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: headerTextWidget),
            ],
          ),
        );
      case 'hero':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding.copyWith(top: verticalPadding * 1.5, bottom: verticalPadding * 1.5),
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
          child: DefaultTextStyle(
            style: TextStyle(color: theme.colorScheme.onPrimary),
            child: headerTextWidget,
          ),
        );
      case 'minimal':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
        );
      case 'accent':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      borderColor,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: headerTextWidget),
            ],
          ),
        );
      case 'badge':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'H',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: headerTextWidget),
            ],
          ),
        );
      case 'ribbon':
        return Stack(
          children: [
            Container(
              constraints: const BoxConstraints(),
              padding: padding.copyWith(left: horizontalPadding + 24),
              margin: margin.copyWith(top: verticalMargin + 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: headerTextWidget,
            ),
            Positioned(
              left: horizontalPadding,
              top: verticalMargin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star,
                  color: theme.colorScheme.onPrimary,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      case 'callout':
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: borderColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: headerTextWidget),
            ],
          ),
        );
      default:
        return Container(
          constraints: const BoxConstraints(),
          padding: padding,
          margin: margin,
          decoration: styleUtils.parseHex(widget.block.style.background) != null
              ? BoxDecoration(
                  color: styleUtils.parseHex(widget.block.style.background),
                )
              : null,
          child: headerTextWidget,
        );
    }
  }

  @override
  Widget buildEditor(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);

    final headerTextWidget = _buildHeaderTextField(context, styleUtils, theme);
    final contentWidget = _buildStyledContent(context, headerTextWidget, styleUtils, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: contentWidget,
        ),
      ],
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return HeaderBlockReader(block: widget.block, allowSelection: false);
  }
}
