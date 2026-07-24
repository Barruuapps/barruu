import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for fetching the total count of blocks in a document
///
/// This use case provides the total number of blocks, useful for
/// implementing pagination UI (e.g., page indicators, total pages).
class GetBlocksCountUseCase {
  final IDocumentRepository _repository;

  GetBlocksCountUseCase(this._repository);

  /// Executes the use case to get the total block count
  ///
  /// Returns a [Result] containing the block count or an error message
  Future<Result<int>> execute() async {
    try {
      final count = await _repository.getBlocksCount();
      return Result.success(count);
    } catch (e) {
      return Result.error('Failed to get block count: $e');
    }
  }
}
