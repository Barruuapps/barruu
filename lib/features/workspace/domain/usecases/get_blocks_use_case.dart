import 'dart:io';
import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/usecases/base_use_case.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for fetching all blocks from a document
///
/// This use case encapsulates the business logic for retrieving blocks,
/// including error handling and data transformation.
class GetBlocksUseCase extends UseCase<List<Block>, GetBlocksParams> {
  final IDocumentRepository _repository;

  GetBlocksUseCase(this._repository);

  @override
  Future<Result<List<Block>>> call(GetBlocksParams params) async {
    try {
      final blocks = await _repository.getBlocks();
      return Result.success(blocks);
    } catch (e) {
      return Result.error('Failed to load blocks: ${e.toString()}');
    }
  }
}

/// Parameters for GetBlocksUseCase
class GetBlocksParams {
  final Directory docDir;

  GetBlocksParams({required this.docDir});
}
