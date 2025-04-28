import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:deltamind/services/gemini_service.dart';

/// Quiz state class
class QuizState {
  final List<Quiz> userQuizzes;
  final Quiz? currentQuiz;
  final List<Question> currentQuestions;
  final bool isLoading;
  final String? error;
  final bool isGenerating;
  final List<String> userAnswers;
  final bool isReviewMode;

  const QuizState({
    this.userQuizzes = const [],
    this.currentQuiz,
    this.currentQuestions = const [],
    this.isLoading = false,
    this.error,
    this.isGenerating = false,
    this.userAnswers = const [],
    this.isReviewMode = false,
  });

  QuizState copyWith({
    List<Quiz>? userQuizzes,
    Quiz? currentQuiz,
    List<Question>? currentQuestions,
    bool? isLoading,
    String? error,
    bool? isGenerating,
    List<String>? userAnswers,
    bool? isReviewMode,
  }) {
    return QuizState(
      userQuizzes: userQuizzes ?? this.userQuizzes,
      currentQuiz: currentQuiz ?? this.currentQuiz,
      currentQuestions: currentQuestions ?? this.currentQuestions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isGenerating: isGenerating ?? this.isGenerating,
      userAnswers: userAnswers ?? this.userAnswers,
      isReviewMode: isReviewMode ?? this.isReviewMode,
    );
  }
}

/// Provider for quiz controller
final quizControllerProvider = StateNotifierProvider<QuizController, QuizState>(
  (ref) {
    return QuizController();
  },
);

/// Controller for managing quizzes
class QuizController extends StateNotifier<QuizState> {
  QuizController() : super(const QuizState());

  /// Safe state update method to prevent errors during widget building
  void _safeUpdateState(QuizState newState) {
    if (mounted) {
      try {
        state = newState;
      } catch (e) {
        debugPrint('Error updating quiz state: $e');
      }
    }
  }

  /// Load user quizzes
  Future<void> loadUserQuizzes() async {
    if (!mounted) return;

    try {
      _safeUpdateState(state.copyWith(isLoading: true, error: null));
      final quizzes = await QuizService.getUserQuizzes();
      _safeUpdateState(state.copyWith(userQuizzes: quizzes, isLoading: false));
    } catch (e) {
      debugPrint('Error loading user quizzes: $e');

      if (mounted) {
        _safeUpdateState(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  /// Load a quiz by ID
  Future<void> loadQuiz(String quizId) async {
    if (!mounted) return;

    try {
      _safeUpdateState(state.copyWith(isLoading: true, error: null));
      final quiz = await QuizService.getQuizById(quizId);
      final questions = await QuizService.getQuestionsForQuiz(quizId);

      if (mounted) {
        _safeUpdateState(
          state.copyWith(
            currentQuiz: quiz,
            currentQuestions: questions,
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading quiz: $e');

      if (mounted) {
        _safeUpdateState(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  /// Create a new quiz
  Future<Quiz?> createQuiz({
    required String title,
    String? description,
    required String quizType,
    required String difficulty,
  }) async {
    if (!mounted) return null;

    try {
      _safeUpdateState(state.copyWith(isLoading: true, error: null));
      final quiz = await QuizService.createQuiz(
        title: title,
        description: description,
        quizType: quizType,
        difficulty: difficulty,
      );

      // Reload user quizzes to update the list
      if (mounted) {
        await loadUserQuizzes();
      }

      return quiz;
    } catch (e) {
      debugPrint('Error creating quiz: $e');

      if (mounted) {
        _safeUpdateState(state.copyWith(isLoading: false, error: e.toString()));
      }
      return null;
    }
  }

  /// Delete a quiz
  Future<bool> deleteQuiz(String quizId) async {
    if (!mounted) return false;

    try {
      _safeUpdateState(state.copyWith(isLoading: true, error: null));
      await QuizService.deleteQuiz(quizId);

      // Reload user quizzes to update the list
      if (mounted) {
        await loadUserQuizzes();
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting quiz: $e');

      if (mounted) {
        _safeUpdateState(state.copyWith(isLoading: false, error: e.toString()));
      }
      return false;
    }
  }

  /// Generate a quiz with Gemini
  Future<Quiz?> generateQuiz({
    required String title,
    String? description,
    required String quizType,
    required String difficulty,
    required String content,
    int questionCount = 5,
  }) async {
    if (!mounted) return null;

    try {
      _safeUpdateState(state.copyWith(isGenerating: true, error: null));
      final quiz = await QuizService.createQuizWithGeneratedQuestions(
        title: title,
        description: description,
        quizType: quizType,
        difficulty: difficulty,
        content: content,
        questionCount: questionCount,
      );

      // Reload user quizzes to update the list
      if (mounted) {
        await loadUserQuizzes();
        _safeUpdateState(state.copyWith(isGenerating: false));
      }

      return quiz;
    } catch (e) {
      debugPrint('Error generating quiz: $e');

      if (mounted) {
        _safeUpdateState(
          state.copyWith(isGenerating: false, error: e.toString()),
        );
      }
      return null;
    }
  }

  /// Add a question to current quiz
  Future<bool> addQuestion({
    required String questionText,
    required String questionType,
    required List<String> options,
    required String correctAnswer,
    String? explanation,
  }) async {
    if (!mounted) return false;

    try {
      if (state.currentQuiz == null) {
        throw Exception('No quiz selected');
      }

      _safeUpdateState(state.copyWith(isLoading: true, error: null));

      await QuizService.addQuestion(
        quizId: state.currentQuiz!.id,
        questionText: questionText,
        questionType: questionType,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
      );

      // Reload questions
      if (mounted) {
        final questions = await QuizService.getQuestionsForQuiz(
          state.currentQuiz!.id,
        );
        _safeUpdateState(
          state.copyWith(currentQuestions: questions, isLoading: false),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error adding question: $e');

      if (mounted) {
        _safeUpdateState(state.copyWith(isLoading: false, error: e.toString()));
      }
      return false;
    }
  }

  /// Save a user's answer to a question
  void saveAnswer(int questionIndex, String answer) {
    if (!mounted) return;

    final List<String> updatedAnswers = List.from(state.userAnswers);

    // Ensure the list is large enough to accommodate the answer
    while (updatedAnswers.length <= questionIndex) {
      updatedAnswers.add('');
    }

    // Set the answer at the specified index
    updatedAnswers[questionIndex] = answer;

    _safeUpdateState(state.copyWith(userAnswers: updatedAnswers));
  }

  /// Switch to review mode for the current quiz
  void enterReviewMode() {
    if (!mounted) return;

    _safeUpdateState(state.copyWith(isReviewMode: true));
  }

  /// Exit review mode
  void exitReviewMode() {
    if (!mounted) return;

    _safeUpdateState(state.copyWith(isReviewMode: false));
  }

  /// Reset user answers for the current quiz
  void resetAnswers() {
    if (!mounted) return;

    _safeUpdateState(state.copyWith(userAnswers: [], isReviewMode: false));
  }

  /// Generate a quiz from a file
  Future<Quiz?> generateQuizFromFile({
    required String title,
    String? description,
    required String quizType,
    required String difficulty,
    required Uint8List fileBytes,
    required String fileName,
    int questionCount = 5,
  }) async {
    if (!mounted) return null;

    try {
      _safeUpdateState(state.copyWith(isGenerating: true, error: null));

      // Get file extension
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Use GeminiService to generate questions from the file
      final jsonResponse = await GeminiService.generateQuizFromFile(
        fileBytes: fileBytes,
        fileName: fileName,
        fileType: fileExtension,
        format: quizType,
        difficulty: difficulty,
        questionCount: questionCount,
      );

      // Create the quiz
      final quiz = await QuizService.createQuiz(
        title: title,
        description: description ?? "Generated from file: $fileName",
        quizType: quizType,
        difficulty: difficulty,
      );

      // Parse questions from the response
      final Map<String, dynamic> questionsData = jsonDecode(jsonResponse);
      if (!questionsData.containsKey('questions')) {
        throw Exception('Invalid response format: missing questions array');
      }

      final List<dynamic> questions = questionsData['questions'];

      // Add questions to the quiz
      for (var question in questions) {
        await QuizService.addQuestion(
          quizId: quiz.id,
          questionText: question['question'],
          questionType: quizType,
          options: List<String>.from(question['options']),
          correctAnswer: question['answer'],
          explanation: question['explanation'],
        );
      }

      // Reload user quizzes to update the list
      if (mounted) {
        await loadUserQuizzes();
        _safeUpdateState(state.copyWith(isGenerating: false));
      }

      return quiz;
    } catch (e) {
      debugPrint('Error generating quiz from file: $e');

      if (mounted) {
        _safeUpdateState(
          state.copyWith(isGenerating: false, error: e.toString()),
        );
      }
      return null;
    }
  }
}
