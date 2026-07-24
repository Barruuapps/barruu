import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository.dart';

/// Service for managing block ordering and positioning.
///
/// Responsibilities:
/// - Moving blocks up and down in the list
/// - Saving custom block order
/// - Duplicating blocks with correct positioning
/// - Maintaining position consistency across all blocks
class BlockOrderingService {
  final PageRepository repository;

  BlockOrderingService(this.repository);

  /// Duplicates a block and inserts it after the original.
  ///
  /// The new block will have the same content, type, and style as the original,
  /// but a new ID and position.
  ///
  /// [block] - The block to duplicate
  /// [currentBlocks] - The current list of blocks
  ///
  /// Returns a tuple of (new block ID, updated blocks list)
  Future<(String?, List<Block>)> duplicateBlock(
    Block block,
    List<Block> currentBlocks,
  ) async {
    try {
      final newBlock = Block(
        content: block.content,
        position: block.position + 1,
        type: block.type,
        style: block.style,
      );
      final id = await repository.addBlock(newBlock);
      final updatedBlock = newBlock.copyWith(id: id);

      final newBlocks = List<Block>.from(currentBlocks);
      newBlocks.insert(block.position + 1, updatedBlock);
      final reindexedBlocks = _reindexBlocks(newBlocks);

      await repository.updateBlocks(reindexedBlocks);
      logger.i('Block duplicated: $id from original: ${block.id}');
      return (id, reindexedBlocks);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to duplicate block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return (null, currentBlocks);
    }
  }

  /// Moves a block up one position in the list.
  ///
  /// If the block is already at the top, no action is taken.
  ///
  /// [block] - The block to move
  /// [currentBlocks] - The current list of blocks
  ///
  /// Returns the updated blocks list
  Future<List<Block>> moveBlockUp(
    Block block,
    List<Block> currentBlocks,
  ) async {
    final index = currentBlocks.indexOf(block);
    if (index <= 0) return currentBlocks;

    try {
      final newBlocks = List<Block>.from(currentBlocks);
      final temp = newBlocks[index - 1];
      newBlocks[index - 1] = newBlocks[index];
      newBlocks[index] = temp;

      final reindexedBlocks = _reindexBlocks(newBlocks);
      await repository.updateBlocks(reindexedBlocks);
      logger.i('Block moved up: ${block.id}');
      return reindexedBlocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to move block up: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Moves a block down one position in the list.
  ///
  /// If the block is already at the bottom, no action is taken.
  ///
  /// [block] - The block to move
  /// [currentBlocks] - The current list of blocks
  ///
  /// Returns the updated blocks list
  Future<List<Block>> moveBlockDown(
    Block block,
    List<Block> currentBlocks,
  ) async {
    final index = currentBlocks.indexOf(block);
    if (index < 0 || index >= currentBlocks.length - 1) return currentBlocks;

    try {
      final newBlocks = List<Block>.from(currentBlocks);
      final temp = newBlocks[index + 1];
      newBlocks[index + 1] = newBlocks[index];
      newBlocks[index] = temp;

      final reindexedBlocks = _reindexBlocks(newBlocks);
      await repository.updateBlocks(reindexedBlocks);
      logger.i('Block moved down: ${block.id}');
      return reindexedBlocks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to move block down: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Saves a custom block order.
  ///
  /// Reindexes all blocks to match their position in the provided list
  /// and persists the changes to the repository.
  ///
  /// [updatedBlocks] - The blocks in their new order
  ///
  /// Returns the reindexed blocks list
  Future<List<Block>> saveBlockOrder(List<Block> updatedBlocks) async {
    try {
      final reindexedBlocks = _reindexBlocks(updatedBlocks);
      await repository.updateBlocks(reindexedBlocks);
      logger.i('Block order saved');
      return reindexedBlocks;
    } catch (e, stackTrace) {
      logger.e('Failed to save block order', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Reindexes all blocks to ensure positions are sequential.
  ///
  /// [blocks] - The list of blocks to reindex
  ///
  /// Returns a new list with updated positions
  List<Block> _reindexBlocks(List<Block> blocks) {
    return blocks.asMap().entries.map((entry) {
      return entry.value.copyWith(position: entry.key);
    }).toList();
  }
}
