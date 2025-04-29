import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/features/gamification/widgets/streak_freeze_card.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
                  onUseFreeze: _handleUseFreeze,
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
                children: [
                  Icon(
                    PhosphorIconsFill.snowflake,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Streak Freeze Active - Expires ${_formatExpiryTime(streak.streakFreezeExpiry!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

    // This would normally be populated from actual usage history
    // For now, we'll show a placeholder message
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
        Container(
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
        ),
      ],
    );
  }

  Future<void> _handleUseFreeze() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await ref
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

  String _formatExpiryTime(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);

    if (difference.inDays > 0) {
      return 'tomorrow';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes}m';
    } else {
      return 'soon';
    }
  }
}
