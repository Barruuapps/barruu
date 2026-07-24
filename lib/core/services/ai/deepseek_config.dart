import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for DeepSeek AI API integration.
///
/// Contains all necessary configuration for connecting to the DeepSeek API.
/// API keys and URLs are read from the .env file using flutter_dotenv.
/// 
/// Make sure to call `await dotenv.load()` in main() before using this config.
class DeepSeekConfig {
  // Private constructor to prevent instantiation
  DeepSeekConfig._();

  /// DeepSeek API key - reads from .env file
  static String get apiKey {
    return dotenv.env['DEEP_SEEK_API_KEY'] ?? '';
  }

  /// DeepSeek API base URL - reads from .env file or uses default
  static String get apiUrl {
    return dotenv.env['DEEPSEEK_API_URL'] ?? 'https://api.deepseek.com';
  }

  /// DeepSeek Chat API endpoint
  static const String chatEndpoint = '/chat/completions';

  /// Default model to use for chat completions
  static const String defaultModel = 'deepseek-chat';

  /// API timeout duration - increased to handle longer content generation (up to 300+ blocks)
  static const Duration apiTimeout = Duration(seconds: 300);

  /// Maximum tokens for response - increased to handle large documents with many blocks
  static const int maxTokens = 8192;

  /// Temperature for response generation (0.0 - 1.0)
  /// Lower values = more deterministic, higher values = more creative
  static const double temperature = 0.7;

  /// Top P for nucleus sampling
  static const double topP = 0.95;

  /// Get the full chat endpoint URL
  static String get fullChatUrl => '$apiUrl$chatEndpoint';

  /// Check if API key is configured
  static bool get isConfigured => apiKey.isNotEmpty;
}

