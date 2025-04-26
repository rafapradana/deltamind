import 'package:deltamind/core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for interacting with Supabase
class SupabaseService {
  /// Initialize Supabase client
  static Future<void> initialize() async {
    try {
      await dotenv.load();

      await Supabase.initialize(
        url: SupabaseConfig.urlFromEnv,
        anonKey: SupabaseConfig.anonKeyFromEnv,
        debug: kDebugMode,
      );

      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.deltamind://login-callback/',
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Create user profile after sign up
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    String? username,
  }) async {
    await client.from('profiles').insert({
      'id': userId,
      'email': email,
      'username': username ?? email.split('@').first,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return response;
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (username != null) data['username'] = username;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    await client.from('profiles').update(data).eq('id', userId);
  }

  /// Get quiz history statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get all quiz attempts for the user
      final response = await client
          .from('quiz_attempts')
          .select('created_at')
          .eq('user_id', userId);
          
      final attempts = response as List;
      final totalQuizzes = attempts.length;
      
      // Calculate today's quizzes
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final completedToday = attempts.where((attempt) {
        final createdAt = DateTime.parse(attempt['created_at']);
        return createdAt.isAfter(today);
      }).length;
      
      // Calculate this week's quizzes
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      
      final weekly = attempts.where((attempt) {
        final createdAt = DateTime.parse(attempt['created_at']);
        return createdAt.isAfter(weekStart);
      }).length;
      
      return {
        'totalQuizzes': totalQuizzes,
        'completedToday': completedToday,
        'weekly': weekly,
      };
    } catch (e) {
      debugPrint('Error getting quiz statistics: $e');
      return {
        'totalQuizzes': 0, 
        'completedToday': 0,
        'weekly': 0,
      };
    }
  }
} 