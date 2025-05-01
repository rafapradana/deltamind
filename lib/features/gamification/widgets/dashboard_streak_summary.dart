import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/features/gamification/widgets/streak_freeze_widget.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:deltamind/features/gamification/widgets/streak_freeze_countdown.dart';

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
    final streakFreeze = gamificationState.streakFreeze;
    final hasStreakFreezes =
        streakFreeze != null && streakFreeze.availableFreezes > 0;

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                streak.currentStreak > 0
                                    ? 'Keep going! Your longest streak is ${streak.longestStreak} days.'
                                    : 'Complete a quiz today to start your streak!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasStreakFreezes) ...[
                              const SizedBox(width: 4),
                              const StreakFreezeWidget(compact: true),
                            ],
                          ],
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

            // Active streak freeze indicator
            if (streak.isStreakFreezeActive)
              _buildCompactActiveStreakFreezeIndicator(
                context,
                streak.streakFreezeExpiry,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActiveStreakFreezeIndicator(
    BuildContext context,
    DateTime? expiryTime,
  ) {
    final theme = Theme.of(context);

    // Check if streak freeze has expired
    if (expiryTime != null) {
      final now = DateTime.now();
      if (expiryTime.isBefore(now)) {
        return const SizedBox.shrink();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(top: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsFill.snowflake,
            color: Colors.blue.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Streak Freeze: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: StreakFreezeCountdown(
                    expiryTime: expiryTime,
                    compact: true,
                    textColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Color _getStreakColor(int streakCount) {
    if (streakCount >= 30) {
      return Colors.purple;
    } else if (streakCount >= 14) {
      return Colors.indigo;
    } else if (streakCount >= 7) {
      return Colors.blue;
    } else if (streakCount >= 3) {
      return Colors.green;
    } else if (streakCount > 0) {
      return AppColors.primary;
    } else {
      return Colors.grey;
    }
  }
}
