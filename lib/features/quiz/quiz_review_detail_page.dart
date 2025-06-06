import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/services/recommendation_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

/// Quiz Review Detail Page shows complete results of a taken quiz
class QuizReviewDetailPage extends ConsumerStatefulWidget {
  /// ID of the quiz attempt to review
  final String attemptId;

  const QuizReviewDetailPage({required this.attemptId, Key? key})
      : super(key: key);

  @override
  ConsumerState<QuizReviewDetailPage> createState() =>
      _QuizReviewDetailPageState();
}

class _QuizReviewDetailPageState extends ConsumerState<QuizReviewDetailPage> {
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  String? _errorMessage;
  Map<String, dynamic>? _quizAttempt;
  Map<String, dynamic>? _aiRecommendation;
  List<Map<String, dynamic>> _userAnswers = [];
  List<bool> _expandedQuestions = [];
  bool _showRecommendations = true;
  bool _animateRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadQuizAttempt();

    // Don't automatically show recommendations
    _showRecommendations = true;

    // Add a delay to ensure the widget is built before starting the animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showRecommendations = true;
        });
      }
    });

    // Don't auto-generate fallback - we will prompt the user instead
  }

  Future<void> _loadQuizAttempt() async {
    final quizAttemptId = widget.attemptId;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = SupabaseService.client;

      // Load quiz attempt details
      final quizAttemptResponse =
          await supabase.from('quiz_attempts').select('''
            id, quiz_id, user_id, score, total_questions, created_at,
            quizzes:quiz_id (id, title, quiz_type, difficulty)
          ''').eq('id', quizAttemptId).single();

      if (quizAttemptResponse != null) {
        // Load user answers for this attempt
        final userAnswersResponse =
            await supabase.from('user_answers').select('''
              id, question_id, user_answer, is_correct,
              questions:question_id (id, quiz_id, question_text, options, correct_answer, explanation)
            ''').eq('quiz_attempt_id', quizAttemptId).order('created_at');

        if (mounted) {
          setState(() {
            _quizAttempt = quizAttemptResponse;
            _userAnswers = userAnswersResponse;
            _expandedQuestions = List.generate(
              userAnswersResponse.length,
              (_) => false,
            );
            _isLoading = false;
          });

          // Load AI recommendations after quiz data is loaded
          _loadRecommendations();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        print('Error loading quiz attempt: $e');
      }
    }
  }

  // Load recommendations with error handling and loading state
  void _loadRecommendations() async {
    if (_quizAttempt == null) {
      setState(() {
        _isLoadingRecommendations = false;
      });
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      // Use the quiz attempt ID, not the quiz ID
      final quizAttemptId = _quizAttempt!['id'];
      final recommendationData =
          await RecommendationService.getQuizRecommendation(quizAttemptId);

      if (mounted) {
        setState(() {
          _aiRecommendation = recommendationData;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
          _aiRecommendation = null;
        });
        print('Error loading recommendation: $e');

        // Don't auto-generate recommendation - we will prompt the user instead
      }
    }
  }

  // Generate an initial recommendation if one doesn't already exist
  void _generateInitialRecommendation() async {
    if (_quizAttempt == null || _isLoadingRecommendations) {
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      // Use the quiz attempt ID, not the quiz ID
      final quizAttemptId = _quizAttempt!['id'];

      // Generate new recommendation
      final newRecommendation =
          await RecommendationService.generateAndSaveQuizRecommendation(
        quizAttemptId,
      );

      if (mounted) {
        setState(() {
          _aiRecommendation = newRecommendation;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;

          // Create a fallback recommendation if generation fails
          _aiRecommendation = {
            'performance_overview':
                'Performance data couldn\'t be generated at this time. Please try regenerating.',
            'strengths':
                'Strength analysis couldn\'t be generated at this time.',
            'areas_for_improvement':
                'Areas for improvement couldn\'t be generated at this time.',
            'learning_strategies':
                'Learning strategies couldn\'t be generated at this time.',
            'action_plan':
                'Try reviewing your answers and looking at explanations to learn from your mistakes.',
          };
        });
        print('Error generating recommendation: $e');
      }
    }
  }

  // Method to regenerate recommendations
  void _regenerateRecommendations() async {
    if (_quizAttempt == null || _isLoadingRecommendations) {
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      // Use the quiz attempt ID, not the quiz ID
      final quizAttemptId = _quizAttempt!['id'];

      // Delete existing recommendation first
      try {
        await RecommendationService.deleteRecommendation(quizAttemptId);
      } catch (e) {
        print('Error deleting previous recommendation: $e');
        // Continue even if deletion fails
      }

      // Generate new recommendation
      final newRecommendation =
          await RecommendationService.generateAndSaveQuizRecommendation(
        quizAttemptId,
      );

      if (mounted) {
        setState(() {
          _aiRecommendation = newRecommendation;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;

          // Don't clear existing recommendation on regeneration failure
          if (_aiRecommendation == null) {
            _aiRecommendation = {
              'performance_overview':
                  'Performance data couldn\'t be generated at this time. Please try regenerating.',
              'strengths':
                  'Strength analysis couldn\'t be generated at this time.',
              'areas_for_improvement':
                  'Areas for improvement couldn\'t be generated at this time.',
              'learning_strategies':
                  'Learning strategies couldn\'t be generated at this time.',
              'action_plan':
                  'Try reviewing your answers and looking at explanations to learn from your mistakes.',
            };
          }
        });
        print('Error regenerating recommendation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _quizAttempt != null
              ? 'Review: ${_quizAttempt!['quizzes']['title']}'
              : 'Quiz Review',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuizAttempt,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_quizAttempt == null) {
      return const Center(child: Text('Quiz attempt not found'));
    }

    final quiz = _quizAttempt!['quizzes'];
    final score = _quizAttempt!['score'];
    final totalQuestions = _quizAttempt!['total_questions'];
    final percentage =
        totalQuestions > 0 ? (score / totalQuestions * 100).round() : 0;
    final createdAt = DateTime.parse(_quizAttempt!['created_at']);
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats card with enhanced design
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getScoreGradientColor(percentage),
                  _getScoreGradientColor(percentage).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PhosphorIcons.trophy(),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz['title'],
                              style: AppTheme.headingSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${quiz['quiz_type']} • ${quiz['difficulty']} difficulty',
                              style: AppTheme.bodyText.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(createdAt),
                              style: AppTheme.smallText.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Score visualization
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Score
                        Column(
                          children: [
                            Text(
                              '$score/$totalQuestions',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Correct',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        // Divider
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),

                        // Percentage
                        Column(
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getScoreLabel(percentage),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Questions title with enhanced design
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.list(), color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Questions & Answers',
                  style: AppTheme.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_userAnswers.length} items',
                  style: AppTheme.smallText.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Questions and answers list
          ..._buildQuestionsAnswers(),

          const SizedBox(height: 32),

          // AI Recommendations section - moved here after questions and before dashboard button
          _buildAIRecommendationsSection(),

          const SizedBox(height: 32),

          // Return to Dashboard button - enhanced
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: Icon(PhosphorIcons.houseSimple()),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade400),
              ),
              label: const Text('Return to Dashboard'),
            ),
          ),
          const SizedBox(height: 16),

          // Create Note button with proper quiz_id reference
          ElevatedButton.icon(
            onPressed: () {
              final quizId = _quizAttempt?['quiz_id'];
              if (quizId != null) {
                context.go('${AppRoutes.createNote}?quiz_id=$quizId');
              }
            },
            icon: const Icon(Icons.note_add),
            label: const Text('Create Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionsAnswers() {
    final List<Widget> widgets = [];

    for (int i = 0; i < _userAnswers.length; i++) {
      final answer = _userAnswers[i];
      final question = answer['questions'];
      final userAnswer = answer['user_answer'];
      final isCorrect = answer['is_correct'];
      final options = List<String>.from(question['options']);
      final correctAnswer = question['correct_answer'];

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                      ),
                      child: Center(
                        child: Icon(
                          isCorrect ? PhosphorIcons.check() : PhosphorIcons.x(),
                          size: 18,
                          color: isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Question ${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _expandedQuestions[i]
                            ? PhosphorIcons.caretUp()
                            : PhosphorIcons.caretDown(),
                        color: Colors.grey[600],
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

              // Question content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  question['question_text'],
                  style: AppTheme.subtitle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (_expandedQuestions[i]) ...[
                const Divider(),

                // Options
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Options:',
                        style: AppTheme.smallText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...options.map((option) {
                        final isUserAnswer = option == userAnswer;
                        final isCorrectAnswer = option == correctAnswer;

                        Color? textColor;
                        if (isUserAnswer && !isCorrect) {
                          textColor = Colors.red.shade700;
                        } else if (isCorrectAnswer) {
                          textColor = Colors.green.shade700;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              if (isUserAnswer)
                                Icon(
                                  isCorrect
                                      ? PhosphorIcons.checkCircle()
                                      : PhosphorIcons.xCircle(),
                                  color: isCorrect
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
                    ],
                  ),
                ),

                // Explanation
                if (question['explanation'] != null &&
                    question['explanation'].toString().trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.lightbulb(),
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question['explanation'],
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildAIRecommendationsSection() {
    return AnimatedOpacity(
      opacity: _showRecommendations ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _showRecommendations ? null : 0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AI assistant branding
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: Colors.blue.shade800,
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.blue.shade800,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Learning Assistant',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalized insights based on your quiz performance',
                            style: TextStyle(
                              color: Colors.blue.shade800.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _aiRecommendation != null &&
                              !_isLoadingRecommendations
                          ? _regenerateRecommendations
                          : null,
                      tooltip: 'Regenerate recommendations',
                      icon: Icon(
                        PhosphorIcons.lightning(),
                        color: Colors.blue.shade800.withOpacity(
                          _aiRecommendation != null &&
                                  !_isLoadingRecommendations
                              ? 1.0
                              : 0.5,
                        ),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Recommendations content with elegant styling
              if (_showRecommendations)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _isLoadingRecommendations
                      ? _buildLoadingState()
                      : _aiRecommendation == null
                          ? _buildNoRecommendationsState()
                          : _buildRecommendationCards(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCards() {
    // Check if recommendation has required fields
    if (_aiRecommendation == null) {
      return _buildNoRecommendationsState();
    }

    // Ensure all required fields are present, using empty strings as fallbacks
    // Support both new and old field names
    final performanceOverview = _aiRecommendation!['performance_overview'] ??
        _aiRecommendation!['overall_assessment'] ??
        'Performance data not available.';

    final strengths = _aiRecommendation!['strengths'] ??
        _aiRecommendation!['strong_areas'] ??
        'Strength analysis not available.';

    final areasForImprovement = _aiRecommendation!['areas_for_improvement'] ??
        _aiRecommendation!['weak_areas'] ??
        'Areas for improvement not available.';

    final learningStrategies = _aiRecommendation!['learning_strategies'] ??
        _aiRecommendation!['learning_recommendations'] ??
        'Learning strategies not available.';

    final actionPlan = _aiRecommendation!['action_plan'] ??
        _aiRecommendation!['next_steps'] ??
        'Action plan not available.';

    // Define action buttons for the action plan card
    final actionButtons = [
      Expanded(
        child: OutlinedButton.icon(
          icon: Icon(PhosphorIcons.listBullets(), size: 18),
          label: const Text('View Quizzes'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: Colors.green.shade300),
          ),
          onPressed: () => context.push(AppRoutes.quizList),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton.icon(
          icon: Icon(PhosphorIcons.plus(), size: 18),
          label: const Text('Create Quiz'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () => context.push(AppRoutes.createQuiz),
        ),
      ),
    ];

    // Determine layout based on screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final useHorizontalLayout = screenWidth > 768;

    if (useHorizontalLayout) {
      // Horizontal layout for larger screens (tablets, desktops)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance overview card
          _buildRecommendationCard(
            title: 'Performance Overview',
            icon: PhosphorIcons.chartBar(),
            iconColor: Colors.blue.shade700,
            content: performanceOverview,
          ),
          const SizedBox(height: 16),

          // Strengths and improvements row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRecommendationCard(
                  title: 'Your Strengths',
                  icon: PhosphorIcons.star(),
                  iconColor: Colors.amber.shade700,
                  content: strengths,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecommendationCard(
                  title: 'Areas for Improvement',
                  icon: PhosphorIcons.trendUp(),
                  iconColor: Colors.orange.shade700,
                  content: areasForImprovement,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Learning strategies and action plan row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRecommendationCard(
                  title: 'Learning Strategies',
                  icon: PhosphorIcons.lightbulb(),
                  iconColor: Colors.purple.shade700,
                  content: learningStrategies,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecommendationCard(
                  title: 'Action Plan',
                  icon: PhosphorIcons.checkSquare(),
                  iconColor: Colors.green.shade700,
                  content: actionPlan,
                  actions: actionButtons,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Vertical layout for smaller screens (phones)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationCard(
            title: 'Performance Overview',
            icon: PhosphorIcons.chartBar(),
            iconColor: Colors.blue.shade700,
            content: performanceOverview,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            title: 'Your Strengths',
            icon: PhosphorIcons.star(),
            iconColor: Colors.amber.shade700,
            content: strengths,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            title: 'Areas for Improvement',
            icon: PhosphorIcons.trendUp(),
            iconColor: Colors.orange.shade700,
            content: areasForImprovement,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            title: 'Learning Strategies',
            icon: PhosphorIcons.lightbulb(),
            iconColor: Colors.purple.shade700,
            content: learningStrategies,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            title: 'Action Plan',
            icon: PhosphorIcons.checkSquare(),
            iconColor: Colors.green.shade700,
            content: actionPlan,
            actions: actionButtons,
          ),
        ],
      );
    }
  }

  Widget _buildRecommendationCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    List<Widget>? actions,
  }) {
    // Parse markdown content to support rich text formatting
    final formattedContent = _formatMarkdownContent(content);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with title and icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTheme.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Card content with padding
          Padding(padding: const EdgeInsets.all(16), child: formattedContent),
          // Optional action buttons
          if (actions != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to format markdown content with rich styling
  Widget _formatMarkdownContent(String content) {
    final List<Widget> formattedWidgets = [];

    // Split content by line breaks to handle them separately
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        formattedWidgets.add(const SizedBox(height: 8));
        continue;
      }

      // Handle bullet points
      if (line.startsWith('- ') || line.startsWith('* ')) {
        final bulletText = line.substring(2);
        formattedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Text(bulletText, style: AppTheme.bodyText)),
              ],
            ),
          ),
        );
      }
      // Handle section headers (indicated by ** at beginning and end)
      else if (line.startsWith('**') && line.endsWith('**')) {
        final headerText = line.substring(2, line.length - 2);
        formattedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              headerText,
              style: AppTheme.subtitle.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        );
      }
      // Handle emphasis (indicated by * at beginning and end)
      else if (line.startsWith('*') && line.endsWith('*')) {
        final emphasizedText = line.substring(1, line.length - 1);
        formattedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emphasizedText,
              style: AppTheme.bodyText.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        );
      }
      // Handle normal text with inline formatting
      else {
        String processedText = line;

        // Check for inline bold formatting with **text**
        final boldRegExp = RegExp(r'\*\*(.*?)\*\*');
        final boldMatches = boldRegExp.allMatches(processedText);

        if (boldMatches.isNotEmpty) {
          // If we have inline formatting, use RichText
          final spans = <TextSpan>[];
          int lastIndex = 0;

          for (final match in boldMatches) {
            if (match.start > lastIndex) {
              spans.add(
                TextSpan(
                  text: processedText.substring(lastIndex, match.start),
                  style: AppTheme.bodyText,
                ),
              );
            }

            spans.add(
              TextSpan(
                text: match.group(1),
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            );

            lastIndex = match.end;
          }

          if (lastIndex < processedText.length) {
            spans.add(
              TextSpan(
                text: processedText.substring(lastIndex),
                style: AppTheme.bodyText,
              ),
            );
          }

          formattedWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(children: spans, style: AppTheme.bodyText),
              ),
            ),
          );
        } else {
          // Simple text without inline formatting
          formattedWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(processedText, style: AppTheme.bodyText),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedWidgets,
    );
  }

  Color _getScoreGradientColor(int percentage) {
    if (percentage >= 80) {
      return Colors.green.shade600;
    } else if (percentage >= 60) {
      return Colors.blue.shade600;
    } else if (percentage >= 40) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  String _getScoreLabel(int percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Very Good';
    if (percentage >= 70) return 'Good';
    if (percentage >= 60) return 'Satisfactory';
    if (percentage >= 50) return 'Fair';
    return 'Needs Work';
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyzing your quiz results...',
            style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is creating personalized recommendations based on your performance',
            style: AppTheme.bodyText.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecommendationsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.sparkle(),
            size: 48,
            color: Colors.purple.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'AI Learning Assistant',
            style: AppTheme.subtitle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Want personalized insights about your performance and learning strategy recommendations?',
            style: AppTheme.bodyText.copyWith(
              color: Colors.grey.shade800,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI can analyze your quiz results to identify your strengths, areas for improvement, and suggest customized learning paths.',
            style: AppTheme.bodyText.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateInitialRecommendation,
              icon: Icon(PhosphorIcons.lightning()),
              label: const Text('Generate AI Recommendations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This uses AI to process your quiz responses. Your data is kept private and secure.',
            style: AppTheme.smallText.copyWith(
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
