import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/quiz/quiz_controller.dart';
import 'package:deltamind/features/quiz/quiz_review_service.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Page for reviewing a completed quiz with AI feedback
class QuizReviewPage extends ConsumerStatefulWidget {
  /// The ID of the quiz to review
  final String quizId;
  
  /// The user's answers to the quiz
  final List<String> userAnswers;

  /// Default constructor
  const QuizReviewPage({
    required this.quizId,
    required this.userAnswers,
    super.key,
  });

  @override
  ConsumerState<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends ConsumerState<QuizReviewPage> {
  bool _isLoading = true;
  String _feedback = '';
  double _score = 0.0;
  List<Question> _questions = [];
  String _quizTitle = '';
  List<bool> _expandedQuestions = [];
  
  @override
  void initState() {
    super.initState();
    _loadReview();
  }
  
  Future<void> _loadReview() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load quiz details
      final quiz = await QuizService.getQuizById(widget.quizId);
      _quizTitle = quiz.title;
      
      // Load questions
      _questions = await QuizService.getQuestionsForQuiz(widget.quizId);
      _expandedQuestions = List.generate(_questions.length, (_) => false);
      
      // Calculate score
      _score = QuizReviewService.calculatePercentageScore(
        questions: _questions,
        userAnswers: widget.userAnswers,
      );
      
      // Get AI feedback
      _feedback = await QuizReviewService.reviewQuizAnswers(
        quizId: widget.quizId,
        userAnswers: widget.userAnswers,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading review: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${_quizTitle.length > 20 ? '${_quizTitle.substring(0, 20)}...' : _quizTitle}'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowCounterClockwise()),
            onPressed: _isLoading ? null : _loadReview,
            tooltip: 'Refresh feedback',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating personalized review...',
                    style: AppTheme.subtitle,
                  ),
                ],
              ),
            )
          : _buildReviewContent(),
    );
  }
  
  Widget _buildReviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Summary',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getScoreColor(_score).withOpacity(0.15),
                          border: Border.all(
                            color: _getScoreColor(_score),
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${_score.round()}%',
                            style: AppTheme.headingMedium.copyWith(
                              color: _getScoreColor(_score),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getScoreMessage(_score),
                              style: AppTheme.subtitle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_score),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You got ${(_score * _questions.length / 100).round()} out of ${_questions.length} questions correct',
                              style: AppTheme.bodyText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Questions review section
          Text(
            'Question Review',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),
          
          ..._buildQuestionReviews(),
          
          const SizedBox(height: 32),
          
          // AI feedback section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                      topRight: Radius.circular(AppTheme.borderRadiusMedium),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.robot(),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI Feedback & Study Tips',
                        style: AppTheme.subtitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: _feedback,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTheme.bodyText,
                      h1: AppTheme.headingMedium,
                      h2: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      listBullet: AppTheme.bodyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // AI Learning Recommendations
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade700,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                      topRight: Radius.circular(AppTheme.borderRadiusMedium),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.lightbulb(),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Personalized Learning Path',
                        style: AppTheme.subtitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want a personalized learning plan based on your quiz results?',
                        style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI can analyze your strengths and weaknesses to generate a tailored learning path with recommended resources and practice exercises.',
                        style: AppTheme.bodyText,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement AI recommendation generation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Generating your personalized learning plan...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          // In a real implementation, this would call a service to generate recommendations
                        },
                        icon: Icon(PhosphorIcons.sparkle()),
                        label: const Text('Generate Learning Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Back to quiz button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(PhosphorIcons.arrowLeft()),
              label: const Text('Back to Results'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildQuestionReviews() {
    final List<Widget> questionWidgets = [];
    
    for (int i = 0; i < _questions.length; i++) {
      if (i >= widget.userAnswers.length) continue;
      
      final question = _questions[i];
      final userAnswer = widget.userAnswers[i];
      final isCorrect = question.correctAnswer == userAnswer;
      
      questionWidgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            side: BorderSide(
              color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
              width: 1,
            ),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                    topRight: Radius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isCorrect ? 'Correct' : 'Incorrect',
                        style: AppTheme.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _expandedQuestions[i]
                            ? PhosphorIcons.caretUp()
                            : PhosphorIcons.caretDown(),
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedQuestions[i] = !_expandedQuestions[i];
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Question details (expandable)
              if (_expandedQuestions[i])
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question:',
                        style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.questionText,
                        style: AppTheme.bodyText,
                      ),
                      const SizedBox(height: 16),
                      
                      // Options
                      Text(
                        'Options:',
                        style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...question.options.map((option) {
                        final isUserAnswer = option == userAnswer;
                        final isCorrectAnswer = option == question.correctAnswer;
                        
                        Color textColor = Colors.black;
                        Color bgColor = Colors.transparent;
                        
                        if (isUserAnswer && isCorrectAnswer) {
                          textColor = Colors.green.shade700;
                          bgColor = Colors.green.shade50;
                        } else if (isUserAnswer && !isCorrectAnswer) {
                          textColor = Colors.red.shade700;
                          bgColor = Colors.red.shade50;
                        } else if (isCorrectAnswer) {
                          textColor = Colors.green.shade700;
                          bgColor = Colors.green.shade50;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: bgColor != Colors.transparent
                                  ? bgColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isUserAnswer)
                                Icon(
                                  isCorrectAnswer
                                      ? PhosphorIcons.checkCircle()
                                      : PhosphorIcons.xCircle(),
                                  color: isCorrectAnswer
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  size: 18,
                                )
                              else if (isCorrectAnswer)
                                Icon(
                                  PhosphorIcons.checkCircle(),
                                  color: Colors.green.shade700,
                                  size: 18,
                                )
                              else
                                Icon(
                                  PhosphorIcons.circle(),
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: isCorrectAnswer || isUserAnswer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // Explanation
                      if (question.explanation != null &&
                          question.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Explanation:',
                          style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIcons.info(),
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.explanation!,
                                  style: AppTheme.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              
              // Quick summary (when collapsed)
              if (!_expandedQuestions[i])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          question.questionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isCorrect ? 'Correct' : 'Incorrect',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return questionWidgets;
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  String _getScoreMessage(double score) {
    if (score >= 80) {
      return 'Excellent!';
    } else if (score >= 60) {
      return 'Good effort!';
    } else {
      return 'Keep practicing!';
    }
  }
} 