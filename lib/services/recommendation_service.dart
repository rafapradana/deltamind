import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Service for AI recommendations
class RecommendationService {
  /// Get an AI recommendation for a quiz attempt
  /// If a recommendation already exists, return it
  /// Otherwise, generate a new one
  static Future<Map<String, dynamic>?> getQuizRecommendation(String quizAttemptId) async {
    try {
      // Check if a recommendation already exists
      final existingRecommendation = await SupabaseService.client
          .from('ai_recommendations')
          .select()
          .eq('quiz_attempt_id', quizAttemptId)
          .maybeSingle();
      
      if (existingRecommendation != null) {
        return existingRecommendation;
      }
      
      // No existing recommendation, so generate a new one
      return await generateAndSaveQuizRecommendation(quizAttemptId);
    } catch (e) {
      debugPrint('Error getting quiz recommendation: $e');
      return null;
    }
  }
  
  /// Generate and save a new AI recommendation for a quiz attempt
  static Future<Map<String, dynamic>?> generateAndSaveQuizRecommendation(String quizAttemptId) async {
    try {
      // Get quiz attempt with quiz details
      final quizAttempt = await SupabaseService.client
          .from('quiz_attempts')
          .select('''
            id,
            score,
            total_questions,
            time_taken,
            created_at,
            quizzes (
              id,
              title,
              description,
              quiz_type,
              difficulty
            )
          ''')
          .eq('id', quizAttemptId)
          .single();
      
      // Get user answers with question details
      final userAnswers = await SupabaseService.client
          .from('user_answers')
          .select('''
            id,
            user_answer,
            is_correct,
            time_taken,
            questions (
              id,
              question_text,
              question_type,
              options,
              correct_answer,
              explanation
            )
          ''')
          .eq('quiz_attempt_id', quizAttemptId)
          .order('created_at');
      
      // Call Gemini to generate recommendations
      final recommendations = await GeminiService.generateQuizRecommendations(
        quizData: quizAttempt,
        userAnswers: List<Map<String, dynamic>>.from(userAnswers),
      );
      
      // Save the recommendations to the database
      final recommendationData = {
        'quiz_attempt_id': quizAttemptId,
        'performance_overview': recommendations['overall_assessment'] ?? recommendations['performance_overview'],
        'strengths': recommendations['strong_areas'] ?? recommendations['strengths'],
        'areas_for_improvement': recommendations['weak_areas'] ?? recommendations['areas_for_improvement'],
        'learning_strategies': recommendations['learning_recommendations'] ?? recommendations['learning_strategies'],
        'action_plan': recommendations['next_steps'] ?? recommendations['action_plan'],
        // Keep the old field names too for backward compatibility
        'overall_assessment': recommendations['overall_assessment'] ?? recommendations['performance_overview'],
        'weak_areas': recommendations['weak_areas'] ?? recommendations['areas_for_improvement'],
        'strong_areas': recommendations['strong_areas'] ?? recommendations['strengths'],
        'learning_recommendations': recommendations['learning_recommendations'] ?? recommendations['learning_strategies'],
        'next_steps': recommendations['next_steps'] ?? recommendations['action_plan'],
      };
      
      final response = await SupabaseService.client
          .from('ai_recommendations')
          .insert(recommendationData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error generating quiz recommendation: $e');
      return null;
    }
  }
  
  /// Delete a recommendation by quiz attempt ID
  static Future<void> deleteRecommendation(String quizAttemptId) async {
    try {
      await SupabaseService.client
          .from('ai_recommendations')
          .delete()
          .eq('quiz_attempt_id', quizAttemptId);
    } catch (e) {
      debugPrint('Error deleting recommendation: $e');
      rethrow;
    }
  }
} 