import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/usecases/base_use_case.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for deleting a block from a document
/// 
/// This use case handles block deletion logic, including validation
/// and error handling.
class DeleteBlockUseCase extends UseCase<bool, DeleteBlockParams> {
  final IDocumentRepository _repository;

  DeleteBlockUseCase(this._repository);

  @override
  Future<Result<bool>> call(DeleteBlockParams params) async {
    try {
      // Validate block ID
      if (params.blockId.isEmpty) {
        return Result.error('Cannot delete block: Invalid block ID');
      }

      // Delete the block
      final success = await _repository.deleteBlock(params.blockId);
      
      if (!success) {
        return Result.error('Failed to delete block: Block not found');
      }

      return Result.success(true);
    } catch (e) {
      return Result.error('Failed to delete block: ${e.toString()}');
    }
  }
}

/// Parameters for DeleteBlockUseCase
class DeleteBlockParams {
  final String blockId;

  DeleteBlockParams({required this.blockId});
}
