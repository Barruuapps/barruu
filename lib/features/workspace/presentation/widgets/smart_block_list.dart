import 'dart:io';
import 'package:barruu/core/config/pagination_config.dart';
import 'package:barruu/core/providers/workspace_use_case_providers.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Smart block list widget that automatically chooses between pagination and full-load
/// based on document size for optimal performance and functionality.
/// 
/// For small documents (<100 blocks), uses full-load with reordering support.
/// For large documents (>100 blocks), uses pagination for better memory performance.
class SmartBlockList extends ConsumerStatefulWidget {
  final Directory docDir;
  final ScrollController scrollController;
  final EdgeInsets padding;
  final Widget Function(Block block, int index) itemBuilder;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Widget? emptyWidget;

  const SmartBlockList({
    required this.docDir,
    required this.scrollController,
    required this.padding,
    required this.itemBuilder,
    this.onReorder,
    this.emptyWidget,
    super.key,
  });

  @override
  ConsumerState<SmartBlockList> createState() => _SmartBlockListState();
}

class _SmartBlockListState extends ConsumerState<SmartBlockList> {
  bool _isCheckingSize = true;
  bool _shouldUsePagination = false;

  @override
  void initState() {
    super.initState();
    _checkDocumentSize();
  }

  Future<void> _checkDocumentSize() async {
    try {
      // Get total block count to decide pagination strategy
      final countUseCase = ref.read(getBlocksCountUseCaseProvider(widget.docDir));
      final result = await countUseCase.execute();
      
      result.when(
        success: (count) {
          if (mounted) {
            setState(() {
              _shouldUsePagination = PaginationConfig.shouldUsePagination(count);
              _isCheckingSize = false;
            });
            
            // Only setup scroll listener if pagination is needed
            if (_shouldUsePagination) {
              widget.scrollController.addListener(_onScroll);
            }
          }
        },
        error: (message) {
          if (mounted) {
            setState(() {
              _shouldUsePagination = false; // Fallback to full-load on error
              _isCheckingSize = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _shouldUsePagination = false;
          _isCheckingSize = false;
        });
      }
    }
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (controller.position.pixels >= 
        controller.position.maxScrollExtent - PaginationConfig.loadMoreThreshold) {
      _loadMoreBlocks();
    }
  }

  void _loadMoreBlocks() {
    if (!_shouldUsePagination) return;
    
    final paginatedState = ref.read(paginatedEditControllerProvider(widget.docDir));
    if (!paginatedState.isLoading && paginatedState.hasMore) {
      ref.read(paginatedEditControllerProvider(widget.docDir).notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    // Only remove listener if it was added
    if (_shouldUsePagination) {
      widget.scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSize) {
      return Center(
        child: ShimmerLoading(
          child: Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }

    if (_shouldUsePagination) {
      return _buildPaginatedList();
    } else {
      return _buildFullLoadList();
    }
  }

  Widget _buildPaginatedList() {
    final state = ref.watch(paginatedEditControllerProvider(widget.docDir));

    if (state.hasError && state.blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Error loading blocks: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(paginatedEditControllerProvider(widget.docDir).notifier)
                    .refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.blocks.isEmpty && !state.isLoading) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: widget.padding,
      itemCount: state.blocks.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == state.blocks.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: ShimmerCircularProgress(size: 40),
            ),
          );
        }

        final block = state.blocks[index];
        return widget.itemBuilder(block, index);
      },
    );
  }

  Widget _buildFullLoadList() {
    final blocks = ref.watch(editDocumentControllerProvider(widget.docDir));

    if (blocks.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    // Use ReorderableListView for full-load mode to maintain reordering
    if (widget.onReorder != null) {
      return ReorderableListView.builder(
        scrollController: widget.scrollController,
        padding: widget.padding,
        itemCount: blocks.length,
        onReorder: widget.onReorder!,
        itemBuilder: (context, index) {
          final block = blocks[index];
          // ValueKey required for ReorderableListView
          return Container(
            key: ValueKey(block.id),
            child: widget.itemBuilder(block, index),
          );
        },
      );
    }

    // Fallback to regular ListView if no reordering needed
    // No ValueKey needed here - more efficient
    return ListView.builder(
      controller: widget.scrollController,
      padding: widget.padding,
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return widget.itemBuilder(block, index);
      },
    );
  }
}
