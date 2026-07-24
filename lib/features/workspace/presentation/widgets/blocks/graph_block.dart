import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/graph_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/enhanced_graph_editor.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/graph_controller.dart';
import 'package:barruu/features/workspace/presentation/services/graph_utilities.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GraphType { line, parametric, polar, bar, scatter }

/// Maximum number of simultaneous equations allowed on a line graph.
const int kMaxEquations = 6;

class GraphBlock extends BaseEditableBlock {
  const GraphBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<GraphBlock> createState() => _GraphBlockState();
}

class _GraphBlockState extends BaseEditableBlockState<GraphBlock> {
  /// One controller per equation for [GraphType.line]; other types use index 0 only.
  final List<TextEditingController> _equationControllers = [];

  /// Index of the equation row whose text field is currently focused.
  int _activeEquationIndex = 0;

  late TextEditingController _captionController;
  late TextEditingController _minXController;
  late TextEditingController _maxXController;

  /// A single [FocusNode] is shared with the *first* equation field (line type)
  /// or the single expression field (other types).  Subsequent equation rows
  /// manage their own implicit focus without an explicit node.
  final FocusNode _focusNode = FocusNode();
  GraphType _selectedGraphType = GraphType.line;

  // -------------------------------------------------------------------------
  // BaseEditableBlock lifecycle
  // -------------------------------------------------------------------------

  @override
  Map<String, dynamic> getDefaultContent() => {
    'type': 'line',
    'expression': '',
    'caption': '',
    'min_x': '-10',
    'max_x': '10',
    'color_scheme': 'default',
  };

  @override
  void initializeBlockSpecifics() {
    _selectedGraphType = _getGraphTypeFromString(content['type'] ?? 'line');
    _captionController = TextEditingController(text: content['caption'] ?? '');
    _minXController = TextEditingController(text: content['min_x'] ?? '-10');
    _maxXController = TextEditingController(text: content['max_x'] ?? '10');

    _rebuildEquationControllers(content['expression'] as String? ?? '');
  }

  @override
  void onContentChanged() {
    // Guard against calls that arrive after the widget has been disposed
    // (e.g. an async saveContent() completes after the user navigated away).
    if (!mounted) return;

    final expression = content['expression'] as String? ?? '';
    final prevLength = _equationControllers.length;
    _reconcileEquationControllers(expression);

    if (_captionController.text != content['caption']) {
      _captionController.text = content['caption'] ?? '';
    }
    if (_minXController.text != content['min_x']) {
      _minXController.text = content['min_x'] ?? '-10';
    }
    if (_maxXController.text != content['max_x']) {
      _maxXController.text = content['max_x'] ?? '10';
    }
    final newType = _getGraphTypeFromString(content['type'] ?? 'line');
    final lengthChanged = _equationControllers.length != prevLength;
    if (_selectedGraphType != newType || lengthChanged) {
      setState(() {
        _selectedGraphType = newType;
      });
    }
  }

  @override
  void disposeBlockSpecifics() {
    for (final ctrl in _equationControllers) {
      ctrl.dispose();
    }
    _captionController.dispose();
    _minXController.dispose();
    _maxXController.dispose();
    _focusNode.dispose();
  }

  // -------------------------------------------------------------------------
  // Equation controller management
  // -------------------------------------------------------------------------

  /// (Re)builds [_equationControllers] from a raw expression string.
  void _rebuildEquationControllers(String expression) {
    for (final c in _equationControllers) {
      c.dispose();
    }
    _equationControllers.clear();

    final parts = _splitExpression(expression);
    for (final part in parts) {
      _equationControllers.add(TextEditingController(text: part));
    }
    if (_equationControllers.isEmpty) {
      _equationControllers.add(TextEditingController());
    }
    _activeEquationIndex = _activeEquationIndex.clamp(
      0,
      _equationControllers.length - 1,
    );
  }

  /// Reconciles existing controllers with a new expression string without
  /// creating/disposing unnecessarily (preserves cursor positions when possible).
  void _reconcileEquationControllers(String expression) {
    final parts = _splitExpression(expression);
    final desired = parts.isEmpty ? [''] : parts;

    // Grow
    while (_equationControllers.length < desired.length) {
      _equationControllers.add(TextEditingController());
    }
    // Shrink – but only when the user is NOT actively focused on one of the
    // extra (empty) rows they just added.  This prevents a newly-added empty
    // equation from being immediately removed when another field saves.
    while (_equationControllers.length > desired.length &&
        _activeEquationIndex < desired.length) {
      final ctrl = _equationControllers.removeLast();
      // Dispose after the current frame so any TextField that still references
      // the controller can unmount cleanly, avoiding '_elements.contains'
      // assertions from the Flutter framework.
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    }
    // Sync text
    for (
      int i = 0;
      i < desired.length && i < _equationControllers.length;
      i++
    ) {
      if (_equationControllers[i].text != desired[i]) {
        _equationControllers[i].text = desired[i];
      }
    }
    if (_equationControllers.isEmpty) {
      _equationControllers.add(TextEditingController());
    }
    _activeEquationIndex = _activeEquationIndex.clamp(
      0,
      _equationControllers.length - 1,
    );
  }

  /// Splits a raw expression on `;` into trimmed non-empty parts.
  List<String> _splitExpression(String expression) => expression
      .split(';')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  String get _combinedExpression => _equationControllers
      .map((c) => c.text.trim())
      .where((e) => e.isNotEmpty)
      .join('; ');

  // -------------------------------------------------------------------------
  // Add / remove equations
  // -------------------------------------------------------------------------

  void _addEquation() {
    if (_equationControllers.length >= kMaxEquations) return;
    setState(() {
      _equationControllers.add(TextEditingController());
      _activeEquationIndex = _equationControllers.length - 1;
    });
    // Do NOT call _saveContentLocal() here.  The new row is empty so
    // _combinedExpression would omit it, causing onContentChanged() to
    // reconcile it away immediately (deleting the row the user just added).
    // The row will be saved the first time the user types something in it.
  }

  void _removeEquation(int index) {
    if (_equationControllers.length <= 1) return;
    // Save the reference BEFORE setState so it can be disposed afterwards.
    // Disposing inside setState causes the '_elements.contains(element)'
    // Flutter assertion because the TextField using the controller is still
    // part of the element tree during the rebuild.
    final removed = _equationControllers[index];
    setState(() {
      _equationControllers.removeAt(index);
      _activeEquationIndex = _activeEquationIndex.clamp(
        0,
        _equationControllers.length - 1,
      );
    });
    // Dispose after the frame so the old TextField can unmount cleanly.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
    _saveContentLocal();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  GraphType _getGraphTypeFromString(String type) {
    return GraphType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => GraphType.line,
    );
  }

  String _getStringFromGraphType(GraphType type) =>
      type.toString().split('.').last;

  void _saveContentLocal() {
    if (!_validateInputs()) return;

    content['type'] = _getStringFromGraphType(_selectedGraphType);
    content['expression'] = _selectedGraphType == GraphType.line
        ? _combinedExpression
        : _equationControllers.first.text.trim();
    content['caption'] = _captionController.text.trim();
    content['min_x'] = _minXController.text.trim();
    content['max_x'] = _maxXController.text.trim();
    content['color_scheme'] = content['color_scheme'] ?? 'default';

    saveContent();
  }

  bool _validateInputs() {
    final minX = double.tryParse(_minXController.text.trim());
    final maxX = double.tryParse(_maxXController.text.trim());

    if (minX == null || maxX == null || minX >= maxX) {
      showError('Invalid range: minX must be less than maxX');
      return false;
    }

    // Return false silently when all fields are still empty – the user may be
    // in the middle of typing their first equation.
    final hasExpression = _equationControllers.any(
      (c) => c.text.trim().isNotEmpty,
    );
    if (!hasExpression) return false;

    return true;
  }

  bool _isEnhancedGraphType(String typeString) =>
      !kLegacyGraphTypes.contains(typeString);

  // -------------------------------------------------------------------------
  // BaseEditableBlock build overrides
  // -------------------------------------------------------------------------

  @override
  Widget buildReader(BuildContext context) {
    return GraphReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);

    final typeString = content['type']?.toString() ?? 'line';
    if (_isEnhancedGraphType(typeString)) {
      return _buildEnhancedEditingMode(theme, styleUtils);
    }

    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final color =
        styleUtils.parseHex(widget.block.style.color) ??
        theme.colorScheme.onSurface;
    return _buildEditingMode(styleUtils, color, textAlign, theme);
  }

  // -------------------------------------------------------------------------
  // Editor widget builders
  // -------------------------------------------------------------------------

  Widget _buildEnhancedEditingMode(ThemeData theme, StyleUtils styleUtils) {
    final textStyle = styleUtils.applyStyle(widget.block.style);
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final color =
        styleUtils.parseHex(widget.block.style.color) ??
        theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnhancedGraphEditor(
                content: content,
                theme: theme,
                onContentChanged: (newContent) {
                  content = newContent;
                  saveContent();
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                textAlign: textAlign,
                style: textStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: color.withValues(alpha: 0.7),
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  hintText: 'Optional caption...',
                  hintStyle: textStyle.copyWith(
                    color: color.withValues(alpha: 0.3),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) => _saveContentLocal(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditingMode(
    StyleUtils styleUtils,
    Color color,
    TextAlign textAlign,
    ThemeData theme,
  ) {
    final textStyle = styleUtils.applyStyle(widget.block.style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(
            block: widget.block,
            docDir: widget.docDir,
            child: GraphControls(
              controller: ref.read(
                editDocumentControllerProvider(widget.docDir).notifier,
              ),
              block: widget.block,
              expressionController: _equationControllers[_activeEquationIndex],
              onExpressionSaved: _saveContentLocal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Graph type selector – only the two educationally important types.
              _buildGraphTypeSelector(theme),
              const SizedBox(height: 10),

              // Equation input(s)
              if (_selectedGraphType == GraphType.line)
                _buildMultiEquationEditor(theme, textStyle, color, textAlign)
              else
                _buildSingleEquationField(theme, textStyle, color, textAlign),

              const SizedBox(height: 10),

              // X-range
              _buildRangeRow(theme, textStyle, color),

              const SizedBox(height: 10),

              // Caption
              TextField(
                controller: _captionController,
                textAlign: textAlign,
                style: textStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: color.withValues(alpha: 0.7),
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  hintText: 'Optional caption...',
                  hintStyle: textStyle.copyWith(
                    color: color.withValues(alpha: 0.3),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (_) => _saveContentLocal(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Multi-equation editor (line type only) – mobile-first layout
  // ---------------------------------------------------------------------------

  Widget _buildMultiEquationEditor(
    ThemeData theme,
    TextStyle textStyle,
    Color color,
    TextAlign textAlign,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Equations',
            style: textStyle.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // One row per equation controller
        ...List.generate(_equationControllers.length, (i) {
          final equationColor = getEquationColor(i, theme);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Colour indicator dot
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: equationColor,
                    shape: BoxShape.circle,
                  ),
                ),
                // Expression text field
                Expanded(
                  child: TextField(
                    controller: _equationControllers[i],
                    focusNode: i == 0 ? _focusNode : null,
                    maxLines: 1,
                    textAlign: textAlign,
                    style: textStyle.copyWith(
                      fontFamily: 'RobotoMono',
                      color: equationColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: i == 0 ? 'e.g. x^2 + 1' : 'e.g. sin(x)',
                      hintStyle: textStyle.copyWith(
                        color: color.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: equationColor.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: equationColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: _equationControllers.length > 1
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.7,
                              ),
                              tooltip: 'Remove equation',
                              onPressed: () => _removeEquation(i),
                              padding: EdgeInsets.zero,
                            )
                          : null,
                    ),
                    onTap: () {
                      if (_activeEquationIndex != i) {
                        setState(() => _activeEquationIndex = i);
                      }
                    },
                    onChanged: (_) => _saveContentLocal(),
                  ),
                ),
              ],
            ),
          );
        }),

        // "Add equation" button
        if (_equationControllers.length < kMaxEquations)
          TextButton.icon(
            onPressed: _addEquation,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add equation'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 44),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Single-expression field (bar / legacy polar / parametric) – mobile-first
  // ---------------------------------------------------------------------------

  Widget _buildSingleEquationField(
    ThemeData theme,
    TextStyle textStyle,
    Color color,
    TextAlign textAlign,
  ) {
    final ctrl = _equationControllers.isNotEmpty
        ? _equationControllers.first
        : TextEditingController();

    return TextField(
      controller: ctrl,
      focusNode: _focusNode,
      maxLines: null,
      textAlign: textAlign,
      style: textStyle.copyWith(
        fontFamily: 'RobotoMono',
        color: color,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: _getExpressionHint(),
        hintStyle: textStyle.copyWith(
          color: color.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (_) => _saveContentLocal(),
    );
  }

  // ---------------------------------------------------------------------------
  // Range row – mobile-first
  // ---------------------------------------------------------------------------

  Widget _buildRangeRow(ThemeData theme, TextStyle textStyle, Color color) {
    final labelStyle = textStyle.copyWith(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    final fieldDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    return Row(
      children: [
        Text('x range:', style: labelStyle),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _minXController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            style: textStyle.copyWith(color: color, fontSize: 13),
            decoration: fieldDecoration.copyWith(hintText: '-10'),
            onChanged: (_) => _saveContentLocal(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'to',
            style: textStyle.copyWith(color: color, fontSize: 13),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _maxXController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            style: textStyle.copyWith(color: color, fontSize: 13),
            decoration: fieldDecoration.copyWith(hintText: '10'),
            onChanged: (_) => _saveContentLocal(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Graph type selector – only the two types most useful in education
  // ---------------------------------------------------------------------------

  Widget _buildGraphTypeSelector(ThemeData theme) {
    // Legacy blocks may store parametric/polar/scatter; map them to 'line'
    // for the writer UI so the user can still edit the expression.
    final editorType = _selectedGraphType == GraphType.bar
        ? GraphType.bar
        : GraphType.line;

    return SegmentedButton<GraphType>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<GraphType>(
          value: GraphType.line,
          label: Text('Function y = f(x)', overflow: TextOverflow.ellipsis),
          icon: Icon(Icons.show_chart, size: 16),
        ),
        ButtonSegment<GraphType>(
          value: GraphType.bar,
          label: Text('Bar Chart', overflow: TextOverflow.ellipsis),
          icon: Icon(Icons.bar_chart, size: 16),
        ),
      ],
      selected: {editorType},
      onSelectionChanged: (Set<GraphType> selection) {
        final newType = selection.first;
        setState(() {
          _selectedGraphType = newType;
          // Collapse to a single equation for non-line types.
          if (newType != GraphType.line) {
            final firstText = _equationControllers.isNotEmpty
                ? _equationControllers.first.text
                : '';
            _rebuildEquationControllers(firstText);
          }
        });
        _saveContentLocal();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Expression hint text
  // ---------------------------------------------------------------------------

  String _getExpressionHint() {
    if (_selectedGraphType == GraphType.bar) return '10, 20, 15, 25, 30';
    return 'e.g. x^2 + 1';
  }
}
