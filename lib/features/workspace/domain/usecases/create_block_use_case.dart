import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/domain/usecases/base_use_case.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for creating a new block in a document
///
/// This use case handles block creation logic, including validation,
/// error handling, and returning the created block's ID.
class CreateBlockUseCase extends UseCase<String, CreateBlockParams> {
  final IDocumentRepository _repository;

  CreateBlockUseCase(this._repository);

  @override
  Future<Result<String>> call(CreateBlockParams params) async {
    try {
      // Validate block data
      if (params.block.content.isEmpty &&
          params.block.type != BlockType.divider) {
        return Result.error('Block content cannot be empty');
      }

      // Create the block
      final blockId = await _repository.addBlock(params.block);

      if (blockId.isEmpty) {
        return Result.error('Failed to create block: Invalid ID returned');
      }

      return Result.success(blockId);
    } catch (e) {
      return Result.error('Failed to create block: ${e.toString()}');
    }
  }
}

/// Parameters for CreateBlockUseCase
class CreateBlockParams {
  final Block block;

  CreateBlockParams({required this.block});
}
