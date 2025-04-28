import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(achievement.category);

    return Card(
      elevation: achievement.isEarned ? 1 : 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color:
              achievement.isEarned
                  ? categoryColor.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.1),
          width: achievement.isEarned ? 1 : 0.5,
        ),
      ),
      color:
          achievement.isEarned
              ? theme.colorScheme.surface
              : theme.colorScheme.surface.withOpacity(0.7),
      child: InkWell(
        onTap: () {
          // Show achievement details in a dialog
          showDialog(
            context: context,
            builder: (context) => _buildAchievementDialog(context, theme),
          );
        },
        splashColor: categoryColor.withOpacity(0.1),
        highlightColor: categoryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievement icon with improved visual
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  gradient:
                      achievement.isEarned
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor,
                              categoryColor.withOpacity(0.7),
                            ],
                          )
                          : null,
                  color:
                      achievement.isEarned
                          ? null
                          : theme.colorScheme.onSurface.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                      achievement.isEarned
                          ? [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: Icon(
                    _getIconData(achievement.iconName),
                    color:
                        achievement.isEarned
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and category row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  achievement.isEarned
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (achievement.isEarned)
                          Icon(
                            PhosphorIconsFill.checkCircle,
                            color: categoryColor,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Category label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            achievement.isEarned
                                ? categoryColor.withOpacity(0.15)
                                : theme.colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        achievement.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              achievement.isEarned
                                  ? categoryColor
                                  : theme.colorScheme.onSurface.withOpacity(
                                    0.6,
                                  ),
                          fontWeight:
                              achievement.isEarned
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description with limited lines
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            achievement.isEarned
                                ? theme.colorScheme.onSurface.withOpacity(0.8)
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Achievement status
                    Row(
                      children: [
                        if (achievement.isEarned &&
                            achievement.earnedAt != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIconsFill.calendar,
                                  color: categoryColor.withOpacity(0.7),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    DateFormat.yMMMd().format(
                                      achievement.earnedAt!,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              'Not yet earned',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // XP reward
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                achievement.isEarned
                                    ? Colors.green.withOpacity(0.15)
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.05,
                                    ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIconsFill.star,
                                size: 12,
                                color:
                                    achievement.isEarned
                                        ? Colors.amber
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${achievement.xpReward} XP',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight:
                                      achievement.isEarned
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      achievement.isEarned
                                          ? Colors.green
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                ),
                              ),
                            ],
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
    );
  }

  // Dialog to show achievement details
  Widget _buildAchievementDialog(BuildContext context, ThemeData theme) {
    final categoryColor = _getCategoryColor(achievement.category);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with achievement icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [categoryColor, categoryColor.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(achievement.iconName),
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    achievement.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      achievement.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Achievement details
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Status information
                  Row(
                    children: [
                      Icon(
                        achievement.isEarned
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsFill.clock,
                        color:
                            achievement.isEarned ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.isEarned
                                  ? 'Earned'
                                  : 'Not Yet Earned',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    achievement.isEarned
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ),
                            if (achievement.isEarned &&
                                achievement.earnedAt != null)
                              Text(
                                'On ${DateFormat.yMMMMd().format(achievement.earnedAt!)}',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsFill.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${achievement.xpReward} XP',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!achievement.isEarned)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsFill.info,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How to earn this achievement',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getRequirementText(achievement),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to generate requirement text
  String _getRequirementText(Achievement achievement) {
    switch (achievement.requirementType) {
      case 'streak_days':
        return 'Maintain a streak of ${achievement.requirementValue} days.';
      case 'quizzes_completed':
        return 'Complete ${achievement.requirementValue} quizzes.';
      case 'perfect_scores':
        return 'Get ${achievement.requirementValue} perfect scores in quizzes.';
      case 'quizzes_created':
        return 'Create ${achievement.requirementValue} quizzes.';
      default:
        return 'Continue using the app to unlock this achievement.';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Beginner':
        return Colors.blue;
      case 'Intermediate':
        return Colors.green;
      case 'Advanced':
        return Colors.deepPurple;
      case 'Streak':
        return Colors.orange;
      case 'Performance':
        return Colors.red;
      case 'Creation':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'flame_small':
      case 'flame_medium':
      case 'flame_large':
      case 'flame_max':
        return PhosphorIconsFill.flame;
      case 'footprint':
        return PhosphorIconsFill.footprints;
      case 'compass':
        return PhosphorIconsFill.compass;
      case 'medal':
        return PhosphorIconsFill.medal;
      case 'star':
        return PhosphorIconsFill.star;
      case 'stopwatch':
        return PhosphorIconsFill.timer;
      case 'lightbulb':
        return PhosphorIconsFill.lightbulb;
      case 'pencil':
        return PhosphorIconsFill.pencilSimple;
      case 'trophy':
      default:
        return PhosphorIconsFill.trophy;
    }
  }
}
