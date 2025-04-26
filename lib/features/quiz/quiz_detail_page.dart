import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/quiz/quiz_controller.dart';
import 'package:deltamind/features/quiz/quiz_review_page.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Page for displaying and taking a quiz
class QuizDetailPage extends ConsumerStatefulWidget {
  /// Quiz ID to display
  final String quizId;

  /// Default constructor
  const QuizDetailPage({
    required this.quizId,
    super.key,
  });

  @override
  ConsumerState<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends ConsumerState<QuizDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    await ref.read(quizControllerProvider.notifier).loadQuiz(widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(state.currentQuiz?.title ?? 'Quiz'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowCounterClockwise()),
            tooltip: 'Reset Quiz',
            onPressed: () {
              ref.read(quizControllerProvider.notifier).resetAnswers();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Text(
                    'Error: ${state.error}',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                )
              : _buildQuizContent(context, state),
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizState state) {
    if (state.currentQuiz == null) {
      return const Center(
        child: Text('Quiz not found'),
      );
    }

    if (state.currentQuestions.isEmpty) {
      return const Center(
        child: Text('No questions found for this quiz'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz info
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentQuiz!.title,
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 8),
                  if (state.currentQuiz!.description != null) ...[
                    Text(
                      state.currentQuiz!.description!,
                      style: AppTheme.bodyText.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(state.currentQuiz!.difficulty),
                        backgroundColor: _getDifficultyColor(state.currentQuiz!.difficulty),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      Chip(
                        label: Text(state.currentQuiz!.quizType),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.7),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      Chip(
                        label: Text('${state.currentQuestions.length} Questions'),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Questions
          ...state.currentQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(context, state, index, question);
          }),
          
          const SizedBox(height: 24),
          
          // Add this section for the Review Quiz button
          if (state.currentQuestions.isNotEmpty && 
              state.userAnswers.length >= state.currentQuestions.length) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizReviewPage(
                        quizId: state.currentQuiz!.id,
                        userAnswers: state.userAnswers,
                      ),
                    ),
                  );
                },
                icon: Icon(PhosphorIcons.chartBar()),
                label: const Text('Review Quiz Results'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (state.currentQuestions.isNotEmpty) ...[
            // Show submit button if all questions not yet answered
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: state.userAnswers.length < state.currentQuestions.length
                    ? null  // Disable if not all questions answered
                    : () {
                        // Submit answers
                        ref.read(quizControllerProvider.notifier).enterReviewMode();
                        
                        // Show a snackbar to prompt the user to review
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Answers submitted. Click "Review Quiz Results" to see feedback.'),
                            action: SnackBarAction(
                              label: 'Review',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => QuizReviewPage(
                                      quizId: state.currentQuiz!.id,
                                      userAnswers: state.userAnswers,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                icon: Icon(PhosphorIcons.checkCircle()),
                label: const Text('Submit Answers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
            if (state.userAnswers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${state.userAnswers.length} of ${state.currentQuestions.length} questions answered',
                style: AppTheme.smallText.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildQuestionCard(BuildContext context, QuizState state, int index, Question question) {
    final isAnswered = state.userAnswers.length > index && state.userAnswers[index].isNotEmpty;
    final userAnswer = isAnswered ? state.userAnswers[index] : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: AppTheme.subtitle.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.questionText,
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...question.options.map((option) {
              final isSelected = userAnswer == option;
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: userAnswer,
                onChanged: state.isReviewMode 
                    ? null 
                    : (value) {
                        if (value != null) {
                          ref.read(quizControllerProvider.notifier).saveAnswer(index, value);
                        }
                      },
                activeColor: AppTheme.primaryColor,
                selected: isSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  side: isSelected 
                      ? BorderSide(color: AppTheme.primaryColor, width: 1) 
                      : BorderSide.none,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
} 