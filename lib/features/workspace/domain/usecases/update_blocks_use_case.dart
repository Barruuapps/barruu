import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/usecases/base_use_case.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for updating multiple blocks in a single transaction
/// 
/// This use case handles batch block updates, including validation
/// and atomic transaction handling.
class UpdateBlocksUseCase extends UseCase<void, UpdateBlocksParams> {
  final IDocumentRepository _repository;

  UpdateBlocksUseCase(this._repository);

  @override
  Future<Result<void>> call(UpdateBlocksParams params) async {
    try {
      // Validate all blocks have IDs
      final invalidBlocks = params.blocks.where(
        (block) => block.id == null || block.id!.isEmpty
      ).toList();
      
      if (invalidBlocks.isNotEmpty) {
        return Result.error(
          'Cannot update blocks: ${invalidBlocks.length} block(s) have invalid IDs'
        );
      }

      if (params.blocks.isEmpty) {
        return Result.error('Cannot update blocks: No blocks provided');
      }

      // Update all blocks in a transaction
      await _repository.updateBlocks(params.blocks);

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to update blocks: ${e.toString()}');
    }
  }
}

/// Parameters for UpdateBlocksUseCase
class UpdateBlocksParams {
  final List<Block> blocks;

  UpdateBlocksParams({required this.blocks});
}
