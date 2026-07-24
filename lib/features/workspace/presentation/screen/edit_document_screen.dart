import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/widgets/empty_state_widget.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/constants/block_type_constants.dart';
import 'package:barruu/features/workspace/presentation/controllers/documents_controller.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/router/app_router.dart';
import 'package:barruu/core/theme/domain/presentation/pages/theme_selection_page.dart';
import 'package:barruu/features/workspace/presentation/widgets/minibook_theme_wrapper.dart';

import 'package:barruu/features/workspace/presentation/widgets/blocks/blocks_widgets.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/evaluation_button_block.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:barruu/features/workspace/presentation/widgets/smart_block_list.dart';
import 'package:barruu/features/workspace/presentation/widgets/edit_document/scroll_indicator_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/edit_document/block_type_selector_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/edit_document/page_drawer_widget.dart';
import 'package:barruu/features/workspace/presentation/dialogs/graph_type_selector_dialog.dart';
import 'package:barruu/features/workspace/presentation/services/media_block_service.dart';
import 'package:barruu/features/workspace/presentation/services/document_auth_service.dart';
import 'package:barruu/features/workspace/presentation/services/scroll_helper.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' hide Block;
import 'package:iconsax_plus/iconsax_plus.dart';

class EditDocumentScreen extends ConsumerStatefulWidget {
  final Directory doc;

  const EditDocumentScreen({super.key, required this.doc});

  @override
  ConsumerState<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends ConsumerState<EditDocumentScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String? _editingBlockId;
  double _scrollProgress = 0.0;
  late final AnimationController _scrollIndicatorController;
  late final Animation<double> _scrollIndicatorOpacity;
  bool _isAuthorized = false;
  bool _isChecking = true;
  TabController? _tabController;
  List<DocumentPage> _tabPages = [];
  String? _lastDrawerPageId; // Track last drawer page to detect changes

  @override
  void initState() {
    super.initState();
    _checkEditAccess();
    _setupScrollListeners();
    _setupScrollIndicator();
    _loadTabPages();
  }

  Future<void> _checkEditAccess() async {
    final result = await DocumentAuthService.checkEditAccess(
      context,
      ref,
      widget.doc,
    );

    if (mounted) {
      setState(() {
        _isChecking = result.isChecking;
        _isAuthorized = result.isAuthorized;
      });
    }
  }

  void _setupScrollListeners() {
    ScrollHelper.setupScrollListeners(
      scrollController: _scrollController,
      onScrollProgressUpdate: _updateScrollProgress,
      onScrollIndicatorToggle: _toggleScrollIndicator,
    );
  }

  void _setupScrollIndicator() {
    _scrollIndicatorController = ScrollHelper.createScrollIndicatorController(
      vsync: this,
    );
    _scrollIndicatorOpacity =
        ScrollHelper.createScrollIndicatorOpacityAnimation(
          controller: _scrollIndicatorController,
        );
  }

  @override
  void dispose() {
    ScrollHelper.removeScrollListeners(
      scrollController: _scrollController,
      onScrollProgressUpdate: _updateScrollProgress,
      onScrollIndicatorToggle: _toggleScrollIndicator,
    );
    _scrollController.dispose();
    _scrollIndicatorController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    final progress = ScrollHelper.calculateScrollProgress(_scrollController);
    setState(() {
      _scrollProgress = progress;
    });
  }

  Future<void> _loadTabPages() async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final pages = await documentService.getDocumentPages(widget.doc);
      final currentPageId = ref.read(currentPageIdProvider(widget.doc.path));

      // Find the current drawer page - if current page is a tab, find its parent drawer page
      final currentPage = pages.firstWhere(
        (page) => page.id == currentPageId,
        orElse: () => pages.first,
      );

      // If the stored currentPageId doesn't actually exist in this document's pages
      // (e.g. a web-created document has UUID-based page IDs, not 'page_1'), sync
      // the provider to the first real page so blocks are loaded from the correct DB.
      if (!pages.any((p) => p.id == currentPageId)) {
        ref.read(currentPageIdProvider(widget.doc.path).notifier).state =
            currentPage.id;
      }

      final DocumentPage currentDrawerPage;
      if (currentPage.isDrawerPage) {
        // Current page is already a drawer page
        currentDrawerPage = currentPage;
      } else if (currentPage.isTabPage && currentPage.parentPageId != null) {
        // Current page is a tab page, find its parent drawer page
        currentDrawerPage = pages.firstWhere(
          (page) => page.id == currentPage.parentPageId,
          orElse: () => pages.firstWhere(
            (page) => page.isDrawerPage,
            orElse: () => pages.first,
          ),
        );
      } else {
        // Fallback to first drawer page
        currentDrawerPage = pages.firstWhere(
          (page) => page.isDrawerPage,
          orElse: () => pages.first,
        );
      }

      // Track the drawer page ID for change detection
      _lastDrawerPageId = currentDrawerPage.id;

      // Get only the tab pages that belong to the current drawer page (as children)
      final pageTabPages = pages
          .where(
            (page) =>
                page.isTabPage && page.parentPageId == currentDrawerPage.id,
          )
          .toList();

      // Tab 1 is always the current drawer page, followed by its child tab pages
      final tabPages = [currentDrawerPage, ...pageTabPages];

      if (mounted) {
        setState(() {
          _tabPages = tabPages;
          if (_tabPages.isNotEmpty) {
            // Default to Tab 1 (the drawer page) if current page is not in tabs
            final currentIndex = _tabPages.indexWhere(
              (p) => p.id == currentPageId,
            );
            final initialIndex = currentIndex >= 0 ? currentIndex : 0;

            _tabController?.dispose();
            _tabController = TabController(
              length: _tabPages.length,
              vsync: this,
              initialIndex: initialIndex,
            );

            _tabController?.addListener(() {
              if (_tabController!.indexIsChanging) {
                final selectedPage = _tabPages[_tabController!.index];
                ref
                        .read(currentPageIdProvider(widget.doc.path).notifier)
                        .state =
                    selectedPage.id;
              }
            });
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('Failed to load tab pages', error: e, stackTrace: stackTrace);
    }
  }

  void _toggleScrollIndicator() {
    if (ScrollHelper.shouldShowScrollIndicator(_scrollController)) {
      _scrollIndicatorController.forward();
    } else {
      _scrollIndicatorController.reverse();
    }
  }

  Future<Map<String, dynamic>> _loadMeta() async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final meta = await documentService.getDocumentMetadata(widget.doc);
      if (meta == null) {
        logger.w('No metadata found for document: ${widget.doc.path}');
        return {MetaFile.nameKey: 'Untitled Document'};
      }
      final name = meta[MetaFile.nameKey]?.toString().trim();
      if (name == null || name.isEmpty) {
        logger.w('Document name missing in metadata: ${widget.doc.path}');
        meta[MetaFile.nameKey] = 'Untitled Document';
      }
      return meta;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to load metadata for document: ${widget.doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return {MetaFile.nameKey: 'Untitled Document'};
    }
  }

  /// Handles adding a new page to the document.
  Future<void> _handleAddNewPage(WidgetRef ref) async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final pages = await documentService.getDocumentPages(widget.doc);
      final currentPageId = ref.read(currentPageIdProvider(widget.doc.path));

      // Find the current drawer page
      final currentDrawerPage = pages.firstWhere(
        (page) => page.id == currentPageId && page.isDrawerPage,
        orElse: () => pages.firstWhere(
          (page) => page.isDrawerPage,
          orElse: () => pages.first,
        ),
      );

      // Count existing child tab pages of the current drawer page
      final childTabPages = pages
          .where(
            (page) =>
                page.isTabPage && page.parentPageId == currentDrawerPage.id,
          )
          .toList();

      // Tab numbering starts from 2 (Tab 1 is the drawer page itself)
      final tabCount = childTabPages.length + 2;
      final defaultTitle = 'Tab $tabCount';

      // Create a new nested tab page under the current drawer page
      final newPage = await documentService.createNestedTabPage(
        widget.doc,
        defaultTitle,
        currentDrawerPage.id,
      );

      if (newPage != null && mounted) {
        // Reload tab pages to show the new tab
        await _loadTabPages();

        // Navigate to the new tab page
        ref.read(currentPageIdProvider(widget.doc.path).notifier).state =
            newPage.id;

        UIUtils.showSnackBar(context, 'Tab "${newPage.displayTitle}" created');
      } else if (mounted) {
        UIUtils.showSnackBar(context, 'Failed to create tab', isError: true);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to create new tab', error: e, stackTrace: stackTrace);
      if (mounted) {
        UIUtils.showSnackBar(context, 'Failed to create tab', isError: true);
      }
    }
  }

  /// Handles renaming a tab page.
  Future<void> _handleRenameTab(DocumentPage page) async {
    try {
      final result = await showDialog<String?>(
        context: context,
        builder: (dialogContext) =>
            _EditPageTitleDialog(initialTitle: page.tabTitle),
      );

      if (result != null && mounted) {
        final documentService = ref.read(documentServiceProvider);

        // Use updateTabTitleOnly to ONLY update the tab display name without modifying page content
        final success = await documentService.updateTabTitleOnly(
          widget.doc,
          page.id,
          result.isEmpty ? '' : result,
        );

        if (success && mounted) {
          final displayTitle = result.isEmpty
              ? (page.isDrawerPage ? 'Tab 1' : 'Untitled Screen')
              : result;
          UIUtils.showSnackBar(context, 'Tab renamed to "$displayTitle"');

          // Reload tab pages to reflect the change
          await _loadTabPages();
        } else if (mounted) {
          UIUtils.showSnackBar(context, 'Failed to rename tab', isError: true);
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to rename tab', error: e, stackTrace: stackTrace);
      if (mounted) {
        UIUtils.showSnackBar(context, 'Failed to rename tab', isError: true);
      }
    }
  }

  /// Handles deleting a tab page.
  Future<void> _handleDeleteTab(DocumentPage page) async {
    try {
      // Prevent deletion of Tab 1 (the drawer page)
      if (page.isDrawerPage) {
        UIUtils.showSnackBar(
          context,
          'Cannot delete Tab 1 - it represents the current page',
          isError: true,
        );
        return;
      }

      // Prevent deletion if it's the only tab
      if (_tabPages.length <= 1) {
        UIUtils.showSnackBar(
          context,
          'Cannot delete the only tab',
          isError: true,
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Tab?'),
          content: Text(
            'Are you sure you want to delete "${page.displayTitle}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final documentService = ref.read(documentServiceProvider);
        final success = await documentService.deletePage(widget.doc, page.id);

        if (success && mounted) {
          UIUtils.showSnackBar(context, 'Tab deleted');

          // If the deleted page was the current page, switch to Tab 1 (drawer page)
          final currentPageId = ref.read(
            currentPageIdProvider(widget.doc.path),
          );
          if (currentPageId == page.id) {
            // Switch to the drawer page (Tab 1)
            final drawerPage = _tabPages.firstWhere((p) => p.isDrawerPage);
            ref.read(currentPageIdProvider(widget.doc.path).notifier).state =
                drawerPage.id;
          }

          // Reload tab pages to reflect the change
          await _loadTabPages();
        } else if (mounted) {
          UIUtils.showSnackBar(context, 'Failed to delete tab', isError: true);
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to delete tab', error: e, stackTrace: stackTrace);
      if (mounted) {
        UIUtils.showSnackBar(context, 'Failed to delete tab', isError: true);
      }
    }
  }

  Future<void> _handleBlockTypeAdd(BlockType type, bool isSidebar) async {
    final controller = ref.read(
      editDocumentControllerProvider(widget.doc).notifier,
    );

    try {
      // For media blocks, use the MediaBlockService
      if (type == BlockType.image ||
          type == BlockType.video ||
          type == BlockType.audio) {
        await MediaBlockService.handleMediaBlockAdd(
          context,
          ref,
          widget.doc,
          type,
        );
      } else if (type == BlockType.graph) {
        // For graph blocks, show the graph type selector
        final graphType = await GraphTypeSelectorDialog.show(context);

        if (graphType == null || !mounted) return;

        // Add the graph block with the selected type
        await controller.addGraphBlock(graphType: graphType);
      } else {
        await controller.addBlock(type: type);
      }

      final blocks = ref.read(editDocumentControllerProvider(widget.doc));
      if (blocks.isNotEmpty && mounted) {
        final newBlock = blocks.last;
        setState(() => _editingBlockId = newBlock.id);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('Failed to add block: $type', error: e, stackTrace: stackTrace);
      if (mounted) {
        UIUtils.showSnackBar(
          context,
          'Failed to add ${type.displayName}',
          isError: true,
        );
      }
    }
  }

  Widget _renderBlock(Block block, double? maxWidth) {
    final isEditing = _editingBlockId == block.id;
    final theme = Theme.of(context);
    final controller = ref.read(
      editDocumentControllerProvider(widget.doc).notifier,
    );

    Widget blockWidget;
    switch (block.type) {
      case BlockType.header:
        blockWidget = HeaderBlock(
          docDir: widget.doc,
          block: block,
          isEditing: isEditing,
        );
        break;
      case BlockType.image:
        blockWidget = ImageBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.video:
        blockWidget = VideoBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.audio:
        blockWidget = AudioBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.divider:
        blockWidget = DividerBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.spacer:
        blockWidget = SpacerBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.blockquote:
        blockWidget = BlockQuoteBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.list:
        blockWidget = ListBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.code:
        blockWidget = CodeBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.math:
        blockWidget = MathBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.chat:
        blockWidget = ChatBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.box:
        blockWidget = BoxBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.checkbox:
        blockWidget = CheckBoxBlock(
          block: block,
          isEditing: isEditing,
          docDir: widget.doc,
        );
        break;
      case BlockType.table:
        blockWidget = TableBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.evaluationButton:
        blockWidget = EvaluationButtonBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.graph:
        blockWidget = GraphBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.page:
        blockWidget = PageBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.wordOrder:
        blockWidget = WordOrderBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.mathWorkpad:
        blockWidget = MathWorkpadBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.tabs:
        blockWidget = TabsBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.cards:
        blockWidget = CardsBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.expandable:
        blockWidget = ExpandableBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.stepper:
        blockWidget = StepperBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.columns:
        blockWidget = ColumnsBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.rows:
        blockWidget = RowsBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.multipleChoice:
        blockWidget = MultipleChoiceBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.trueFalse:
        blockWidget = TrueFalseBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.fillInBlank:
        blockWidget = FillBlankBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.matching:
        blockWidget = MatchingBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.theorem:
        blockWidget = TheoremBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.proof:
        blockWidget = ProofBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.definition:
        blockWidget = DefinitionBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.example:
        blockWidget = ExampleBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.learningObjective:
        blockWidget = LearningObjectiveBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.conceptSummary:
        blockWidget = ConceptSummaryBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.numericalQuestion:
        blockWidget = NumericalQuestionBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.glossary:
        blockWidget = GlossaryBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.parametricGraph:
        blockWidget = ParametricGraphBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.citation:
        blockWidget = CitationBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.toc:
        blockWidget = TocBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.faq:
        blockWidget = FaqBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;
      case BlockType.keyPoint:
        blockWidget = KeyPointBlock(
          block: block,
          docDir: widget.doc,
          isEditing: isEditing,
        );
        break;

      case BlockType.unsupported:
        blockWidget = _UnsupportedBlockPlaceholder(block: block);
        break;

      default:
        blockWidget = ParagraphBlock(
          docDir: widget.doc,
          block: block,
          isEditing: isEditing,
        );
    }

    final constrainedWidget = maxWidth != null
        ? Container(
            constraints: BoxConstraints(maxWidth: maxWidth * 0.95),
            child: blockWidget,
          )
        : blockWidget;

    if (isEditing) {
      return Padding(
        key: ValueKey('editing-${block.id}'),
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            constrainedWidget,
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final spacing = ResponsiveUtils.isDesktop(context)
                    ? 10.0
                    : (isSmallScreen ? 4.0 : 8.0);
                return Wrap(
                  alignment: WrapAlignment.end,
                  spacing: spacing,
                  runSpacing: 4,
                  children: [
                    _ActionButton(
                      icon: Icons.arrow_upward,
                      tooltip: 'Move Up',
                      onPressed: () => controller.moveBlockUp(block),
                      theme: theme,
                    ),
                    _ActionButton(
                      icon: Icons.arrow_downward,
                      tooltip: 'Move Down',
                      onPressed: () => controller.moveBlockDown(block),
                      theme: theme,
                    ),
                    _ActionButton(
                      icon: Icons.content_copy,
                      tooltip: 'Duplicate',
                      onPressed: () async {
                        final newId = await controller.duplicateBlock(block);
                        if (newId != null && mounted) {
                          setState(() => _editingBlockId = newId);
                        }
                      },
                      theme: theme,
                    ),
                    _ActionButton(
                      icon: Icons.check,
                      tooltip: 'Save',
                      onPressed: () async {
                        await controller.saveBlock(block);
                        if (mounted) setState(() => _editingBlockId = null);
                      },
                      theme: theme,
                    ),
                    _ActionButton(
                      icon: Icons.delete,
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            final dialogWidth = ResponsiveUtils.getDialogWidth(
                              ctx,
                            );
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              insetPadding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.isDesktop(ctx)
                                    ? 40
                                    : 16,
                                vertical: 24,
                              ),
                              title: const Text('Delete Block?'),
                              content: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: dialogWidth,
                                ),
                                child: const Text(
                                  'Are you sure you want to delete this block? This action cannot be undone.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmed == true) {
                          await controller.deleteBlock(block);
                          if (mounted) setState(() => _editingBlockId = null);
                        }
                      },
                      theme: theme,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      // HitTestBehavior.opaque ensures this GestureDetector participates in hit
      // testing even when a child block wraps its reader in IgnorePointer (e.g.
      // PageBlock and ExpandableBlock), allowing a tap anywhere on the block to
      // enter edit mode rather than being swallowed by an inner InkWell.
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _editingBlockId = block.id),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: constrainedWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isChecking) {
      return MinibookThemeWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Edit Document')),
          body: Center(
            child: ShimmerCircularProgress(
              size: 50,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (!_isAuthorized) {
      return MinibookThemeWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Edit Document')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Access Denied', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'You do not have permission to edit this document',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final blocks = ref.watch(editDocumentControllerProvider(widget.doc));
    final navigationStack = ref.watch(
      pageNavigationStackProvider(widget.doc.path),
    );
    final canGoBack = navigationStack.length > 1;

    // Watch for drawer page changes and reload tabs
    final currentPageId = ref.watch(currentPageIdProvider(widget.doc.path));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Check if we're on a different drawer page
      final documentService = ref.read(documentServiceProvider);
      final pages = await documentService.getDocumentPages(widget.doc);

      // Find the current drawer page - if current page is a tab, find its parent drawer page
      final currentPage = pages.firstWhere(
        (page) => page.id == currentPageId,
        orElse: () => pages.first,
      );

      final DocumentPage currentDrawerPage;
      if (currentPage.isDrawerPage) {
        // Current page is already a drawer page
        currentDrawerPage = currentPage;
      } else if (currentPage.isTabPage && currentPage.parentPageId != null) {
        // Current page is a tab page, find its parent drawer page
        currentDrawerPage = pages.firstWhere(
          (page) => page.id == currentPage.parentPageId,
          orElse: () => pages.firstWhere(
            (page) => page.isDrawerPage,
            orElse: () => pages.first,
          ),
        );
      } else {
        // Fallback to first drawer page
        currentDrawerPage = pages.firstWhere(
          (page) => page.isDrawerPage,
          orElse: () => pages.first,
        );
      }

      if (_lastDrawerPageId != null &&
          _lastDrawerPageId != currentDrawerPage.id) {
        await _loadTabPages();
      }
    });

    return MinibookThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: canGoBack
              ? IconButton(
                  icon: const Icon(IconsaxPlusLinear.arrow_left_2),
                  tooltip: 'Back',
                  onPressed: () {
                    // Pop from navigation stack
                    final stack = ref.read(
                      pageNavigationStackProvider(widget.doc.path),
                    );
                    if (stack.length > 1) {
                      final newStack = List<String>.from(stack);
                      final previousPageId = newStack.removeLast();
                      ref
                              .read(
                                pageNavigationStackProvider(
                                  widget.doc.path,
                                ).notifier,
                              )
                              .state =
                          newStack;
                      ref
                              .read(
                                currentPageIdProvider(widget.doc.path).notifier,
                              )
                              .state =
                          previousPageId;
                    }
                  },
                )
              : null,
          title: FutureBuilder<Map<String, dynamic>>(
            future: _loadMeta(),
            builder: (context, snapshot) {
              final title =
                  snapshot.data?[MetaFile.nameKey]?.toString().trim() ??
                  'Untitled Document';
              return Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(IconsaxPlusLinear.magic_star),
              tooltip: 'AI Assistant',
              onPressed: () {
                final encodedPath = Uri.encodeComponent(widget.doc.path);
                context.push('/ai-chat/$encodedPath');
              },
            ),
            IconButton(
              icon: const Icon(IconsaxPlusLinear.color_swatch),
              tooltip: 'Change Minibook Theme',
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectionPage()),
              ),
            ),
            IconButton(
              icon: const Icon(IconsaxPlusLinear.eye),
              tooltip: 'Preview',
              onPressed: () {
                try {
                  final encodedPath = Uri.encodeComponent(widget.doc.path);
                  final router = ref.read(routerProvider);
                  router.go('/preview-document/$encodedPath');
                  ref.read(documentsProvider.notifier).loadDocuments();
                } catch (e, stackTrace) {
                  logger.e(
                    'Navigation failed',
                    error: e,
                    stackTrace: stackTrace,
                  );
                  if (mounted) {
                    UIUtils.showSnackBar(
                      context,
                      'Failed to open preview',
                      isError: true,
                    );
                  }
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_tabPages.length >= 2 && _tabController != null)
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: _tabPages.length > 3,
                        tabAlignment: _tabPages.length > 3
                            ? TabAlignment.start
                            : null,
                        indicatorColor: theme.colorScheme.primary,
                        indicatorWeight: 3.0,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.onSurface
                            .withOpacity(0.6),
                        labelStyle: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.3,
                        ),
                        unselectedLabelStyle: theme.textTheme.titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: _tabPages.length > 3 ? 20 : 16,
                          vertical: 8,
                        ),
                        tabs: _tabPages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final page = entry.value;
                          final isDrawerPage = page.isDrawerPage;
                          // Use the tab-specific display name
                          final displayTitle = page.tabTitle;

                          return Tab(
                            height: 52,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayTitle,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    IconsaxPlusLinear.more,
                                    size: 18,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  tooltip: 'Tab Options',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  splashRadius: 16,
                                  onSelected: (value) async {
                                    if (value == 'rename') {
                                      await _handleRenameTab(page);
                                    } else if (value == 'delete') {
                                      await _handleDeleteTab(page);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem<String>(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(
                                            IconsaxPlusLinear.edit,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Rename',
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Only show delete option if it's not Tab 1 (drawer page)
                                    if (!isDrawerPage && _tabPages.length > 1)
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              IconsaxPlusLinear.trash,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Add New Tab button - always visible with improved styling
                  Container(
                    margin: const EdgeInsets.only(right: 8.0, left: 4.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleAddNewPage(ref),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            IconsaxPlusLinear.add_square,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: PageDrawerWidget(docDir: widget.doc),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = ResponsiveUtils.isDesktop(context);
              final maxContentWidth = ResponsiveUtils.getContentMaxWidth(
                context,
              );
              final padding = ResponsiveUtils.getHorizontalPadding(context);

              final content = SmartBlockList(
                docDir: widget.doc,
                scrollController: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? padding : 8,
                  vertical: isLargeScreen ? 24 : 12,
                ),
                emptyWidget: const EmptyStateWidget(
                  icon: IconsaxPlusLinear.document_text,
                  title: 'Empty Document',
                  description:
                      'Start adding content by selecting a block type from the sidebar or toolbar',
                ),
                onReorder: (oldIndex, newIndex) {
                  final controller = ref.read(
                    editDocumentControllerProvider(widget.doc).notifier,
                  );
                  final currentBlocks = ref.read(
                    editDocumentControllerProvider(widget.doc),
                  );
                  final updated = List<Block>.from(currentBlocks);
                  final adjustedIndex = newIndex > oldIndex
                      ? newIndex - 1
                      : newIndex;
                  final item = updated.removeAt(oldIndex);
                  updated.insert(adjustedIndex, item);
                  controller.saveBlockOrder(updated);
                },
                itemBuilder: (block, index) {
                  return _renderBlock(
                    block,
                    isLargeScreen ? maxContentWidth : null,
                  );
                },
              );

              if (isLargeScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlockTypeSelectorWidget(
                      theme: theme,
                      onBlockTypeSelected: (type, isSidebar) async =>
                          await _handleBlockTypeAdd(type, isSidebar),
                      maxWidth: constraints.maxWidth,
                    ),
                    Expanded(
                      child: ResponsiveUtils.centerContent(
                        context,
                        Stack(
                          children: [
                            content,
                            Align(
                              alignment: Alignment.centerRight,
                              child: ScrollIndicatorWidget(
                                scrollProgress: _scrollProgress,
                                opacityAnimation: _scrollIndicatorOpacity,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(child: content),
                      BlockTypeSelectorWidget(
                        theme: theme,
                        onBlockTypeSelected: (type, isSidebar) async =>
                            await _handleBlockTypeAdd(type, isSidebar),
                        maxWidth: constraints.maxWidth,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ScrollIndicatorWidget(
                      scrollProgress: _scrollProgress,
                      opacityAnimation: _scrollIndicatorOpacity,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveUtils.getIconSize(context, baseSize: 20.0);
    return IconButton(
      icon: Icon(icon, size: iconSize, fontWeight: FontWeight.bold),
      color: theme.colorScheme.primary,
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: iconSize,
    );
  }
}

/// Stateful dialog for editing page title.
/// Manages its own TextEditingController lifecycle to avoid disposal issues.
class _EditPageTitleDialog extends StatefulWidget {
  final String initialTitle;

  const _EditPageTitleDialog({required this.initialTitle});

  @override
  State<_EditPageTitleDialog> createState() => _EditPageTitleDialogState();
}

class _EditPageTitleDialogState extends State<_EditPageTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Tab Title'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Tab Title',
          hintText: 'Enter tab title',
          counterText: '', // Hide counter, but still enforce limit
        ),
        autofocus: true,
        maxLength: 100,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// A placeholder widget rendered for block types this version of the Flutter
/// app does not recognise (e.g. new STEM blocks added on the web app).
/// The block data is preserved in full so re-exporting as .bipy retains it.
class _UnsupportedBlockPlaceholder extends StatelessWidget {
  final Block block;

  const _UnsupportedBlockPlaceholder({required this.block});

  String get _originalType {
    try {
      final map = jsonDecode(block.content) as Map<String, dynamic>;
      return map[BlockTypeConstants.originalBlockTypeKey] as String? ?? '?';
    } catch (_) {
      return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.block,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Block type "$_originalType" is not supported in this version of the app.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
