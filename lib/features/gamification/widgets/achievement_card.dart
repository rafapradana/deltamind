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

    return Card(
      elevation: achievement.isEarned ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color:
          achievement.isEarned
              ? theme.colorScheme.surface
              : theme.colorScheme.surface.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    achievement.isEarned
                        ? _getCategoryColor(achievement.category)
                        : theme.colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getIconData(achievement.iconName),
                  color:
                      achievement.isEarned
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              achievement.isEarned
                                  ? _getCategoryColor(
                                    achievement.category,
                                  ).withOpacity(0.2)
                                  : theme.colorScheme.onSurface.withOpacity(
                                    0.05,
                                  ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          achievement.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                achievement.isEarned
                                    ? _getCategoryColor(achievement.category)
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          achievement.isEarned
                              ? theme.colorScheme.onSurface.withOpacity(0.8)
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (achievement.isEarned && achievement.earnedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsFill.trophy,
                          color: _getCategoryColor(achievement.category),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Earned on ${DateFormat.yMMMd().format(achievement.earnedAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Not yet earned • +${achievement.xpReward} XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
