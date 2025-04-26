import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class for Supabase
class SupabaseConfig {
  /// Supabase URL
  static String get url => const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'YOUR_SUPABASE_URL',
      );

  /// Supabase Anonymous Key
  static String get anonKey => const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'YOUR_SUPABASE_ANON_KEY',
      );

  /// Alternative method to get URL from .env file
  static String get urlFromEnv => dotenv.env['SUPABASE_URL'] ?? url;

  /// Alternative method to get Anon Key from .env file
  static String get anonKeyFromEnv => dotenv.env['SUPABASE_ANON_KEY'] ?? anonKey;
} 