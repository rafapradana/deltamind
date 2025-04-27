import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/history/quiz_review_detail_page.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// State for quiz attempt
class QuizAttemptState {
  final String quizId;
  final List<Question> questions;
  final int currentQuestionIndex;
  final Map<String, String> userAnswers;
  final Map<String, bool> isCorrect;
  final Map<String, int> timeTaken;
  final DateTime startTime;
  final bool isCompleted;
  final int score;

  QuizAttemptState({
    required this.quizId,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.isCorrect = const {},
    this.timeTaken = const {},
    required this.startTime,
    this.isCompleted = false,
    this.score = 0,
  });

  QuizAttemptState copyWith({
    String? quizId,
    List<Question>? questions,
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    Map<String, bool>? isCorrect,
    Map<String, int>? timeTaken,
    DateTime? startTime,
    bool? isCompleted,
    int? score,
  }) {
    return QuizAttemptState(
      quizId: quizId ?? this.quizId,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isCorrect: isCorrect ?? this.isCorrect,
      timeTaken: timeTaken ?? this.timeTaken,
      startTime: startTime ?? this.startTime,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
    );
  }

  /// Get current question
  Question get currentQuestion => questions[currentQuestionIndex];

  /// Check if current question has been answered
  bool isCurrentQuestionAnswered() {
    return userAnswers.containsKey(currentQuestion.id);
  }

  /// Calculate progress
  double get progress {
    return (currentQuestionIndex + 1) / questions.length;
  }

  /// Get total questions
  int get totalQuestions => questions.length;

  /// Get number of correct answers
  int get correctAnswers => isCorrect.values.where((value) => value).length;

  /// Calculate accuracy
  double get accuracy {
    if (userAnswers.isEmpty) return 0;
    return correctAnswers / userAnswers.length;
  }

  /// Calculate total time taken in seconds
  int get totalTimeTaken {
    return timeTaken.values.fold(0, (sum, time) => sum + time);
  }
}

/// Provider for quiz attempt
final quizAttemptProvider = StateNotifierProvider.family<QuizAttemptNotifier, QuizAttemptState, QuizAttemptParams>(
  (ref, params) => QuizAttemptNotifier(params.quizId, params.questions),
);

/// Parameters for quiz attempt
class QuizAttemptParams {
  final String quizId;
  final List<Question> questions;

  QuizAttemptParams({required this.quizId, required this.questions});
}

/// Notifier for quiz attempt
class QuizAttemptNotifier extends StateNotifier<QuizAttemptState> {
  QuizAttemptNotifier(String quizId, List<Question> questions)
      : super(QuizAttemptState(
          quizId: quizId,
          questions: questions,
          startTime: DateTime.now(),
        ));
        
  /// Safe state update method to prevent errors during widget building
  void _safeUpdateState(QuizAttemptState newState) {
    if (mounted) {
      try {
        state = newState;
      } catch (e) {
        debugPrint('Error updating quiz attempt state: $e');
      }
    }
  }

  /// Answer current question
  void answerQuestion(String answer) {
    if (!mounted) return;
    
    try {
    final currentQuestion = state.currentQuestion;
    final questionId = currentQuestion.id;
    final isCorrect = answer == currentQuestion.correctAnswer;
    final timeTaken = DateTime.now().difference(state.startTime).inSeconds;

    // Update user answers, correctness, and time taken
    final updatedUserAnswers = Map<String, String>.from(state.userAnswers);
    updatedUserAnswers[questionId] = answer;

    final updatedIsCorrect = Map<String, bool>.from(state.isCorrect);
    updatedIsCorrect[questionId] = isCorrect;

    final updatedTimeTaken = Map<String, int>.from(state.timeTaken);
    updatedTimeTaken[questionId] = timeTaken;

    // Calculate new score
    final newScore = updatedIsCorrect.values.where((value) => value).length;

      _safeUpdateState(state.copyWith(
      userAnswers: updatedUserAnswers,
      isCorrect: updatedIsCorrect,
      timeTaken: updatedTimeTaken,
      score: newScore,
      ));
    } catch (e) {
      debugPrint('Error answering question: $e');
    }
  }

  /// Move to next question
  void nextQuestion() {
    if (!mounted) return;
    
    try {
    if (state.currentQuestionIndex < state.questions.length - 1) {
        _safeUpdateState(state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        ));
    } else {
      completeQuiz();
      }
    } catch (e) {
      debugPrint('Error moving to next question: $e');
    }
  }

  /// Move to previous question
  void previousQuestion() {
    if (!mounted) return;
    
    try {
    if (state.currentQuestionIndex > 0) {
        _safeUpdateState(state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
        ));
      }
    } catch (e) {
      debugPrint('Error moving to previous question: $e');
    }
  }

  /// Complete the quiz
  void completeQuiz() {
    if (!mounted) return;
    
    try {
      _safeUpdateState(state.copyWith(isCompleted: true));
      // Quiz attempt will be saved when navigating to review page
    } catch (e) {
      debugPrint('Error completing quiz: $e');
    }
  }

  /// Save quiz attempt to database
  Future<String?> saveQuizAttempt() async {
    if (!mounted) return null;
    
    // Save quiz attempt
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // 1. Create quiz attempt record
      final quizAttemptData = {
        'user_id': userId,
        'quiz_id': state.quizId,
        'score': state.score,
        'total_questions': state.questions.length,
        'time_taken': state.totalTimeTaken,
        'completed': true,
      };
      
      final response = await SupabaseService.client
          .from('quiz_attempts')
          .insert(quizAttemptData)
          .select()
          .single();
      
      final quizAttemptId = response['id'];
      
      // 2. Save individual user answers
      for (final questionId in state.userAnswers.keys) {
        if (!mounted) return null;
        
        final answer = state.userAnswers[questionId]!;
        final isCorrect = state.isCorrect[questionId] ?? false;
        final timeTaken = state.timeTaken[questionId] ?? 0;
        
        await SupabaseService.client
            .from('user_answers')
            .insert({
              'quiz_attempt_id': quizAttemptId,
              'question_id': questionId,
              'user_answer': answer,
              'is_correct': isCorrect,
              'time_taken': timeTaken,
            });
      }
      
      debugPrint('Quiz attempt saved successfully');
      
      // Return the quiz attempt ID for navigation
      return quizAttemptId;
    } catch (e) {
      debugPrint('Error saving quiz attempt: $e');
      return null;
    }
  }
}

/// Page for taking a quiz
class TakeQuizPage extends ConsumerStatefulWidget {
  final String quizId;
  final String quizTitle;
  final List<Question> questions;

  const TakeQuizPage({
    Key? key,
    required this.quizId,
    required this.quizTitle,
    required this.questions,
  }) : super(key: key);
  
  /// Create a TakeQuizPage from a quiz ID
  static Widget fromId(String quizId) {
    return FutureBuilder<Quiz>(
      future: QuizService.getQuizById(quizId),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (quizSnapshot.hasError || !quizSnapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text('Error loading quiz: ${quizSnapshot.error}'),
            ),
          );
        }
        
        final quiz = quizSnapshot.data!;
        
        return FutureBuilder<List<Question>>(
          future: QuizService.getQuestionsForQuiz(quizId),
          builder: (context, questionsSnapshot) {
            if (questionsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (questionsSnapshot.hasError || !questionsSnapshot.hasData) {
              return Scaffold(
                body: Center(
                  child: Text('Error loading questions: ${questionsSnapshot.error}'),
                ),
              );
            }
            
            final questions = questionsSnapshot.data!;
            
            if (questions.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(quiz.title)),
                body: const Center(
                  child: Text('This quiz has no questions yet.'),
                ),
              );
            }
            
            return TakeQuizPage(
              quizId: quizId,
              quizTitle: quiz.title,
              questions: questions,
            );
          },
        );
      },
    );
  }

  @override
  ConsumerState<TakeQuizPage> createState() => _TakeQuizPageState();
}

class _TakeQuizPageState extends ConsumerState<TakeQuizPage> {
  late final QuizAttemptParams _params;

  @override
  void initState() {
    super.initState();
    _params = QuizAttemptParams(
      quizId: widget.quizId,
      questions: widget.questions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizAttempt = ref.watch(quizAttemptProvider(_params));
    final quizAttemptNotifier = ref.read(quizAttemptProvider(_params).notifier);

    // If quiz is completed, show results
    if (quizAttempt.isCompleted) {
      return _buildQuizCompletedScreen(quizAttempt);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        actions: [
          TextButton(
            onPressed: () => quizAttemptNotifier.completeQuiz(),
            child: const Text('Finish'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: quizAttempt.progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${quizAttempt.currentQuestionIndex + 1}/${quizAttempt.totalQuestions}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Score: ${quizAttempt.score}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          
          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quizAttempt.currentQuestion.questionText,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  ..._buildOptions(
                    quizAttempt.currentQuestion,
                    quizAttempt,
                    quizAttemptNotifier,
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (quizAttempt.currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () => quizAttemptNotifier.previousQuestion(),
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox(width: 100),
                  
                ElevatedButton(
                  onPressed: quizAttempt.isCurrentQuestionAnswered()
                      ? () => quizAttemptNotifier.nextQuestion()
                      : null,
                  child: Text(
                    quizAttempt.currentQuestionIndex == quizAttempt.totalQuestions - 1
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build options for the current question
  List<Widget> _buildOptions(
    Question question,
    QuizAttemptState quizAttempt,
    QuizAttemptNotifier notifier,
  ) {
    final options = question.options;
    final userAnswer = quizAttempt.userAnswers[question.id];
    final isAnswered = userAnswer != null;

    return options.map((option) {
      final isSelected = userAnswer == option;
      final isCorrect = question.correctAnswer == option;

      // Determine the card color based on selection and correctness
      Color cardColor = Colors.white;
      if (isAnswered) {
        if (isSelected && isCorrect) {
          cardColor = Colors.green[100]!;
        } else if (isSelected && !isCorrect) {
          cardColor = Colors.red[100]!;
        } else if (isCorrect) {
          cardColor = Colors.green[50]!;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: isAnswered ? null : () => notifier.answerQuestion(option),
          borderRadius: BorderRadius.circular(8),
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Build the quiz completed screen
  Widget _buildQuizCompletedScreen(QuizAttemptState quizAttempt) {
    // Save quiz attempt and navigate to review page
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quizAttemptId = await ref.read(quizAttemptProvider(_params).notifier).saveQuizAttempt();
      
      if (quizAttemptId != null && mounted) {
        // Navigate to quiz review detail page using GoRouter
        context.go('/quiz-review/${quizAttemptId}');
      }
    });
    
    // Show loading screen while saving attempt
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizing Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Saving your quiz results...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  /// Format time in seconds to mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 