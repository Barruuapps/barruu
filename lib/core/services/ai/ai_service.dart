/// DeepSeek AI integration for Barruu - Professional Knowledge Sharing Platform.
/// 
/// This library provides AI-powered content generation capabilities for professionals
/// and organizations across all fields including:
/// - Professional document generation (multi-page)
/// - Page generation with various block types appropriate to content domain
/// - Block generation and editing
/// - Content generation from uploaded documents
/// - Professional study notes generation
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:barruu/core/services/ai/ai_service.dart';
/// 
/// // Use the provider
/// final aiService = ref.watch(aiContentServiceProvider);
/// 
/// // Generate content
/// final result = await aiService.generate(AIGenerationRequest(
///   type: AIGenerationType.page,
///   prompt: 'Create professional content about photosynthesis',
/// ));
/// ```
library;

export 'deepseek_config.dart';
export 'deepseek_models.dart';
export 'deepseek_api_service.dart';
export 'ai_content_service.dart';
export 'ai_providers.dart';
export 'block_schema_documentation.dart';
