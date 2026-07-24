import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository.dart';
import 'package:barruu/features/workspace/domain/usecases/usecases.dart';
import 'package:barruu/features/workspace/presentation/controllers/paginated_edit_controller.dart';

/// Centralized providers for workspace use cases
/// 
/// This file provides a single source of truth for all workspace-related
/// dependency injection. Use cases are created with proper dependencies
/// and can be easily tested by mocking the repository layer.

// ============================================================================
// Repository Providers
// ============================================================================

// Note: documentRepositoryProvider is defined in workspace_repository.dart
// and is imported here. It returns IDocumentRepository interface type
// to ensure loose coupling between layers.

// ============================================================================
// Use Case Providers
// ============================================================================

/// Provider for GetBlocksUseCase
/// 
/// Used to fetch all blocks from a document. Returns blocks ordered by position.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(getBlocksUseCaseProvider(docDir));
/// final result = await useCase(GetBlocksParams(docDir: docDir));
/// result.when(
///   success: (blocks) => print('Loaded ${blocks.length} blocks'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final getBlocksUseCaseProvider =
    Provider.family<GetBlocksUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return GetBlocksUseCase(repository);
});

/// Provider for CreateBlockUseCase
/// 
/// Used to create a new block in a document. Validates block data before creation.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(createBlockUseCaseProvider(docDir));
/// final result = await useCase(CreateBlockParams(block: newBlock));
/// result.when(
///   success: (blockId) => print('Created block with ID: $blockId'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final createBlockUseCaseProvider =
    Provider.family<CreateBlockUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return CreateBlockUseCase(repository);
});

/// Provider for UpdateBlockUseCase
/// 
/// Used to update an existing block. Validates block ID before update.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(updateBlockUseCaseProvider(docDir));
/// final result = await useCase(UpdateBlockParams(block: updatedBlock));
/// result.when(
///   success: (success) => print('Update successful'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final updateBlockUseCaseProvider =
    Provider.family<UpdateBlockUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return UpdateBlockUseCase(repository);
});

/// Provider for DeleteBlockUseCase
/// 
/// Used to delete a block from a document. Validates block ID before deletion.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(deleteBlockUseCaseProvider(docDir));
/// final result = await useCase(DeleteBlockParams(blockId: '123'));
/// result.when(
///   success: (success) => print('Deletion successful'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final deleteBlockUseCaseProvider =
    Provider.family<DeleteBlockUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return DeleteBlockUseCase(repository);
});

/// Provider for UpdateBlocksUseCase
/// 
/// Used to update multiple blocks in a single transaction. Ensures atomicity.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(updateBlocksUseCaseProvider(docDir));
/// final result = await useCase(UpdateBlocksParams(blocks: updatedBlocks));
/// result.when(
///   success: (_) => print('Batch update successful'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final updateBlocksUseCaseProvider =
    Provider.family<UpdateBlocksUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return UpdateBlocksUseCase(repository);
});

/// Provider for GetDocumentTagsUseCase
/// 
/// Used to fetch document tags from metadata. Returns empty string if not found.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(getDocumentTagsUseCaseProvider(docDir));
/// final result = await useCase();
/// result.when(
///   success: (tags) => print('Tags: $tags'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final getDocumentTagsUseCaseProvider =
    Provider.family<GetDocumentTagsUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return GetDocumentTagsUseCase(repository);
});

/// Provider for GetBlocksPaginatedUseCase
/// 
/// Used to fetch a paginated subset of blocks from a document.
/// Improves performance for large documents by loading blocks incrementally.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(getBlocksPaginatedUseCaseProvider(docDir));
/// final result = await useCase.execute(limit: 20, offset: 0);
/// result.when(
///   success: (blocks) => print('Loaded ${blocks.length} blocks'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final getBlocksPaginatedUseCaseProvider =
    Provider.family<GetBlocksPaginatedUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return GetBlocksPaginatedUseCase(repository);
});

/// Provider for GetBlocksCountUseCase
/// 
/// Used to fetch the total count of blocks in a document.
/// Useful for implementing pagination UI and progress indicators.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(getBlocksCountUseCaseProvider(docDir));
/// final result = await useCase.execute();
/// result.when(
///   success: (count) => print('Total blocks: $count'),
///   error: (message) => print('Error: $message'),
/// );
/// ```
final getBlocksCountUseCaseProvider =
    Provider.family<GetBlocksCountUseCase, Directory>((ref, docDir) {
  final repository = ref.watch(documentRepositoryProvider(docDir));
  return GetBlocksCountUseCase(repository);
});

// ============================================================================
// Paginated Edit Controller Provider
// ============================================================================

/// Provider for PaginatedEditController
/// 
/// Manages paginated loading of blocks for better performance with large documents.
/// Uses the pagination infrastructure from Phase 4 Week 13.
/// 
/// Example:
/// ```dart
/// final controller = ref.watch(paginatedEditControllerProvider(docDir));
/// 
/// // Access blocks
/// final blocks = controller.blocks;
/// 
/// // Load more when scrolling
/// ScrollController().addListener(() {
///   if (_scrollController.position.pixels >= 
///       _scrollController.position.maxScrollExtent - 200) {
///     ref.read(paginatedEditControllerProvider(docDir).notifier).loadNextPage();
///   }
/// });
/// ```
final paginatedEditControllerProvider = StateNotifierProvider.family<
    PaginatedEditController, PaginatedBlocksState, Directory>(
  (ref, docDir) {
    final getPaginatedUseCase = ref.watch(getBlocksPaginatedUseCaseProvider(docDir));
    final getCountUseCase = ref.watch(getBlocksCountUseCaseProvider(docDir));
    
    return PaginatedEditController(
      docDir: docDir,
      getPaginatedUseCase: getPaginatedUseCase,
      getCountUseCase: getCountUseCase,
    );
  },
);
