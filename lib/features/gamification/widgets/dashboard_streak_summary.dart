import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
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
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // If user has no streak data yet, show a placeholder
    if (gamificationState.userStreak == null) {
      return _buildEmptyStreakCard(context, theme);
    }

    // User has streak data, show it
    final streak = gamificationState.userStreak!;
    final level = gamificationState.userLevel;
    final recentAchievements =
        ref
            .read(gamificationControllerProvider.notifier)
            .getRecentAchievements();

    return _buildStreakCard(context, theme, streak, level, recentAchievements);
  }

  Widget _buildEmptyStreakCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.achievements),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(PhosphorIconsFill.flame, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0-Day Streak',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete a quiz today to start your streak!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsFill.caretRight,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    ThemeData theme,
    UserStreak streak,
    UserLevel? level,
    List<Achievement> recentAchievements,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.achievements),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Main streak info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStreakIcon(context, streak.currentStreak),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${streak.currentStreak}-Day Streak',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (level != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Level ${level.currentLevel}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streak.currentStreak > 0
                              ? 'Keep going! Your longest streak is ${streak.longestStreak} days.'
                              : 'Complete a quiz today to start your streak!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIconsFill.caretRight,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),

            // Recent achievements section with horizontal divider
            if (recentAchievements.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsFill.trophy,
                          color: Colors.amber.shade700,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recently earned:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildAchievementChips(context, theme, recentAchievements),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIcon(BuildContext context, int streakCount) {
    final color = _getStreakColor(streakCount);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: streakCount > 0 ? color.withOpacity(0.1) : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        PhosphorIconsFill.flame,
        color: streakCount > 0 ? color : Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildAchievementChips(
    BuildContext context,
    ThemeData theme,
    List<Achievement> achievements,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children:
          achievements.take(3).map((achievement) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsFill.star,
                    size: 12,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    achievement.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Color _getStreakColor(int streakDays) {
    if (streakDays >= 30) {
      return Colors.deepOrange.shade700;
    } else if (streakDays >= 14) {
      return Colors.orange.shade800;
    } else if (streakDays >= 7) {
      return Colors.orange.shade600;
    } else if (streakDays >= 3) {
      return Colors.orange;
    } else {
      return Colors.orange.shade300;
    }
  }
}
