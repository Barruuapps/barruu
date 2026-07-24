import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/block_empty_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/tabs_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/presentation/widgets/edit_document/page_drawer_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/tab_template_selector.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/tab_templates.dart';
import 'package:barruu/features/workspace/constants/block_dimension_constants.dart';

/// Tabs block for displaying content in tabs.
///
/// Content format:
/// ```json
/// {
///   "tabs": [
///     {"title": "Tab 1", "icon": "document", "content": "Content here..."},
///     {"title": "Tab 2", "icon": "folder", "content": "More content..."}
///   ],
///   "activeTab": 0,
///   "tabTemplate": "standard"
/// }
/// ```
class TabsBlock extends BaseEditableBlock {
  const TabsBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<TabsBlock> createState() => _TabsBlockState();
}

class _TabsBlockState extends BaseEditableBlockState<TabsBlock> {
  int _selectedIndex = 0;
  late String _tabTemplate;
  late double _contentHeight;
  final Map<int, Map<String, TextEditingController>> _tabControllers = {};

  // Consistent spacing constants
  static const double _spacingXSmall = 4.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 16.0;
  static const double _spacingXLarge = 20.0;
  static const double _spacingXXLarge = 24.0;

  // Height control constants
  static const double _minContentHeight = 200.0;
  static const double _maxContentHeight = 800.0;
  static const int _heightSliderDivisions = 20;
  static const double _defaultContentHeight = 400.0;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'tabs': [],
    'activeTab': 0,
    'tabTemplate': kDefaultTabTemplate,
    'contentHeight': _defaultContentHeight,
  };

  @override
  void initializeBlockSpecifics() {
    // Ensure tabs is a list
    if (content['tabs'] is! List) {
      content['tabs'] = [];
    }

    _selectedIndex = (content['activeTab'] as num?)?.toInt() ?? 0;
    _tabTemplate = content['tabTemplate']?.toString() ?? kDefaultTabTemplate;
    _contentHeight =
        (content['contentHeight'] as num?)?.toDouble() ?? _defaultContentHeight;

    // Initialize controllers for existing tabs
    _initializeTabControllers();
  }

  @override
  void onContentChanged() {
    _tabTemplate = content['tabTemplate']?.toString() ?? kDefaultTabTemplate;
    _contentHeight =
        (content['contentHeight'] as num?)?.toDouble() ?? _defaultContentHeight;

    // Update controllers when content changes externally
    _updateTabControllers();
  }

  @override
  void disposeBlockSpecifics() {
    _disposeTabControllers();
  }

  void _initializeTabControllers() {
    final tabs = content['tabs'] as List;
    for (int i = 0; i < tabs.length; i++) {
      if (!_tabControllers.containsKey(i)) {
        final tab = tabs[i] as Map<String, dynamic>;
        _tabControllers[i] = {
          'title': TextEditingController(text: tab['title']?.toString() ?? ''),
          'content': TextEditingController(
            text: tab['content']?.toString() ?? '',
          ),
        };
      }
    }
  }

  void _updateTabControllers() {
    final tabs = content['tabs'] as List;

    // Remove controllers for tabs that no longer exist
    _tabControllers.removeWhere((key, controllers) {
      if (key >= tabs.length) {
        for (var controller in controllers.values) {
          controller.dispose();
        }
        return true;
      }
      return false;
    });

    // Update existing controllers and create new ones
    for (int i = 0; i < tabs.length; i++) {
      final tab = tabs[i] as Map<String, dynamic>;

      if (_tabControllers.containsKey(i)) {
        // Only update if text is different to avoid cursor reset
        final titleText = tab['title']?.toString() ?? '';
        if (_tabControllers[i]!['title']!.text != titleText) {
          _tabControllers[i]!['title']!.text = titleText;
        }

        final contentText = tab['content']?.toString() ?? '';
        if (_tabControllers[i]!['content']!.text != contentText) {
          _tabControllers[i]!['content']!.text = contentText;
        }
      } else {
        _tabControllers[i] = {
          'title': TextEditingController(text: tab['title']?.toString() ?? ''),
          'content': TextEditingController(
            text: tab['content']?.toString() ?? '',
          ),
        };
      }
    }
  }

  void _disposeTabControllers() {
    for (var controllers in _tabControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    _tabControllers.clear();
  }

  Future<void> _addTab() async {
    // Add tab with content field
    final tabs = List<Map<String, dynamic>>.from(content['tabs'] as List);
    final newIndex = tabs.length;
    tabs.add({'title': '', 'icon': 'document', 'content': ''});

    content['tabs'] = tabs;

    // Create controllers for new tab
    _tabControllers[newIndex] = {
      'title': TextEditingController(text: ''),
      'content': TextEditingController(text: ''),
    };

    await saveContent();
  }

  void _removeTab(int index) {
    final tabs = List<Map<String, dynamic>>.from(content['tabs'] as List);
    if (index < 0 || index >= tabs.length) return;

    final removedTab = Map<String, dynamic>.from(tabs[index]);
    tabs.removeAt(index);
    content['tabs'] = tabs;

    if (_selectedIndex >= tabs.length && tabs.isNotEmpty) {
      _selectedIndex = tabs.length - 1;
      content['activeTab'] = _selectedIndex;
    }

    // Dispose and remove controllers for removed tab
    if (_tabControllers.containsKey(index)) {
      for (var controller in _tabControllers[index]!.values) {
        controller.dispose();
      }
      _tabControllers.remove(index);
    }

    // Reindex remaining controllers
    final newControllers = <int, Map<String, TextEditingController>>{};
    for (var entry in _tabControllers.entries) {
      if (entry.key > index) {
        newControllers[entry.key - 1] = entry.value;
      } else {
        newControllers[entry.key] = entry.value;
      }
    }
    _tabControllers.clear();
    _tabControllers.addAll(newControllers);

    setState(() {});
    saveContent();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: BlockDimensionConstants.undoSnackbarDuration,
        content: const Text('Tab deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final currentTabs = List<Map<String, dynamic>>.from(
              content['tabs'] as List,
            );
            currentTabs.insert(index, removedTab);
            content['tabs'] = currentTabs;

            final shifted = <int, Map<String, TextEditingController>>{};
            for (var e in _tabControllers.entries) {
              shifted[e.key >= index ? e.key + 1 : e.key] = e.value;
            }
            _tabControllers.clear();
            _tabControllers.addAll(shifted);

            setState(() {});
            saveContent();
          },
        ),
      ),
    );
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final tabs = List<Map<String, dynamic>>.from(content['tabs'] as List);
    final moved = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, moved);
    content['tabs'] = tabs;

    // Reindex controllers without disposing to preserve text/focus state
    final n = tabs.length;
    final controllerList = List<Map<String, TextEditingController>?>.generate(
      n,
      (i) => _tabControllers[i],
    );
    final movedCtrl = controllerList.removeAt(oldIndex);
    controllerList.insert(newIndex, movedCtrl);
    _tabControllers.clear();
    for (int i = 0; i < n; i++) {
      if (controllerList[i] != null) {
        _tabControllers[i] = controllerList[i]!;
      }
    }

    if (_selectedIndex == oldIndex) {
      _selectedIndex = newIndex;
    } else if (_selectedIndex > oldIndex && _selectedIndex <= newIndex) {
      _selectedIndex--;
    } else if (_selectedIndex < oldIndex && _selectedIndex >= newIndex) {
      _selectedIndex++;
    }
    content['activeTab'] = _selectedIndex;

    setState(() {});
    saveContent();
  }

  void _updateTabTemplate(String newTemplate) {
    setState(() {
      _tabTemplate = newTemplate;
      content['tabTemplate'] = newTemplate;
      saveContent();
    });
  }

  void _updateContentHeight(double newHeight) {
    setState(() {
      _contentHeight = newHeight;
      content['contentHeight'] = newHeight;
      saveContent();
    });
  }

  /// Returns the nearest preset height value (250/400/600) for the SegmentedButton selection.
  double _nearestPreset(double height) {
    const presets = [250.0, 400.0, 600.0];
    return presets.reduce(
      (a, b) => (height - a).abs() < (height - b).abs() ? a : b,
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return TabsReaderBlock(
      block: widget.block,
      docDir: widget.docDir,
      allowSelection: false,
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = content['tabs'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_spacingMedium),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(_spacingMedium),
                  ),
                  child: Icon(
                    IconsaxPlusLinear.task_square,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: _spacingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tabs Block',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: _spacingXSmall),
                      Text(
                        'Create tabbed content sections',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Template selector button
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => TabTemplateSelector(
                        selectedTemplate: _tabTemplate,
                        onTemplateSelected: (value) {
                          _updateTabTemplate(value);
                          Navigator.of(context).pop();
                        },
                        theme: theme,
                      ),
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.gallery, size: 16),
                  label: Text(_getTemplateDisplayName(_tabTemplate)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),

            SizedBox(height: _spacingXLarge),

            // Height preset selector (Small / Medium / Large)
            Row(
              children: [
                Icon(
                  IconsaxPlusLinear.arrow_up_3,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: _spacingSmall),
                Text(
                  'Height:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(width: _spacingSmall),
                Expanded(
                  child: SegmentedButton<double>(
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 250.0,
                        label: Text('S', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 400.0,
                        label: Text('M', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 600.0,
                        label: Text('L', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_nearestPreset(_contentHeight)},
                    onSelectionChanged: (values) =>
                        _updateContentHeight(values.first),
                  ),
                ),
              ],
            ),

            SizedBox(height: _spacingMedium),

            // Tab list
            if (tabs.isEmpty)
              BlockEmptyState(
                icon: IconsaxPlusLinear.task_square,
                message: 'No tabs yet',
                actionLabel: 'Add Tab',
                onAction: () {
                  _addTab();
                },
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tabs.length,
                onReorder: _reorderTabs,
                itemBuilder: (context, index) {
                  final tab = tabs[index] as Map<String, dynamic>;
                  return KeyedSubtree(
                    key: ValueKey('tab_$index'),
                    child: _buildTabItem(theme, tab, index),
                  );
                },
              ),

            SizedBox(height: _spacingLarge),

            // Add tab button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addTab,
                icon: const Icon(IconsaxPlusLinear.add),
                label: const Text(
                  'Add Tab',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: _spacingLarge,
                    horizontal: _spacingXXLarge,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabItem(ThemeData theme, Map<String, dynamic> tab, int index) {
    final icon = getDrawerPageIcon(tab['icon']?.toString());
    final currentIconName = tab['icon']?.toString() ?? 'document';

    // Ensure controllers exist for this tab
    if (!_tabControllers.containsKey(index)) {
      _tabControllers[index] = {
        'title': TextEditingController(text: tab['title']?.toString() ?? ''),
        'content': TextEditingController(
          text: tab['content']?.toString() ?? '',
        ),
      };
    }

    return Container(
      margin: EdgeInsets.only(bottom: _spacingMedium),
      padding: EdgeInsets.all(_spacingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_spacingMedium),
        border: Border.all(
          color: index == _selectedIndex
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: index == _selectedIndex ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon picker button
              PopupMenuButton<String>(
                tooltip: 'Change icon',
                offset: const Offset(0, 32),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon ?? Icons.insert_drive_file_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onSelected: (String newIconName) {
                  final tabs = List<Map<String, dynamic>>.from(
                    content['tabs'] as List,
                  );
                  tabs[index]['icon'] = newIconName;
                  content['tabs'] = tabs;
                  setState(() {});
                  saveContent();
                },
                itemBuilder: (_) => drawerPageIconOptions.map((option) {
                  final optName = option['name'] as String;
                  final optIcon = option['icon'] as IconData?;
                  final optLabel = option['label'] as String;
                  return PopupMenuItem<String>(
                    value: optName,
                    child: Row(
                      children: [
                        if (optIcon != null)
                          Icon(
                            optIcon,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 10),
                        Text(
                          optLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: optName == currentIconName
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        if (optName == currentIconName) ...[
                          const Spacer(),
                          Icon(
                            Icons.check,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              Expanded(
                child: TextField(
                  maxLines: 2,
                  minLines: 1,
                  controller: _tabControllers[index]!['title'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Tab title',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  onChanged: (value) {
                    final tabs = List<Map<String, dynamic>>.from(
                      content['tabs'] as List,
                    );
                    tabs[index]['title'] = value;
                    content['tabs'] = tabs;
                    saveContent();
                  },
                  onEditingComplete: () {
                    // Trim on blur / submit
                    final trimmed = _tabControllers[index]!['title']!.text
                        .trim();
                    _tabControllers[index]!['title']!.text = trimmed;
                    final tabs = List<Map<String, dynamic>>.from(
                      content['tabs'] as List,
                    );
                    tabs[index]['title'] = trimmed;
                    content['tabs'] = tabs;
                    saveContent();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(IconsaxPlusLinear.minus),
                onPressed: () => _removeTab(index),
                tooltip: 'Remove tab',
                color: theme.colorScheme.error,
              ),
            ],
          ),
          SizedBox(height: _spacingMedium),
          Text(
            'Content',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _spacingSmall),
          TextField(
            controller: _tabControllers[index]!['content'],
            maxLines: null,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Type content...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              contentPadding: EdgeInsets.all(_spacingMedium),
            ),
            onChanged: (value) {
              final tabs = List<Map<String, dynamic>>.from(
                content['tabs'] as List,
              );
              tabs[index]['content'] = value;
              content['tabs'] = tabs;
              saveContent();
            },
          ),
        ],
      ),
    );
  }

  String _getTemplateDisplayName(String template) {
    return kTabTemplateNames[template] ??
        kTabTemplateNames[kDefaultTabTemplate]!;
  }
}
