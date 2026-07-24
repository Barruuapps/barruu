
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/services/page_navigation_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/page_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_rename_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_selector_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_card_style.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_button_style.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_compact_style.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_minimal_style.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_extended_styles.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/page_loading_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Page block widget that enables hierarchical document navigation.
/// 
/// This widget automatically creates a nested child page when first added.
/// When clicked, it opens the nested page in edit/reader mode.
/// The page block can also be used to link to existing pages.
/// 
/// Content format: {"pageId": "page_2", "title": "Page Title", "isNested": true}
class PageBlock extends BaseEditableBlock {
  const PageBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<PageBlock> createState() => _PageBlockState();
}

class _PageBlockState extends BaseEditableBlockState<PageBlock> {
  late TextEditingController _titleController;
  late PageNavigationService _navigationService;
  bool _isInitializing = false;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'pageId': '',
    'title': '',
    'isNested': true
  };

  @override
  void initializeBlockSpecifics() {
    // Initialize navigation service
    final documentService = ref.read(documentServiceProvider);
    _navigationService = PageNavigationService(documentService);
    
    // Ensure isNested exists in content
    if (!content.containsKey('isNested')) {
      content['isNested'] = true;
    }
    
    _titleController = TextEditingController(text: content['title']?.toString() ?? '');
    
    if (widget.isEditing) {
      // Create nested page if not already created
      _initializeNestedPage();
    }
  }

  @override
  void onContentChanged() {
    if (_titleController.text != content['title']?.toString()) {
      _titleController.text = content['title']?.toString() ?? '';
    }
  }

  @override
  void disposeBlockSpecifics() {
    _titleController.dispose();
  }

  Future<void> _initializeNestedPage() async {
    if (_isInitializing) return;
    
    // If page already exists, no need to create
    if (content['pageId']?.toString().isNotEmpty == true) {
      return;
    }
    
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final currentPageId = ref.read(currentPageIdProvider(widget.docDir.path));
      final title = content['title']?.toString() ?? 'Untitled';
      
      final newPage = await _navigationService.createNestedPage(
        widget.docDir,
        title,
        currentPageId,
      );
      
      if (newPage != null && mounted) {
        setState(() {
          content['pageId'] = newPage.id;
          content['isNested'] = true; // Mark as auto-created nested page
          // Leave content['title'] empty so hint text shows until user types
        });
        await _updateBlockLocal();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }


  Future<void> _updateBlockLocal() async {
    // Content fields are already set in the calling methods
    // Just save to persist changes
    saveContent();
  }

  void _updateTitle(String newTitle) {
    setState(() {
      content['title'] = newTitle;
    });
    _updateBlockLocal();
    // Also update the page title if it's a nested page
    _updatePageTitle(newTitle);
  }

  Future<void> _updatePageTitle(String newTitle) async {
    final pageId = content['pageId']?.toString();
    if (pageId == null || pageId.isEmpty) return;
    
    await _navigationService.updatePageTitle(widget.docDir, pageId, newTitle);
  }

  Future<void> _showRenameDialog() async {
    final newTitle = await showPageRenameDialog(
      context: context,
      initialTitle: content['title']?.toString() ?? '',
    );
    
    if (newTitle != null && newTitle.trim().isNotEmpty && mounted) {
      _updateTitle(newTitle.trim());
    }
  }

  void _navigateToPage() {
    final pageId = content['pageId']?.toString() ?? '';
    if (pageId.isEmpty) {
      return;
    }

    // Add current page to navigation stack before navigating
    final currentPageId = ref.read(currentPageIdProvider(widget.docDir.path));
    final stack = ref.read(pageNavigationStackProvider(widget.docDir.path));
    ref.read(pageNavigationStackProvider(widget.docDir.path).notifier).state = [...stack, currentPageId];
    
    // Navigate to the linked page (stays in edit mode)
    ref.read(currentPageIdProvider(widget.docDir.path).notifier).state = pageId;
  }

  @override
  Widget buildReader(BuildContext context) {
    // IgnorePointer prevents the reader's InkWell (page navigation) from
    // absorbing taps in the edit screen's non-editing state.  The outer
    // GestureDetector in edit_document_screen (HitTestBehavior.opaque) then fires
    // and enters edit mode.  In preview/display mode PageReaderBlock is used
    // directly (not through PageBlock), so navigation there is unaffected.
    return IgnorePointer(
      child: PageReaderBlock(block: widget.block, docDir: widget.docDir),
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final blockStyle = widget.block.style;
    final hasPage = content['pageId']?.toString().isNotEmpty == true;
    final displayStyle = blockStyle.displayStyle ?? 'card';
    final showIcon = blockStyle.showIcon;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildDisplayStyle(theme, styleUtils, blockStyle, hasPage, displayStyle, showIcon),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayStyle(
    ThemeData theme,
    dynamic styleUtils,
    BlockStyle blockStyle,
    bool hasPage,
    String displayStyle,
    bool showIcon,
  ) {
    if (_isInitializing) {
      return buildPageBlockLoadingState(theme);
    }

    final title = content['title']?.toString() ?? 'Untitled';

    switch (displayStyle) {
      case 'button':
        return buildPageBlockButtonStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'compact':
        return buildPageBlockCompactStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'minimal':
        return buildPageBlockMinimalStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'banner':
        return buildPageBlockBannerStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'sidebar':
        return buildPageBlockSidebarStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'floating':
        return buildPageBlockFloatingStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'gradient':
        return buildPageBlockGradientStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'outlined':
        return buildPageBlockOutlinedStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'hero':
        return buildPageBlockHeroStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
      case 'card':
      default:
        return buildPageBlockCardStyle(
          theme: theme,
          styleUtils: styleUtils,
          blockStyle: blockStyle,
          title: title,
          hasPage: hasPage,
          isEditing: widget.isEditing,
          showIcon: showIcon,
          onNavigate: _navigateToPage,
          onLinkPage: _showPageSelector,
          titleController: _titleController,
          onTitleChanged: _updateTitle,
        );
    }
  }

  Future<void> _showPageSelector() async {
    final currentPageId = ref.read(currentPageIdProvider(widget.docDir.path));
    
    final selectedPage = await showPageSelectorDialog(
      context: context,
      docDir: widget.docDir,
      currentPageId: currentPageId,
      navigationService: _navigationService,
    );
    
    if (selectedPage != null && mounted) {
      // If we previously had an auto-created nested page, delete it
      final previousPageId = content['pageId']?.toString();
      final wasNested = content['isNested'] == true;
      final blockId = widget.block.id ?? '';
      
      if (previousPageId != null && previousPageId.isNotEmpty && wasNested && blockId.isNotEmpty) {
        await _navigationService.deletePageIfUnused(
          widget.docDir,
          previousPageId,
          blockId,
        );
      }
      
      setState(() {
        content['pageId'] = selectedPage.id;
        content['title'] = selectedPage.title;
        content['isNested'] = false; // Mark as linked, not auto-created
      });
      await _updateBlockLocal();
    }
  }
}
