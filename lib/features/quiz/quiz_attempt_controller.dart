import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for quiz attempts
class QuizAttemptState {
  /// List of quiz attempts
  final List<QuizAttempt> quizAttempts;

  /// Whether the quiz attempts are loading
  final bool isLoading;

  /// Error message if loading failed
  final String? errorMessage;

  /// Create quiz attempt state with the given parameters
  const QuizAttemptState({
    this.quizAttempts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Create a copy of this state with the given values
  QuizAttemptState copyWith({
    List<QuizAttempt>? quizAttempts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QuizAttemptState(
      quizAttempts: quizAttempts ?? this.quizAttempts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller for quiz attempts
class QuizAttemptController extends StateNotifier<QuizAttemptState> {
  /// Create a quiz attempt controller
  QuizAttemptController(this.ref) : super(const QuizAttemptState());

  /// Reference to the provider scope
  final Ref ref;

  /// Load quiz attempts from the database
  Future<void> loadQuizAttempts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // In a real app, this would be a call to a service to get quiz attempts
      // For now, we'll use dummy data
      await Future.delayed(const Duration(milliseconds: 500));
      final attempts = _getDummyQuizAttempts();

      state = state.copyWith(quizAttempts: attempts, isLoading: false);
    } catch (e) {
      debugPrint('Error loading quiz attempts: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load quiz attempts: $e',
      );
    }
  }

  /// Delete a quiz attempt
  Future<bool> deleteQuizAttempt(String id) async {
    try {
      // In a real app, this would be a call to a service to delete the quiz attempt
      await Future.delayed(const Duration(milliseconds: 300));

      // Remove the quiz attempt from the state
      final updatedAttempts =
          state.quizAttempts.where((attempt) => attempt.id != id).toList();

      state = state.copyWith(quizAttempts: updatedAttempts);

      return true;
    } catch (e) {
      debugPrint('Error deleting quiz attempt: $e');
      return false;
    }
  }

  /// Get dummy quiz attempts for testing
  List<QuizAttempt> _getDummyQuizAttempts() {
    return [
      QuizAttempt(
        id: '1',
        quizId: '101',
        quizTitle: 'Flutter Basics',
        correctAnswers: 8,
        totalQuestions: 10,
        timeTaken: 300,
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        quizType: 'Multiple Choice',
        difficulty: 'Easy',
      ),
      QuizAttempt(
        id: '2',
        quizId: '102',
        quizTitle: 'Dart Advanced',
        correctAnswers: 7,
        totalQuestions: 15,
        timeTaken: 500,
        completedAt: DateTime.now().subtract(const Duration(days: 5)),
        quizType: 'Multiple Choice',
        difficulty: 'Hard',
      ),
      QuizAttempt(
        id: '3',
        quizId: '103',
        quizTitle: 'State Management',
        correctAnswers: 6,
        totalQuestions: 8,
        timeTaken: 240,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        quizType: 'True/False',
        difficulty: 'Medium',
      ),
    ];
  }
}

/// Provider for quiz attempt controller
final quizAttemptControllerProvider =
    StateNotifierProvider<QuizAttemptController, QuizAttemptState>((ref) {
      return QuizAttemptController(ref);
    });
