import 'dart:convert';

import 'package:barruu/core/services/ai/deepseek_api_service.dart';
import 'package:barruu/core/services/ai/deepseek_models.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/services/ai/ai_providers.dart';

/// The action the learner wants the AI to perform on a block.
enum AiAction {
  /// Plain-language explanation of the block content.
  explain,

  /// Deeper, more technical explanation.
  goDeeper,

  /// A worked example derived from the block content.
  giveExample,
}

extension AiActionLabel on AiAction {
  String get label {
    switch (this) {
      case AiAction.explain:
        return '💡 Explain this';
      case AiAction.goDeeper:
        return '🔍 Go deeper';
      case AiAction.giveExample:
        return '📝 Give me an example';
    }
  }

  String get promptVerb {
    switch (this) {
      case AiAction.explain:
        return 'Explain the following in clear, plain language suitable for a student. '
            'Be concise (3–5 sentences).';
      case AiAction.goDeeper:
        return 'Provide a deeper technical explanation of the following. '
            'Include underlying principles, nuances, or edge-cases.';
      case AiAction.giveExample:
        return 'Give a clear, worked example that illustrates the following. '
            'Walk through the example step-by-step.';
    }
  }
}

/// Service that queries the DeepSeek AI with a type-aware prompt built from a
/// [Block] and returns a streaming response.
class BlockAiService {
  final DeepSeekApiService _api;

  const BlockAiService(this._api);

  /// Streams an AI response for [block] based on [action].
  Stream<String> query(Block block, AiAction action) {
    final blockSummary = _summariseBlock(block);
    final prompt = '${action.promptVerb}\n\n$blockSummary';

    return _api.streamCompletion(
      messages: [
        DeepSeekMessage.system(
          'You are a helpful educational AI assistant embedded in Barruu, '
          'a learning platform. Your answers are short, clear and educational. '
          'Use Markdown for structure when helpful.',
        ),
        DeepSeekMessage.user(prompt),
      ],
      maxTokens: 512,
      temperature: 0.7,
    );
  }

  /// Builds a human-readable text summary of a block's content for the AI
  /// prompt, using the block type to extract the most relevant information.
  String _summariseBlock(Block block) {
    switch (block.type) {
      case BlockType.paragraph:
      case BlockType.header:
      case BlockType.blockquote:
        return block.content;

      case BlockType.code:
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final language = json['language'] as String? ?? 'code';
          final code = json['code'] as String? ?? block.content;
          return 'Code block ($language):\n```$language\n$code\n```';
        } catch (_) {
          return 'Code:\n${block.content}';
        }

      case BlockType.math:
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final latex = json['latex'] as String? ?? block.content;
          return 'Math expression: $latex';
        } catch (_) {
          return 'Math: ${block.content}';
        }

      case BlockType.list:
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final items = (json['items'] as List<dynamic>?)
                  ?.map((e) => '- $e')
                  .join('\n') ??
              block.content;
          return 'List:\n$items';
        } catch (_) {
          return block.content;
        }

      case BlockType.table:
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final headers = (json['headers'] as List<dynamic>?)?.join(' | ') ?? '';
          final rows = (json['rows'] as List<dynamic>?)
                  ?.map((r) => (r as List<dynamic>).join(' | '))
                  .join('\n') ??
              '';
          return 'Table:\n$headers\n$rows';
        } catch (_) {
          return block.content;
        }

      case BlockType.multipleChoice:
      case BlockType.trueFalse:
      case BlockType.fillInBlank:
      case BlockType.matching:
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final question = json['question'] as String? ?? block.content;
          return 'Question: $question';
        } catch (_) {
          return block.content;
        }

      case BlockType.expandable:
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final title = json['title'] as String? ?? '';
          final body = json['body'] as String? ?? block.content;
          return title.isNotEmpty ? '$title\n$body' : body;
        } catch (_) {
          return block.content;
        }

      default:
        // Fall back to raw content for unsupported types
        return block.content.isNotEmpty ? block.content : '(${block.type.name} block)';
    }
  }
}

/// Riverpod provider for [BlockAiService].
final blockAiServiceProvider = Provider<BlockAiService>((ref) {
  final api = ref.watch(deepSeekApiServiceProvider);
  return BlockAiService(api);
});
