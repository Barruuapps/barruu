import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';

import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/list_reader_block.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/provider/block_style_preferences_provider.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// List block widget that extends BaseEditableBlock.
/// Supports multiple list types: bulleted, numbered, roman, alpha, custom.
/// Includes bulk import mode for pasting multiple items at once.
class ListBlock extends BaseEditableBlock {
  const ListBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<ListBlock> createState() => _ListBlockState();
}

class _ListBlockState extends BaseEditableBlockState<ListBlock> {
  // Block-specific state
  late TextEditingController _headerController;
  late List<TextEditingController> _itemControllers;
  final FocusNode _headerFocusNode = FocusNode();
  final List<FocusNode> _itemFocusNodes = [];
  bool _showBulkInput = false;
  bool _bulkImportMode = false;
  final TextEditingController _bulkInputController = TextEditingController();
  bool _preferencesChecked = false;
  late final Debouncer _debouncer;

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
    _headerController = TextEditingController(
      text: content['header']?.toString() ?? '',
    );
    _itemControllers = [];
    _itemFocusNodes.clear();
    final itemsList = content['items'] is List ? content['items'] : [];
    for (final item in itemsList) {
      _itemControllers.add(TextEditingController(text: item.toString()));
      _itemFocusNodes.add(FocusNode());
    }

    if (_itemControllers.isEmpty) {
      _addNewItem();
    }

    _setupFocusListeners();
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _headerController.dispose();
    _headerFocusNode.dispose();
    for (var c in _itemControllers) {
      c.dispose();
    }
    for (var f in _itemFocusNodes) {
      f.dispose();
    }
    _bulkInputController.dispose();
  }

  @override
  void onContentChanged() {
    // Skip update if we're the ones who triggered the save
    if (_isSaving) return;

    // Update header if changed
    final headerChanged =
        content['header']?.toString() != _headerController.text;
    if (headerChanged) {
      _headerController.text = content['header']?.toString() ?? '';
    }

    final itemsList = content['items'] is List ? content['items'] : [];
    if (itemsList.length != _itemControllers.length) {
      _updateItemsFromContent(content);
    } else {
      for (int i = 0; i < itemsList.length; i++) {
        final text = itemsList[i].toString();
        if (_itemControllers[i].text != text) {
          _itemControllers[i].text = text;
        }
      }
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
      _itemFocusNodes[i].addListener(
        () => onFocusChange(_itemFocusNodes[i], i),
      );
    }
  }

  void _updateItemsFromContent(Map<String, dynamic> newContent) {
    // Dispose unused controllers and focus nodes
    for (var i = newContent['items'].length; i < _itemControllers.length; i++) {
      _itemControllers[i].dispose();
      _itemFocusNodes[i].dispose();
    }

    // Resize lists and reuse existing controllers/focus nodes
    final itemsList = newContent['items'] is List ? newContent['items'] : [];
    final newControllers = List<TextEditingController>.generate(
      itemsList.length,
      (i) => i < _itemControllers.length
          ? _itemControllers[i]
          : TextEditingController(),
    );
    final newFocusNodes = List<FocusNode>.generate(
      itemsList.length,
      (i) => i < _itemFocusNodes.length ? _itemFocusNodes[i] : FocusNode(),
    );

    // Update content
    for (int i = 0; i < itemsList.length; i++) {
      newControllers[i].text = itemsList[i].toString();
    }

    setState(() {
      _itemControllers = newControllers;
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

    _saveContentItems();
  }

  void _removeItem(int index) {
    if (_itemControllers.length <= 1) return;

    setState(() {
      _itemControllers[index].dispose();
      _itemFocusNodes[index].dispose();
      _itemControllers.removeAt(index);
      _itemFocusNodes.removeAt(index);
      _pendingSelections.remove(index);
      if (_focusedIndex >= index) {
        _focusedIndex = (_focusedIndex - 1).clamp(
          -1,
          _itemControllers.length - 1,
        );
      }
    });

    _saveContentItems();
  }

  void _saveContentItems() {
    // Keep all items during editing, including empty ones
    // This prevents items from disappearing while user is typing
    final items = _itemControllers.map((c) => c.text).toList();

    content['header'] = _headerController.text.trim();
    content['items'] = items;

    // Set flag to prevent infinite loop when saveContent calls onContentChanged
    _isSaving = true;
    _debouncer.call(() {
      saveContent()
          .then((_) {
            _isSaving = false;
          })
          .catchError((e) {
            _isSaving = false;
          });
    });
  }

  void _onHeaderChanged(String value) {
    final selection = _headerController.selection;
    if (selection.baseOffset >= 0) {
      _headerPendingSelection = selection;
    }
    _debouncer.call(() {
      _saveContentItems();
    });
  }

  void _onTextFieldChanged(int index, String value) {
    final controller = _itemControllers[index];
    final selection = controller.selection;
    if (selection.baseOffset >= 0) {
      _pendingSelections[index] = selection;
    }
    _debouncer.call(() {
      _saveContentItems();
    });
  }

  void _toggleBulkInput() {
    setState(() {
      _showBulkInput = !_showBulkInput;
      if (_showBulkInput) {
        ref
            .read(blockStylePreferencesProvider.notifier)
            .setListBulkImport(true);
        _bulkImportMode = true;
        if (_itemControllers.isNotEmpty) {
          _bulkInputController.text = _itemControllers
              .map((c) => c.text.trim())
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
    _saveContentItems();
  }

  void _exitBulkMode() {
    setState(() {
      _showBulkInput = false;
      _bulkImportMode = false;
      _bulkInputController.clear();
    });
    ref.read(blockStylePreferencesProvider.notifier).setListBulkImport(false);
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final controller = _itemControllers.removeAt(oldIndex);
      final focusNode = _itemFocusNodes.removeAt(oldIndex);
      _itemControllers.insert(newIndex, controller);
      _itemFocusNodes.insert(newIndex, focusNode);
    });
    _saveContentItems();
  }

  void _parseBulkText(String text) {
    if (text.isEmpty) return;

    final List<String> lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    final List<String> cleanedLines = lines.map((line) {
      String cleaned = line.trim();
      cleaned = cleaned.replaceFirst(
        RegExp(r'^[•\-\*\+\>\✓\✔\◦\◘\◙\○\◎\◉\◈\diamond\◆\★\☆\✦\✧\➤\➢](\s|\t)+'),
        '',
      );
      cleaned = cleaned.replaceFirst(RegExp(r'^\d+[\.\)\]]\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'^[a-zA-Z][\.\)\]]\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'^[ivxIVX]+[\.\)\]]\s*'), '');
      return cleaned;
    }).toList();

    setState(() {
      for (final controller in _itemControllers) {
        controller.dispose();
      }
      for (final focusNode in _itemFocusNodes) {
        focusNode.dispose();
      }

      _itemControllers = [];
      _itemFocusNodes.clear();

      for (int idx = 0; idx < cleanedLines.length; idx++) {
        final controller = TextEditingController(text: cleanedLines[idx]);
        final focusNode = FocusNode();
        final currentIndex = idx; // Capture the current index
        focusNode.addListener(() {
          if (focusNode.hasFocus) _focusedIndex = currentIndex;
        });
        _itemControllers.add(controller);
        _itemFocusNodes.add(focusNode);
      }

      if (_itemControllers.isEmpty) {
        _addNewItem();
      }
    });

    _saveContentItems();
  }

  Widget _buildEditableItem({
    required Key key,
    required int index,
    required String prefix,
    required StyleUtils styleUtils,
    required Color color,
    required TextAlign textAlign,
    required TextStyle textStyle,
  }) {
    final theme = Theme.of(context);

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.drag_indicator,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          if (prefix.isNotEmpty)
            SizedBox(
              width: 32,
              child: Text(
                prefix,
                style: textStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          if (prefix.isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: ValueKey('list_field_$index'),
              controller: _itemControllers[index],
              focusNode: _itemFocusNodes[index],
              maxLines: null,
              style: textStyle,
              textAlign: textAlign,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'List item ${index + 1}',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
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
          // Delete button outside text field for better UX
          if (_itemControllers.length > 1)
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: () => _removeItem(index),
              color: theme.colorScheme.error,
              tooltip: 'Remove list item',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  void _showCustomEmojiInput(BuildContext context, ThemeData theme) {
    final controller = TextEditingController(
      text: widget.block.style.customIcon ?? '🔹',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Custom Emoji'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32),
            decoration: const InputDecoration(
              hintText: '🔹',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final emoji = controller.text.trim();
                if (emoji.isNotEmpty) {
                  final updatedBlock = widget.block.copyWith(
                    style: widget.block.style.copyWith(
                      listType: 'custom',
                      customIcon: emoji,
                    ),
                  );
                  ref
                      .read(
                        editDocumentControllerProvider(widget.docDir).notifier,
                      )
                      .saveBlock(updatedBlock);
                }
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

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
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    String result = '';
    romanMap.forEach((value, letter) {
      while (number >= value) {
        result += letter;
        number -= value;
      }
    });
    return result;
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

  Widget _buildListTypeSelector(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.format_list_bulleted,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      tooltip: 'Change List Type',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'bulleted',
          child: Row(
            children: [
              Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Bulleted'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'numbered',
          child: Row(
            children: [
              Text('1. ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Numbered'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'roman',
          child: Row(
            children: [
              Text('I. ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Roman'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'alpha',
          child: Row(
            children: [
              Text('A. ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Alphabetical (A-Z)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'alpha-lower',
          child: Row(
            children: [
              Text('a. ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Alphabetical (a-z)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'custom',
          child: Row(
            children: [
              Text('🔹 ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Custom Emoji'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'none',
          child: Row(
            children: [SizedBox(width: 16), Text('None (Plain list)')],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'custom') {
          _showCustomEmojiInput(context, theme);
        } else {
          final updatedBlock = widget.block.copyWith(
            style: widget.block.style.copyWith(listType: value),
          );
          ref
              .read(editDocumentControllerProvider(widget.docDir).notifier)
              .saveBlock(updatedBlock);
        }
      },
    );
  }

  Widget _buildBulkInputUI(ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Exit Bulk Mode',
                  onPressed: _exitBulkMode,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Paste your list items below (one per line). Bullet points and numbering will be automatically removed.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bulkInputController,
              maxLines: 10,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'Paste your list here...\n• Item 1\n• Item 2\n• Item 3',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _exitBulkMode,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _applyBulkInput,
                  icon: const Icon(IconsaxPlusLinear.tick_circle, size: 18),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    // Check user preference for bulk import mode
    if (widget.isEditing && !_preferencesChecked) {
      _preferencesChecked = true;
      final preferences = ref.read(blockStylePreferencesProvider);
      if (preferences.listUseBulkImport && !_bulkImportMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _toggleBulkInput();
        });
      }
    }

    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final listType = widget.block.style.listType ?? 'bulleted';
    final customIcon = widget.block.style.customIcon ?? '•';
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final textStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(color: color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: TextField(
            key: const ValueKey('list_header'),
            controller: _headerController,
            focusNode: _headerFocusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'List Title (optional)',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            style: styleUtils
                .applyStyle(widget.block.style)
                .copyWith(fontWeight: FontWeight.bold, color: color),
            onChanged: _onHeaderChanged,
          ),
        ),

        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        // Bulk import mode toggle and list type selector
        if (!_bulkImportMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildListTypeSelector(theme),
                IconButton(
                  icon: Icon(
                    IconsaxPlusLinear.document_upload,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  tooltip: 'Bulk Import',
                  onPressed: _toggleBulkInput,
                ),
              ],
            ),
          ),

        // Show bulk input UI when in bulk mode
        if (_bulkImportMode)
          _buildBulkInputUI(theme)
        else
          // Show individual list items
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemControllers.length,
            onReorder: _reorderItem,
            itemBuilder: (context, i) {
              final prefix = _getPrefix(i, listType, customIcon);
              return _buildEditableItem(
                key: ValueKey('list_item_$i'),
                index: i,
                prefix: prefix,
                styleUtils: styleUtils,
                color: color,
                textAlign: textAlign,
                textStyle: textStyle,
              );
            },
          ),

        // Add item button (only in normal mode)
        if (!_bulkImportMode)
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 8.0),
            child: IconButton(
              onPressed: _addNewItem,
              icon: const Icon(IconsaxPlusLinear.add_circle),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              tooltip: 'Add list item',
            ),
          ),
      ],
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return ListReaderBlock(block: widget.block, allowSelection: false);
  }
}
