import 'package:deltamind/core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Service for interacting with Supabase
class SupabaseService {
  /// Initialize Supabase client
  static Future<void> initialize() async {
    try {
      // Make sure dotenv is loaded
      if (dotenv.env.isEmpty) {
        debugPrint(
            'Warning: .env file seems empty, attempting to load it again');
        await dotenv.load();
      }

      // Get Supabase credentials from .env
      final url = SupabaseConfig.urlFromEnv;
      final anonKey = SupabaseConfig.anonKeyFromEnv;

      // Validate credentials before initialization
      if (url.isEmpty ||
          url.contains('YOUR_SUPABASE_URL') ||
          anonKey.isEmpty ||
          anonKey.contains('YOUR_SUPABASE_ANON_KEY')) {
        throw Exception('Invalid Supabase credentials. Check your .env file.');
      }

      // Initialize Supabase with credentials
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );

      // Verify client is accessible
      Supabase.instance.client;

      debugPrint('Supabase initialized successfully with URL: $url');
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
    return await client.auth.signUp(email: email, password: password);
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
    final response =
        await client.from('profiles').select().eq('id', userId).single();

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

  /// Upload profile picture and update profile
  static Future<String?> uploadProfilePicture({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
    String fileType = 'image/jpeg',
  }) async {
    try {
      // Get file extension
      final fileExt = fileName.split('.').last.toLowerCase();

      // Generate a unique file name to prevent conflicts
      final uniqueFileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload file to Supabase Storage
      final uploadPath = await client.storage.from('avatars').uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(contentType: fileType),
          );

      // Create a public URL for the image
      final avatarUrl =
          client.storage.from('avatars').getPublicUrl(uniqueFileName);

      // Update the user's profile with the new avatar URL
      await updateUserProfile(userId: userId, avatarUrl: avatarUrl);

      return avatarUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Delete old profile picture if it exists
  static Future<void> deleteOldProfilePicture(String? oldAvatarUrl) async {
    if (oldAvatarUrl == null || oldAvatarUrl.isEmpty) return;

    try {
      // Extract the file path from the URL
      final storageUrl = client.storage.url;
      final bucketName = 'avatars';

      if (oldAvatarUrl.startsWith(storageUrl)) {
        // Extract the file name from the URL
        final filePath = oldAvatarUrl.split('$bucketName/').last;

        // Delete the file from storage
        await client.storage.from(bucketName).remove([filePath]);
      }
    } catch (e) {
      debugPrint('Error deleting old profile picture: $e');
    }
  }

  /// Get quiz history statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use the SQL function we created to get accurate stats
      final response = await client.rpc(
        'get_user_statistics',
        params: {'user_uuid': userId},
      );

      if (response == null || response.isEmpty) {
        return {
          'total_quizzes': 0,
          'completed_quizzes': 0,
          'average_score': 0.0,
        };
      }

      // The response contains the columns with our new names
      final stats = response[0];

      // Calculate today's quizzes (still need to get this separately)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final attemptsToday = await client
          .from('quiz_attempts')
          .select('created_at')
          .eq('user_id', userId)
          .gte('created_at', today.toIso8601String());

      final completedToday = (attemptsToday as List).length;

      // Get weekly count
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weeklyAttempts = await client
          .from('quiz_attempts')
          .select('created_at')
          .eq('user_id', userId)
          .gte('created_at', weekStart.toIso8601String());

      final weekly = (weeklyAttempts as List).length;

      return {
        'total_quizzes': stats['quiz_count'] ?? 0,
        'completed_quizzes': stats['completed_count'] ?? 0,
        'average_score': stats['avg_score'] ?? 0.0,
        'completed_today': completedToday,
        'weekly': weekly,
      };
    } catch (e) {
      debugPrint('Error getting quiz statistics: $e');
      return {
        'total_quizzes': 0,
        'completed_quizzes': 0,
        'average_score': 0.0,
        'completed_today': 0,
        'weekly': 0,
      };
    }
  }

  /// Delete a quiz attempt completely
  static Future<bool> deleteQuizAttempt(String quizAttemptId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Deleting quiz attempt $quizAttemptId for user $userId');

      // First try using the stored procedure we created
      try {
        debugPrint('Attempting deletion via stored procedure');
        final result = await client.rpc(
          'delete_quiz_attempt',
          params: {'attempt_id': quizAttemptId},
        );

        // Check if the deletion was successful
        if (result == true) {
          debugPrint('Deletion via stored procedure successful');
          return true;
        } else {
          debugPrint(
            'Stored procedure returned false, trying fallback methods',
          );
        }
      } catch (procError) {
        debugPrint('Error using stored procedure: $procError');
        // Continue with fallback methods
      }

      // Verify that this user owns the attempt
      final attemptResponse = await client
          .from('quiz_attempts')
          .select('user_id')
          .eq('id', quizAttemptId)
          .maybeSingle();

      if (attemptResponse == null) {
        debugPrint('Quiz attempt not found');
        return false;
      }

      final attemptUserId = attemptResponse['user_id'];
      if (attemptUserId != userId) {
        debugPrint(
          'User $userId does not own quiz attempt $quizAttemptId (owned by $attemptUserId)',
        );
        return false;
      }

      // Delete in this specific order to handle any potential foreign key issues

      // 1. First delete AI recommendations
      await client
          .from('ai_recommendations')
          .delete()
          .eq('quiz_attempt_id', quizAttemptId);

      // 2. Then delete user answers
      await client
          .from('user_answers')
          .delete()
          .eq('quiz_attempt_id', quizAttemptId);

      // 3. Finally delete the quiz attempt itself
      final deleteResponse =
          await client.from('quiz_attempts').delete().eq('id', quizAttemptId);

      // Verify deletion was successful
      final verifyResponse =
          await client.from('quiz_attempts').select().eq('id', quizAttemptId);

      final isDeleted = verifyResponse.isEmpty;
      debugPrint(
        'Quiz attempt deletion verification: ${isDeleted ? 'SUCCESS' : 'FAILED'}',
      );

      // If normal deletion failed, try direct SQL as a last resort
      if (!isDeleted) {
        return await _forceDeletionWithSQL(quizAttemptId, userId);
      }

      return isDeleted;
    } catch (e) {
      debugPrint('Error deleting quiz attempt: $e');

      // Try direct SQL as a fallback
      try {
        final userId = currentUser?.id;
        if (userId != null) {
          return await _forceDeletionWithSQL(quizAttemptId, userId);
        }
      } catch (sqlError) {
        debugPrint('SQL fallback deletion also failed: $sqlError');
      }

      return false;
    }
  }

  /// Force deletion using direct SQL as a last resort
  /// Only use this when normal deletion fails
  static Future<bool> _forceDeletionWithSQL(
    String quizAttemptId,
    String userId,
  ) async {
    try {
      debugPrint('Attempting forced deletion as fallback for $quizAttemptId');

      // First check if the user actually owns this quiz attempt as a safety measure
      final ownershipCheck = await client
          .from('quiz_attempts')
          .select('id')
          .eq('id', quizAttemptId)
          .eq('user_id', userId)
          .maybeSingle();

      if (ownershipCheck == null) {
        debugPrint('Ownership verification failed for fallback deletion');
        return false;
      }

      // Try a method that bypasses some restrictions
      try {
        // 1. Try deleting related records first
        debugPrint('Fallback: Deleting AI recommendations');
        await client.rpc(
          'delete_quiz_recommendations',
          params: {'attempt_id': quizAttemptId},
        );
      } catch (e) {
        debugPrint('RPC failed, falling back to direct deletion: $e');

        // Direct API call first for recommendations
        try {
          await client
              .from('ai_recommendations')
              .delete()
              .eq('quiz_attempt_id', quizAttemptId);
          debugPrint('Direct deletion of recommendations succeeded');
        } catch (recError) {
          debugPrint('Direct deletion of recommendations failed: $recError');
        }

        // Then user answers
        try {
          await client
              .from('user_answers')
              .delete()
              .eq('quiz_attempt_id', quizAttemptId);
          debugPrint('Direct deletion of user answers succeeded');
        } catch (ansError) {
          debugPrint('Direct deletion of user answers failed: $ansError');
        }
      }

      // Finally delete the quiz attempt
      try {
        await client
            .from('quiz_attempts')
            .delete()
            .eq('id', quizAttemptId)
            .eq('user_id', userId);
        debugPrint('Final deletion of quiz attempt succeeded');
      } catch (attemptError) {
        debugPrint('Final deletion of quiz attempt failed: $attemptError');
        return false;
      }

      // Verify deletion succeeded
      final verifyDeletion =
          await client.from('quiz_attempts').select().eq('id', quizAttemptId);

      final success = verifyDeletion.isEmpty;
      debugPrint('Forced deletion ${success ? 'SUCCEEDED' : 'FAILED'}');
      return success;
    } catch (e) {
      debugPrint('Error in forced deletion: $e');
      return false;
    }
  }

  /// Check if a quiz attempt exists by ID
  static Future<bool> checkQuizAttemptExists(String attemptId) async {
    try {
      final response = await client
          .from('quiz_attempts')
          .select('id')
          .eq('id', attemptId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking quiz attempt: $e');
      return false;
    }
  }

  /// Generate a UUID
  static String generateUuid() {
    const uuid = Uuid();
    return uuid.v4();
  }
}
