import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/expandable_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/code_block_style.dart';
import 'package:barruu/features/workspace/provider/constants_providers.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/all.dart';
import 'package:flutter_math_fork/flutter_math.dart';

// ---------------------------------------------------------------------------
// Content-type descriptor (drives both the dropdown and the editor factory)
// ---------------------------------------------------------------------------

class _ContentTypeOption {
  final String key;
  final IconData icon;
  final String label;
  const _ContentTypeOption(this.key, this.icon, this.label);
}

const List<_ContentTypeOption> _kContentTypeOptions = [
  _ContentTypeOption('paragraph', Icons.text_fields_rounded, 'Paragraph'),
  _ContentTypeOption('blockquote', Icons.format_quote_rounded, 'Quote'),
  _ContentTypeOption('list', Icons.format_list_bulleted_rounded, 'List'),
  _ContentTypeOption('code', Icons.code_rounded, 'Code'),
  _ContentTypeOption('math', Icons.functions_rounded, 'Math'),
  _ContentTypeOption('image', Icons.image_outlined, 'Image'),
  _ContentTypeOption('table', Icons.table_chart_outlined, 'Table'),
];

// ---------------------------------------------------------------------------
// Widget declaration
// ---------------------------------------------------------------------------

/// Expandable block whose hidden section supports multiple content types.
///
/// In **edit mode** the content area is always visible so the author can edit
/// it immediately.  In **read mode** (via [ExpandableReaderBlock]) the content
/// starts collapsed; the reader respects the "Open by default" toggle.
///
/// Adding a new content type requires:
///  1. Appending a [_ContentTypeOption] to [_kContentTypeOptions].
///  2. Adding a builder in [_buildContentEditor] and [_buildContentData].
///  3. Adding a synthetic-block case in [ExpandableReaderBlock].
class ExpandableBlock extends BaseEditableBlock {
  const ExpandableBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<ExpandableBlock> createState() => _ExpandableBlockState();
}

class _ExpandableBlockState extends BaseEditableBlockState<ExpandableBlock> {
  // Title
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;

  // Paragraph
  late TextEditingController _paragraphController;
  late FocusNode _paragraphFocusNode;

  // Blockquote
  late TextEditingController _blockquoteController;
  late TextEditingController _blockquoteAuthorController;

  // List (one controller per item)
  List<TextEditingController> _listItemControllers = [];

  // Code
  late CodeController _codeController;
  String _codeLanguage = 'text';

  // Math
  late TextEditingController _latexController;
  late TextEditingController _captionController;

  // Image
  late TextEditingController _imageUrlController;
  late TextEditingController _imageCaptionController;

  // Table (2D list of controllers, rows × cols)
  List<List<TextEditingController>> _tableCellControllers = [];

  late Debouncer _debouncer;

  /// Currently selected content type for the hidden section.
  String _contentType = 'paragraph';

  // ---------------------------------------------------------------------------
  // BaseEditableBlockState contract
  // ---------------------------------------------------------------------------

  @override
  Map<String, dynamic> getDefaultContent() => {
    'title': '',
    'contentType': 'paragraph',
    'contentData': {'content': ''},
    'initiallyOpen': false,
  };

  @override
  void initializeBlockSpecifics() {
    _titleFocusNode = FocusNode();
    _paragraphFocusNode = FocusNode();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

    _titleController = TextEditingController(text: content['title'] ?? '');

    _contentType = content['contentType']?.toString() ?? 'paragraph';
    // Migrate legacy 'header' content type to 'paragraph' since header is no
    // longer an option in the editor.  The text content format is identical.
    if (_contentType == 'header') _contentType = 'paragraph';
    final data = _extractContentData();

    // Paragraph
    _paragraphController = TextEditingController(
      text: _contentType == 'paragraph' ? data['content']?.toString() ?? '' : '',
    );

    // Blockquote
    _blockquoteController = TextEditingController(
      text: _contentType == 'blockquote' ? data['content']?.toString() ?? '' : '',
    );
    _blockquoteAuthorController = TextEditingController(
      text: _contentType == 'blockquote' ? data['author']?.toString() ?? '' : '',
    );

    // List
    final rawItems = _contentType == 'list'
        ? (data['items'] as List?)?.map((e) => e.toString()).toList() ?? <String>[]
        : <String>[];
    _listItemControllers = rawItems.isEmpty
        ? [TextEditingController()]
        : rawItems.map((e) => TextEditingController(text: e)).toList();

    // Code
    _codeLanguage = _contentType == 'code'
        ? data['language']?.toString() ?? 'text'
        : 'text';
    _codeController = CodeController(
      text: _contentType == 'code' ? data['content']?.toString() ?? '' : '',
      language: _getCodeMode(_codeLanguage),
    );
    _codeController.addListener(() {
      if (_contentType == 'code') _debouncer.call(_saveContentLocal);
    });

    // Math
    _latexController = TextEditingController(
      text: _contentType == 'math' ? data['latex']?.toString() ?? '' : '',
    );
    _captionController = TextEditingController(
      text: _contentType == 'math' ? data['caption']?.toString() ?? '' : '',
    );

    // Image
    _imageUrlController = TextEditingController(
      text: _contentType == 'image' ? data['url']?.toString() ?? '' : '',
    );
    _imageCaptionController = TextEditingController(
      text: _contentType == 'image' ? data['caption']?.toString() ?? '' : '',
    );

    // Table
    final tableRows = _contentType == 'table'
        ? _parseTableRows(data['rows'])
        : [
            ['Header 1', 'Header 2'],
            ['', ''],
          ];
    _tableCellControllers = tableRows
        .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
  }

  @override
  void onContentChanged() {
    final newTitle = content['title']?.toString() ?? '';
    if (_titleController.text != newTitle) _titleController.text = newTitle;

    // Migrate legacy 'header' to 'paragraph'.
    final raw = content['contentType']?.toString() ?? 'paragraph';
    final newType = raw == 'header' ? 'paragraph' : raw;
    final data = _extractContentData();
    if (_contentType != newType) setState(() => _contentType = newType);

    switch (newType) {
      case 'paragraph':
        final t = data['content']?.toString() ?? '';
        if (_paragraphController.text != t) _paragraphController.text = t;
        break;
      case 'blockquote':
        final t = data['content']?.toString() ?? '';
        if (_blockquoteController.text != t) _blockquoteController.text = t;
        final a = data['author']?.toString() ?? '';
        if (_blockquoteAuthorController.text != a) {
          _blockquoteAuthorController.text = a;
        }
        break;
      case 'list':
        final items = (data['items'] as List?)
                ?.map((e) => e.toString()).toList() ??
            <String>[];
        if (items.length != _listItemControllers.length) {
          for (final c in _listItemControllers) c.dispose();
          setState(() {
            _listItemControllers = items.isEmpty
                ? [TextEditingController()]
                : items.map((e) => TextEditingController(text: e)).toList();
          });
        } else {
          for (var i = 0; i < items.length; i++) {
            if (_listItemControllers[i].text != items[i]) {
              _listItemControllers[i].text = items[i];
            }
          }
        }
        break;
      case 'code':
        final ct = data['content']?.toString() ?? '';
        if (_codeController.text != ct) _codeController.text = ct;
        final lang = data['language']?.toString() ?? 'text';
        if (_codeLanguage != lang) {
          setState(() => _codeLanguage = lang);
          _codeController.language = _getCodeMode(lang);
        }
        break;
      case 'math':
        final l = data['latex']?.toString() ?? '';
        if (_latexController.text != l) _latexController.text = l;
        final c = data['caption']?.toString() ?? '';
        if (_captionController.text != c) _captionController.text = c;
        break;
      case 'image':
        final url = data['url']?.toString() ?? '';
        if (_imageUrlController.text != url) _imageUrlController.text = url;
        final cap = data['caption']?.toString() ?? '';
        if (_imageCaptionController.text != cap) _imageCaptionController.text = cap;
        break;
      case 'table':
        final newRows = _parseTableRows(data['rows']);
        if (_tableDataDiffers(newRows)) {
          for (final row in _tableCellControllers) {
            for (final ctrl in row) ctrl.dispose();
          }
          setState(() {
            _tableCellControllers = newRows
                .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
                .toList();
          });
        }
        break;
    }
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _paragraphController.dispose();
    _paragraphFocusNode.dispose();
    _blockquoteController.dispose();
    _blockquoteAuthorController.dispose();
    for (final c in _listItemControllers) c.dispose();
    _codeController.dispose();
    _latexController.dispose();
    _captionController.dispose();
    _imageUrlController.dispose();
    _imageCaptionController.dispose();
    for (final row in _tableCellControllers) {
      for (final ctrl in row) ctrl.dispose();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _extractContentData() {
    final raw = content['contentData'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    // Legacy: text stored in 'content' key directly.
    return {'content': content['content']?.toString() ?? ''};
  }

  List<List<String>> _parseTableRows(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return [
        ['Header 1', 'Header 2'],
        ['', ''],
      ];
    }
    return raw.map<List<String>>((row) {
      if (row is! List) return ['', ''];
      return row.map<String>((cell) => cell?.toString() ?? '').toList();
    }).toList();
  }

  /// Returns true if [newRows] differs from the current [_tableCellControllers] data.
  bool _tableDataDiffers(List<List<String>> newRows) {
    if (newRows.length != _tableCellControllers.length) return true;
    for (var ri = 0; ri < newRows.length; ri++) {
      if (newRows[ri].length != _tableCellControllers[ri].length) return true;
      for (var ci = 0; ci < newRows[ri].length; ci++) {
        if (newRows[ri][ci] != _tableCellControllers[ri][ci].text) return true;
      }
    }
    return false;
  }

  /// Returns the highlight language mode, or null (= plain text).
  dynamic _getCodeMode(String? language) {
    if (language == null || language.isEmpty) return null;
    final lang = language.toLowerCase();
    if (lang == 'text') return null;
    return allLanguages[lang];
  }

  void _saveContentLocal() {
    content['title'] = _titleController.text;
    content['contentType'] = _contentType;
    content['contentData'] = _buildContentData();
    saveContent();
  }

  Map<String, dynamic> _buildContentData() {
    switch (_contentType) {
      case 'blockquote':
        return {
          'content': _blockquoteController.text,
          'author': _blockquoteAuthorController.text,
        };
      case 'list':
        return {
          // Preserve all items (including empty ones) so the UI and stored
          // data stay in sync.  Empty bullet slots that the author intentionally
          // left blank are persisted; the reader already handles them gracefully.
          'items': _listItemControllers.map((c) => c.text).toList(),
        };
      case 'code':
        return {'content': _codeController.text, 'language': _codeLanguage};
      case 'math':
        return {
          'latex': _latexController.text,
          'caption': _captionController.text,
        };
      case 'image':
        return {
          'url': _imageUrlController.text,
          'caption': _imageCaptionController.text,
        };
      case 'table':
        return {
          'rows': _tableCellControllers
              .map((row) => row.map((c) => c.text).toList())
              .toList(),
        };
      case 'paragraph':
      default:
        return {'content': _paragraphController.text};
    }
  }

  void _switchContentType(String type) {
    if (_contentType == type) return;
    if (type == 'table' && _tableCellControllers.isEmpty) {
      _tableCellControllers = [
        [TextEditingController(text: 'Header 1'), TextEditingController(text: 'Header 2')],
        [TextEditingController(), TextEditingController()],
      ];
    }
    setState(() => _contentType = type);
    _saveContentLocal();
  }

  // ---------------------------------------------------------------------------
  // BaseEditableBlockState build hooks
  // ---------------------------------------------------------------------------

  @override
  Widget buildReader(BuildContext context) {
    // IgnorePointer prevents the reader's InkWell from absorbing taps in the
    // non-editing state of the edit screen (the outer GestureDetector then
    // fires and enters edit mode).
    // forceExpanded: true so the edit-screen preview always shows the content
    // open – matching the "5-button checkmark" preview behaviour of other blocks.
    return IgnorePointer(
      child: ExpandableReaderBlock(block: widget.block, forceExpanded: true),
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final blockStyle = widget.block.style;
    final template = blockStyle.expandableTemplate ?? 'default';

    final parsedBg = styleUtils.parseHex(blockStyle.background);
    final parsedColor = styleUtils.parseHex(blockStyle.color);
    final titleColor = parsedColor ?? theme.colorScheme.onSurface;
    final bgColor = parsedBg ?? theme.colorScheme.surface;

    final titleStyle = styleUtils.applyStyle(blockStyle).copyWith(
      fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
      color: titleColor,
      fontSize: blockStyle.fontSize,
    );

    // Content text style derives from the parent block's style so that toolbar
    // formatting (font family, size, color, bold/italic) applies to the inner
    // content area automatically.
    final contentTextStyle = styleUtils.applyStyle(blockStyle).copyWith(
      color: titleColor.withOpacity(0.9),
      fontSize: blockStyle.fontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        _buildExpandableEditorUI(
          context: context,
          theme: theme,
          template: template,
          bgColor: bgColor,
          titleStyle: titleStyle,
          contentTextStyle: contentTextStyle,
          titleColor: titleColor,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Template builders
  // ---------------------------------------------------------------------------

  Widget _buildExpandableEditorUI({
    required BuildContext context,
    required ThemeData theme,
    required String template,
    required Color bgColor,
    required TextStyle titleStyle,
    required TextStyle contentTextStyle,
    required Color titleColor,
  }) {
    switch (template) {
      case 'filled':
        return _buildFilledTemplate(
            context, theme, bgColor, titleStyle, contentTextStyle, titleColor);
      case 'minimal':
        return _buildMinimalTemplate(
            context, theme, titleStyle, contentTextStyle, titleColor);
      case 'card':
        return _buildCardTemplate(
            context, theme, bgColor, titleStyle, contentTextStyle, titleColor);
      case 'outlined':
        return _buildOutlinedTemplate(
            context, theme, titleStyle, contentTextStyle, titleColor);
      case 'accent':
        return _buildAccentTemplate(
            context, theme, bgColor, titleStyle, contentTextStyle, titleColor);
      case 'default':
      default:
        return _buildDefaultTemplate(
            context, theme, bgColor, titleStyle, contentTextStyle, titleColor);
    }
  }

  Widget _buildDefaultTemplate(BuildContext context, ThemeData theme,
      Color bgColor, TextStyle titleStyle, TextStyle contentTextStyle,
      Color titleColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildExpandableContent(
          context, theme, titleStyle, contentTextStyle, titleColor),
    );
  }

  Widget _buildFilledTemplate(BuildContext context, ThemeData theme,
      Color bgColor, TextStyle titleStyle, TextStyle contentTextStyle,
      Color titleColor) {
    final fillColor = bgColor == theme.colorScheme.surface
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : bgColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildExpandableContent(
          context, theme, titleStyle, contentTextStyle, titleColor),
    );
  }

  Widget _buildMinimalTemplate(BuildContext context, ThemeData theme,
      TextStyle titleStyle, TextStyle contentTextStyle, Color titleColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(theme, titleStyle, titleColor, showDivider: true),
          _buildContentArea(context, theme, contentTextStyle, titleColor),
        ],
      ),
    );
  }

  Widget _buildCardTemplate(BuildContext context, ThemeData theme,
      Color bgColor, TextStyle titleStyle, TextStyle contentTextStyle,
      Color titleColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _buildExpandableContent(
          context, theme, titleStyle, contentTextStyle, titleColor),
    );
  }

  Widget _buildOutlinedTemplate(BuildContext context, ThemeData theme,
      TextStyle titleStyle, TextStyle contentTextStyle, Color titleColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildExpandableContent(
          context, theme, titleStyle, contentTextStyle, titleColor),
    );
  }

  Widget _buildAccentTemplate(BuildContext context, ThemeData theme,
      Color bgColor, TextStyle titleStyle, TextStyle contentTextStyle,
      Color titleColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Container(
                color: bgColor == theme.colorScheme.surface
                    ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                    : bgColor,
                child: _buildExpandableContent(
                    context, theme, titleStyle, contentTextStyle, titleColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent(BuildContext context, ThemeData theme,
      TextStyle titleStyle, TextStyle contentTextStyle, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(theme, titleStyle, titleColor),
        _buildContentArea(context, theme, contentTextStyle, titleColor),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header row (title text field + expand indicator)
  // ---------------------------------------------------------------------------

  Widget _buildHeaderRow(
    ThemeData theme,
    TextStyle titleStyle,
    Color titleColor, {
    bool showDivider = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  // Content is always visible in edit mode → use primary colour.
                  style: titleStyle.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Section title...',
                    hintStyle: titleStyle.copyWith(
                      color: titleColor.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _debouncer.call(_saveContentLocal),
                ),
              ),
              const SizedBox(width: 8),
              // Static down-arrow indicates "content visible below" in edit mode.
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
                size: 26,
              ),
            ],
          ),
          if (showDivider)
            Divider(
              height: 12,
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content area – always visible in edit mode
  // ---------------------------------------------------------------------------

  Widget _buildContentArea(
    BuildContext context,
    ThemeData theme,
    TextStyle contentTextStyle,
    Color titleColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Separator
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.3),
                  theme.colorScheme.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // ── Top control row: dropdown (left) + open-by-default switch (right) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Content-type dropdown takes all remaining space
              Expanded(
                child: _buildContentTypeDropdown(theme, titleColor),
              ),
              const SizedBox(width: 8),
              // Compact "open by default" toggle
              _buildOpenByDefaultToggle(theme),
            ],
          ),
          const SizedBox(height: 12),
          // ── Per-type editor ──────────────────────────────────────────────
          _buildContentEditor(context, theme, contentTextStyle, titleColor),
        ],
      ),
    );
  }

  /// Compact inline toggle for the "Open by default in read mode" setting.
  Widget _buildOpenByDefaultToggle(ThemeData theme) {
    final isOn = content['initiallyOpen'] as bool? ?? false;
    return GestureDetector(
      onTap: () {
        setState(() => content['initiallyOpen'] = !isOn);
        _saveContentLocal();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Default open',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOn
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.45),
              fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 2),
          Transform.scale(
            scale: 0.75,
            alignment: Alignment.centerRight,
            child: Switch(
              value: isOn,
              onChanged: (value) {
                setState(() => content['initiallyOpen'] = value);
                _saveContentLocal();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content-type dropdown
  // ---------------------------------------------------------------------------

  Widget _buildContentTypeDropdown(ThemeData theme, Color titleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _contentType,
          icon: Icon(Icons.arrow_drop_down,
              color: theme.colorScheme.primary, size: 20),
          isDense: true,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          // Selected item label
          selectedItemBuilder: (_) => _kContentTypeOptions.map((opt) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.icon, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
          // Dropdown menu items
          items: _kContentTypeOptions.map((opt) {
            final isCurrent = opt.key == _contentType;
            return DropdownMenuItem<String>(
              value: opt.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(opt.icon,
                      size: 16,
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) _switchContentType(v);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Per-type editors
  // ---------------------------------------------------------------------------

  Widget _buildContentEditor(
    BuildContext context,
    ThemeData theme,
    TextStyle contentTextStyle,
    Color titleColor,
  ) {
    switch (_contentType) {
      case 'blockquote':
        return _buildBlockquoteEditor(theme, contentTextStyle, titleColor);
      case 'list':
        return _buildListEditor(theme, contentTextStyle, titleColor);
      case 'code':
        return _buildCodeEditor(context, theme);
      case 'math':
        return _buildMathEditor(theme, titleColor);
      case 'image':
        return _buildImageEditor(theme, titleColor);
      case 'table':
        return _buildTableEditor(theme, contentTextStyle, titleColor);
      case 'paragraph':
      default:
        return _buildParagraphEditor(contentTextStyle, titleColor);
    }
  }

  // ── Paragraph ──────────────────────────────────────────────────────────────

  Widget _buildParagraphEditor(TextStyle contentTextStyle, Color titleColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.18),
        ),
      ),
      child: TextField(
        controller: _paragraphController,
        focusNode: _paragraphFocusNode,
        style: contentTextStyle,
        decoration: InputDecoration(
          hintText: 'Write your content here...',
          hintStyle: contentTextStyle.copyWith(
            color: titleColor.withOpacity(0.35),
          ),
          border: InputBorder.none,
          isCollapsed: true,
        ),
        maxLines: null,
        onChanged: (_) => _debouncer.call(_saveContentLocal),
      ),
    );
  }

  // ── Blockquote ─────────────────────────────────────────────────────────────

  Widget _buildBlockquoteEditor(
      ThemeData theme, TextStyle contentTextStyle, Color titleColor) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.6),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _blockquoteController,
            style: contentTextStyle.copyWith(fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: 'Quote text...',
              hintStyle: contentTextStyle.copyWith(
                color: titleColor.withOpacity(0.35),
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
            maxLines: null,
            onChanged: (_) => _debouncer.call(_saveContentLocal),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withOpacity(0.15),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _blockquoteAuthorController,
            style: contentTextStyle.copyWith(
              fontSize: (contentTextStyle.fontSize ?? 16) * 0.85,
              color: titleColor.withOpacity(0.6),
            ),
            decoration: InputDecoration(
              hintText: '— Author (optional)',
              hintStyle: contentTextStyle.copyWith(
                fontSize: (contentTextStyle.fontSize ?? 16) * 0.85,
                color: titleColor.withOpacity(0.3),
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
            maxLines: 1,
            onChanged: (_) => _debouncer.call(_saveContentLocal),
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildListEditor(
      ThemeData theme, TextStyle contentTextStyle, Color titleColor) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _listItemControllers.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 36,
                color: theme.colorScheme.outline.withOpacity(0.12),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Numbered badge
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _listItemControllers[i],
                      style: contentTextStyle,
                      decoration: InputDecoration(
                        hintText: 'Item ${i + 1}...',
                        hintStyle: contentTextStyle.copyWith(
                          color: titleColor.withOpacity(0.35),
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      maxLines: 1,
                      onChanged: (_) => _debouncer.call(_saveContentLocal),
                    ),
                  ),
                  if (_listItemControllers.length > 1)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _listItemControllers[i].dispose();
                          _listItemControllers.removeAt(i);
                        });
                        _saveContentLocal();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          // ── Add item button at bottom ─────────────────────────────────
          InkWell(
            onTap: () {
              setState(
                  () => _listItemControllers.add(TextEditingController()));
              _saveContentLocal();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.04),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.18),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded,
                      size: 16,
                      color: theme.colorScheme.primary.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Add item',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary.withOpacity(0.8),
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

  // ── Code ───────────────────────────────────────────────────────────────────

  Widget _buildCodeEditor(BuildContext context, ThemeData theme) {
    final brightness = theme.brightness;
    final backgroundColor = CodeBlockStyle.background(brightness);
    final headerBackground = CodeBlockStyle.header(brightness);
    final borderColor = CodeBlockStyle.border(brightness);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: headerBackground,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () => _showCodeLanguageSelector(context, theme),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code,
                        color: theme.colorScheme.onSurfaceVariant, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      getLanguageDisplayName(_codeLanguage),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant, size: 16),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
          CodeTheme(
            data: CodeThemeData(
              styles: brightness == Brightness.dark
                  ? atomOneDarkTheme
                  : atomOneLightTheme,
            ),
            child: CodeField(
              controller: _codeController,
              enabled: widget.isEditing,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(
                theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              textStyle: CodeBlockStyle.codeTextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCodeLanguageSelector(
      BuildContext context, ThemeData theme) async {
    final supportedLanguages = ref.read(supportedLanguagesProvider);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Select Language',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: supportedLanguages.map((lang) {
                final isSelected = lang == _codeLanguage;
                return ListTile(
                  title: Text(
                    getLanguageDisplayName(lang),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  leading: isSelected
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _codeLanguage = lang;
                      _codeController.language = _getCodeMode(lang);
                    });
                    _saveContentLocal();
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ── Math ───────────────────────────────────────────────────────────────────

  Widget _buildMathEditor(ThemeData theme, Color titleColor) {
    final equations = _latexController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (equations.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: theme.colorScheme.surface,
              border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                equations.first,
                textStyle: TextStyle(fontSize: 18, color: titleColor),
                onErrorFallback: (_) => Text(
                  'Invalid LaTeX',
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 12),
                ),
              ),
            ),
          ),
        TextField(
          controller: _latexController,
          style: TextStyle(
              fontFamily: 'monospace', color: titleColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'LaTeX expression (e.g., E = mc^2)',
            hintStyle:
                TextStyle(color: titleColor.withOpacity(0.4), fontSize: 14),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          maxLines: null,
          onChanged: (_) {
            _debouncer.call(_saveContentLocal);
            setState(() {}); // refresh live preview
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: titleColor.withOpacity(0.7),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Optional caption...',
            hintStyle:
                TextStyle(color: titleColor.withOpacity(0.3), fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          maxLines: 1,
          onChanged: (_) => _debouncer.call(_saveContentLocal),
        ),
      ],
    );
  }

  // ── Image ──────────────────────────────────────────────────────────────────

  Widget _buildImageEditor(ThemeData theme, Color titleColor) {
    final imageUrl = _imageUrlController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _imageUrlController,
                style: TextStyle(color: titleColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Image URL…',
                  hintStyle: TextStyle(color: titleColor.withOpacity(0.4), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  prefixIcon: Icon(Icons.link_rounded, size: 16, color: titleColor.withOpacity(0.5)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
                ),
                maxLines: 1,
                onChanged: (_) {
                  _debouncer.call(_saveContentLocal);
                  setState(() {}); // refresh preview
                },
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _imageCaptionController,
                style: TextStyle(fontStyle: FontStyle.italic, color: titleColor.withOpacity(0.7), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Caption (optional)',
                  hintStyle: TextStyle(color: titleColor.withOpacity(0.3), fontSize: 13, fontStyle: FontStyle.italic),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
                onChanged: (_) => _debouncer.call(_saveContentLocal),
              ),
            ],
          ),
        ),
        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Unable to load image',
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Local path: $imageUrl',
                        style: TextStyle(color: titleColor.withOpacity(0.6), fontSize: 12),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────

  Widget _buildTableEditor(ThemeData theme, TextStyle contentTextStyle, Color titleColor) {
    // Guard: ensure table has at least the default header + one data row.
    if (_tableCellControllers.isEmpty) {
      _tableCellControllers = [
        [TextEditingController(text: 'Header 1'), TextEditingController(text: 'Header 2')],
        [TextEditingController(), TextEditingController()],
      ];
    }
    final rows = _tableCellControllers;
    final colCount = rows[0].length;

    void addRow() {
      setState(() => _tableCellControllers.add(
            List.generate(colCount, (_) => TextEditingController()),
          ));
      _saveContentLocal();
    }

    void removeRow(int ri) {
      if (_tableCellControllers.length <= 1) return;
      setState(() {
        for (final ctrl in _tableCellControllers[ri]) ctrl.dispose();
        _tableCellControllers.removeAt(ri);
      });
      _saveContentLocal();
    }

    void addColumn() {
      setState(() {
        for (final row in _tableCellControllers) {
          row.add(TextEditingController());
        }
      });
      _saveContentLocal();
    }

    void removeColumn() {
      if (colCount <= 1) return;
      setState(() {
        for (final row in _tableCellControllers) {
          if (row.isNotEmpty) {
            row.last.dispose();
            row.removeLast();
          }
        }
      });
      _saveContentLocal();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var ri = 0; ri < rows.length; ri++) ...[
                    if (ri > 0)
                      Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.12)),
                    Row(
                      children: [
                        for (var ci = 0; ci < rows[ri].length; ci++) ...[
                          if (ci > 0)
                            Container(
                              width: 1,
                              height: 36,
                              color: theme.colorScheme.outline.withOpacity(0.12),
                            ),
                          SizedBox(
                            width: 100,
                            child: Container(
                              color: ri == 0
                                  ? theme.colorScheme.primary.withOpacity(0.06)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: TextField(
                                controller: rows[ri][ci],
                                style: contentTextStyle.copyWith(
                                  fontSize: 13,
                                  fontWeight: ri == 0 ? FontWeight.w600 : FontWeight.normal,
                                  color: titleColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: ri == 0 ? 'Header ${ci + 1}' : 'Cell',
                                  hintStyle: TextStyle(color: titleColor.withOpacity(0.3), fontSize: 12),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                maxLines: 1,
                                onChanged: (_) => _debouncer.call(_saveContentLocal),
                              ),
                            ),
                          ),
                        ],
                        if (ri > 0 && rows.length > 1)
                          GestureDetector(
                            onTap: () => removeRow(ri),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.close_rounded, size: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.35)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.18)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _tableActionBtn(theme, Icons.add_rounded, '+ Row', addRow),
                const SizedBox(width: 8),
                _tableActionBtn(theme, Icons.view_column_rounded, '+ Col', addColumn),
                if (colCount > 1) ...[
                  const SizedBox(width: 8),
                  _tableActionBtn(theme, Icons.view_column_rounded, '− Col', removeColumn),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableActionBtn(ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: theme.colorScheme.primary.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
