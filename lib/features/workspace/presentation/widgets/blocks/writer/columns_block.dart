import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/block_empty_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/columns_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/services/image_file_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/column_template_selector.dart';
import 'package:barruu/features/workspace/constants/block_dimension_constants.dart';

/// Columns block for multi-column layout with image support.
///
/// Content format:
/// ```json
/// {
///   "columns": [
///     {
///       "width": 0.5,
///       "content": "Left column content",
///       "imagePath": "path/to/image.jpg"
///     },
///     {
///       "width": 0.5,
///       "content": "Right column content"
///     }
///   ],
///   "gap": 16.0,
///   "columnStyle": "elevated",
///   "columnTemplate": "standard"
/// }
/// ```
class ColumnsBlock extends BaseEditableBlock {
  const ColumnsBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<ColumnsBlock> createState() => _ColumnsBlockState();
}

class _ColumnsBlockState extends BaseEditableBlockState<ColumnsBlock> {
  late double _gap;
  late String _columnStyle;
  late String _columnTemplate;
  late Debouncer _debouncer;
  late ImageFileService _imageFileService;
  final Map<int, TextEditingController> _columnControllers = {};

  @override
  Map<String, dynamic> getDefaultContent() => {
    'columns': [],
    'gap': 16.0,
    'columnStyle': 'elevated',
    'columnTemplate': 'standard',
  };

  @override
  void initializeBlockSpecifics() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _imageFileService = ImageFileService();

    // Ensure columns is a list
    if (content['columns'] is! List) {
      content['columns'] = [];
    }

    _gap = (content['gap'] as num?)?.toDouble() ?? 16.0;
    _columnStyle = content['columnStyle']?.toString() ?? 'elevated';
    _columnTemplate = content['columnTemplate']?.toString() ?? 'standard';

    // Initialize controllers for existing columns
    _initializeColumnControllers();
  }

  @override
  void onContentChanged() {
    _gap = (content['gap'] as num?)?.toDouble() ?? 16.0;
    _columnStyle = content['columnStyle']?.toString() ?? 'elevated';
    _columnTemplate = content['columnTemplate']?.toString() ?? 'standard';

    // Update controllers when content changes externally
    _updateColumnControllers();
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _disposeColumnControllers();
  }

  void _initializeColumnControllers() {
    final columns = content['columns'] as List;
    for (int i = 0; i < columns.length; i++) {
      if (!_columnControllers.containsKey(i)) {
        final column = columns[i] as Map<String, dynamic>;
        _columnControllers[i] = TextEditingController(
          text: column['content']?.toString() ?? '',
        );
      }
    }
  }

  void _updateColumnControllers() {
    final columns = content['columns'] as List;

    // Remove controllers for columns that no longer exist
    _columnControllers.removeWhere((key, controller) {
      if (key >= columns.length) {
        controller.dispose();
        return true;
      }
      return false;
    });

    // Update existing controllers and create new ones
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i] as Map<String, dynamic>;
      final text = column['content']?.toString() ?? '';

      if (_columnControllers.containsKey(i)) {
        // Only update if text is different to avoid cursor reset
        if (_columnControllers[i]!.text != text) {
          _columnControllers[i]!.text = text;
        }
      } else {
        _columnControllers[i] = TextEditingController(text: text);
      }
    }
  }

  void _disposeColumnControllers() {
    for (var controller in _columnControllers.values) {
      controller.dispose();
    }
    _columnControllers.clear();
  }

  void _addColumn() {
    final columns = List<Map<String, dynamic>>.from(content['columns'] as List);
    if (columns.length < 4) {
      // Redistribute widths evenly
      final newWidth = 1.0 / (columns.length + 1);
      for (var column in columns) {
        column['width'] = newWidth;
      }

      final newIndex = columns.length;
      columns.add({'width': newWidth, 'content': '', 'imagePath': ''});

      content['columns'] = columns;

      // Create controller for new column
      _columnControllers[newIndex] = TextEditingController(text: '');

      saveContent();
    }
  }

  void _removeColumn(int index) {
    final columns = List<Map<String, dynamic>>.from(content['columns'] as List);
    if (columns.length <= 1 || index < 0 || index >= columns.length) return;

    final removedColumn = Map<String, dynamic>.from(columns[index]);
    columns.removeAt(index);

    // Redistribute widths evenly
    final newWidth = 1.0 / columns.length;
    for (var column in columns) {
      column['width'] = newWidth;
    }

    content['columns'] = columns;

    // Dispose and remove controller for removed column
    _columnControllers[index]?.dispose();
    _columnControllers.remove(index);

    // Reindex remaining controllers
    final newControllers = <int, TextEditingController>{};
    for (var entry in _columnControllers.entries) {
      if (entry.key > index) {
        newControllers[entry.key - 1] = entry.value;
      } else {
        newControllers[entry.key] = entry.value;
      }
    }
    _columnControllers.clear();
    _columnControllers.addAll(newControllers);

    setState(() {});
    saveContent();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: BlockDimensionConstants.undoSnackbarDuration,
        content: const Text('Column deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final currentColumns = List<Map<String, dynamic>>.from(
              content['columns'] as List,
            );
            currentColumns.insert(index, removedColumn);
            // Redistribute widths
            final restoredWidth = 1.0 / currentColumns.length;
            for (var c in currentColumns) {
              c['width'] = restoredWidth;
            }
            content['columns'] = currentColumns;

            final shifted = <int, TextEditingController>{};
            for (var e in _columnControllers.entries) {
              shifted[e.key >= index ? e.key + 1 : e.key] = e.value;
            }
            _columnControllers.clear();
            _columnControllers.addAll(shifted);

            setState(() {});
            saveContent();
          },
        ),
      ),
    );
  }

  void _updateColumn(int index, String value) {
    final columns = List<Map<String, dynamic>>.from(content['columns'] as List);
    if (index >= 0 && index < columns.length) {
      columns[index]['content'] = value;
      content['columns'] = columns;
      _debouncer.call(() => saveContent());
    }
  }

  void _updateColumnAlign(int index, String align) {
    final columns = List<Map<String, dynamic>>.from(content['columns'] as List);
    if (index >= 0 && index < columns.length) {
      columns[index]['align'] = align;
      content['columns'] = columns;
      setState(() {});
      saveContent();
    }
  }

  void _updateGap(double newGap) {
    setState(() {
      _gap = newGap;
      content['gap'] = newGap;
      saveContent();
    });
  }

  void _updateColumnStyle(String newStyle) {
    setState(() {
      _columnStyle = newStyle;
      content['columnStyle'] = newStyle;
      saveContent();
    });
  }

  void _updateColumnTemplate(String newTemplate) {
    setState(() {
      _columnTemplate = newTemplate;
      content['columnTemplate'] = newTemplate;
      saveContent();
    });
  }

  Future<void> _addImageToColumn(int columnIndex) async {
    final images = await _imageFileService.pickAndSaveImages(widget.docDir);
    if (images != null && images.isNotEmpty) {
      final columns = List<Map<String, dynamic>>.from(
        content['columns'] as List,
      );
      if (columnIndex >= 0 && columnIndex < columns.length) {
        columns[columnIndex]['imagePath'] = images[0]['path'];
        content['columns'] = columns;
        saveContent();
      }
    }
  }

  /// Replaces the existing column image: removes old file, then picks a new one.
  Future<void> _changeImageInColumn(int columnIndex) async {
    final columns = List<Map<String, dynamic>>.from(content['columns'] as List);
    if (columnIndex < 0 || columnIndex >= columns.length) return;
    // Delete old file
    final oldPath = columns[columnIndex]['imagePath'] as String?;
    if (oldPath != null && oldPath.isNotEmpty) {
      final file = File('${widget.docDir.path}/$oldPath');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    columns[columnIndex]['imagePath'] = '';
    content['columns'] = columns;
    saveContent();
    // Pick new image
    final images = await _imageFileService.pickAndSaveImages(widget.docDir);
    if (images != null && images.isNotEmpty) {
      final updated = List<Map<String, dynamic>>.from(
        content['columns'] as List,
      );
      if (columnIndex < updated.length) {
        updated[columnIndex]['imagePath'] = images[0]['path'];
        content['columns'] = updated;
        saveContent();
      }
    }
  }

  void _removeImageFromColumn(int columnIndex) {
    final columns = List<Map<String, dynamic>>.from(content['columns'] as List);
    if (columnIndex >= 0 && columnIndex < columns.length) {
      final imagePath = columns[columnIndex]['imagePath'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File('${widget.docDir.path}/$imagePath');
        if (file.existsSync()) {
          file.deleteSync();
        }
      }

      columns[columnIndex]['imagePath'] = '';
      content['columns'] = columns;
      saveContent();
    }
  }

  @override
  Widget buildReader(BuildContext context) {
    return ColumnsReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final columns = content['columns'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Columns',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Visual template selector button
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ColumnTemplateSelector(
                              selectedTemplate: _columnTemplate,
                              onTemplateSelected: (value) {
                                _updateColumnTemplate(value);
                                Navigator.of(context).pop();
                              },
                              theme: theme,
                            ),
                          );
                        },
                        icon: const Icon(IconsaxPlusLinear.gallery, size: 16),
                        label: Text(_getTemplateDisplayName(_columnTemplate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Style selector
                      DropdownButton<String>(
                        value: _columnStyle,
                        hint: const Text('Style'),
                        items: const [
                          DropdownMenuItem(
                            value: 'elevated',
                            child: Text('Elevated'),
                          ),
                          DropdownMenuItem(
                            value: 'outlined',
                            child: Text('Outlined'),
                          ),
                          DropdownMenuItem(
                            value: 'filled',
                            child: Text('Filled'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updateColumnStyle(value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gap slider
              Row(
                children: [
                  Text(
                    'Gap: ${_gap.toInt()}px',
                    style: theme.textTheme.bodySmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: _gap,
                      min: 0,
                      max: 48,
                      divisions: 12,
                      onChanged: (value) => _updateGap(value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Columns editors
              if (columns.isEmpty)
                BlockEmptyState(
                  icon: Icons.view_week_outlined,
                  message: 'No columns yet',
                  actionLabel: 'Add Column',
                  onAction: _addColumn,
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(columns.length, (index) {
                    final column = columns[index] as Map<String, dynamic>;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < columns.length - 1 ? _gap / 2 : 0,
                          left: index > 0 ? _gap / 2 : 0,
                        ),
                        child: _buildColumnEditor(theme, column, index),
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 12),

              // Add/Remove buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: columns.length < 4 ? _addColumn : null,
                    icon: const Icon(IconsaxPlusLinear.add),
                    label: const Text('Add'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: columns.length > 1
                        ? () => _removeColumn(columns.length - 1)
                        : null,
                    icon: const Icon(IconsaxPlusLinear.minus),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlignButton(
    Map<String, dynamic> column,
    int index,
    String align,
    IconData icon,
  ) {
    final current = column['align'] as String? ?? 'left';
    final isSelected = current == align;
    final theme = Theme.of(context);
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 14),
        padding: EdgeInsets.zero,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        onPressed: () => _updateColumnAlign(index, align),
        tooltip: align[0].toUpperCase() + align.substring(1),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildColumnEditor(
    ThemeData theme,
    Map<String, dynamic> column,
    int index,
  ) {
    final imagePath = column['imagePath'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    // Ensure controller exists for this column
    if (!_columnControllers.containsKey(index)) {
      _columnControllers[index] = TextEditingController(
        text: column['content']?.toString() ?? '',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Column ${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Per-column text alignment toggle
                  _buildAlignButton(
                    column,
                    index,
                    'left',
                    Icons.format_align_left,
                  ),
                  _buildAlignButton(
                    column,
                    index,
                    'center',
                    Icons.format_align_center,
                  ),
                  _buildAlignButton(
                    column,
                    index,
                    'right',
                    Icons.format_align_right,
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.gallery_edit,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      onPressed: () => _changeImageInColumn(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Change image',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.close_circle,
                        color: theme.colorScheme.error,
                        size: 18,
                      ),
                      onPressed: () => _removeImageFromColumn(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove image',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Image display or add button
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File('${widget.docDir.path}/$imagePath'),
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _addImageToColumn(index),
              icon: const Icon(IconsaxPlusLinear.gallery_add, size: 16),
              label: const Text('Add Image', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),

          const SizedBox(height: 8),
          TextField(
            controller: _columnControllers[index],
            style: theme.textTheme.bodySmall,
            decoration: const InputDecoration(
              hintText: 'Content',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            onChanged: (value) => _updateColumn(index, value),
          ),
        ],
      ),
    );
  }

  String _getTemplateDisplayName(String template) {
    switch (template) {
      case 'standard':
        return 'Standard';
      case 'sidebar':
        return 'Sidebar';
      case 'hero':
        return 'Hero';
      case 'grid':
        return 'Grid';
      case 'card':
        return 'Card';
      case 'compact':
        return 'Compact';
      case 'featured':
        return 'Featured';
      case 'overlay':
        return 'Overlay';
      case 'magazine':
        return 'Magazine';
      case 'split':
        return 'Split';
      case 'banner':
        return 'Banner';
      case 'avatar':
        return 'Avatar';
      case 'icon':
        return 'Icon';
      default:
        return 'Standard';
    }
  }
}
