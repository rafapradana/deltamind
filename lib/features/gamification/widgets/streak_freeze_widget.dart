import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StreakFreezeWidget extends ConsumerWidget {
  final bool compact;

  const StreakFreezeWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationControllerProvider);
    final theme = Theme.of(context);

    // If no streak freeze data available or still loading
    if (gamificationState.isLoading || gamificationState.streakFreeze == null) {
      return const SizedBox();
    }

    final streakFreeze = gamificationState.streakFreeze!;
    final availableFreezes = streakFreeze.availableFreezes;

    // Compact version for use in smaller UI areas
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsFill.snowflake,
              color: Colors.blue.shade700,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              availableFreezes.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // Full version
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsFill.snowflake,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak Freezes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  availableFreezes.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Protect your streak when you miss a day',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.blue.shade900,
            ),
          ),
          
          const SizedBox(height: 8),
          
          if (availableFreezes > 0) ...[
            OutlinedButton.icon(
              onPressed: () => _useStreakFreeze(context, ref),
              icon: Icon(PhosphorIconsFill.snowflake, color: Colors.blue.shade700),
              label: const Text('Use Streak Freeze'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
              ),
            ),
          ] else ...[
            Text(
              'Level up to earn more streak freezes!',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _useStreakFreeze(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Use Streak Freeze?'),
            content: const Text(
              'This will use one streak freeze to protect your streak when you miss a day.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: const Text('Use'),
              ),
            ],
          ),
    );

    if (!(confirm ?? false)) return;

    final result =
        await ref
            .read(gamificationControllerProvider.notifier)
            .useStreakFreeze();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'Streak freeze used successfully!'
                : 'Failed to use streak freeze. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
