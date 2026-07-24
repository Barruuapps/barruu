import 'package:barruu/features/workspace/domain/entities/block.dart';

/// Request types for AI content generation
enum AIGenerationType {
  /// Generate a complete document with multiple pages
  fullDocument,
  /// Generate a single page with blocks
  page,
  /// Generate a single block
  block,
  /// Edit existing blocks
  editBlocks,
  /// Generate content from uploaded document
  fromDocument,
  /// Generate interactive quiz/notes
  interactiveNotes,
}

/// Request for AI content generation
class AIGenerationRequest {
  final AIGenerationType type;
  final String prompt;
  final String? context;
  final List<Block>? existingBlocks;
  final String? documentContent;
  final int? pageCount;
  final List<String>? preferredBlockTypes;

  const AIGenerationRequest({
    required this.type,
    required this.prompt,
    this.context,
    this.existingBlocks,
    this.documentContent,
    this.pageCount,
    this.preferredBlockTypes,
  });
}
