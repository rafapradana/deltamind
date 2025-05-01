import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/features/gamification/widgets/streak_freeze_card.dart';
import 'package:deltamind/features/gamification/widgets/streak_freeze_countdown.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

class StreakFreezePage extends ConsumerStatefulWidget {
  const StreakFreezePage({Key? key}) : super(key: key);

  @override
  ConsumerState<StreakFreezePage> createState() => _StreakFreezePageState();
}

class _StreakFreezePageState extends ConsumerState<StreakFreezePage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final gamificationState = ref.watch(gamificationControllerProvider);
    final streakFreeze = gamificationState.streakFreeze;
    final userStreak = gamificationState.userStreak;

    return Scaffold(
      appBar: AppBar(title: const Text('Streak Freezes'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(gamificationControllerProvider.notifier)
              .loadGamificationData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current streak info
              if (userStreak != null)
                _buildCurrentStreakInfo(context, userStreak),

              const SizedBox(height: 20),

              // Streak Freeze Card
              if (streakFreeze != null)
                StreakFreezeCard(
                  streakFreeze: streakFreeze,
                  onUseFreeze: _useStreakFreeze,
                ),

              const SizedBox(height: 24),

              // How streak freezes work section
              _buildInfoSection(context),

              const SizedBox(height: 24),

              // Usage history
              _buildUsageHistorySection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStreakInfo(BuildContext context, UserStreak streak) {
    final theme = Theme.of(context);
    final isStreakActive = streak.currentStreak > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.flame,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStreakActive
                        ? '${streak.currentStreak}-Day Streak'
                        : 'No Active Streak',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isStreakActive
                        ? 'Keep it going!'
                        : 'Complete a quiz today to start a streak',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (streak.isStreakFreezeActive &&
              streak.streakFreezeExpiry != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsFill.snowflake,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streak Freeze Active',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        StreakFreezeCountdown(
                          expiryTime: streak.streakFreezeExpiry,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How Streak Freezes Work',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: PhosphorIconsFill.shieldCheck,
          title: 'Protection',
          description:
              'Streak freezes protect your streak for one day when you miss completing any quiz.',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: PhosphorIconsFill.clock,
          title: '24-Hour Coverage',
          description:
              'Once activated, a streak freeze protects your streak for 24 hours.',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: PhosphorIconsFill.lightbulb,
          title: 'Use Wisely',
          description:
              'You can earn streak freezes by completing special challenges and maintaining longer streaks.',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHistorySection(BuildContext context) {
    final theme = Theme.of(context);
    final gamificationState = ref.watch(gamificationControllerProvider);
    final history = gamificationState.freezeHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage History',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          _buildEmptyHistoryCard(context)
        else
          _buildHistoryList(context, history),
      ],
    );
  }

  Widget _buildEmptyHistoryCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIconsFill.clock,
            size: 40,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No usage history yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your streak freeze usage history will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
      BuildContext context, List<StreakFreezeHistory> history) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          ...history.map((item) => _buildHistoryItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, StreakFreezeHistory item) {
    final theme = Theme.of(context);
    final isActive = item.isActive;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final gamificationState = ref.watch(gamificationControllerProvider);
    final history = gamificationState.freezeHistory;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.snowflake,
                  color: isActive ? Colors.blue : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Active Streak Freeze' : 'Streak Freeze Used',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? theme.colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used on ${dateFormat.format(item.usedAt)} at ${timeFormat.format(item.usedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (!isActive && item.expiredAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Expired on ${dateFormat.format(item.expiredAt!)} at ${timeFormat.format(item.expiredAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ] else if (isActive && item.expiredAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Expires on ${dateFormat.format(item.expiredAt!)} at ${timeFormat.format(item.expiredAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            PhosphorIconsFill.clock,
                            size: 12,
                            color: isActive
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${item.durationText}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? theme.colorScheme.primary
                                : Colors.grey,
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
        if (history.last != item)
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2))
      ],
    );
  }

  void _useStreakFreeze() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(gamificationControllerProvider.notifier)
          .useStreakFreeze();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Streak freeze activated successfully!'
                : 'Failed to activate streak freeze. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
