import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/usecases/base_use_case.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for updating an existing block
///
/// This use case handles block update logic, including validation
/// and error handling.
class UpdateBlockUseCase extends UseCase<bool, UpdateBlockParams> {
  final IDocumentRepository _repository;

  UpdateBlockUseCase(this._repository);

  @override
  Future<Result<bool>> call(UpdateBlockParams params) async {
    try {
      // Validate block has an ID
      if (params.block.id == null || params.block.id!.isEmpty) {
        return Result.error('Cannot update block: Invalid block ID');
      }

      // Update the block
      final success = await _repository.updateBlock(params.block);

      if (!success) {
        return Result.error('Failed to update block: Block not found');
      }

      return Result.success(true);
    } catch (e) {
      return Result.error('Failed to update block: ${e.toString()}');
    }
  }
}

/// Parameters for UpdateBlockUseCase
class UpdateBlockParams {
  final Block block;

  UpdateBlockParams({required this.block});
}
