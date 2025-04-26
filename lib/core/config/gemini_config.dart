import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class for Google Gemini API
class GeminiConfig {
  /// Gemini API Key
  static String get apiKey => const String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: 'YOUR_GEMINI_API_KEY',
      );

  /// Alternative method to get API Key from .env file
  static String get apiKeyFromEnv => dotenv.env['GEMINI_API_KEY'] ?? apiKey;

  /// The model name to use
  static const String modelName = 'gemini-2.0-flash';
} 