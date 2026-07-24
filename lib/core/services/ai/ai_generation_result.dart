import 'package:barruu/features/workspace/domain/entities/block.dart';

/// Result of AI content generation
class AIGenerationResult {
  final bool success;
  final String? error;
  final List<AIGeneratedPage>? pages;
  final List<Block>? blocks;
  final String? rawResponse;
  final int? tokensUsed;

  const AIGenerationResult({
    required this.success,
    this.error,
    this.pages,
    this.blocks,
    this.rawResponse,
    this.tokensUsed,
  });

  factory AIGenerationResult.failure(String error) {
    return AIGenerationResult(success: false, error: error);
  }

  factory AIGenerationResult.successWithPages(
    List<AIGeneratedPage> pages, {
    int? tokensUsed,
    String? rawResponse,
  }) {
    return AIGenerationResult(
      success: true,
      pages: pages,
      tokensUsed: tokensUsed,
      rawResponse: rawResponse,
    );
  }

  factory AIGenerationResult.successWithBlocks(
    List<Block> blocks, {
    int? tokensUsed,
    String? rawResponse,
  }) {
    return AIGenerationResult(
      success: true,
      blocks: blocks,
      tokensUsed: tokensUsed,
      rawResponse: rawResponse,
    );
  }
}

/// Represents an AI-generated page with its blocks
class AIGeneratedPage {
  final String title;
  final List<Block> blocks;

  const AIGeneratedPage({required this.title, required this.blocks});
}
