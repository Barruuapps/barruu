import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/services/ai/deepseek_config.dart';
import 'package:barruu/core/services/ai/deepseek_models.dart';
import 'package:flutter/foundation.dart';

/// Service for communicating with DeepSeek AI API.
/// 
/// This service handles all HTTP communication with the DeepSeek API,
/// including authentication, request formatting, and response parsing.
class DeepSeekApiService {
  final http.Client _client;
  final String _apiKey;
  final String _baseUrl;

  DeepSeekApiService({
    http.Client? client,
    String? apiKey,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? DeepSeekConfig.apiKey,
        _baseUrl = baseUrl ?? DeepSeekConfig.apiUrl;

  /// Sends a chat completion request to the DeepSeek API.
  /// 
  /// [messages] - List of messages in the conversation
  /// [model] - The model to use (defaults to deepseek-chat)
  /// [maxTokens] - Maximum tokens in the response
  /// [temperature] - Response creativity (0.0 - 1.0)
  /// 
  /// Returns a [DeepSeekChatResponse] on success.
  /// Throws [DeepSeekException] on failure.
  Future<DeepSeekChatResponse> chatCompletion({
    required List<DeepSeekMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async {
    // Validate API key is configured
    if (_apiKey.isEmpty) {
      throw const DeepSeekException(
        message: 'DeepSeek API key is not configured. Add DEEP_SEEK_API_KEY to your .env file.',
      );
    }

    try {
      final request = DeepSeekChatRequest(
        model: model ?? DeepSeekConfig.defaultModel,
        messages: messages,
        maxTokens: maxTokens ?? DeepSeekConfig.maxTokens,
        temperature: temperature ?? DeepSeekConfig.temperature,
        topP: topP ?? DeepSeekConfig.topP,
      );

      logger.i('Sending DeepSeek API request with ${messages.length} messages');

      final response = await _client
          .post(
            Uri.parse(DeepSeekConfig.fullChatUrl),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(DeepSeekConfig.apiTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      logger.e('DeepSeek API request timed out after ${DeepSeekConfig.apiTimeout.inSeconds} seconds');
      throw const DeepSeekException(
        message: 'Request timed out. The AI is taking too long to respond. Please try again with a simpler prompt or check your internet connection.',
      );
    } on DeepSeekException {
      rethrow;
    } catch (e, stackTrace) {
      logger.e('DeepSeek API request failed', error: e, stackTrace: stackTrace);
      
      // Provide more helpful error messages
      String errorMessage;
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'Network error: Unable to connect to DeepSeek API. Please check your internet connection.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'SSL/TLS error: Unable to establish secure connection. Please check your network settings.';
      } else {
        errorMessage = 'Failed to communicate with DeepSeek API: $e';
      }
      
      throw DeepSeekException(message: errorMessage);
    }
  }

  /// Sends a simple prompt and returns the text response.
  /// 
  /// This is a convenience method for simple single-turn conversations.
  /// [prompt] - The user prompt
  /// [systemPrompt] - Optional system prompt for context
  /// 
  /// Returns the text content of the response.
  Future<String> simplePrompt({
    required String prompt,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) async {
    final messages = <DeepSeekMessage>[
      if (systemPrompt != null) DeepSeekMessage.system(systemPrompt),
      DeepSeekMessage.user(prompt),
    ];

    final response = await chatCompletion(
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
    );

    return response.content;
  }

  /// Get standard headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'Accept': 'application/json',
    };
  }

  /// Handle the HTTP response and parse it
  DeepSeekChatResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    logger.d('DeepSeek API response status: $statusCode');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final chatResponse = DeepSeekChatResponse.fromJson(json);
        logger.i('DeepSeek API response received: ${chatResponse.usage.totalTokens} tokens used');
        return chatResponse;
      } catch (e, stackTrace) {
        logger.e('Failed to parse DeepSeek response', error: e, stackTrace: stackTrace);
        throw DeepSeekException(
          message: 'Failed to parse API response: $e',
          statusCode: statusCode,
        );
      }
    } else {
      DeepSeekError? error;
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        error = DeepSeekError.fromJson(json);
      } catch (_) {
        // Ignore parsing errors for error response
      }

      logger.e('DeepSeek API error: $statusCode - ${error?.message ?? body}');
      
      // Provide user-friendly error messages based on status code
      String errorMessage;
      if (statusCode == 401) {
        errorMessage = 'Invalid API key. Please check your DEEP_SEEK_API_KEY in the .env file.';
      } else if (statusCode == 429) {
        errorMessage = 'Rate limit exceeded. Please wait a moment and try again.';
      } else if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
        errorMessage = 'DeepSeek server error. The service may be temporarily unavailable. Please try again later.';
      } else {
        errorMessage = error?.message ?? 'API request failed with status $statusCode';
      }

      throw DeepSeekException(
        message: errorMessage,
        statusCode: statusCode,
        error: error,
      );
    }
  }

  /// Streams a chat completion from the DeepSeek API using Server-Sent Events.
  ///
  /// [messages] - List of messages in the conversation
  /// [model] - The model to use (defaults to deepseek-chat)
  /// [maxTokens] - Maximum tokens in the response
  /// [temperature] - Response creativity (0.0 - 1.0)
  ///
  /// Yields text deltas as they arrive from the API.
  /// Throws [DeepSeekException] on failure.
  Stream<String> streamCompletion({
    required List<DeepSeekMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async* {
    if (_apiKey.isEmpty) {
      throw const DeepSeekException(
        message: 'DeepSeek API key is not configured. Add DEEP_SEEK_API_KEY to your .env file.',
      );
    }

    final request = http.Request('POST', Uri.parse(DeepSeekConfig.fullChatUrl));
    request.headers.addAll(_getHeaders());
    request.body = jsonEncode({
      'model': model ?? DeepSeekConfig.defaultModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': true,
      'max_tokens': maxTokens ?? 512,
      if (temperature != null) 'temperature': temperature,
    });

    try {
      logger.i('Sending DeepSeek streaming request with ${messages.length} messages');
      final streamedResponse = await _client.send(request).timeout(DeepSeekConfig.apiTimeout);

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final body = await streamedResponse.stream.bytesToString();
        logger.e('DeepSeek streaming API error: ${streamedResponse.statusCode} - $body');
        throw DeepSeekException(
          message: 'Streaming request failed with status ${streamedResponse.statusCode}',
          statusCode: streamedResponse.statusCode,
        );
      }

      String buffer = '';
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        // SSE events are separated by '\n\n'; process complete events only
        final events = buffer.split('\n\n');
        buffer = events.removeLast(); // keep incomplete last segment
        for (final event in events) {
          for (final line in event.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices == null || choices.isEmpty) continue;
              final delta = (choices.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) yield content;
            } catch (_) {
              // Skip malformed SSE lines
            }
          }
        }
      }
      // Process any remaining buffer content
      for (final line in buffer.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]' || data.isEmpty) continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta = (choices.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) yield content;
        } catch (_) {
          // Skip malformed lines
        }
      }
    } on DeepSeekException {
      rethrow;
    } catch (e, stackTrace) {
      logger.e('DeepSeek streaming request failed', error: e, stackTrace: stackTrace);
      throw DeepSeekException(message: 'Streaming failed: $e');
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}
