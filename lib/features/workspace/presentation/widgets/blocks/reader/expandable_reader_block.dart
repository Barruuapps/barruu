import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/paragraph_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/code_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/math_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/header_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/block_quote_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/list_reader_block.dart';

/// Read-only display of an expandable block with collapse/expand functionality.
///
/// The hidden content can be one of several block types (paragraph, header,
/// blockquote, list, code, math) as specified by [Block.content]'s
/// `contentType` field.  Legacy blocks that only have a `content` key are
/// treated as paragraph type.
///
/// **Edit-screen preview** (`forceExpanded: true`): content is always shown
/// open so authors can see how the block looks after pressing the checkmark.
/// **Read mode**: starts collapsed by default; respects the `initiallyOpen`
/// toggle that the author set in the editor.
class ExpandableReaderBlock extends ConsumerStatefulWidget {
  final Block block;

  /// When `true` the block is always rendered expanded, regardless of the
  /// `initiallyOpen` value stored in the content.  Used by the write-side
  /// `buildReader()` so that the edit-screen preview shows the full content.
  final bool forceExpanded;

  const ExpandableReaderBlock({
    required this.block,
    this.forceExpanded = false,
    super.key,
  });

  @override
  ConsumerState<ExpandableReaderBlock> createState() =>
      _ExpandableReaderBlockState();
}

class _ExpandableReaderBlockState extends ConsumerState<ExpandableReaderBlock>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    // In read mode, start collapsed by default unless the author set
    // "Open by default" OR the caller forces expansion (e.g. edit-screen preview).
    bool initiallyOpen = widget.forceExpanded;
    if (!initiallyOpen) {
      try {
        final parsed = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
        initiallyOpen = parsed['initiallyOpen'] as bool? ?? false;
      } catch (_) {}
    }
    _isExpanded = initiallyOpen;

    _animationController = AnimationController(
      duration: ResponsiveUtils.getPlatformAnimationDuration(isComplex: true),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Content parsing helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _parseContent() {
    try {
      return JsonStringConverter().convertFromJsonString(widget.block.content);
    } catch (_) {
      return {
        'title': 'Section',
        'contentType': 'paragraph',
        'contentData': {'content': ''},
      };
    }
  }

  /// Returns the per-type data map. Falls back to the legacy `content` key.
  Map<String, dynamic> _extractContentData(Map<String, dynamic> parsed) {
    final raw = parsed['contentData'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'content': parsed['content']?.toString() ?? ''};
  }

  /// Builds a synthetic [Block] so that existing reader widgets can be reused.
  ///
  /// The synthetic block inherits `widget.block.style` so that toolbar
  /// formatting (font, color, size, bold/italic) applied on the expandable
  /// block propagates to the inner content display automatically.
  Block _buildSyntheticBlock(
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    switch (contentType) {
      case 'header':
        return Block(
          content: jsonEncode({'content': contentData['content'] ?? ''}),
          type: BlockType.header,
          position: 0,
          style: widget.block.style,
        );
      case 'blockquote':
        return Block(
          content: jsonEncode({
            'content': contentData['content'] ?? '',
            'author': contentData['author'] ?? '',
          }),
          type: BlockType.blockquote,
          position: 0,
          style: widget.block.style,
        );
      case 'list':
        final items =
            (contentData['items'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        return Block(
          content: jsonEncode({'header': '', 'items': items}),
          type: BlockType.list,
          position: 0,
          style: widget.block.style,
        );
      case 'code':
        return Block(
          content: jsonEncode({'content': contentData['content'] ?? ''}),
          type: BlockType.code,
          position: 0,
          style: widget.block.style.copyWith(
            language: contentData['language']?.toString() ?? 'text',
          ),
        );
      case 'math':
        return Block(
          content: jsonEncode({
            'latex': contentData['latex'] ?? '',
            'caption': contentData['caption'] ?? '',
          }),
          type: BlockType.math,
          position: 0,
          style: widget.block.style,
        );
      case 'paragraph':
      default:
        return Block(
          content: jsonEncode({'content': contentData['content'] ?? ''}),
          type: BlockType.paragraph,
          position: 0,
          style: widget.block.style,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final parsedContent = _parseContent();
    final title = parsedContent['title']?.toString() ?? 'Section';
    final template = widget.block.style.expandableTemplate ?? 'default';

    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final parsedBackground = styleUtils.parseHex(widget.block.style.background);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final baseTextStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(fontSize: fontSize * textMultiplier, color: color);

    final contentType = parsedContent['contentType']?.toString() ?? 'paragraph';
    final contentData = _extractContentData(parsedContent);

    return DefaultTextStyle(
      style: baseTextStyle,
      child: _buildContent(
        theme,
        template,
        parsedBackground,
        color,
        baseTextStyle,
        title,
        contentType,
        contentData,
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    String template,
    Color? parsedBackground,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    switch (template) {
      case 'filled':
        final fillColor =
            parsedBackground ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        return _buildContainerTemplate(
          theme,
          fillColor,
          color,
          baseTextStyle,
          title,
          contentType,
          contentData,
          borderRadius: 12,
        );
      case 'minimal':
        return _buildMinimalTemplate(
          theme,
          color,
          baseTextStyle,
          title,
          contentType,
          contentData,
        );
      case 'card':
        return _buildCardTemplate(
          theme,
          parsedBackground,
          color,
          baseTextStyle,
          title,
          contentType,
          contentData,
        );
      case 'outlined':
        return _buildOutlinedTemplate(
          theme,
          color,
          baseTextStyle,
          title,
          contentType,
          contentData,
        );
      case 'accent':
        return _buildAccentTemplate(
          theme,
          parsedBackground,
          color,
          baseTextStyle,
          title,
          contentType,
          contentData,
        );
      case 'default':
      default:
        return _buildDefaultTemplate(
          theme,
          parsedBackground,
          color,
          baseTextStyle,
          title,
          contentType,
          contentData,
        );
    }
  }

  Widget _buildDefaultTemplate(
    ThemeData theme,
    Color? parsedBackground,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: parsedBackground ?? theme.colorScheme.surface,
        border: Border.all(
          color: _isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: _isExpanded ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildExpandableCore(
        theme,
        color,
        baseTextStyle,
        title,
        contentType,
        contentData,
        borderRadius: 12,
      ),
    );
  }

  Widget _buildContainerTemplate(
    ThemeData theme,
    Color bgColor,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData, {
    double borderRadius = 12,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _buildExpandableCore(
        theme,
        color,
        baseTextStyle,
        title,
        contentType,
        contentData,
        borderRadius: borderRadius,
      ),
    );
  }

  Widget _buildMinimalTemplate(
    ThemeData theme,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: baseTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isExpanded
                              ? theme.colorScheme.primary
                              : color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _isExpanded
                            ? theme.colorScheme.primary
                            : color.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              _buildContentSection(
                theme,
                baseTextStyle,
                contentType,
                contentData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTemplate(
    ThemeData theme,
    Color? parsedBackground,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: parsedBackground ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _buildExpandableCore(
        theme,
        color,
        baseTextStyle,
        title,
        contentType,
        contentData,
        borderRadius: 12,
      ),
    );
  }

  Widget _buildOutlinedTemplate(
    ThemeData theme,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildExpandableCore(
        theme,
        color,
        baseTextStyle,
        title,
        contentType,
        contentData,
        borderRadius: 12,
      ),
    );
  }

  Widget _buildAccentTemplate(
    ThemeData theme,
    Color? parsedBackground,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:
            parsedBackground ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: _buildExpandableCore(
        theme,
        color,
        baseTextStyle,
        title,
        contentType,
        contentData,
      ),
    );
  }

  Widget _buildExpandableCore(
    ThemeData theme,
    Color color,
    TextStyle baseTextStyle,
    String title,
    String contentType,
    Map<String, dynamic> contentData, {
    double borderRadius = 12,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: baseTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isExpanded ? theme.colorScheme.primary : color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _isExpanded
                          ? theme.colorScheme.primary
                          : color.withValues(alpha: 0.6),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            _buildContentSection(
              theme,
              baseTextStyle,
              contentType,
              contentData,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Collapsed/expanded content section
  // ---------------------------------------------------------------------------

  Widget _buildContentSection(
    ThemeData theme,
    TextStyle baseTextStyle,
    String contentType,
    Map<String, dynamic> contentData,
  ) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isExpanded
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                          theme.colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isExpanded ? 1.0 : 0.0,
                    child: _buildBlockContent(
                      contentType,
                      contentData,
                      baseTextStyle,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Renders the appropriate read-only widget for [contentType].
  ///
  /// A synthetic [Block] is constructed from [contentData] so that existing
  /// reader widgets can be reused without modification.  The synthetic block
  /// inherits the expandable block's style, so toolbar formatting (font, color,
  /// alignment, bold/italic) applies automatically to the inner content.
  ///
  /// **Extending**: adding a new content type only requires adding a case here
  /// and in [_buildSyntheticBlock].
  Widget _buildBlockContent(
    String contentType,
    Map<String, dynamic> contentData,
    TextStyle baseTextStyle,
  ) {
    final syntheticBlock = _buildSyntheticBlock(contentType, contentData);
    switch (contentType) {
      case 'header':
        return HeaderBlockReader(block: syntheticBlock, allowSelection: false);
      case 'blockquote':
        return BlockQuoteReaderBlock(
          block: syntheticBlock,
          allowSelection: false,
        );
      case 'list':
        return ListReaderBlock(block: syntheticBlock, allowSelection: false);
      case 'code':
        return CodeReaderBlock(block: syntheticBlock);
      case 'math':
        return MathReaderBlock(block: syntheticBlock);
      case 'image':
        return _buildInlineImage(contentData);
      case 'table':
        return _buildInlineTable(contentData);
      case 'paragraph':
      default:
        return ParagraphReaderBlock(
          block: syntheticBlock,
          allowSelection: false,
        );
    }
  }

  Widget _buildInlineImage(Map<String, dynamic> contentData) {
    final url = contentData['url']?.toString() ?? '';
    final caption = contentData['caption']?.toString() ?? '';
    if (url.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url.startsWith('http')
              ? Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Image unavailable',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : Image.file(
                  File(url),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Image not found: $url',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildInlineTable(Map<String, dynamic> contentData) {
    final rawRows = contentData['rows'];
    if (rawRows is! List || rawRows.isEmpty) return const SizedBox.shrink();
    final rows = rawRows.map<List<String>>((row) {
      if (row is! List) return <String>[];
      return row.map<String>((cell) => cell?.toString() ?? '').toList();
    }).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final headerRow = rows[0];
    final bodyRows = rows.sublist(1);
    final colCount = headerRow.length;

    TextStyle cellStyle(bool isHeader) => TextStyle(
      fontSize: 13,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
      color: theme.colorScheme.onSurface.withValues(
        alpha: isHeader ? 0.9 : 0.75,
      ),
    );

    Widget buildCell(
      String text,
      bool isHeader, {
      bool isLast = false,
      bool isLastRow = false,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: isHeader
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border(
              right: isLast
                  ? BorderSide.none
                  : BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
              bottom: isLastRow
                  ? BorderSide.none
                  : BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
            ),
          ),
          child: Text(
            text,
            style: cellStyle(isHeader),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var ci = 0; ci < headerRow.length; ci++)
                      buildCell(
                        headerRow[ci],
                        true,
                        isLast: ci == headerRow.length - 1,
                        isLastRow: bodyRows.isEmpty,
                      ),
                  ],
                ),
                for (var ri = 0; ri < bodyRows.length; ri++)
                  Row(
                    children: [
                      for (var ci = 0; ci < colCount; ci++)
                        buildCell(
                          ci < bodyRows[ri].length ? bodyRows[ri][ci] : '',
                          false,
                          isLast: ci == colCount - 1,
                          isLastRow: ri == bodyRows.length - 1,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
