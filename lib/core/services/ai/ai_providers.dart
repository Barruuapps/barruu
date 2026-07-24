import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/services/ai/deepseek_api_service.dart';
import 'package:barruu/core/services/ai/ai_content_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider for the DeepSeek API service
final deepSeekApiServiceProvider = Provider<DeepSeekApiService>((ref) {
  final service = DeepSeekApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the AI content generation service
final aiContentServiceProvider = Provider<AIContentService>((ref) {
  final apiService = ref.watch(deepSeekApiServiceProvider);
  final service = AIContentService(apiService: apiService);
  ref.onDispose(() => service.dispose());
  return service;
});

/// State for AI generation operations
class AIGenerationState {
  final bool isLoading;
  final String? error;
  final AIGenerationResult? result;

  const AIGenerationState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  AIGenerationState copyWith({
    bool? isLoading,
    String? error,
    AIGenerationResult? result,
  }) {
    return AIGenerationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

/// Notifier for AI generation state
class AIGenerationNotifier extends StateNotifier<AIGenerationState> {
  final AIContentService _service;

  AIGenerationNotifier(this._service) : super(const AIGenerationState());

  /// Generate content based on the request
  Future<void> generate(AIGenerationRequest request) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _service.generate(request);
      state = state.copyWith(
        isLoading: false,
        result: result,
        error: result.success ? null : result.error,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Generation failed: $e',
      );
    }
  }

  /// Generate a full document
  Future<void> generateDocument({
    required String prompt,
    String? context,
    int pageCount = 3,
  }) async {
    await generate(AIGenerationRequest(
      type: AIGenerationType.fullDocument,
      prompt: prompt,
      context: context,
      pageCount: pageCount,
    ));
  }

  /// Generate a single page
  Future<void> generatePage({
    required String prompt,
    String? context,
    List<String>? preferredBlockTypes,
  }) async {
    await generate(AIGenerationRequest(
      type: AIGenerationType.page,
      prompt: prompt,
      context: context,
      preferredBlockTypes: preferredBlockTypes,
    ));
  }

  /// Generate blocks
  Future<void> generateBlocks({
    required String prompt,
    String? context,
    List<String>? preferredBlockTypes,
  }) async {
    await generate(AIGenerationRequest(
      type: AIGenerationType.block,
      prompt: prompt,
      context: context,
      preferredBlockTypes: preferredBlockTypes,
    ));
  }

  /// Generate interactive notes
  Future<void> generateInteractiveNotes({
    required String prompt,
    String? context,
  }) async {
    await generate(AIGenerationRequest(
      type: AIGenerationType.interactiveNotes,
      prompt: prompt,
      context: context,
    ));
  }

  /// Generate content from uploaded document
  Future<void> generateFromDocument({
    required String documentContent,
    required String prompt,
    String? context,
  }) async {
    await generate(AIGenerationRequest(
      type: AIGenerationType.fromDocument,
      prompt: prompt,
      documentContent: documentContent,
      context: context,
    ));
  }

  /// Clear the current state
  void clear() {
    state = const AIGenerationState();
  }
}

/// Provider for AI generation state notifier
final aiGenerationProvider =
    StateNotifierProvider<AIGenerationNotifier, AIGenerationState>((ref) {
  final service = ref.watch(aiContentServiceProvider);
  return AIGenerationNotifier(service);
});

/// Provider for generating a summary
final aiSummaryProvider = FutureProvider.family<String, String>((ref, content) async {
  final service = ref.watch(aiContentServiceProvider);
  return service.generateSummary(content);
});
