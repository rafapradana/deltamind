import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/models/learning_path.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Enhanced widget for displaying learning path progress with detailed metrics
class LearningPathProgressWidget extends StatelessWidget {
  final LearningPath learningPath;
  final bool isCompact;
  final VoidCallback? onContinue;

  const LearningPathProgressWidget({
    Key? key,
    required this.learningPath,
    this.isCompact = false,
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate progress metrics
    final int totalModules = learningPath.modules.length;
    final int completedModules =
        learningPath.modules.where((m) => m.status == ModuleStatus.done).length;
    final int inProgressModules = learningPath.modules
        .where((m) => m.status == ModuleStatus.inProgress)
        .length;

    // Find next incomplete module that's not locked
    final LearningPathModule? nextModuleToComplete = learningPath.modules
        .where((m) => m.status == ModuleStatus.inProgress)
        .firstOrNull;

    // Determine if the path is completed
    final bool isCompleted = completedModules == totalModules;

    // Compact view for use in cards or list items
    if (isCompact) {
      return _buildCompactProgress(
        context,
        completedModules,
        totalModules,
        isCompleted,
      );
    }

    // Full detailed view for dashboard or dedicated progress pages
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and progress percentage
            Row(
              children: [
                Icon(
                  PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Learning Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isCompleted ? Colors.green : AppColors.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isCompleted ? Colors.green : AppColors.primary)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${learningPath.progress}%',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: learningPath.progress / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Progress metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressMetric(
                  context,
                  'Completed',
                  '$completedModules/$totalModules',
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  Colors.green,
                ),
                _buildProgressMetric(
                  context,
                  'In Progress',
                  '$inProgressModules/$totalModules',
                  PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                  AppColors.primary,
                ),
                _buildProgressMetric(
                  context,
                  'Remaining',
                  '${totalModules - completedModules - inProgressModules}/$totalModules',
                  PhosphorIcons.lockKey(PhosphorIconsStyle.fill),
                  Colors.grey.shade600,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Next up section
            if (nextModuleToComplete != null && !isCompleted) ...[
              Text(
                'Continue Learning:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildNextModuleCard(context, nextModuleToComplete),
            ] else if (isCompleted) ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learning Path Completed!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Congratulations on completing this learning path',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Stats and streaks section (could be expanded in the future)
            if (!isCompleted && onContinue != null) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: onContinue,
                  icon: Icon(
                    PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
                  ),
                  label: const Text('Continue Learning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a compact progress indicator for use in cards or list items
  Widget _buildCompactProgress(
    BuildContext context,
    int completedModules,
    int totalModules,
    bool isCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress: ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${learningPath.progress}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : AppColors.primary,
                  ),
            ),
            const Spacer(),
            Text(
              '$completedModules/$totalModules modules',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: learningPath.progress / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build a metric display for the progress dashboard
  Widget _buildProgressMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
      ],
    );
  }

  /// Build a card for the next module to complete
  Widget _buildNextModuleCard(
    BuildContext context,
    LearningPathModule module,
  ) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          module.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: module.estimatedDuration != null
            ? Row(
                children: [
                  Icon(
                    PhosphorIcons.clock(PhosphorIconsStyle.fill),
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    module.estimatedDuration!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              )
            : null,
        trailing: onContinue != null
            ? IconButton(
                icon: Icon(
                  PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
                  color: AppColors.primary,
                ),
                onPressed: onContinue,
                tooltip: 'Continue',
              )
            : null,
      ),
    );
  }
}
