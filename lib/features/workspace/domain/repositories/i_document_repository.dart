import 'package:barruu/features/workspace/domain/entities/block.dart';

/// Abstract interface for document repository
///
/// This interface defines the contract for document data operations,
/// allowing for multiple implementations (e.g., local database, cloud storage)
/// without affecting the business logic layer.
abstract class IDocumentRepository {
  /// Fetches all blocks from the document, ordered by position
  ///
  /// Returns a list of [Block] objects
  /// Throws an exception if the operation fails
  Future<List<Block>> getBlocks();

  /// Fetches a paginated list of blocks from the document
  ///
  /// Parameters:
  /// - [limit]: Maximum number of blocks to return
  /// - [offset]: Number of blocks to skip
  ///
  /// Returns a list of [Block] objects for the requested page
  /// Throws an exception if the operation fails
  Future<List<Block>> getBlocksPaginated({
    required int limit,
    required int offset,
  });

  /// Gets the total count of blocks in the document
  ///
  /// Returns the number of blocks
  /// Throws an exception if the operation fails
  Future<int> getBlocksCount();

  /// Adds a new block to the document
  ///
  /// Parameters:
  /// - [block]: The block to add
  ///
  /// Returns the ID of the newly created block
  /// Throws an exception if the operation fails
  Future<String> addBlock(Block block);

  /// Updates an existing block in the document
  ///
  /// Parameters:
  /// - [block]: The block with updated data
  ///
  /// Returns true if the update was successful, false otherwise
  /// Throws an exception if the operation fails
  Future<bool> updateBlock(Block block);

  /// Deletes a block from the document
  ///
  /// Parameters:
  /// - [id]: The ID of the block to delete
  ///
  /// Returns true if the deletion was successful, false otherwise
  /// Throws an exception if the operation fails
  Future<bool> deleteBlock(String id);

  /// Updates multiple blocks in a single transaction
  ///
  /// Parameters:
  /// - [blocks]: List of blocks to update
  ///
  /// Throws an exception if the operation fails
  Future<void> updateBlocks(List<Block> blocks);

  /// Fetches document tags from metadata
  ///
  /// Returns the tags string, or empty string if not found
  /// Throws an exception if the operation fails
  Future<String> getTags();
}
