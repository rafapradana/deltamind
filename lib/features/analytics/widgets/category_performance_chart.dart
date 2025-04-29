import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Chart displaying performance by category
class CategoryPerformanceChart extends StatelessWidget {
  final List<QuizAnalytics> categoryAnalytics;

  const CategoryPerformanceChart({Key? key, required this.categoryAnalytics})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort by average score
    final sortedAnalytics = List<QuizAnalytics>.from(categoryAnalytics)
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIconsFill.chartBar,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (categoryAnalytics.isEmpty)
              _buildEmptyState(context)
            else
              _buildCategoryPerformance(context, sortedAnalytics),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsFill.chartBar,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No category data available yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Take more quizzes to see category performance',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance(
    BuildContext context,
    List<QuizAnalytics> sortedAnalytics,
  ) {
    // Limit to top 5 categories for better visualization
    final displayAnalytics =
        sortedAnalytics.length > 5
            ? sortedAnalytics.sublist(0, 5)
            : sortedAnalytics;

    return Column(
      children:
          displayAnalytics.map((analytics) {
            return _buildCategoryBar(
              context,
              analytics.categoryName ?? 'Unknown',
              analytics.averageScore,
              analytics.totalAttempts,
            );
          }).toList(),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    String categoryName,
    double score,
    int attempts,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($attempts ${attempts == 1 ? 'quiz' : 'quizzes'})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.divider),
                ),
              ),
              FractionallySizedBox(
                widthFactor: score / 100,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getScoreColor(score).withOpacity(0.7),
                        _getScoreColor(score),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return AppColors.success;
    } else if (score >= 70) {
      return AppColors.info;
    } else if (score >= 60) {
      return AppColors.secondary;
    } else if (score >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
}
