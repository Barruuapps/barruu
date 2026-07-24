import 'dart:io';
import 'dart:convert';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/domain/usecases/get_blocks_paginated_use_case.dart';
import 'package:barruu/features/workspace/domain/usecases/get_blocks_count_use_case.dart';
import 'package:flutter_riverpod/legacy.dart';

/// State for paginated block loading
class PaginatedBlocksState {
  final List<Block> blocks;
  final int totalCount;
  final int currentOffset;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedBlocksState({
    this.blocks = const [],
    this.totalCount = 0,
    this.currentOffset = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedBlocksState copyWith({
    List<Block>? blocks,
    int? totalCount,
    int? currentOffset,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedBlocksState(
      blocks: blocks ?? this.blocks,
      totalCount: totalCount ?? this.totalCount,
      currentOffset: currentOffset ?? this.currentOffset,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  bool get hasLoadedAll => blocks.length >= totalCount && totalCount > 0;
  bool get hasError => error != null;
}

/// Controller for paginated block loading in EditDocumentScreen
/// 
/// This controller manages incremental loading of blocks for better performance
/// with large documents. It uses the pagination infrastructure from Phase 4 Week 13.
class PaginatedEditController extends StateNotifier<PaginatedBlocksState> {
  final Directory docDir;
  final GetBlocksPaginatedUseCase _getPaginatedUseCase;
  final GetBlocksCountUseCase _getCountUseCase;
  final int pageSize;

  PaginatedEditController({
    required this.docDir,
    required GetBlocksPaginatedUseCase getPaginatedUseCase,
    required GetBlocksCountUseCase getCountUseCase,
    this.pageSize = 30,
  })  : _getPaginatedUseCase = getPaginatedUseCase,
        _getCountUseCase = getCountUseCase,
        super(const PaginatedBlocksState()) {
    _initialize();
  }

  /// Initialize by loading total count and first page
  Future<void> _initialize() async {
    if (!mounted) return;
    
    try {
      // Get total count first (don't set isLoading yet)
      final countResult = await _getCountUseCase.execute();
      
      if (!mounted) return;
      
      // Handle the result
      if (countResult.isSuccess) {
        final count = (countResult as Success<int>).value;
        state = state.copyWith(totalCount: count, hasMore: count > 0);
        
        // Load first page if there are blocks
        // loadNextPage() will manage its own isLoading state
        if (count > 0) {
          await loadNextPage();
        }
        // If count is 0, state remains with isLoading: false, hasMore: false
      } else {
        final message = (countResult as Error<int>).message;
        logger.e('Failed to get blocks count: $message');
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error initializing paginated controller', error: e, stackTrace: stackTrace);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to initialize: $e',
          hasMore: false,
        );
      }
    }
  }

  /// Load the next page of blocks
  Future<void> loadNextPage() async {
    if (!mounted || state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _getPaginatedUseCase.execute(
        limit: pageSize,
        offset: state.currentOffset,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final newBlocks = (result as Success<List<Block>>).value;
        final normalizedBlocks = newBlocks
            .map((block) => _normalizeBlockContent(block))
            .toList();

        // Filter out blocks with missing media files
        final validBlocks = <Block>[];
        for (var block in normalizedBlocks) {
          if (_isMediaBlock(block)) {
            final isValid = _validateMediaBlock(block);
            if (isValid) {
              validBlocks.add(block);
            } else {
              logger.w('Skipping block with missing media: ${block.id}');
            }
          } else {
            validBlocks.add(block);
          }
        }

        final allBlocks = [...state.blocks, ...validBlocks];
        final hasMore = allBlocks.length < state.totalCount;

        // Note: currentOffset tracks the position in the repository's block list,
        // not in our filtered list. This is correct because the next pagination
        // request needs to start from where the repository left off, regardless
        // of how many blocks we filtered out for validation.
        state = state.copyWith(
          blocks: allBlocks,
          currentOffset: state.currentOffset + newBlocks.length,
          isLoading: false,
          hasMore: hasMore,
        );

        logger.i('Loaded ${newBlocks.length} blocks, total: ${allBlocks.length}/${state.totalCount}');
      } else {
        final message = (result as Error<List<Block>>).message;
        logger.e('Failed to load blocks: $message');
        state = state.copyWith(
          isLoading: false,
          error: message,
          hasMore: false,
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error loading next page', error: e, stackTrace: stackTrace);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load blocks: $e',
          hasMore: false,
        );
      }
    }
  }

  /// Refresh all blocks (reload from beginning)
  Future<void> refresh() async {
    state = const PaginatedBlocksState();
    await _initialize();
  }

  bool _isMediaBlock(Block block) {
    return block.type == BlockType.image ||
        block.type == BlockType.audio ||
        block.type == BlockType.video;
  }

  bool _validateMediaBlock(Block block) {
    try {
      final json = jsonDecode(block.content) as Map<String, dynamic>;
      final relativePath = json['path'] as String? ?? '';
      
      if (relativePath.isEmpty) {
        return true; // Empty path is valid (no media selected yet)
      }

      final absolutePath = '${docDir.path}/$relativePath';
      final file = File(absolutePath);
      return file.existsSync();
    } catch (e) {
      logger.w('Failed to validate media block ${block.id}: $e');
      return false;
    }
  }

  Block _normalizeBlockContent(Block block) {
    if (!_isMediaBlock(block)) {
      return block;
    }

    try {
      final json = jsonDecode(block.content) as Map<String, dynamic>;
      
      // Ensure path is relative
      final path = json['path'] as String? ?? '';
      if (path.isNotEmpty && path.startsWith(docDir.path)) {
        json['path'] = path.replaceFirst('${docDir.path}/', '');
      }
      
      return block.copyWith(content: jsonEncode(json));
    } catch (e, stackTrace) {
      logger.w('Invalid JSON content for block ${block.id}', error: e, stackTrace: stackTrace);
      
      // Return block with default empty content based on type
      final defaultContent = _getDefaultMediaContent(block.type);
      return block.copyWith(content: jsonEncode(defaultContent));
    }
  }

  Map<String, dynamic> _getDefaultMediaContent(BlockType type) {
    switch (type) {
      case BlockType.image:
        return {
          'path': '',
          'caption': '',
          'cropTop': 0.0,
          'cropBottom': 0.0,
          'fit': 'cover',
          'fileName': ''
        };
      case BlockType.audio:
        return {
          'path': '',
          'caption': '',
          'autoPlay': false,
        };
      case BlockType.video:
        return {
          'path': '',
          'caption': '',
          'autoPlay': false,
        };
      default:
        return {'path': '', 'caption': ''};
    }
  }
}
