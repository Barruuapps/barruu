import 'package:barruu/core/utils/result.dart';
import 'package:barruu/features/workspace/domain/usecases/base_use_case.dart';
import 'package:barruu/features/workspace/domain/repositories/i_document_repository.dart';

/// Use case for fetching document tags from metadata
///
/// This use case handles retrieval of document tags with proper
/// error handling for missing or invalid metadata.
class GetDocumentTagsUseCase extends NoParamsUseCase<String> {
  final IDocumentRepository _repository;

  GetDocumentTagsUseCase(this._repository);

  @override
  Future<Result<String>> call() async {
    try {
      final tags = await _repository.getTags();
      return Result.success(tags);
    } catch (e) {
      return Result.error('Failed to load document tags: ${e.toString()}');
    }
  }
}
