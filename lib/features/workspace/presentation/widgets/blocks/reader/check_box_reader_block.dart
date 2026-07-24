import 'dart:io';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class CheckBoxReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory? docDir;
  final bool allowSelection;

  const CheckBoxReaderBlock({
    super.key,
    required this.block,
    this.docDir,
    this.allowSelection = true,
  });

  @override
  ConsumerState<CheckBoxReaderBlock> createState() => _CheckBoxReaderBlockState();
}

class _CheckBoxReaderBlockState extends ConsumerState<CheckBoxReaderBlock> {
  late List<Map<String, dynamic>> _items;
  late String _header;

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  @override
  void didUpdateWidget(covariant CheckBoxReaderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block != oldWidget.block) {
      _initializeContent();
    }
  }

  void _initializeContent() {
    Map<String, dynamic> content = {'header': '', 'items': []};
    try {
      if (widget.block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(widget.block.content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse block content', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading checklist content: $e')),
        );
      }
    }

    final items = content['items'] is List ? content['items'] : [];
    _header = content['header']?.toString() ?? '';
    _items = List.generate(items.length, (index) {
      final item = items[index] is Map<String, dynamic>
          ? items[index]
          : {'text': items[index].toString(), 'checked': false};
      return Map<String, dynamic>.from(item);
    });
  }

  /// Parse markdown in checkbox item text
  Widget _buildItemText(String text, TextStyle baseStyle, ThemeData theme, bool allowSelection) {
    if (!text.contains(':')) {
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

    // If there's a colon, make label bold using markdown
    final parts = text.split(':');
    final label = parts[0].trim();
    final value = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

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
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final color = styleUtils.parseHex(widget.block.style.color) ?? theme.colorScheme.onSurface;
    final baseTextStyle = styleUtils.applyStyle(widget.block.style).copyWith(color: color);
    final checkboxTemplate = widget.block.style.checkboxTemplate ?? 'default';

    if (_items.isEmpty) return const SizedBox.shrink();

    final isWide = MediaQuery.of(context).size.width > 600;
    final padding = isWide ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
    const margin = EdgeInsets.symmetric(vertical: 4);

    BoxDecoration containerDecoration;
    switch (checkboxTemplate) {
      case 'card':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: styleUtils.parseHex(widget.block.style.background) ?? theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
        break;
      case 'minimal':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: styleUtils.parseHex(widget.block.style.background),
        );
        break;
      case 'outlined':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: styleUtils.parseHex(widget.block.style.background),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        );
        break;
      case 'modern':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: styleUtils.parseHex(widget.block.style.background) ??
              theme.colorScheme.surfaceVariant.withOpacity(0.5),
        );
        break;
      case 'gradient':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.4),
              theme.colorScheme.secondaryContainer.withOpacity(0.4),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        );
        break;
      case 'progress':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: styleUtils.parseHex(widget.block.style.background) ??
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
        );
        break;
      case 'priority':
      case 'split':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: styleUtils.parseHex(widget.block.style.background),
        );
        break;
      case 'compact':
        containerDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: styleUtils.parseHex(widget.block.style.background),
        );
        break;
      default: // 'default' — minimal, no decorative container
        containerDecoration = BoxDecoration(
          color: styleUtils.parseHex(widget.block.style.background),
        );
    }

    // Header widget — default is plain/minimal, no icon, no border, no bold
    Widget? buildHeader() {
      if (_header.isEmpty) return null;
      if (checkboxTemplate == 'default' || checkboxTemplate == 'minimal' ||
          checkboxTemplate == 'compact' || checkboxTemplate == 'split' ||
          checkboxTemplate == 'progress' || checkboxTemplate == 'priority') {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _header,
            style: baseTextStyle,
            semanticsLabel: 'Checklist header',
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.only(bottom: 12.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.checklist,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _header,
                style: baseTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
                semanticsLabel: 'Checklist header',
              ),
            ),
          ],
        ),
      );
    }

    final headerWidget = buildHeader();

    // Helper to build a single checkbox item widget
    Widget buildCheckboxItem(int index, {EdgeInsets? padding, BoxDecoration? decoration}) {
      final item = _items[index];
      final text = item['text']?.toString() ?? '';
      final checked = item['checked'] == true;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: padding ?? const EdgeInsets.all(8.0),
        decoration: decoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ResponsiveUtils.ensureTouchTarget(
              Transform.scale(
                scale: 1.1,
                child: Theme(
                  data: theme.copyWith(
                    checkboxTheme: CheckboxThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PlatformThemeHelper.isAndroid ? 4.0 : 5.0,
                        ),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline,
                        width: ResponsiveUtils.getPlatformBorderWidth(),
                      ),
                    ),
                  ),
                  child: Checkbox(
                    value: checked,
                    onChanged: (bool? newValue) {
                      HapticFeedback.selectionClick();
                      if (widget.docDir == null) {
                        setState(() { _items[index]['checked'] = newValue; });
                        return;
                      }
                      setState(() { _items[index]['checked'] = newValue; });
                      try {
                        final updatedContent = {'header': _header, 'items': _items};
                        final jsonContent = JsonStringConverter().convertToJsonString(updatedContent);
                        final updatedBlock = widget.block.copyWith(content: jsonContent);
                        ref
                            .read(editDocumentControllerProvider(widget.docDir!).notifier)
                            .saveBlock(updatedBlock);
                        logger.i('Checkbox state updated for block: ${widget.block.id}');
                      } catch (e, stackTrace) {
                        logger.e('Failed to save checkbox state', error: e, stackTrace: stackTrace);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving checkbox state: $e')),
                          );
                        }
                      }
                    },
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    activeColor: theme.colorScheme.primary,
                    checkColor: theme.colorScheme.onPrimary,
                    semanticLabel: checked ? 'Checked item: $text' : 'Unchecked item: $text',
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing12),
            Expanded(
              child: _buildItemText(
                text,
                baseTextStyle.copyWith(
                  decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
                  color: checked ? color.withOpacity(0.6) : color,
                  height: 1.5,
                ),
                theme,
                widget.allowSelection,
              ),
            ),
          ],
        ),
      );
    }

    // ── Progress template ─────────────────────────────────────────────────
    if (checkboxTemplate == 'progress') {
      final checkedCount = _items.where((it) => it['checked'] == true).length;
      final total = _items.length;
      final progress = total > 0 ? checkedCount / total : 0.0;

      return Container(
        padding: padding,
        margin: margin,
        decoration: containerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerWidget != null) headerWidget,
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$checkedCount/$total',
                  style: baseTextStyle.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_items.length, (index) => buildCheckboxItem(index)),
          ],
        ),
      );
    }

    // ── Priority template (color-coded left borders) ───────────────────────
    if (checkboxTemplate == 'priority') {
      final priorityColors = [
        theme.colorScheme.error,
        Colors.orange,
        Colors.amber.shade700,
        theme.colorScheme.primary,
        Colors.teal,
      ];

      return Container(
        padding: padding,
        margin: margin,
        decoration: containerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerWidget != null) headerWidget,
            ...List.generate(_items.length, (index) {
              final pc = priorityColors[index % priorityColors.length];
              return buildCheckboxItem(
                index,
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border(left: BorderSide(color: pc, width: 4)),
                  color: pc.withOpacity(0.05),
                ),
              );
            }),
          ],
        ),
      );
    }

    // ── Split template (pending vs done) ──────────────────────────────────
    if (checkboxTemplate == 'split') {
      final pending = _items.asMap().entries.where((e) => e.value['checked'] != true).toList();
      final done = _items.asMap().entries.where((e) => e.value['checked'] == true).toList();

      return Container(
        padding: padding,
        margin: margin,
        decoration: containerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerWidget != null) headerWidget,
            if (pending.isNotEmpty) ...[
              for (final e in pending) buildCheckboxItem(e.key),
            ],
            if (done.isNotEmpty) ...[
              if (pending.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.4),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Done',
                        style: baseTextStyle.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.4),
                        thickness: 1,
                      ),
                    ),
                  ]),
                ),
              for (final e in done) buildCheckboxItem(e.key),
            ],
          ],
        ),
      );
    }

    // ── Compact template ──────────────────────────────────────────────────
    if (checkboxTemplate == 'compact') {
      return Container(
        padding: padding,
        margin: margin,
        decoration: containerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerWidget != null) headerWidget,
            ...List.generate(_items.length, (index) => buildCheckboxItem(
              index,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            )),
          ],
        ),
      );
    }

    // ── Default / standard rendering ──────────────────────────────────────
    return Container(
      padding: padding,
      margin: margin,
      decoration: containerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerWidget != null) headerWidget,
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final text = item['text']?.toString() ?? '';
            final checked = item['checked'] == true;

            BoxDecoration itemDecoration;
            switch (checkboxTemplate) {
              case 'card':
                itemDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getPlatformRadius(context, baseRadius: 8.0),
                  ),
                  color: checked
                      ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                      : theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.06),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                );
                break;
              case 'outlined':
                itemDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getPlatformRadius(context, baseRadius: 8.0),
                  ),
                  color: checked ? theme.colorScheme.primaryContainer.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                );
                break;
              case 'modern':
                itemDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getPlatformRadius(context, baseRadius: 8.0),
                  ),
                  color: checked
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                );
                break;
              default:
                itemDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getPlatformRadius(context, baseRadius: 8.0),
                  ),
                  color: checked
                      ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                      : Colors.transparent,
                );
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(8.0),
              decoration: itemDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ensure checkbox meets minimum touch target
                  ResponsiveUtils.ensureTouchTarget(
                    Transform.scale(
                      scale: 1.1,
                      child: Theme(
                        // Apply platform-specific checkbox styling
                        data: theme.copyWith(
                          checkboxTheme: CheckboxThemeData(
                            shape: RoundedRectangleBorder(
                              // Apple HIG: 5pt radius for checkboxes
                              // Android: 4pt radius (more square)
                              borderRadius: BorderRadius.circular(
                                PlatformThemeHelper.isAndroid ? 4.0 : 5.0,
                              ),
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.outline,
                              width: ResponsiveUtils.getPlatformBorderWidth(),
                            ),
                          ),
                        ),
                        child: Checkbox(
                          value: checked,
                          onChanged: (bool? newValue) {
                            // Add haptic feedback for interactivity (Apple HIG guideline)
                            HapticFeedback.selectionClick();
                            
                            if (widget.docDir == null) {
                              setState(() {
                                _items[index]['checked'] = newValue;
                              });
                              return;
                            }

                            setState(() {
                              _items[index]['checked'] = newValue;
                            });

                            try {
                              final updatedContent = {
                                'header': _header,
                                'items': _items,
                              };

                              final jsonContent = JsonStringConverter().convertToJsonString(updatedContent);
                              final updatedBlock = widget.block.copyWith(content: jsonContent);

                              ref
                                  .read(editDocumentControllerProvider(widget.docDir!).notifier)
                                  .saveBlock(updatedBlock);

                              logger.i('Checkbox state updated for block: ${widget.block.id}');
                            } catch (e, stackTrace) {
                              logger.e('Failed to save checkbox state', error: e, stackTrace: stackTrace);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving checkbox state: $e')),
                                );
                              }
                            }
                          },
                          materialTapTargetSize: MaterialTapTargetSize.padded, // Changed for proper touch targets
                          activeColor: theme.colorScheme.primary,
                          checkColor: theme.colorScheme.onPrimary,
                          semanticLabel: checked ? 'Checked item: $text' : 'Unchecked item: $text',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing12),
                  Expanded(
                    child: _buildItemText(
                      text,
                      baseTextStyle.copyWith(
                        decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
                        color: checked ? color.withOpacity(0.6) : color,
                        height: 1.5,
                      ),
                      theme,
                      widget.allowSelection,
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