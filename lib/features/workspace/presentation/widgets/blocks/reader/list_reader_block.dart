import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ListReaderBlock extends ConsumerWidget {
  final Block block;
  final bool allowSelection;

  const ListReaderBlock({
    super.key,
    required this.block,
    this.allowSelection = true,
  });

  String _toRoman(int number) {
    const romanMap = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: '10',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    var n = number;
    var result = StringBuffer();
    romanMap.forEach((value, symbol) {
      while (n >= value) {
        result.write(symbol);
        n -= value;
      }
    });
    return result.toString();
  }

  String _toAlpha(int index, {bool upper = true}) {
    final letter = String.fromCharCode(65 + (index % 26));
    return upper ? letter : letter.toLowerCase();
  }

  String _getPrefix(int i, String listType, String customIcon) {
    switch (listType) {
      case 'numbered':
        return '${i + 1}.';
      case 'roman':
        return '${_toRoman(i + 1)}.';
      case 'alpha':
        return '${_toAlpha(i)}.';
      case 'alpha-lower':
        return '${_toAlpha(i, upper: false)}.';
      case 'custom':
        return customIcon;
      case 'none':
        return ''; // No prefix for 'none' type
      default:
        return '•';
    }
  }

  /// Parse markdown in list item text
  Widget _buildItemText(
    String text,
    TextStyle baseStyle,
    ThemeData theme,
    bool allowSelection,
  ) {
    final colonIndex = text.indexOf(':');

    // If no colon, just use markdown
    if (colonIndex == -1 || colonIndex == text.length - 1) {
      return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: baseStyle,
          strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
          em: baseStyle.copyWith(fontStyle: FontStyle.italic),
          a: baseStyle.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          code: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          listBullet: baseStyle,
          checkbox: baseStyle,
          textAlign: WrapAlignment.start,
        ),
        selectable: allowSelection,
        onTapLink: (text, href, title) async {
          if (href != null) {
            await LinkUtils.launchURL(href);
          }
        },
      );
    }

    // If there's a colon, make label bold and use markdown for entire text
    final label = text.substring(0, colonIndex).trim();
    final value = text.substring(colonIndex + 1).trim();

    return MarkdownBody(
      data: '**$label**: $value',
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        a: baseStyle.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        listBullet: baseStyle,
        checkbox: baseStyle,
        textAlign: WrapAlignment.start,
      ),
      selectable: allowSelection,
      onTapLink: (text, href, title) async {
        if (href != null) {
          await LinkUtils.launchURL(href);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final listType = block.style.listType ?? 'bulleted';
    final customIcon = block.style.customIcon ?? '•';
    final parsedColor = styleUtils.parseHex(block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final textAlign = styleUtils.textAlignFromStyle(block.style);
    final lineHeight = ResponsiveUtils.getLineHeight(context, baseHeight: 1.5);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);

    final baseTextStyle = styleUtils
        .applyStyle(block.style)
        .copyWith(
          color: color,
          textBaseline: TextBaseline.alphabetic,
          height: lineHeight,
          fontSize: block.style.fontSize * textMultiplier,
        );

    Map<String, dynamic> content = {'header': '', 'items': []};
    try {
      if (block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(block.content);
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse block content',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading list content: $e')),
        );
      }
    }

    final header = content['header']?.toString() ?? '';
    final items = content['items'] is List ? content['items'] : [];
    if (items.isEmpty) return const SizedBox.shrink();

    final listTemplate = block.style.listTemplate ?? 'default';
    final isWide = MediaQuery.of(context).size.width > 600;
    final padding = isWide
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
    const margin = EdgeInsets.symmetric(vertical: 4);

    // Priority colors (red → orange → yellow → green) cycling per item
    final priorityColors = [
      theme.colorScheme.error,
      Colors.orange,
      Colors.amber,
      theme.colorScheme.primary,
      Colors.teal,
    ];

    BoxDecoration containerDecoration;
    switch (listTemplate) {
      case 'card':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              styleUtils.parseHex(block.style.background) ??
              theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
        break;
      case 'minimal':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: styleUtils.parseHex(block.style.background),
        );
        break;
      case 'outlined':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: styleUtils.parseHex(block.style.background),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        );
        break;
      case 'gradient':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        );
        break;
      case 'modern':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              styleUtils.parseHex(block.style.background) ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        );
        break;
      case 'timeline':
      case 'numbered_card':
      case 'badge':
      case 'priority':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: styleUtils.parseHex(block.style.background),
        );
        break;
      default: // 'default' — minimal, no decorative container
        containerDecoration = BoxDecoration(
          color: styleUtils.parseHex(block.style.background),
        );
    }

    // Per-item decoration
    BoxDecoration? itemDecoration(int i) {
      switch (listTemplate) {
        case 'modern':
          return BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
          );
        case 'card':
          return BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          );
        case 'numbered_card':
          return BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          );
        case 'priority':
          final color = priorityColors[i % priorityColors.length];
          return BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: color, width: 4)),
            color: color.withValues(alpha: 0.05),
          );
        default:
          return null;
      }
    }

    EdgeInsets? itemPadding(int i) {
      switch (listTemplate) {
        case 'modern':
          return const EdgeInsets.fromLTRB(8, 4, 4, 4);
        case 'card':
          return const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
        case 'numbered_card':
          return const EdgeInsets.symmetric(horizontal: 8, vertical: 8);
        case 'priority':
          return const EdgeInsets.fromLTRB(10, 6, 6, 6);
        case 'badge':
          return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
        default:
          return null;
      }
    }

    // Build header based on template — default is plain/minimal
    Widget? buildHeader() {
      if (header.isEmpty) return null;
      if (listTemplate == 'default' ||
          listTemplate == 'minimal' ||
          listTemplate == 'badge' ||
          listTemplate == 'priority' ||
          listTemplate == 'timeline' ||
          listTemplate == 'numbered_card') {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            header,
            style: baseTextStyle,
            semanticsLabel: 'List header',
          ),
        );
      }
      // Decorated header for card/modern/outlined/gradient
      return Container(
        padding: const EdgeInsets.only(bottom: 12.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.format_list_bulleted,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                header,
                style: baseTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
                semanticsLabel: 'List header',
              ),
            ),
          ],
        ),
      );
    }

    final headerWidget = buildHeader();

    // ── Timeline template ────────────────────────────────────────────────
    if (listTemplate == 'timeline') {
      return Container(
        padding: padding,
        margin: margin,
        decoration: containerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerWidget != null) headerWidget,
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vertical connecting line
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: List.generate(
                        items.length,
                        (i) => Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (i < items.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Items
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(items.length, (i) {
                        final rawText = items[i].toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Semantics(
                            label: 'List item ${i + 1}: $rawText',
                            child: _buildItemText(
                              rawText,
                              baseTextStyle.copyWith(height: 1.5),
                              theme,
                              allowSelection,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Badge template ────────────────────────────────────────────────────
    if (listTemplate == 'badge') {
      return Container(
        padding: padding,
        margin: margin,
        decoration: containerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerWidget != null) headerWidget,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(items.length, (i) {
                final rawText = items[i].toString();
                final prefix = _getPrefix(i, listType, customIcon);
                return Semantics(
                  label: 'List item ${i + 1}: $rawText',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prefix.isNotEmpty) ...[
                          Text(
                            prefix,
                            style: baseTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          rawText,
                          style: baseTextStyle.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    // ── Default/standard items rendering ─────────────────────────────────
    return Container(
      padding: padding,
      margin: margin,
      decoration: containerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerWidget != null) headerWidget,
          // List items
          ...List.generate(items.length, (i) {
            final rawText = items[i].toString();
            final prefix = _getPrefix(i, listType, customIcon);

            // numbered_card: circle badge prefix
            if (listTemplate == 'numbered_card') {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                padding: itemPadding(i) ?? EdgeInsets.zero,
                decoration: itemDecoration(i),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        label: 'List item ${i + 1}: $rawText',
                        child: _buildItemText(
                          rawText,
                          baseTextStyle.copyWith(height: 1.5),
                          theme,
                          allowSelection,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: itemPadding(i) ?? EdgeInsets.zero,
              decoration: itemDecoration(i),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prefix.isNotEmpty)
                    SizedBox(
                      width: 32,
                      child: Semantics(
                        label: 'List item prefix ${i + 1}',
                        child: Text(
                          prefix,
                          style: baseTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  if (prefix.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'List item ${i + 1}: $rawText',
                      child: _buildItemText(
                        rawText,
                        baseTextStyle.copyWith(height: 1.5),
                        theme,
                        allowSelection,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
