import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/presentation/widgets/minibook_theme_wrapper.dart';
import 'package:barruu/features/workspace/presentation/screen/display_document.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/presentation/widgets/edit_document/page_drawer_widget.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/router/app_router.dart';
class PreviewDocument extends ConsumerStatefulWidget {
  final Directory doc;

  const PreviewDocument({super.key, required this.doc});

  @override
  ConsumerState<PreviewDocument> createState() => _PreviewDocumentState();
}

class _PreviewDocumentState extends ConsumerState<PreviewDocument> with TickerProviderStateMixin {
  bool _showAllBlocks = true;
  TabController? _tabController;
  List<DocumentPage> _tabPages = [];
  String? _lastPageId;

  @override
  void initState() {
    super.initState();
    _loadTabPages();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _toggleShowAllBlocks() {
    setState(() {
      _showAllBlocks = !_showAllBlocks;
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
      
      // Get only the tab pages that belong to the current drawer page (as children)
      final pageTabPages = pages.where(
        (page) => page.isTabPage && page.parentPageId == currentDrawerPage.id
      ).toList();
      
      // Tab 1 is always the current drawer page, followed by its child tab pages
      final tabPages = [currentDrawerPage, ...pageTabPages];
      
      if (mounted) {
        setState(() {
          _tabPages = tabPages;
          if (_tabPages.isNotEmpty) {
            // Default to Tab 1 (the drawer page) if current page is not in tabs
            final currentIndex = _tabPages.indexWhere((p) => p.id == currentPageId);
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
                ref.read(currentPageIdProvider(widget.doc.path).notifier).state = selectedPage.id;
              }
            });
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('Failed to load tab pages', error: e, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>> _loadMeta() async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final metadata = await documentService.getDocumentMetadata(widget.doc);
      return metadata ?? {};
    } catch (e, stackTrace) {
      logger.e('Failed to load document metadata', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Build a persistent page outline sidebar for desktop,
  /// or use a traditional drawer for mobile.
  Widget _buildPageOutline() {
    final theme = Theme.of(context); // Use current theme from context
    final documentService = ref.watch(documentServiceProvider);
    
    return Drawer(
      child: FutureBuilder<List<DocumentPage>>(
        future: documentService.getDocumentPages(widget.doc),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: ShimmerCircularProgress(
                size: 40,
                color: theme.colorScheme.primary,
              ),
            );
          }
          
          final allPages = snapshot.data!;
          // Filter to show only drawer pages (root pages without parent)
          final drawerPages = allPages.where((page) => page.isDrawerPage).toList();
          final currentPageId = ref.watch(currentPageIdProvider(widget.doc.path));
          
          return Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pages',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: drawerPages.length,
                  itemBuilder: (context, index) {
                    final page = drawerPages[index];
                    final isCurrentPage = page.id == currentPageId;
                    final pageIcon = getDrawerPageIcon(page.icon);
                    
                    return ListTile(
                      // Only show leading icon if the page has one
                      leading: pageIcon != null
                          ? Icon(
                              pageIcon,
                              color: isCurrentPage ? theme.colorScheme.primary : null,
                            )
                          : null,
                      title: Text(
                        page.displayTitle,
                        style: TextStyle(
                          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentPage ? theme.colorScheme.primary : null,
                          fontStyle: page.title.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      selected: isCurrentPage,
                      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      onTap: () {
                        ref.read(currentPageIdProvider(widget.doc.path).notifier).state = page.id;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use current theme from context
    final navigationStack = ref.watch(pageNavigationStackProvider(widget.doc.path));
    final canGoBack = navigationStack.length > 1;
    final router = ref.watch(routerProvider);
    
    // Watch for page changes and reload tabs if we've switched to a different drawer page
    final currentPageId = ref.watch(currentPageIdProvider(widget.doc.path));
    
    // Check if we need to reload tabs (when switching to a different drawer page)
    if (_lastPageId != null && _lastPageId != currentPageId) {
      // Schedule reload for next frame to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTabPages();
      });
    }
    _lastPageId = currentPageId;
    
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
                    final stack = ref.read(pageNavigationStackProvider(widget.doc.path));
                    if (stack.length > 1) {
                      final newStack = List<String>.from(stack);
                      final previousPageId = newStack.removeLast();
                      ref.read(pageNavigationStackProvider(widget.doc.path).notifier).state = newStack;
                      ref.read(currentPageIdProvider(widget.doc.path).notifier).state = previousPageId;
                    }
                  },
                )
              : null,
          title: FutureBuilder<Map<String, dynamic>>(
            future: _loadMeta(),
            builder: (context, snapshot) {
              final title = snapshot.data?[MetaFile.nameKey]?.toString().trim() ?? 'Untitled Document';
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
              icon: Icon(
                _showAllBlocks ? Icons.fullscreen_sharp : Icons.line_weight_sharp,
              ),
              onPressed: _toggleShowAllBlocks,
              tooltip: _showAllBlocks ? 'Show Incremental View' : 'Show All Blocks',
            ),
            IconButton(
              icon: Icon(
                IconsaxPlusLinear.color_swatch,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Change Minibook Theme',
              onPressed: ()=> router.go('/theme-selection'),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              icon: const Icon(IconsaxPlusLinear.edit),
              tooltip: 'Edit Document',
              onPressed: () => _handleEditDocument(),
            ),
            IconButton(
              icon: const Icon(IconsaxPlusLinear.home),
              tooltip: 'Home',
              onPressed: () =>router.go('/')
            ),
          ],
          bottom: _tabPages.length >= 2 && _tabController != null
              ? TabBar(
                  controller: _tabController,
                  isScrollable: _tabPages.length > 3,
                  tabAlignment: _tabPages.length > 3 ? TabAlignment.start : null,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3.0,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  labelStyle: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                  labelPadding: EdgeInsets.symmetric(
                    horizontal: _tabPages.length > 3 ? 20 : 16, 
                    vertical: 8
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: _tabPages.asMap().entries.map((entry) {
                    final page = entry.value;
                    // Use the tab-specific display name
                    final displayTitle = page.tabTitle;
                    
                    return Tab(
                      height: 52,
                      child: Text(
                        displayTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                )
              : null,
        ),
        drawer: _buildPageOutline(),
        body: DisplayDocument(
          doc: widget.doc,
          showAllBlocks: _showAllBlocks,
        ),
      ),
    );
  }

  /// Handles edit document action
  Future<void> _handleEditDocument() async {
    try {
      if (mounted) {
        final docPath = Uri.encodeComponent(widget.doc.path);
        context.push('/edit-document/$docPath');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to handle edit document', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open editor')),
        );
      }
    }
  }
}