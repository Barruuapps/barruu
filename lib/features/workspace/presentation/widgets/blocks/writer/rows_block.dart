import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/block_empty_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/rows_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/services/image_file_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/row_template_selector.dart';
import 'package:barruu/features/workspace/constants/block_dimension_constants.dart';

/// Rows block for horizontal layout with image support.
/// 
/// Content format:
/// ```json
/// {
///   "rows": [
///     {
///       "height": 100.0,
///       "content": "First row content",
///       "imagePath": "path/to/image.jpg"
///     },
///     {
///       "height": 100.0,
///       "content": "Second row content"
///     }
///   ],
///   "gap": 16.0,
///   "rowStyle": "elevated",
///   "rowTemplate": "standard"
/// }
/// ```
class RowsBlock extends BaseEditableBlock {
  const RowsBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<RowsBlock> createState() => _RowsBlockState();
}

class _RowsBlockState extends BaseEditableBlockState<RowsBlock> {
  late double _gap;
  late String _rowStyle;
  late String _rowTemplate;
  late Debouncer _debouncer;
  late ImageFileService _imageFileService;
  final Map<int, TextEditingController> _rowControllers = {};

  @override
  Map<String, dynamic> getDefaultContent() => {
    'rows': [],
    'gap': 16.0,
    'rowStyle': 'elevated',
    'rowTemplate': 'standard',
  };

  @override
  void initializeBlockSpecifics() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _imageFileService = ImageFileService();
    
    // Ensure rows is a list
    if (content['rows'] is! List) {
      content['rows'] = [];
    }
    
    _gap = (content['gap'] as num?)?.toDouble() ?? 16.0;
    _rowStyle = content['rowStyle']?.toString() ?? 'elevated';
    _rowTemplate = content['rowTemplate']?.toString() ?? 'standard';
    
    // Initialize controllers for existing rows
    _initializeRowControllers();
  }

  @override
  void onContentChanged() {
    _gap = (content['gap'] as num?)?.toDouble() ?? 16.0;
    _rowStyle = content['rowStyle']?.toString() ?? 'elevated';
    _rowTemplate = content['rowTemplate']?.toString() ?? 'standard';
    
    // Update controllers when content changes externally
    _updateRowControllers();
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _disposeRowControllers();
  }
  
  void _initializeRowControllers() {
    final rows = content['rows'] as List;
    for (int i = 0; i < rows.length; i++) {
      if (!_rowControllers.containsKey(i)) {
        final row = rows[i] as Map<String, dynamic>;
        _rowControllers[i] = TextEditingController(text: row['content']?.toString() ?? '');
      }
    }
  }
  
  void _updateRowControllers() {
    final rows = content['rows'] as List;
    
    // Remove controllers for rows that no longer exist
    _rowControllers.removeWhere((key, controller) {
      if (key >= rows.length) {
        controller.dispose();
        return true;
      }
      return false;
    });
    
    // Update existing controllers and create new ones
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i] as Map<String, dynamic>;
      final text = row['content']?.toString() ?? '';
      
      if (_rowControllers.containsKey(i)) {
        // Only update if text is different to avoid cursor reset
        if (_rowControllers[i]!.text != text) {
          _rowControllers[i]!.text = text;
        }
      } else {
        _rowControllers[i] = TextEditingController(text: text);
      }
    }
  }
  
  void _disposeRowControllers() {
    for (var controller in _rowControllers.values) {
      controller.dispose();
    }
    _rowControllers.clear();
  }

  void _addRow() {
    final rows = List<Map<String, dynamic>>.from(content['rows'] as List);
    if (rows.length < 6) {
      final newIndex = rows.length;
      rows.add({
        'height': 100.0,
        'content': '',
        'imagePath': '',
      });
      
      content['rows'] = rows;
      
      // Create controller for new row
      _rowControllers[newIndex] = TextEditingController(text: '');
      
      saveContent();
    }
  }

  void _removeRow(int index) {
    final rows = List<Map<String, dynamic>>.from(content['rows'] as List);
    if (rows.length <= 1 || index < 0 || index >= rows.length) return;

    final removedRow = Map<String, dynamic>.from(rows[index]);
    final imagePath = removedRow['imagePath'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File('${widget.docDir.path}/$imagePath');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    
    rows.removeAt(index);
    content['rows'] = rows;
    
    // Dispose and remove controller for removed row
    _rowControllers[index]?.dispose();
    _rowControllers.remove(index);
    
    // Reindex remaining controllers
    final newControllers = <int, TextEditingController>{};
    for (var entry in _rowControllers.entries) {
      if (entry.key > index) {
        newControllers[entry.key - 1] = entry.value;
      } else {
        newControllers[entry.key] = entry.value;
      }
    }
    _rowControllers.clear();
    _rowControllers.addAll(newControllers);
    
    setState(() {});
    saveContent();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: BlockDimensionConstants.undoSnackbarDuration,
        content: const Text('Row deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final currentRows = List<Map<String, dynamic>>.from(content['rows'] as List);
            currentRows.insert(index, removedRow);
            content['rows'] = currentRows;

            final shifted = <int, TextEditingController>{};
            for (var e in _rowControllers.entries) {
              shifted[e.key >= index ? e.key + 1 : e.key] = e.value;
            }
            _rowControllers.clear();
            _rowControllers.addAll(shifted);

            setState(() {});
            saveContent();
          },
        ),
      ),
    );
  }

  void _reorderRows(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final rows = List<Map<String, dynamic>>.from(content['rows'] as List);
    final moved = rows.removeAt(oldIndex);
    rows.insert(newIndex, moved);
    content['rows'] = rows;

    // Reindex controllers without disposing to preserve text/focus state
    final n = rows.length;
    final controllerList = List<TextEditingController?>.generate(
      n, (i) => _rowControllers[i],
    );
    final movedCtrl = controllerList.removeAt(oldIndex);
    controllerList.insert(newIndex, movedCtrl);
    _rowControllers.clear();
    for (int i = 0; i < n; i++) {
      if (controllerList[i] != null) {
        _rowControllers[i] = controllerList[i]!;
      }
    }

    setState(() {});
    saveContent();
  }

  void _updateRow(int index, String value) {
    final rows = List<Map<String, dynamic>>.from(content['rows'] as List);
    if (index >= 0 && index < rows.length) {
      rows[index]['content'] = value;
      content['rows'] = rows;
      _debouncer.call(() => saveContent());
    }
  }

  void _updateGap(double newGap) {
    setState(() {
      _gap = newGap;
      content['gap'] = newGap;
      saveContent();
    });
  }

  void _updateRowStyle(String newStyle) {
    setState(() {
      _rowStyle = newStyle;
      content['rowStyle'] = newStyle;
      saveContent();
    });
  }

  void _updateRowTemplate(String newTemplate) {
    setState(() {
      _rowTemplate = newTemplate;
      content['rowTemplate'] = newTemplate;
      saveContent();
    });
  }

  double _getEditorHeight() {
    // Return appropriate height for the editor based on template
    switch (_rowTemplate) {
      case 'stacked':
        return 180;
      case 'highlight':
        return 280;
      case 'timeline':
        return 300;
      case 'feature':
        return 380;
      case 'standard':
      default:
        return 300;
    }
  }

  Future<void> _addImageToRow(int rowIndex) async {
    final images = await _imageFileService.pickAndSaveImages(widget.docDir);
    if (images != null && images.isNotEmpty) {
      final rows = List<Map<String, dynamic>>.from(content['rows'] as List);
      if (rowIndex >= 0 && rowIndex < rows.length) {
        rows[rowIndex]['imagePath'] = images[0]['path'];
        content['rows'] = rows;
        saveContent();
      }
    }
  }

  void _removeImageFromRow(int rowIndex) {
    final rows = List<Map<String, dynamic>>.from(content['rows'] as List);
    if (rowIndex >= 0 && rowIndex < rows.length) {
      final imagePath = rows[rowIndex]['imagePath'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File('${widget.docDir.path}/$imagePath');
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
      
      rows[rowIndex]['imagePath'] = '';
      content['rows'] = rows;
      saveContent();
    }
  }

  @override
  Widget buildReader(BuildContext context) {
    return RowsReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final rows = content['rows'] as List;

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
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rows',
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
                            builder: (context) => RowTemplateSelector(
                              selectedTemplate: _rowTemplate,
                              onTemplateSelected: (value) {
                                _updateRowTemplate(value);
                                Navigator.of(context).pop();
                              },
                              theme: theme,
                            ),
                          );
                        },
                        icon: const Icon(IconsaxPlusLinear.gallery, size: 16),
                        label: Text(_getTemplateDisplayName(_rowTemplate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Style selector
                      DropdownButton<String>(
                        value: _rowStyle,
                        hint: const Text('Style'),
                        items: const [
                          DropdownMenuItem(value: 'elevated', child: Text('Elevated')),
                          DropdownMenuItem(value: 'outlined', child: Text('Outlined')),
                          DropdownMenuItem(value: 'filled', child: Text('Filled')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updateRowStyle(value);
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
              
              // Rows editors - horizontal scrollable list
              if (rows.isEmpty)
                BlockEmptyState(
                  icon: Icons.view_agenda_outlined,
                  message: 'No rows added yet',
                  actionLabel: 'Add Row',
                  onAction: _addRow,
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  onReorder: _reorderRows,
                  itemBuilder: (context, index) {
                    final row = rows[index] as Map<String, dynamic>;
                    return KeyedSubtree(
                      key: ValueKey('row_$index'),
                      child: _buildRowEditor(theme, row, index),
                    );
                  },
                ),
              
              const SizedBox(height: 12),
              
              // Add/Remove buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: rows.length < 6 ? _addRow : null,
                    icon: const Icon(IconsaxPlusLinear.add),
                    label: const Text('Add Row'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: rows.length > 1 ? () => _removeRow(rows.length - 1) : null,
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

  Widget _buildRowEditor(ThemeData theme, Map<String, dynamic> row, int index) {
    final imagePath = row['imagePath'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final rows = content['rows'] as List;
    
    // Ensure controller exists for this row
    if (!_rowControllers.containsKey(index)) {
      _rowControllers[index] = TextEditingController(text: row['content']?.toString() ?? '');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with row label and delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Row ${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rows.length > 1)
                IconButton(
                  icon: const Icon(IconsaxPlusLinear.trash, size: 18),
                  onPressed: () => _removeRow(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete row',
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image section
          if (hasImage)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File('${widget.docDir.path}/$imagePath'),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.close_circle,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () => _removeImageFromRow(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      tooltip: 'Remove image',
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addImageToRow(index),
                icon: const Icon(IconsaxPlusLinear.gallery_add, size: 18),
                label: const Text('Add Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          
          if (hasImage) const SizedBox(height: 12),
          
          // Content field
          TextField(
            controller: _rowControllers[index],
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter content for this row...',
              labelText: 'Content',
              labelStyle: theme.textTheme.labelSmall,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: null,
            minLines: 1,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (value) => _updateRow(index, value),
          ),
        ],
      ),
    );
  }

  String _getTemplateDisplayName(String template) {
    switch (template) {
      case 'standard':
        return 'Standard';
      case 'stacked':
        return 'Stacked';
      case 'highlight':
        return 'Highlight';
      case 'timeline':
        return 'Timeline';
      case 'feature':
        return 'Feature';
      case 'compact':
        return 'Compact';
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
      case 'horizontal':
        return 'Horizontal';
      default:
        return 'Standard';
    }
  }
}
