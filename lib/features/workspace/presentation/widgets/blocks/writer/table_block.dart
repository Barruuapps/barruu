
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/block_empty_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/table_reader_block.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class TableBlock extends BaseEditableBlock {
  const TableBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends BaseEditableBlockState<TableBlock> {
  static const int _maxColumns = 8;

  late TextEditingController _headerController;
  final FocusNode _headerFocusNode = FocusNode();
  late final Debouncer _debouncer;

  // Grid: rows x columns of controllers
  final List<List<TextEditingController>> _cellControllers = [];

  @override
  Map<String, dynamic> getDefaultContent() => {
    'header': '',
    'rows': [
      ['', ''],
      ['', ''],
    ],
  };

  @override
  void initializeBlockSpecifics() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

    if (content['rows'] == null || content['rows'] is! List) {
      content['rows'] = [['', ''], ['', '']];
    }
    if (content['header'] == null) {
      content['header'] = '';
    }

    _headerController = TextEditingController(text: content['header']?.toString() ?? '');
    _initCellControllers();
  }

  @override
  void onContentChanged() {
    if (content['rows'] == null || content['rows'] is! List) {
      content['rows'] = [['', ''], ['', '']];
    }
    if (content['header'] == null) {
      content['header'] = '';
    }

    _headerController.text = content['header']?.toString() ?? '';

    // Sync cell controllers only if dimensions changed
    final rows = content['rows'] as List;
    final newNumRows = rows.length;
    final newNumCols = newNumRows > 0 ? (rows[0] as List).length : 0;

    if (_cellControllers.length != newNumRows ||
        (_cellControllers.isNotEmpty && _cellControllers[0].length != newNumCols)) {
      _disposeCellControllers();
      _initCellControllers();
    } else {
      // Just update text without full reinit to avoid disrupting focus
      for (int r = 0; r < newNumRows; r++) {
        final row = rows[r] as List;
        for (int c = 0; c < row.length && c < _cellControllers[r].length; c++) {
          final text = row[c]?.toString() ?? '';
          if (_cellControllers[r][c].text != text) {
            _cellControllers[r][c].text = text;
          }
        }
      }
    }
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _headerController.dispose();
    _headerFocusNode.dispose();
    _disposeCellControllers();
  }

  void _initCellControllers() {
    _cellControllers.clear();
    final rows = content['rows'] as List;
    for (final row in rows) {
      final rowList = row as List;
      _cellControllers.add(
        rowList.map((cell) => TextEditingController(text: cell?.toString() ?? '')).toList(),
      );
    }
  }

  void _disposeCellControllers() {
    for (final row in _cellControllers) {
      for (final ctrl in row) {
        ctrl.dispose();
      }
    }
    _cellControllers.clear();
  }

  void _saveFromGrid() {
    final rows = _cellControllers
        .map((row) => row.map((ctrl) => ctrl.text).toList())
        .toList();
    content['header'] = _headerController.text.trim();
    content['rows'] = rows;
    saveContent();
  }

  int get _numCols {
    final rows = content['rows'] as List;
    if (rows.isEmpty) return 2;
    return (rows[0] as List).length;
  }

  void _addRow() {
    final cols = _numCols;
    final newRow = List<String>.filled(cols, '');
    final rows = List<List<dynamic>>.from(
      (content['rows'] as List).map((r) => List<dynamic>.from(r as List)),
    );
    rows.add(newRow);
    content['rows'] = rows;
    setState(() {
      _cellControllers.add(newRow.map((c) => TextEditingController(text: c)).toList());
    });
    saveContent();
  }

  void _removeLastRow() {
    final rows = content['rows'] as List;
    if (rows.length <= 1) return;
    final updatedRows = List<List<dynamic>>.from(
      rows.map((r) => List<dynamic>.from(r as List)),
    );
    updatedRows.removeLast();
    content['rows'] = updatedRows;
    setState(() {
      final lastRow = _cellControllers.removeLast();
      for (final ctrl in lastRow) {
        ctrl.dispose();
      }
    });
    saveContent();
  }

  void _addColumn() {
    if (_numCols >= _maxColumns) return;
    final rows = List<List<dynamic>>.from(
      (content['rows'] as List).map((r) => List<dynamic>.from(r as List)..add('')),
    );
    content['rows'] = rows;
    setState(() {
      for (int i = 0; i < _cellControllers.length; i++) {
        _cellControllers[i].add(TextEditingController(text: ''));
      }
    });
    saveContent();
  }

  void _removeLastColumn() {
    if (_numCols <= 1) return;
    final rows = List<List<dynamic>>.from(
      (content['rows'] as List).map((r) {
        final row = List<dynamic>.from(r as List);
        row.removeLast();
        return row;
      }),
    );
    content['rows'] = rows;
    setState(() {
      for (final row in _cellControllers) {
        final ctrl = row.removeLast();
        ctrl.dispose();
      }
    });
    saveContent();
  }

  @override
  Widget buildReader(BuildContext context) {
    return TableReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final textStyle = styleUtils.applyStyle(widget.block.style);
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final rows = content['rows'] as List;
    final numCols = _numCols;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        // Table title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: TextField(
            key: const ValueKey('table_header'),
            controller: _headerController,
            focusNode: _headerFocusNode,
            textAlign: textAlign,
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Table Title (optional)',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
            style: textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
            onChanged: (_) => _debouncer.call(_saveFromGrid),
          ),
        ),

        // Interactive grid editor
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid (or empty state when all rows are removed)
              if (rows.isEmpty)
                BlockEmptyState(
                  icon: Icons.table_chart_outlined,
                  message: 'No rows yet',
                  actionLabel: 'Add Row',
                  onAction: _addRow,
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                    columnWidths: {
                      for (int c = 0; c < numCols; c++) c: const FixedColumnWidth(120),
                    },
                  children: List.generate(rows.length, (rowIdx) {
                    final isFirstRow = rowIdx == 0;
                    return TableRow(
                      decoration: isFirstRow
                          ? BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                            )
                          : null,
                      children: List.generate(numCols, (colIdx) {
                        if (rowIdx >= _cellControllers.length ||
                            colIdx >= _cellControllers[rowIdx].length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: TextField(
                            controller: _cellControllers[rowIdx][colIdx],
                            style: textStyle.copyWith(
                              fontSize: 13,
                              fontWeight: isFirstRow ? FontWeight.w600 : FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                            ),
                            maxLines: null,
                            onChanged: (_) => _debouncer.call(_saveFromGrid),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 8),

              // Row/column controls
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Row'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (rows.length > 1) ? _removeLastRow : null,
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('Remove Row'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (numCols < _maxColumns) ? _addColumn : null,
                    icon: const Icon(Icons.view_column, size: 16),
                    label: const Text('Add Col'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (numCols > 1) ? _removeLastColumn : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Remove Col'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                'First row is treated as header',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
