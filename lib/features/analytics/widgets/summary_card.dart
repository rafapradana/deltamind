import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

/// A card showing summary analytics info with modern design
class SummaryCard extends StatelessWidget {
  final QuizAnalytics analytics;

  const SummaryCard({Key? key, required this.analytics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 1);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIconsFill.chartLine,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (analytics.lastUpdated != null)
                  Text(
                    'Updated: ${_formatUpdateTime(analytics.lastUpdated!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Average score with circular indicator
            Row(
              children: [
                _buildScoreIndicator(context, analytics.averageScore),
                const SizedBox(width: 16),
                Expanded(child: _buildStatsList(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(BuildContext context, double score) {
    final theme = Theme.of(context);
    final size = 100.0;

    // Determine color based on score
    Color scoreColor = AppColors.primary;
    if (score < 40) {
      scoreColor = AppColors.error;
    } else if (score < 70) {
      scoreColor = AppColors.warning;
    } else if (score >= 90) {
      scoreColor = AppColors.success;
    }

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: scoreColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toStringAsFixed(1)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              Text(
                'Average',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem(
          context,
          'Quizzes Completed',
          '${analytics.totalAttempts}',
          PhosphorIconsFill.checkSquare,
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          context,
          'Questions Answered',
          '${analytics.totalQuestionsAttempted}',
          PhosphorIconsFill.listChecks,
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          context,
          'Correct Answers',
          '${analytics.totalCorrectAnswers}',
          PhosphorIconsFill.check,
          additionalInfo:
              analytics.totalQuestionsAttempted > 0
                  ? '${(analytics.totalCorrectAnswers / analytics.totalQuestionsAttempted * 100).toStringAsFixed(1)}% accuracy'
                  : null,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    String? additionalInfo,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (additionalInfo != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        additionalInfo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatUpdateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
