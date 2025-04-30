import 'dart:convert';
import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Model class for Quiz
class Quiz {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String quizType;
  final String difficulty;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quiz({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.quizType,
    required this.difficulty,
    this.createdAt,
    this.updatedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      quizType: json['quiz_type'],
      difficulty: json['difficulty'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'quiz_type': quizType,
      'difficulty': difficulty,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Model class for Question
class Question {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      options:
          json['options'] is List
              ? List<String>.from(json['options'])
              : List<String>.from(jsonDecode(json['options'])),
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'options': options is List ? jsonEncode(options) : options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Model class for Quiz Attempt
class QuizAttempt {
  final String id;
  final String? quizId;
  final String quizTitle;
  final int correctAnswers;
  final int totalQuestions;
  final int timeTaken;
  final DateTime? completedAt;
  final String? quizType;
  final String? difficulty;

  QuizAttempt({
    required this.id,
    this.quizId,
    required this.quizTitle,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTaken,
    this.completedAt,
    this.quizType,
    this.difficulty,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quiz_id'],
      quizTitle: json['quiz_title'] ?? 'Untitled Quiz',
      correctAnswers: json['score'] ?? json['correct_answers'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      timeTaken: json['time_taken'] ?? 0,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      quizType: json['quiz_type'],
      difficulty: json['difficulty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'quiz_title': quizTitle,
      'score': correctAnswers,
      'total_questions': totalQuestions,
      'time_taken': timeTaken,
      'completed_at': completedAt?.toIso8601String(),
      'quiz_type': quizType,
      'difficulty': difficulty,
    };
  }
}

/// Service for managing quizzes
class QuizService {
  /// Create a new quiz
  static Future<Quiz> createQuiz({
    required String title,
    String? description,
    required String quizType,
    required String difficulty,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final quizData = {
        'title': title,
        'description': description,
        'quiz_type': quizType,
        'difficulty': difficulty,
        'user_id': userId,
      };

      final response =
          await SupabaseService.client
              .from('quizzes')
              .insert(quizData)
              .select()
              .single();

      return Quiz.fromJson(response);
    } catch (e) {
      debugPrint('Error creating quiz: $e');
      rethrow;
    }
  }

  /// Get all quizzes for the current user
  static Future<List<Quiz>> getUserQuizzes() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client
          .from('quizzes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((quiz) => Quiz.fromJson(quiz)).toList();
    } catch (e) {
      debugPrint('Error getting user quizzes: $e');
      rethrow;
    }
  }

  /// Get a quiz by ID
  static Future<Quiz> getQuizById(String quizId) async {
    try {
      final response =
          await SupabaseService.client
              .from('quizzes')
              .select()
              .eq('id', quizId)
              .single();

      return Quiz.fromJson(response);
    } catch (e) {
      debugPrint('Error getting quiz by ID: $e');
      rethrow;
    }
  }

  /// Delete a quiz
  static Future<void> deleteQuiz(String quizId) async {
    try {
      // First delete all questions associated with the quiz
      await SupabaseService.client
          .from('questions')
          .delete()
          .eq('quiz_id', quizId);

      // Then delete the quiz
      await SupabaseService.client.from('quizzes').delete().eq('id', quizId);
    } catch (e) {
      debugPrint('Error deleting quiz: $e');
      rethrow;
    }
  }

  /// Get questions for a quiz
  static Future<List<Question>> getQuestionsForQuiz(String quizId) async {
    try {
      final response = await SupabaseService.client
          .from('questions')
          .select()
          .eq('quiz_id', quizId)
          .order('created_at');

      return (response as List)
          .map((question) => Question.fromJson(question))
          .toList();
    } catch (e) {
      debugPrint('Error getting questions for quiz: $e');
      rethrow;
    }
  }

  /// Add a question to a quiz
  static Future<Question> addQuestion({
    required String quizId,
    required String questionText,
    required String questionType,
    required List<String> options,
    required String correctAnswer,
    String? explanation,
  }) async {
    try {
      final questionData = {
        'quiz_id': quizId,
        'question_text': questionText,
        'question_type': questionType,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
      };

      final response =
          await SupabaseService.client
              .from('questions')
              .insert(questionData)
              .select()
              .single();

      return Question.fromJson(response);
    } catch (e) {
      debugPrint('Error adding question: $e');
      rethrow;
    }
  }

  /// Generate quiz questions using Gemini AI
  static Future<List<Map<String, dynamic>>> generateQuizQuestions({
    required String content,
    required String format,
    required String difficulty,
    int questionCount = 5,
  }) async {
    try {
      final response = await GeminiService.generateQuiz(
        content: content,
        format: format,
        difficulty: difficulty,
        questionCount: questionCount,
      );

      final jsonResponse = jsonDecode(response);
      return List<Map<String, dynamic>>.from(jsonResponse['questions']);
    } catch (e) {
      debugPrint('Error generating quiz questions: $e');
      rethrow;
    }
  }

  /// Create a quiz with generated questions
  static Future<Quiz> createQuizWithGeneratedQuestions({
    required String title,
    String? description,
    required String quizType,
    required String difficulty,
    required String content,
    int questionCount = 5,
  }) async {
    try {
      // Create the quiz first
      final quiz = await createQuiz(
        title: title,
        description: description,
        quizType: quizType,
        difficulty: difficulty,
      );

      // Preprocess content if needed (e.g., trim very large content)
      String processedContent = content;
      if (content.length > 16000) {
        debugPrint('Content is very large, truncating to 16000 characters');
        processedContent = content.substring(0, 16000);
      }

      // Generate questions using Gemini
      final response = await GeminiService.generateQuiz(
        content: processedContent,
        format: quizType,
        difficulty: difficulty,
        questionCount: questionCount,
      );

      // Parse JSON response
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response);
        if (!jsonResponse.containsKey('questions')) {
          throw Exception('Invalid response format: missing questions array');
        }
      } catch (e) {
        debugPrint('Error parsing JSON response: $e');
        throw Exception('Failed to parse AI response: $e');
      }

      final generatedQuestions = List<Map<String, dynamic>>.from(
        jsonResponse['questions'],
      );

      // Add each generated question to the quiz
      for (var questionData in generatedQuestions) {
        try {
          await addQuestion(
            quizId: quiz.id,
            questionText: questionData['question'],
            questionType: quizType,
            options: List<String>.from(questionData['options']),
            correctAnswer: questionData['answer'],
            explanation: questionData['explanation'],
          );
        } catch (e) {
          debugPrint('Error adding question: $e');
          // Continue with other questions even if one fails
        }
      }

      return quiz;
    } catch (e) {
      debugPrint('Error creating quiz with generated questions: $e');
      rethrow;
    }
  }

  /// Delete all quiz attempts for the current user
  static Future<void> deleteAllQuizAttempts() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First get all quiz attempts for this user
      final attempts = await SupabaseService.client
          .from('quiz_attempts')
          .select('id')
          .eq('user_id', userId);

      if (attempts.isEmpty) {
        return; // No attempts to delete
      }

      // Delete all quiz attempts in order to maintain referential integrity
      for (final attempt in attempts) {
        final attemptId = attempt['id'];

        // Delete related AI recommendations
        await SupabaseService.client
            .from('ai_recommendations')
            .delete()
            .eq('quiz_attempt_id', attemptId);

        // Delete related user answers
        await SupabaseService.client
            .from('user_answers')
            .delete()
            .eq('quiz_attempt_id', attemptId);
      }

      // Finally delete all attempts
      await SupabaseService.client
          .from('quiz_attempts')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting all quiz attempts: $e');
      rethrow;
    }
  }
}
