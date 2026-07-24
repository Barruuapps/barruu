/// Model for DeepSeek chat message
class DeepSeekMessage {
  final String role;
  final String content;

  const DeepSeekMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }

  factory DeepSeekMessage.fromJson(Map<String, dynamic> json) {
    return DeepSeekMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  /// Create a system message
  factory DeepSeekMessage.system(String content) {
    return DeepSeekMessage(role: 'system', content: content);
  }

  /// Create a user message
  factory DeepSeekMessage.user(String content) {
    return DeepSeekMessage(role: 'user', content: content);
  }

  /// Create an assistant message
  factory DeepSeekMessage.assistant(String content) {
    return DeepSeekMessage(role: 'assistant', content: content);
  }
}

/// Model for DeepSeek chat request
class DeepSeekChatRequest {
  final String model;
  final List<DeepSeekMessage> messages;
  final int? maxTokens;
  final double? temperature;
  final double? topP;
  final bool stream;

  const DeepSeekChatRequest({
    required this.model,
    required this.messages,
    this.maxTokens,
    this.temperature,
    this.topP,
    this.stream = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': stream,
    };

    if (maxTokens != null) json['max_tokens'] = maxTokens;
    if (temperature != null) json['temperature'] = temperature;
    if (topP != null) json['top_p'] = topP;

    return json;
  }
}

/// Model for DeepSeek usage information
class DeepSeekUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const DeepSeekUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory DeepSeekUsage.fromJson(Map<String, dynamic> json) {
    return DeepSeekUsage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
    );
  }
}

/// Model for a choice in the response
class DeepSeekChoice {
  final int index;
  final DeepSeekMessage message;
  final String? finishReason;

  const DeepSeekChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory DeepSeekChoice.fromJson(Map<String, dynamic> json) {
    return DeepSeekChoice(
      index: json['index'] as int? ?? 0,
      message: DeepSeekMessage.fromJson(
        json['message'] as Map<String, dynamic>,
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

/// Model for DeepSeek chat response
class DeepSeekChatResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<DeepSeekChoice> choices;
  final DeepSeekUsage usage;

  const DeepSeekChatResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory DeepSeekChatResponse.fromJson(Map<String, dynamic> json) {
    return DeepSeekChatResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((c) => DeepSeekChoice.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      usage: DeepSeekUsage.fromJson(
        json['usage'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Get the content of the first choice
  String get content {
    if (choices.isEmpty) return '';
    return choices.first.message.content;
  }
}

/// Error model for DeepSeek API errors
class DeepSeekError {
  final String message;
  final String? type;
  final String? code;

  const DeepSeekError({required this.message, this.type, this.code});

  factory DeepSeekError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    if (error != null) {
      return DeepSeekError(
        message: error['message'] as String? ?? 'Unknown error',
        type: error['type'] as String?,
        code: error['code'] as String?,
      );
    }
    return DeepSeekError(
      message: json['message'] as String? ?? 'Unknown error',
      type: json['type'] as String?,
      code: json['code'] as String?,
    );
  }

  @override
  String toString() => 'DeepSeekError: $message (type: $type, code: $code)';
}

/// Exception thrown when DeepSeek API request fails
class DeepSeekException implements Exception {
  final String message;
  final int? statusCode;
  final DeepSeekError? error;

  const DeepSeekException({required this.message, this.statusCode, this.error});

  @override
  String toString() => 'DeepSeekException: $message (statusCode: $statusCode)';
}
