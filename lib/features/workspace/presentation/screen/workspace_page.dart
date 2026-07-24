import 'dart:async';
import 'dart:io';
import 'package:barruu/core/constants/design_tokens.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/widgets/barruu_card.dart';
import 'package:barruu/core/widgets/premium_empty_state.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/presentation/controllers/documents_controller.dart';
import 'package:barruu/features/workspace/presentation/dialogs/edit_document_info_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/document_card.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/cover_image_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/document_menu_button.dart';
import 'package:barruu/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:intl/intl.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  final Directory? docDir;
  const WorkspacePage({super.key, this.docDir});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage>
    with TickerProviderStateMixin {
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.duration300,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEmphasized,
    );
    _animationController.forward();
    _searchController.addListener(_onSearchChanged);
    _initializeWorkspace();
  }

  void _initializeWorkspace() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(documentsProvider.notifier).loadDocuments();
        if (widget.docDir != null) {
          final docPath = Uri.encodeComponent(widget.docDir!.path);
          if (!mounted) return;
          await context.push('/preview-document/$docPath');
          ref.read(documentsProvider.notifier).loadDocuments();
        }
      } catch (e, stackTrace) {
        logger.e(
          'Workspace initialization failed',
          error: e,
          stackTrace: stackTrace,
        );
        _showSnackBar('Failed to initialize workspace');
      }
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    UIUtils.showSnackBar(context, message, isError: isError);
  }

  Future<Map<String, dynamic>> _loadMeta(Directory doc) async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final meta = await documentService.getDocumentMetadata(doc) ?? {};
      final lastModified = await doc.stat().then((stat) => stat.modified);
      return {
        MetaFile.nameKey:
            meta[MetaFile.nameKey]?.toString().trim().isNotEmpty == true
            ? meta[MetaFile.nameKey]
            : 'Untitled Document',
        MetaFile.descriptionKey:
            meta[MetaFile.descriptionKey]?.toString() ?? '',
        MetaFile.coverKey: meta[MetaFile.coverKey]?.toString(),
        MetaFile.coverOriginalNameKey: meta[MetaFile.coverOriginalNameKey]
            ?.toString(),
        'lastModified': lastModified,
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to load metadata for ${doc.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return {MetaFile.nameKey: 'Untitled Document'};
    }
  }

  // ─── Dialogs (preserved from original) ────────────────────────────────

  Future<void> _showEditInfoDialog(Directory doc) async {
    final meta = await _loadMeta(doc);
    if (!mounted) return;
    await showEditDocumentInfoDialog(
      context: context,
      doc: doc,
      meta: meta,
      onShowSnackBar: _showSnackBar,
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────

  Future<void> _importDocument() async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final success = await documentService.importDocumentFromBipy();
      if (success != null) {
        await ref.read(documentsProvider.notifier).loadDocuments();
        _showSnackBar('Document imported');
      } else {
        _showSnackBar('Failed to import document');
      }
    } catch (e, stackTrace) {
      logger.e('Import failed', error: e, stackTrace: stackTrace);
      _showSnackBar('Import error');
    }
  }

  Future<void> _createNewDocument() async {
    try {
      await context.push('/create-document');
      ref.read(documentsProvider.notifier).loadDocuments();
    } catch (e, stackTrace) {
      logger.e('Create document failed', error: e, stackTrace: stackTrace);
      _showSnackBar('Navigation error');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documentsState = ref.watch(documentsProvider);
    final router = ref.watch(routerProvider);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: _buildPremiumAppBar(theme, router, textTheme, colorScheme),
      body: SafeArea(
        child: Column(
          children: [
            // Animated search bar
            _buildSearchBar(theme),
            // Content
            Expanded(
              child: documentsState.when(
                loading: () => _buildLoadingState(theme),
                error: (error, _) => _buildErrorState(error, theme),
                data: (docs) =>
                    _buildDocumentsView(docs, theme, textTheme, colorScheme),
              ),
            ),
          ],
        ),
      ),
      // Floating action button — premium style
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDocument,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: DesignTokens.elevation4,
        icon: const Icon(IconsaxPlusLinear.add, size: DesignTokens.iconCompact),
        label: Text(
          ResponsiveUtils.isDesktop(context) ? 'New Document' : 'New',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // ─── Premium App Bar ────────────────────────────────────────────────

  PreferredSizeWidget _buildPremiumAppBar(
    ThemeData theme,
    GoRouter router,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surfaceContainerLowest,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Workspace',
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: DesignTokens.weightBold,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        // Search toggle
        _BarruuAppBarIconButton(
          icon: _showSearch
              ? IconsaxPlusLinear.close_circle
              : IconsaxPlusLinear.search_normal_1,
          tooltip: _showSearch ? 'Hide Search' : 'Search Documents',
          highlightColor: _showSearch ? colorScheme.primaryContainer : null,
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchQuery = '';
                _animationController.forward();
              }
            });
          },
        ),
        // Theme switcher
        _BarruuAppBarIconButton(
          icon: IconsaxPlusLinear.color_swatch,
          tooltip: 'Change Theme',
          onPressed: () => router.go('/theme-selection'),
        ),
        // Import
        _BarruuAppBarIconButton(
          icon: IconsaxPlusLinear.import,
          tooltip: 'Import Document',
          onPressed: _importDocument,
        ),
        SizedBox(width: DesignTokens.spacing8),
      ],
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedContainer(
      duration: DesignTokens.duration300,
      curve: DesignTokens.curveEmphasized,
      height: _showSearch ? 72.0 : 0.0,
      child: _showSearch
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacing16,
                vertical: DesignTokens.spacing8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusXLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search documents by name...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: DesignTokens.opacitySubtle,
                      ),
                    ),
                    prefixIcon: Icon(
                      IconsaxPlusLinear.search_normal,
                      size: DesignTokens.iconCompact,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              IconsaxPlusLinear.close_circle,
                              size: DesignTokens.iconCompact,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacing16,
                      vertical: DesignTokens.spacing12,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ─── Loading / Error States ───────────────────────────────────────────

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: DesignTokens.spacing16),
          Text(
            'Loading documents...',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    logger.e('Failed to load documents', error: error);
    return PremiumEmptyState.error(
      message:
          'Unable to load your documents. '
          'Please check your permissions and try again.',
      onRetry: () => ref.read(documentsProvider.notifier).loadDocuments(),
    );
  }

  // ─── Document Grid ────────────────────────────────────────────────────

  Widget _buildDocumentsView(
    List<Directory> docs,
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (docs.isEmpty) {
      return PremiumEmptyState.noDocuments(
        onCreate: _createNewDocument,
        onImport: _importDocument,
      );
    }

    final filteredDocs = _searchQuery.isEmpty
        ? docs
        : docs.where((doc) {
            final meta =
                ref.read(documentsProvider.notifier).getCachedMeta(doc) ?? {};
            final name = meta[MetaFile.nameKey]?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery);
          }).toList();

    if (filteredDocs.isEmpty) {
      return PremiumEmptyState.noSearchResults(
        onClear: () {
          setState(() {
            _searchController.clear();
            _searchQuery = '';
          });
        },
      );
    }

    // Sort alphabetically
    filteredDocs.sort((a, b) {
      final aMeta = ref.read(documentsProvider.notifier).getCachedMeta(a) ?? {};
      final bMeta = ref.read(documentsProvider.notifier).getCachedMeta(b) ?? {};
      return (aMeta[MetaFile.nameKey] ?? 'Untitled').compareTo(
        bMeta[MetaFile.nameKey] ?? 'Untitled',
      );
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = ResponsiveUtils.getGridColumns(context);
          final spacing = ResponsiveUtils.getGridSpacing(context);
          final padding = ResponsiveUtils.getHorizontalPadding(context);
          final aspectRatio = ResponsiveUtils.getCardAspectRatio(context);

          // Welcome header — only when no search query
          final showWelcome = _searchQuery.isEmpty;

          if (width >= 600) {
            final children = <Widget>[];
            if (showWelcome) {
              children.add(
                _buildWelcomeHeader(theme, textTheme, colorScheme, docs.length),
              );
            }
            // Build grid of document cards
            final cardWidgets = List.generate(
              filteredDocs.length,
              (index) =>
                  _buildDocumentCard(context, filteredDocs[index], theme),
            );
            children.addAll(cardWidgets);

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DesignTokens.contentWideMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showWelcome)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spacing24,
                          ),
                          child: _buildWelcomeHeader(
                            theme,
                            textTheme,
                            colorScheme,
                            docs.length,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spacing16,
                          ),
                          child: Text(
                            '${filteredDocs.length} document${filteredDocs.length == 1 ? '' : 's'} found',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: DesignTokens.opacitySubtle,
                              ),
                              fontWeight: DesignTokens.weightMedium,
                            ),
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) => _buildDocumentCard(
                          context,
                          filteredDocs[index],
                          theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // List layout for small screens
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacing16,
              DesignTokens.spacing8,
              DesignTokens.spacing16,
              DesignTokens.spacing24,
            ),
            itemCount: filteredDocs.length + (showWelcome ? 1 : 0),
            itemBuilder: (context, index) {
              if (showWelcome && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: DesignTokens.spacing16,
                  ),
                  child: _buildWelcomeCompact(
                    theme,
                    textTheme,
                    colorScheme,
                    docs.length,
                  ),
                );
              }
              final docIndex = showWelcome ? index - 1 : index;
              return Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
                child: _buildDocumentItem(
                  context,
                  filteredDocs[docIndex],
                  theme,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Welcome Header ─────────────────────────────────────────────────

  Widget _buildWelcomeHeader(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    int docCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back 👋',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: DesignTokens.weightExtraBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Text(
                    'You have $docCount document${docCount == 1 ? '' : 's'} in your workspace',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(
                        alpha: DesignTokens.opacitySubtle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Quick action chips
            _QuickActionChip(
              icon: IconsaxPlusLinear.add,
              label: 'New Document',
              onTap: _createNewDocument,
            ),
            const SizedBox(width: DesignTokens.spacing8),
            _QuickActionChip(
              icon: IconsaxPlusLinear.import,
              label: 'Import',
              onTap: _importDocument,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCompact(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    int docCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workspace',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: DesignTokens.weightBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing4),
        Text(
          '$docCount document${docCount == 1 ? '' : 's'}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(
              alpha: DesignTokens.opacitySubtle,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Row(
          children: [
            _QuickActionChip(
              icon: IconsaxPlusLinear.add,
              label: 'New',
              onTap: _createNewDocument,
            ),
            const SizedBox(width: DesignTokens.spacing8),
            _QuickActionChip(
              icon: IconsaxPlusLinear.import,
              label: 'Import',
              onTap: _importDocument,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Document Card (Grid) ───────────────────────────────────────────

  Widget _buildDocumentCard(
    BuildContext context,
    Directory doc,
    ThemeData theme,
  ) {
    final meta = ref.read(documentsProvider.notifier).getCachedMeta(doc) ?? {};
    return WorkspaceDocumentCard(
      doc: doc,
      meta: meta,
      buildCoverImage: (coverImageUrl, theme) =>
          CoverImageWidget(coverImageUrl: coverImageUrl, theme: theme),
      buildPopupMenuButton: (doc) => DocumentMenuButton(
        doc: doc,
        onEditInfo: _showEditInfoDialog,
        onPublish: (_) async {},
        onShowSnackBar: _showSnackBar,
        onReloadDocuments: () =>
            ref.read(documentsProvider.notifier).loadDocuments(),
      ),
      onShowSnackBar: _showSnackBar,
      onReloadDocuments: () =>
          ref.read(documentsProvider.notifier).loadDocuments(),
    );
  }

  // ─── Document Item (List) ────────────────────────────────────────────

  Widget _buildDocumentItem(
    BuildContext context,
    Directory doc,
    ThemeData theme,
  ) {
    final meta = ref.read(documentsProvider.notifier).getCachedMeta(doc) ?? {};
    final title =
        meta[MetaFile.nameKey]?.toString().trim() ?? 'Untitled Document';
    final lastModified = meta['lastModified'] as DateTime? ?? DateTime.now();
    final coverImageUrl = meta[MetaFile.coverKey]?.toString();
    final formattedDate = DateFormat('MMM d, yyyy').format(lastModified);

    return BarruuListCard(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CoverImageWidget(coverImageUrl: coverImageUrl, theme: theme),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: DesignTokens.weightSemiBold,
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        formattedDate,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DocumentMenuButton(
        doc: doc,
        onEditInfo: _showEditInfoDialog,
        onPublish: (_) async {},
        onShowSnackBar: _showSnackBar,
        onReloadDocuments: () =>
            ref.read(documentsProvider.notifier).loadDocuments(),
      ),
      onTap: () async {
        try {
          final docPath = Uri.encodeComponent(doc.path);
          await context.push('/preview-document/$docPath');
          ref.read(documentsProvider.notifier).loadDocuments();
        } catch (e, stackTrace) {
          logger.e(
            'Navigation error: ${doc.path}',
            error: e,
            stackTrace: stackTrace,
          );
          _showSnackBar('Failed to open document');
        }
      },
    );
  }
}

// ─── App Bar Icon Button (reusable, premium styling) ─────────────────

class _BarruuAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? highlightColor;
  final VoidCallback onPressed;

  const _BarruuAppBarIconButton({
    required this.icon,
    required this.tooltip,
    this.highlightColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: DesignTokens.spacing4),
      decoration: BoxDecoration(
        color:
            highlightColor ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: DesignTokens.iconCompact,
          color: theme.colorScheme.primary,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: DesignTokens.iconCompact,
      ),
    );
  }
}

// ─── Quick Action Chip ────────────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing16,
            vertical: DesignTokens.spacing8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: DesignTokens.iconSmall,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: DesignTokens.weightSemiBold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
