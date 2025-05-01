import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/analytics_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Card to display total quizzes created and completed
class QuizTotalsCard extends StatefulWidget {
  final int totalCreated;
  final int totalCompleted;

  const QuizTotalsCard({
    Key? key,
    required this.totalCreated,
    required this.totalCompleted,
  }) : super(key: key);

  @override
  State<QuizTotalsCard> createState() => _QuizTotalsCardState();
}

class _QuizTotalsCardState extends State<QuizTotalsCard> {
  bool _isLoading = true;
  double _averageScore = 0;
  int _averageTimePerQuiz = 0;

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load average score
      final overallAnalytics = await AnalyticsService.getOverallQuizAnalytics();
      
      // Load quiz completion times using a two-step approach
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        // First get the quiz attempts for this user
        final attemptsResponse = await SupabaseService.client
            .from('quiz_attempts')
            .select('id, created_at')
            .eq('user_id', userId)
            .eq('completed', true)
            .order('created_at');
            
        if (attemptsResponse != null && attemptsResponse.isNotEmpty) {
          // Get all attempt IDs
          final attemptIds = attemptsResponse.map((attempt) => attempt['id'] as String).toList();
          
          // Then get the answers for these quiz attempts - fetch all and filter in memory
          // since the number of attempts is likely reasonable
          final answersResponse = await SupabaseService.client
              .from('user_answers')
              .select('quiz_attempt_id, created_at')
              .order('created_at');
          
          if (answersResponse != null && answersResponse.isNotEmpty) {
            // Filter answers to only those for the user's attempts
            final filteredAnswers = answersResponse.where(
              (answer) => attemptIds.contains(answer['quiz_attempt_id']),
            ).toList();
            
            // Group answers by quiz attempt to calculate time per quiz
            Map<String, List<DateTime>> attemptTimestamps = {};
            
            for (final answer in filteredAnswers) {
              final attemptId = answer['quiz_attempt_id'] as String?;
              final timestamp = answer['created_at'] != null 
                  ? DateTime.parse(answer['created_at']) 
                  : null;
                  
              if (attemptId != null && timestamp != null) {
                if (!attemptTimestamps.containsKey(attemptId)) {
                  attemptTimestamps[attemptId] = [];
                }
                attemptTimestamps[attemptId]!.add(timestamp);
              }
            }
            
            // Calculate time difference between first and last answer for each attempt
            int totalSeconds = 0;
            int validAttempts = 0;
            
            attemptTimestamps.forEach((attemptId, timestamps) {
              if (timestamps.length >= 2) {
                // Sort timestamps to ensure we get first and last correctly
                timestamps.sort();
                final firstTimestamp = timestamps.first;
                final lastTimestamp = timestamps.last;
                
                // Calculate duration in seconds
                final durationSeconds = lastTimestamp.difference(firstTimestamp).inSeconds;
                
                // Only count reasonable durations (between 5 seconds and 2 hours)
                if (durationSeconds >= 5 && durationSeconds < 7200) {
                  totalSeconds += durationSeconds;
                  validAttempts++;
                }
              }
            });
            
            if (validAttempts > 0) {
              _averageTimePerQuiz = (totalSeconds / validAttempts).round();
            }
          }
        }
      }
      
      setState(() {
        _averageScore = overallAnalytics.averageScore;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading additional analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Removed background color
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIconsFill.files,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quiz Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Top row with quiz counts
            Row(
              children: [
                Expanded(
                  child: _buildTotalItem(
                    context,
                    'Quizzes Created',
                    widget.totalCreated.toString(),
                    PhosphorIconsFill.notepad,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTotalItem(
                    context,
                    'Quizzes Completed',
                    widget.totalCompleted.toString(),
                    PhosphorIconsFill.checkSquare,
                    AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom row with average score and time
            Row(
              children: [
                Expanded(
                  child: _buildTotalItem(
                    context,
                    'Average Score',
                    _isLoading ? '...' : '${_averageScore.toStringAsFixed(1)}%',
                    PhosphorIconsFill.chartBar,
                    Colors.orange.shade700,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTotalItem(
                    context,
                    'Avg. Time/Quiz',
                    _isLoading ? '...' : _formatTime(_averageTimePerQuiz),
                    PhosphorIconsFill.clock,
                    Colors.purple.shade700,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} min';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '$hours:${minutes.toString().padLeft(2, '0')} hr';
    }
  }
}
