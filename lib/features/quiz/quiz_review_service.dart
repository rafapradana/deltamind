import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';

/// Service for reviewing quiz answers using Gemini AI
class QuizReviewService {
  /// Generate feedback for a completed quiz
  static Future<String> reviewQuizAnswers({
    required String quizId,
    required List<String> userAnswers,
  }) async {
    try {
      // Get the questions for the quiz
      final questions = await QuizService.getQuestionsForQuiz(quizId);
      
      if (questions.isEmpty) {
        return 'No questions found for this quiz.';
      }
      
      if (questions.length != userAnswers.length) {
        return 'Error: Number of questions (${questions.length}) and answers (${userAnswers.length}) do not match.';
      }
      
      // Get quiz details
      final quiz = await QuizService.getQuizById(quizId);
      
      // Calculate score
      final score = calculatePercentageScore(
        questions: questions,
        userAnswers: userAnswers,
      );
      
      // Identify incorrect answers
      final List<int> incorrectQuestionIndices = [];
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].correctAnswer != userAnswers[i]) {
          incorrectQuestionIndices.add(i);
        }
      }
      
      // Convert questions to the format expected by GeminiService
      final questionData = questions.map((q) => {
        'question': q.questionText,
        'options': q.options,
        'answer': q.correctAnswer,
        'explanation': q.explanation,
      }).toList();
      
      // Prepare a more detailed prompt for Gemini
      String prompt = '''
I'm reviewing a quiz on "${quiz.title}" (Type: ${quiz.quizType}, Difficulty: ${quiz.difficulty}).
Score: ${score.round()}% (${calculateScore(questions: questions, userAnswers: userAnswers)} out of ${questions.length} correct)

Please analyze the following answers and provide:
1. A brief overall assessment of performance
2. Specific feedback on incorrect answers
3. Key concepts that need reinforcement
4. Learning recommendations and study tips
5. Suggestions for improvement

If the score is good (>80%), include encouragement and suggest areas to explore further.
''';

      // Call Gemini service with enhanced prompt
      final feedback = await GeminiService.reviewQuizAnswers(
        questions: questionData, 
        userAnswers: userAnswers,
      );
      
      // Format the feedback with markdown
      return feedback;
    } catch (e) {
      debugPrint('Error reviewing quiz answers: $e');
      return '''
## Review Unavailable

Sorry, an error occurred while generating your personalized review.

### General Feedback

- Review your answers carefully, especially for questions you got wrong
- Check explanations for each question to understand the correct answers
- Consider revisiting the study material to reinforce key concepts

*Error details: $e*
''';
    }
  }
  
  /// Calculate score for a completed quiz
  static int calculateScore({
    required List<Question> questions,
    required List<String> userAnswers,
  }) {
    if (questions.length != userAnswers.length) {
      return 0;
    }
    
    int correctAnswers = 0;
    
    for (int i = 0; i < questions.length; i++) {
      if (questions[i].correctAnswer == userAnswers[i]) {
        correctAnswers++;
      }
    }
    
    return correctAnswers;
  }
  
  /// Calculate percentage score
  static double calculatePercentageScore({
    required List<Question> questions,
    required List<String> userAnswers,
  }) {
    if (questions.isEmpty) {
      return 0.0;
    }
    
    final score = calculateScore(questions: questions, userAnswers: userAnswers);
    return (score / questions.length) * 100;
  }
} 