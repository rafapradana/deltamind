import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

class StreakCard extends StatelessWidget {
  final UserStreak streak;
  final bool isDetailed;
  final VoidCallback? onTap;

  const StreakCard({
    super.key,
    required this.streak,
    this.isDetailed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withOpacity(0.1),
        highlightColor: AppColors.accent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildStreakStats(context),
                  if (isDetailed) _buildDetailedContent(context, constraints),
                  const SizedBox(height: 16),
                  if (isDetailed)
                    _buildStreakChallengesButton(context)
                  else
                    _buildStreakBadge(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            PhosphorIconsFill.flame,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Streak',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Keep practicing daily!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakStats(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildStreakStat(
            context,
            'Current',
            streak.currentStreak.toString(),
            PhosphorIconsFill.flame,
            AppColors.accent,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        Expanded(
          child: _buildStreakStat(
            context,
            'Longest',
            streak.longestStreak.toString(),
            PhosphorIconsFill.trophy,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Last active date
        Row(
          children: [
            Icon(
              PhosphorIconsFill.calendar,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Last Active: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMd().format(streak.lastActivityDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Weekly activity graph
        _buildWeeklyActivity(context, constraints),
        const SizedBox(height: 12),

        // Streak benefits
        _buildStreakBenefits(context),
      ],
    );
  }

  Widget _buildWeeklyActivity(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final theme = Theme.of(context);
    final availableWidth = constraints.maxWidth;
    final dayWidth =
        (availableWidth - 12) / 7; // 12 pixels for spacing between days

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 7 Days Activity',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = DateTime.now().subtract(Duration(days: 6 - index));
              final dayName = DateFormat('E').format(date);
              final isActive = _wasDayActive(date);
              final isToday = index == 6;

              return SizedBox(
                width: dayWidth,
                child: _buildDayActivity(context, dayName, isActive, isToday),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBenefits(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsFill.info,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak Benefits',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBenefitItem(
            context,
            '3 days: Bonus XP multiplier (x1.5)',
            streak.currentStreak >= 3,
          ),
          const SizedBox(height: 4),
          _buildBenefitItem(
            context,
            '7 days: Daily bonus points (+10)',
            streak.currentStreak >= 7,
          ),
          const SizedBox(height: 4),
          _buildBenefitItem(
            context,
            '14 days: Unlock special theme',
            streak.currentStreak >= 14,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = streak.currentStreak > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient:
                hasStreak
                    ? LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.8),
                        AppColors.accent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                    : null,
            color:
                hasStreak ? null : theme.colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                hasStreak
                    ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsFill.lightning,
                size: 16,
                color:
                    hasStreak
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _getStreakBadge(streak.currentStreak),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      hasStreak
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakChallengesButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: () {
          // Handle streak details button tap
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(PhosphorIconsFill.flame),
        label: const Text('View Streak Challenges'),
      ),
    );
  }

  Widget _buildStreakStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDayActivity(
    BuildContext context,
    String dayName,
    bool isActive,
    bool isToday,
  ) {
    final theme = Theme.of(context);
    final barColor =
        isActive
            ? AppColors.accent
            : theme.colorScheme.onSurface.withOpacity(0.1);
    final barHeight = isActive ? 40.0 : 15.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 20, // Smaller width to avoid overflow
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 30,
          child: Text(
            dayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              fontSize: 10, // Smaller font size to avoid overflow
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, String text, bool isUnlocked) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          isUnlocked ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.circle,
          size: 16,
          color:
              isUnlocked
                  ? Colors.green
                  : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isUnlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: isUnlocked ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  bool _wasDayActive(DateTime date) {
    // For demo purposes, generate some random activity
    // In a real app, this would check the actual activity data
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final dateHash = dateString.hashCode;

    if (date.isAfter(DateTime.now())) return false;

    if (dateHash % 3 == 0) return false;
    if (streak.currentStreak > 0 && date.day == DateTime.now().day) return true;

    return dateHash % 2 == 0;
  }

  String _getStreakBadge(int streakCount) {
    if (streakCount == 0) return 'No streak yet';
    if (streakCount < 3) return 'Beginner Streak';
    if (streakCount < 7) return 'Consistent Streak';
    if (streakCount < 14) return 'Dedicated Streak';
    if (streakCount < 30) return 'Impressive Streak';
    return 'Unstoppable Streak';
  }
}
