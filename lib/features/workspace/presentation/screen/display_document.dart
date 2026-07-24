import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/services/block_ai_service.dart';
import 'package:barruu/features/learning/presentation/providers/learning_progress_provider.dart';
import 'package:barruu/features/workspace/constants/block_type_constants.dart';
import 'package:barruu/features/workspace/presentation/widgets/ai_insight_card.dart';
import 'package:barruu/features/workspace/presentation/widgets/minibook_theme_wrapper.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/graph_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/reader_block_widgets.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisplayDocument extends ConsumerStatefulWidget {
  final Directory doc;
  final bool showAllBlocks;

  const DisplayDocument({
    super.key,
    required this.doc,
    this.showAllBlocks = true,
  });

  @override
  ConsumerState<DisplayDocument> createState() => _DisplayDocumentScreenState();
}

class _DisplayDocumentScreenState extends ConsumerState<DisplayDocument>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  int _revealedBlockCount = 1;
  double _scrollProgress = 0.0;
  late AnimationController _scrollIndicatorController;
  late Animation<double> _scrollIndicatorOpacity;

  /// Tracks active AI insight cards keyed by block ID.
  final Map<String, ({AiAction action, Stream<String> stream})> _aiCards = {};

  @override
  void initState() {
    super.initState();
    _initializeDocument();
    _scrollController.addListener(_updateScrollProgress);
    _scrollIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollIndicatorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrollIndicatorController,
        curve: Curves.easeInOut,
      ),
    );
    _scrollController.addListener(_toggleScrollIndicator);
  }

  @override
  void didUpdateWidget(DisplayDocument oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.path != widget.doc.path) {
      _initializeDocument();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.removeListener(_toggleScrollIndicator);
    _scrollController.dispose();
    _scrollIndicatorController.dispose();
    super.dispose();
  }

  Future<void> _initializeDocument() async {
    try {
      // Sync currentPageIdProvider to the first real page in pages.json.
      // This is necessary when a web-created document has UUID-based page IDs
      // (e.g. 'page_abc123') instead of the Flutter default 'page_1'.
      // If the provider keeps the wrong default, editDocumentControllerProvider
      // opens a non-existent DB and returns empty blocks.
      await _syncCurrentPageId();
      if (!mounted) return;
      ref.read(editDocumentControllerProvider(widget.doc));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading document: $e')));
      }
    }
  }

  /// Ensures [currentPageIdProvider] is set to an actual page that exists in
  /// this document's pages.json.  When a document was created on the web, its
  /// pages have UUID-based IDs (e.g. 'page_abc123') instead of Flutter's
  /// default 'page_1'.  If the provider still holds the wrong default the
  /// [editDocumentControllerProvider] would open a non-existent SQLite file
  /// and return empty blocks.
  Future<void> _syncCurrentPageId() async {
    try {
      final documentService = ref.read(documentServiceProvider);
      final pages = await documentService.getDocumentPages(widget.doc);
      if (pages.isEmpty) return;
      final currentId = ref.read(currentPageIdProvider(widget.doc.path));
      if (!pages.any((p) => p.id == currentId)) {
        ref.read(currentPageIdProvider(widget.doc.path).notifier).state =
            pages.first.id;
      }
    } catch (_) {
      // Non-fatal — fall through to load blocks with whatever page ID we have
    }
  }

  void _updateScrollProgress() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final nextProgress = maxScroll > 0
          ? (currentScroll / maxScroll).clamp(0.0, 1.0)
          : 0.0;
      if ((nextProgress - _scrollProgress).abs() > 0.003) {
        setState(() {
          _scrollProgress = nextProgress;
        });
      }
    }
  }

  void _toggleScrollIndicator() {
    if (_scrollController.hasClients &&
        _scrollController.position.isScrollingNotifier.value) {
      _scrollIndicatorController.forward();
    } else {
      _scrollIndicatorController.reverse();
    }
  }

  void _revealNextBlock(int totalBlocks) {
    if (_revealedBlockCount < totalBlocks) {
      setState(() {
        _revealedBlockCount++;
      });
      _scrollToNewBlock();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End of lecture'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _revealPreviousBlock() {
    if (_revealedBlockCount > 1) {
      setState(() {
        _revealedBlockCount--;
      });
      _scrollToNewBlock();
    }
  }

  void _scrollToNewBlock() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Shows a bottom sheet offering the three AI actions for [block].
  void _showAiActionSheet(Block block) {
    showModalBottomSheet<AiAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✨ Ask AI about this block',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final action in AiAction.values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  title: Text(action.label),
                  onTap: () => Navigator.of(ctx).pop(action),
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    ).then((action) {
      if (action == null || block.id == null) return;
      _launchAiCard(block, action);
    });
  }

  /// Starts streaming an AI insight for [block] and registers it in [_aiCards].
  void _launchAiCard(Block block, AiAction action) {
    final service = ref.read(blockAiServiceProvider);
    final stream = service.query(block, action).asBroadcastStream();
    setState(() {
      _aiCards[block.id!] = (action: action, stream: stream);
    });
  }

  Widget renderBlock(Block block) {
    Widget blockWidget;
    switch (block.type) {
      case BlockType.header:
        blockWidget = HeaderBlockReader(block: block);
        break;
      case BlockType.image:
        blockWidget = ImageReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.video:
        blockWidget = VideoReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.audio:
        blockWidget = AudioReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.divider:
        blockWidget = DividerReaderBlock(block: block);
        break;
      case BlockType.spacer:
        blockWidget = SpacerReaderBlock(block: block);
        break;
      case BlockType.blockquote:
        blockWidget = BlockQuoteReaderBlock(block: block);
        break;
      case BlockType.list:
        blockWidget = ListReaderBlock(block: block);
        break;
      case BlockType.code:
        blockWidget = CodeReaderBlock(block: block);
        break;
      case BlockType.math:
        blockWidget = MathReaderBlock(block: block);
        break;
      case BlockType.chat:
        blockWidget = ChatReaderBlock(block: block);
        break;
      case BlockType.box:
        blockWidget = BoxReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.checkbox:
        blockWidget = CheckBoxReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.table:
        blockWidget = TableReaderBlock(block: block);
        break;
      case BlockType.evaluationButton:
        blockWidget = EvaluationButtonReaderBlock(
          block: block,
          docDir: widget.doc,
        );
        break;
      case BlockType.graph:
        blockWidget = GraphReaderBlock(block: block);
        break;
      case BlockType.page:
        blockWidget = PageReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.wordOrder:
        blockWidget = WordOrderReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.mathWorkpad:
        blockWidget = MathWorkpadReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.tabs:
        blockWidget = TabsReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.cards:
        blockWidget = CardsReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.expandable:
        blockWidget = ExpandableReaderBlock(block: block);
        break;
      case BlockType.stepper:
        blockWidget = StepperReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.columns:
        blockWidget = ColumnsReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.rows:
        blockWidget = RowsReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.multipleChoice:
        blockWidget = MultipleChoiceReaderBlock(
          block: block,
          docDir: widget.doc,
        );
        break;
      case BlockType.trueFalse:
        blockWidget = TrueFalseReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.fillInBlank:
        blockWidget = FillBlankReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.matching:
        blockWidget = MatchingReaderBlock(block: block, docDir: widget.doc);
        break;
      case BlockType.theorem:
        blockWidget = TheoremReaderBlock(block: block);
        break;
      case BlockType.proof:
        blockWidget = ProofReaderBlock(block: block);
        break;
      case BlockType.definition:
        blockWidget = DefinitionReaderBlock(block: block);
        break;
      case BlockType.example:
        blockWidget = ExampleReaderBlock(block: block);
        break;
      case BlockType.learningObjective:
        blockWidget = LearningObjectiveReaderBlock(block: block);
        break;
      case BlockType.conceptSummary:
        blockWidget = ConceptSummaryReaderBlock(block: block);
        break;
      case BlockType.numericalQuestion:
        blockWidget = NumericalQuestionReaderBlock(block: block);
        break;
      case BlockType.glossary:
        blockWidget = GlossaryReaderBlock(block: block);
        break;
      case BlockType.parametricGraph:
        blockWidget = ParametricGraphReaderBlock(block: block);
        break;
      case BlockType.citation:
        blockWidget = CitationReaderBlock(block: block);
        break;
      case BlockType.toc:
        blockWidget = TocReaderBlock(block: block);
        break;
      case BlockType.faq:
        blockWidget = FaqReaderBlock(block: block);
        break;
      case BlockType.keyPoint:
        blockWidget = KeyPointReaderBlock(block: block);
        break;
      case BlockType.unsupported:
        blockWidget = _UnsupportedBlockPlaceholder(block: block);
        break;
      default:
        blockWidget = ParagraphReaderBlock(block: block, docDir: widget.doc);
    }

    // Removed extra padding wrapper - blocks now manage their own consistent margins
    return blockWidget;
  }

  Widget _buildAnimatedBlock(
    BuildContext context,
    int index,
    List<Block> blocks,
  ) {
    final block = blocks[index];
    final aiCard = block.id != null ? _aiCards[block.id!] : null;
    return RepaintBoundary(
      child: Column(
        key: ValueKey(block.id),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onLongPress: () => _showAiActionSheet(block),
            child: renderBlock(block),
          ),
          if (aiCard != null)
            AiInsightCard(
              action: aiCard.action,
              stream: aiCard.stream,
              onDismiss: () {
                if (block.id != null) {
                  setState(() => _aiCards.remove(block.id));
                }
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(editDocumentControllerProvider(widget.doc));
    final theme = Theme.of(context); // Use current theme from context

    return MinibookThemeWrapper(
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
              ? const ShimmerDocumentLoading()
              : blocks.isEmpty
              ? const Center(
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxContentWidth = ResponsiveUtils.getReadingMaxWidth(
                      context,
                    );
                    final padding = ResponsiveUtils.getHorizontalPadding(
                      context,
                    );

                    return Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(
                                  editDocumentControllerProvider(widget.doc),
                                );
                                // Brief delay so the new provider has time to load.
                                await Future.delayed(
                                  const Duration(milliseconds: 600),
                                );
                              },
                              child: ListView.builder(
                                scrollCacheExtent: ScrollCacheExtent.pixels(
                                  1000.0,
                                ),
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
                                  vertical: ResponsiveUtils.isDesktop(context)
                                      ? 24.0
                                      : 16.0,
                                ),
                                itemCount: widget.showAllBlocks
                                    ? blocks.length +
                                          1 // Add extra item for bottom padding
                                    : _revealedBlockCount +
                                          1, // Reduced padding in incremental mode
                                itemBuilder: (context, index) {
                                  // Add white space at the end - reduced for slide mode
                                  if (widget.showAllBlocks &&
                                      index == blocks.length) {
                                    return SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.25,
                                    );
                                  }
                                  if (!widget.showAllBlocks &&
                                      index >= _revealedBlockCount) {
                                    return SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.15,
                                    );
                                  }
                                  // Safety check: ensure index is within bounds
                                  if (index >= blocks.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildAnimatedBlock(
                                    context,
                                    index,
                                    blocks,
                                  );
                                },
                              ),
                            ), // RefreshIndicator
                          ),
                        ),
                        // Document scroll indicator
                        FadeTransition(
                          opacity: _scrollIndicatorOpacity,
                          child: Container(
                            width: 8,
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                // Completely transparent background - no background line
                                Positioned(
                                  top:
                                      _scrollProgress *
                                      (MediaQuery.of(context).size.height -
                                          32 -
                                          40),
                                  child: Container(
                                    width: 8,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Progress icon button (top-right corner)
                        Positioned(
                          top: 8,
                          right: 16,
                          child: _ProgressIconButton(docDir: widget.doc),
                        ),
                      ],
                    );
                  },
                ),
        ),
        floatingActionButton:
            _isLoading || blocks.isEmpty || widget.showAllBlocks
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_revealedBlockCount > 1)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _revealPreviousBlock,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.navigate_before_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Previous',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_revealedBlockCount > 1 &&
                        _revealedBlockCount < blocks.length)
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    if (_revealedBlockCount < blocks.length)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _revealNextBlock(blocks.length),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.navigate_next_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

/// A read-only placeholder rendered for block types that this version of the
/// Flutter app does not recognise (e.g. new STEM blocks added on the web app).
/// The block's data is preserved in full so that re-exporting the document as
/// a .bipy file retains the original block without data loss.
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
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

// ---------------------------------------------------------------------------
// Progress icon button — floats in the reader's top-right corner
// ---------------------------------------------------------------------------

class _ProgressIconButton extends ConsumerWidget {
  final Directory docDir;
  const _ProgressIconButton({required this.docDir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(learningProgressProvider(docDir.path));
    final attempted = entries.where((e) => e.attemptCount > 0).length;
    final total = entries.length;

    // Only show the button when there is at least one tracked block.
    if (total == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : attempted / total;

    return GestureDetector(
      onTap: () => _showProgressSheet(context, ref),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
            Icon(
              Icons.bar_chart_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showProgressSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DocumentProgressSheet(docDir: docDir),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-document progress bottom sheet
// ---------------------------------------------------------------------------

class _DocumentProgressSheet extends ConsumerWidget {
  final Directory docDir;
  const _DocumentProgressSheet({required this.docDir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(learningProgressProvider(docDir.path));
    final theme = Theme.of(context);

    final attempted = entries.where((e) => e.attemptCount > 0).length;
    final total = entries.length;
    final totalAttempts = entries.fold<int>(0, (s, e) => s + e.attemptCount);
    final totalCorrect = entries.fold<int>(0, (s, e) => s + e.correctCount);
    final accuracy = totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts;
    final completion = total == 0 ? 0.0 : attempted / total;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Summary cards row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Completion',
                      value: '${(completion * 100).round()}%',
                      icon: Icons.check_circle_outline_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Accuracy',
                      value: '${(accuracy * 100).round()}%',
                      icon: Icons.stars_rounded,
                      color: accuracy >= 0.8
                          ? const Color(0xFF2E7D32)
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Attempted',
                      value: '$attempted / $total',
                      icon: Icons.touch_app_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Block-by-block list
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No assessment attempts yet.\nTry answering some questions!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          final acc = e.accuracy;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            leading: Icon(
                              _iconForType(e.blockType),
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              _labelForType(e.blockType),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${e.attemptCount} attempt${e.attemptCount == 1 ? '' : 's'}  •  '
                              '${e.correctCount} correct',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            trailing: acc == null
                                ? null
                                : Text(
                                    '${(acc * 100).round()}%',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: acc >= 0.8
                                          ? const Color(0xFF2E7D32)
                                          : theme.colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForType(String blockType) {
    switch (blockType) {
      case 'multipleChoice':
        return Icons.radio_button_checked_rounded;
      case 'trueFalse':
        return Icons.toggle_on_rounded;
      case 'fillBlank':
        return Icons.short_text_rounded;
      case 'matching':
        return Icons.link_rounded;
      case 'mathEquationOrder':
      case 'mathWorkpad':
      case 'wordOrder':
        return Icons.functions_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  String _labelForType(String blockType) {
    switch (blockType) {
      case 'multipleChoice':
        return 'Multiple Choice';
      case 'trueFalse':
        return 'True / False';
      case 'fillBlank':
        return 'Fill in the Blank';
      case 'matching':
        return 'Matching';
      case 'mathEquationOrder':
        return 'Word Order';
      case 'mathWorkpad':
        return 'Math Workpad';
      case 'wordOrder':
        return 'Word Order';
      default:
        return blockType;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
