import 'package:deltamind/core/theme/app_colors.dart';
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
  // No additional data to load

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
  }

  // No longer need to load additional data
  Future<void> _loadAdditionalData() async {
    // This method is kept as a placeholder for potential future data loading
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

            // Quiz counts and average score in a row
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

            // Average Score row removed per user request
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
}
