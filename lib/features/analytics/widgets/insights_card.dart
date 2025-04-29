import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Card displaying study insights
class InsightsCard extends StatelessWidget {
  final String? mostImprovedCategory;
  final String? weakestCategory;
  final String? strongestCategory;
  final double consistency;

  const InsightsCard({
    Key? key,
    this.mostImprovedCategory,
    this.weakestCategory,
    this.strongestCategory,
    required this.consistency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIconsFill.lightbulb, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInsightItem(
              context,
              'Study Consistency',
              '${consistency.toStringAsFixed(0)}%',
              'Based on active days in the last month',
              PhosphorIconsFill.calendar,
              _getConsistencyColor(consistency),
            ),

            const Divider(height: 24),

            _buildCategoryInsight(
              context,
              'Strongest Category',
              strongestCategory ?? 'Not enough data',
              PhosphorIconsFill.trophy,
              Colors.amber,
            ),

            const SizedBox(height: 12),

            _buildCategoryInsight(
              context,
              'Weakest Category',
              weakestCategory ?? 'Not enough data',
              PhosphorIconsFill.warning,
              Colors.red,
            ),

            const SizedBox(height: 12),

            _buildCategoryInsight(
              context,
              'Most Improved',
              mostImprovedCategory ?? 'Not enough data',
              PhosphorIconsFill.arrowUp,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryInsight(
    BuildContext context,
    String title,
    String category,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDataAvailable = category != 'Not enough data';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                isDataAvailable
                    ? color.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: isDataAvailable ? color : Colors.grey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                category,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight:
                      isDataAvailable ? FontWeight.w600 : FontWeight.normal,
                  color: isDataAvailable ? AppColors.textPrimary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConsistencyColor(double consistency) {
    if (consistency >= 80) {
      return Colors.green;
    } else if (consistency >= 50) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }
}
