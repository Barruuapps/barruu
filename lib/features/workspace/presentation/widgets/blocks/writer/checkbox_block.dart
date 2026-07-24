
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/check_box_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/provider/block_style_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class CheckBoxBlock extends BaseEditableBlock {
  const CheckBoxBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<CheckBoxBlock> createState() => _CheckBoxBlockState();
}

class _CheckBoxBlockState extends BaseEditableBlockState<CheckBoxBlock> {
  late TextEditingController _headerController;
  late List<TextEditingController> _itemControllers;
  late List<bool> _itemCheckedStates;
  final FocusNode _headerFocusNode = FocusNode();
  final List<FocusNode> _itemFocusNodes = [];
  late final Debouncer _debouncer;
  bool _showBulkInput = false;
  bool _bulkImportMode = false;
  final TextEditingController _bulkInputController = TextEditingController();

  // Track focused index and pending cursor selections
  int _focusedIndex = -1;
  final Map<int, TextSelection> _pendingSelections = {};
  TextSelection? _headerPendingSelection;
  
  // Flag to prevent infinite save loops
  bool _isSaving = false;

  @override
  Map<String, dynamic> getDefaultContent() => {'header': '', 'items': []};

  @override
  void initializeBlockSpecifics() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _setupControllers();
    _setupFocusListeners();
  }

  @override
  void onContentChanged() {
    // Skip update if we're the ones who triggered the save
    if (_isSaving) return;
    _updateContentFromBlock();
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _headerController.dispose();
    _headerFocusNode.dispose();
    _bulkInputController.dispose();
    for (var c in _itemControllers) {
      c.dispose();
    }
    for (var f in _itemFocusNodes) {
      f.dispose();
    }
  }

  void _setupControllers() {
    _headerController = TextEditingController(text: content['header']?.toString() ?? '');
    _itemControllers = [];
    _itemCheckedStates = [];
    _itemFocusNodes.clear();

    final itemsList = content['items'] is List ? content['items'] : [];
    for (final item in itemsList) {
      if (item is Map<String, dynamic>) {
        final text = item['text']?.toString() ?? '';
        final checked = item['checked'] == true;
        _itemControllers.add(TextEditingController(text: text));
        _itemCheckedStates.add(checked);
        _itemFocusNodes.add(FocusNode());
      }
    }

    if (_itemControllers.isEmpty) {
      _addNewItem();
    }
  }

  void _setupFocusListeners() {
    void onFocusChange(FocusNode node, int index) {
      if (node.hasFocus) {
        _focusedIndex = index;
      }
    }

    _headerFocusNode.addListener(() => onFocusChange(_headerFocusNode, -1));
    for (int i = 0; i < _itemFocusNodes.length; i++) {
      _itemFocusNodes[i].addListener(() => onFocusChange(_itemFocusNodes[i], i));
    }
  }


  void _updateContentFromBlock() {
    final headerChanged = content['header']?.toString() != _headerController.text;
    if (headerChanged) {
      _headerController.text = content['header']?.toString() ?? '';
    }

    final itemsList = content['items'] is List ? content['items'] : [];
    if (itemsList.length != _itemControllers.length) {
      _updateItemsFromContent(content);
    } else {
      bool anyChange = false;
      for (int i = 0; i < itemsList.length; i++) {
        if (itemsList[i] is Map<String, dynamic>) {
          final text = itemsList[i]['text']?.toString() ?? '';
          final checked = itemsList[i]['checked'] == true;
          // Only update if there's an actual change to avoid triggering infinite loops
          if (_itemControllers[i].text != text) {
            _itemControllers[i].text = text;
            anyChange = true;
          }
          if (_itemCheckedStates[i] != checked) {
            _itemCheckedStates[i] = checked;
            anyChange = true;
          }
        }
      }
      if (anyChange && mounted) {
        setState(() {});
      }
    }
  }

  void _updateItemsFromContent(Map<String, dynamic> newContent) {
    final itemsList = newContent['items'] is List ? newContent['items'] : [];

    // Dispose excess
    for (var i = itemsList.length; i < _itemControllers.length; i++) {
      _itemControllers[i].dispose();
      _itemFocusNodes[i].dispose();
    }

    final newControllers = List<TextEditingController>.generate(
      itemsList.length,
          (i) => i < _itemControllers.length ? _itemControllers[i] : TextEditingController(),
    );
    final newCheckedStates = List<bool>.generate(
      itemsList.length,
          (i) => i < _itemCheckedStates.length ? _itemCheckedStates[i] : false,
    );
    final newFocusNodes = List<FocusNode>.generate(
      itemsList.length,
          (i) => i < _itemFocusNodes.length ? _itemFocusNodes[i] : FocusNode(),
    );

    for (int i = 0; i < itemsList.length; i++) {
      if (itemsList[i] is Map<String, dynamic>) {
        newControllers[i].text = itemsList[i]['text']?.toString() ?? '';
        newCheckedStates[i] = itemsList[i]['checked'] == true;
      }
    }

    setState(() {
      _itemControllers = newControllers;
      _itemCheckedStates = newCheckedStates;
      _itemFocusNodes.clear();
      _itemFocusNodes.addAll(newFocusNodes);
      _setupFocusListeners(); // Re-attach listeners
      if (_itemControllers.isEmpty) {
        _addNewItem();
      }
    });
  }

  void _addNewItem() {
    setState(() {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      _itemControllers.add(controller);
      _itemCheckedStates.add(false);
      _itemFocusNodes.add(focusNode);
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          _focusedIndex = _itemControllers.length - 1;
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemFocusNodes.isNotEmpty) {
        _itemFocusNodes.last.requestFocus();
      }
    });

    _saveContentLocal();
  }

  void _removeItem(int index) {
    if (_itemControllers.length <= 1) return;

    setState(() {
      _itemControllers[index].dispose();
      _itemFocusNodes[index].dispose();
      _itemControllers.removeAt(index);
      _itemCheckedStates.removeAt(index);
      _itemFocusNodes.removeAt(index);
      _pendingSelections.remove(index);
      if (_focusedIndex >= index) {
        _focusedIndex = (_focusedIndex - 1).clamp(-1, _itemControllers.length - 1);
      }
    });

    _saveContentLocal();
  }

  void _updateItemChecked(int index, bool checked) {
    setState(() {
      _itemCheckedStates[index] = checked;
    });
    _saveContentLocal();
  }

  void _saveContentLocal() {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < _itemControllers.length; i++) {
      // Keep all items during editing, including empty ones
      // This prevents items from disappearing while user is typing
      items.add({
        'text': _itemControllers[i].text,
        'checked': _itemCheckedStates[i],
      });
    }

    content['header'] = _headerController.text.trim();
    content['items'] = items;
    
    // Set flag to prevent infinite loop when saveContent calls onContentChanged
    _isSaving = true;
    saveContent().then((_) {
      _isSaving = false;
    }).catchError((e) {
      _isSaving = false;
    });
  }

  void _restoreFocusAndSelection() {
    if (!mounted) return;

    // Restore item focus
    if (_focusedIndex >= 0 && _focusedIndex < _itemFocusNodes.length) {
      final node = _itemFocusNodes[_focusedIndex];
      if (!node.hasFocus) {
        node.requestFocus();
      }
    }

    // Restore header focus
    if (_focusedIndex == -1 && !_headerFocusNode.hasFocus) {
      _headerFocusNode.requestFocus();
    }

    // Restore header cursor position
    if (_headerPendingSelection != null && _focusedIndex == -1) {
      if (_headerPendingSelection!.baseOffset <= _headerController.text.length) {
        _headerController.selection = _headerPendingSelection!;
      }
      _headerPendingSelection = null;
    }

    // Restore item cursor positions
    for (var entry in _pendingSelections.entries) {
      final index = entry.key;
      final selection = entry.value;
      if (index < _itemControllers.length) {
        final controller = _itemControllers[index];
        if (selection.baseOffset <= controller.text.length) {
          controller.selection = selection;
        }
      }
    }
    _pendingSelections.clear();
  }

  void _onTextFieldChanged(int index, String value) {
    final controller = _itemControllers[index];
    final selection = controller.selection;
    if (selection.baseOffset >= 0) {
      _pendingSelections[index] = selection;
    }
    _debouncer.call(() {
      _saveContentLocal();
    });
  }

  void _onHeaderChanged(String value) {
    final selection = _headerController.selection;
    if (selection.baseOffset >= 0) {
      _headerPendingSelection = selection;
    }
    _debouncer.call(() {
      _saveContentLocal();
    });
  }

  void _toggleBulkInput() {
    setState(() {
      _showBulkInput = !_showBulkInput;
      if (_showBulkInput) {
        // Save preference for this session
        ref.read(blockStylePreferencesProvider.notifier)
            .setCheckboxBulkImport(true);
        // Enable bulk import mode - hide individual item interface
        _bulkImportMode = true;
        // Pre-fill bulk input with existing items if any
        if (_itemControllers.isNotEmpty) {
          _bulkInputController.text = _itemControllers
              .asMap()
              .entries
              .map((e) {
            final text = e.value.text.trim();
            final checked = _itemCheckedStates[e.key] ? ' [✅]' : '';
            return text.isNotEmpty ? '$text$checked' : '';
          })
              .where((t) => t.isNotEmpty)
              .join('\n');
        }
      } else {
        _bulkImportMode = false;
      }
    });
  }

  void _applyBulkInput() {
    _parseBulkText(_bulkInputController.text);
    _saveContentLocal();
  }

  void _exitBulkMode() {
    setState(() {
      _showBulkInput = false;
      _bulkImportMode = false;
      _bulkInputController.clear();
    });
    ref.read(blockStylePreferencesProvider.notifier).setCheckboxBulkImport(false);
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final controller = _itemControllers.removeAt(oldIndex);
      final checkedState = _itemCheckedStates.removeAt(oldIndex);
      final focusNode = _itemFocusNodes.removeAt(oldIndex);
      _itemControllers.insert(newIndex, controller);
      _itemCheckedStates.insert(newIndex, checkedState);
      _itemFocusNodes.insert(newIndex, focusNode);
    });
    _saveContentLocal();
  }

  @override
  Widget buildReader(BuildContext context) {
    return CheckBoxReaderBlock(block: widget.block, allowSelection: false);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final color = styleUtils.parseHex(widget.block.style.color) ?? theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        const SizedBox(height :8),

        // Header input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: TextField(
            key: const ValueKey('checkbox_header'),
            controller: _headerController,
            focusNode: _headerFocusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Checklist Title (optional)',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            style: styleUtils.applyStyle(widget.block.style).copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            onChanged: _onHeaderChanged,
          ),
        ),
        // Bulk import mode toggle
        if (!_bulkImportMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _toggleBulkInput,
                  icon: const Icon(IconsaxPlusLinear.document_upload, size: 16),
                  label: const Text('Bulk Import'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

        // Bulk import input (table-like experience)
        if (_bulkImportMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bulk Import Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _exitBulkMode,
                      icon: const Icon(IconsaxPlusLinear.close_circle, size: 16),
                      label: const Text('Exit Bulk Mode'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Enter your checklist items (one per line). Add [x] for checked items:',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      TextField(
                        controller: _bulkInputController,
                        maxLines: 10,
                        style: styleUtils.applyStyle(widget.block.style).copyWith(fontSize: 14, color: color),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'Buy milk [x]\nCall doctor\nSend email',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                        onChanged: (_) => _applyBulkInput(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Individual item interface (hidden in bulk mode)
        if (!_bulkImportMode) ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemControllers.length,
            onReorder: _reorderItem,
            itemBuilder: (context, index) {
              return _buildEditableItem(
                key: ValueKey('checkbox_item_$index'),
                index: index,
                styleUtils: styleUtils,
                color: color,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 8.0),
            child: IconButton(
              onPressed: _addNewItem,
              icon: const Icon(IconsaxPlusLinear.add_circle),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              tooltip: 'Add checklist item',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditableItem({
    required Key key,
    required int index,
    required StyleUtils styleUtils,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          // Drag handle
          Icon(
            Icons.drag_indicator,
            size: 20,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              key: ValueKey('checkbox_field_$index'),
              controller: _itemControllers[index],
              focusNode: _itemFocusNodes[index],
              maxLines: null,
              style: styleUtils.applyStyle(widget.block.style).copyWith(
                decoration: _itemCheckedStates[index] ? TextDecoration.lineThrough : TextDecoration.none,
                color: color,
              ),
              decoration: InputDecoration(
                prefixIcon: Semantics(
                  label: _itemCheckedStates[index] ? 'Checked' : 'Unchecked',
                  child: GestureDetector(
                    onTap: () => _updateItemChecked(index, !_itemCheckedStates[index]),
                    child: Icon(
                      _itemCheckedStates[index] ? Icons.check_box : Icons.check_box_outline_blank,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
                border: InputBorder.none,
                hintText: 'List item ${index + 1}',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                suffixIcon: _itemControllers.length > 1
                    ? IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => _removeItem(index),
                  color: theme.colorScheme.error,
                  tooltip: 'Remove checklist item',
                )
                    : null,
              ),
              onChanged: (value) => _onTextFieldChanged(index, value),
              onSubmitted: (_) {
                if (index == _itemControllers.length - 1) {
                  _addNewItem();
                } else {
                  _itemFocusNodes[index + 1].requestFocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _parseBulkText(String text) {
    if (text.isEmpty) return;

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return;

    final checkedPattern = RegExp(r'\[(x|X|checked|CHECKED|✓|✔)\]$');
    final itemTexts = <String>[];
    final checkedStates = <bool>[];

    for (var line in lines) {
      String cleaned = line;
      bool isChecked = false;

      if (checkedPattern.hasMatch(line)) {
        isChecked = true;
        cleaned = line.replaceFirst(checkedPattern, '');
      }

      cleaned = cleaned.replaceAll(RegExp(r'^[☐☑□■▢▣✓✔✅❌⬜⬛]\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'^\-\s+\[\s*[xX✓✔]?\s*\]\s*'), '');

      itemTexts.add(cleaned);
      checkedStates.add(isChecked);
    }

    setState(() {
      for (final c in _itemControllers) {
        c.dispose();
      }
      for (final f in _itemFocusNodes) {
        f.dispose();
      }

      _itemControllers = itemTexts.map((t) => TextEditingController(text: t)).toList();
      _itemCheckedStates = checkedStates;
      _itemFocusNodes.clear();
      for (int i = 0; i < itemTexts.length; i++) {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) _focusedIndex = i;
        });
        _itemFocusNodes.add(node);
      }

      if (_itemControllers.isEmpty) _addNewItem();
    });

    _saveContentLocal();
  }
}
