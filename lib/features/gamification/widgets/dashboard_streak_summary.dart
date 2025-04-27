import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

class DashboardStreakSummary extends ConsumerWidget {
  const DashboardStreakSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationControllerProvider);
    final theme = Theme.of(context);

    // Show loading indicator if still loading
    if (gamificationState.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // If user has no streak data yet, show a placeholder
    if (gamificationState.userStreak == null) {
      return InkWell(
        onTap: () {
          context.push('/achievements');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsFill.flame,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start your learning streak',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Complete quizzes on consecutive days to build a streak and earn achievements!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User has streak data, show it
    final streak = gamificationState.userStreak!;
    final level = gamificationState.userLevel;
    final recentAchievements =
        ref
            .read(gamificationControllerProvider.notifier)
            .getRecentAchievements();

    return InkWell(
      onTap: () {
        context.push('/achievements');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIconsFill.flame,
                      color: _getStreakColor(streak.currentStreak),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${streak.currentStreak}-Day Streak',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                if (level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level ${level.currentLevel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              streak.currentStreak > 0
                  ? 'Keep going! Your longest streak is ${streak.longestStreak} days.'
                  : 'Complete a quiz today to start your streak!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            // Recent achievements
            if (recentAchievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    PhosphorIconsFill.trophy,
                    color: theme.colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recently earned:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    recentAchievements.take(3).map((achievement) {
                      return Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          achievement.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.onSurface
                            .withOpacity(0.05),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStreakColor(int streakDays) {
    if (streakDays >= 30) {
      return Colors.purple;
    } else if (streakDays >= 14) {
      return Colors.deepOrange;
    } else if (streakDays >= 7) {
      return Colors.orange;
    } else if (streakDays >= 3) {
      return Colors.amber;
    } else {
      return Colors.grey;
    }
  }
}
