import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for fetching paginated blocks from a document
/// 
/// This use case implements pagination for efficient loading of large documents.
/// It retrieves a specific page of blocks based on limit and offset parameters.
class GetBlocksPaginatedUseCase {
  final IDocumentRepository _repository;

  GetBlocksPaginatedUseCase(this._repository);

  /// Executes the use case to fetch paginated blocks
  /// 
  /// Parameters:
  /// - [limit]: Maximum number of blocks to return
  /// - [offset]: Number of blocks to skip
  /// 
  /// Returns a [Result] containing the list of blocks or an error message
  Future<Result<List<Block>>> execute({
    required int limit,
    required int offset,
  }) async {
    try {
      final blocks = await _repository.getBlocksPaginated(
        limit: limit,
        offset: offset,
      );
      return Result.success(blocks);
    } catch (e) {
      return Result.error('Failed to fetch paginated blocks: $e');
    }
  }
}
