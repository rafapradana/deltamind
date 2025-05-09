import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/features/gamification/widgets/daily_quest_card.dart';
import 'package:deltamind/models/daily_quest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DailyQuestsSection extends ConsumerWidget {
  const DailyQuestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationControllerProvider);
    final dailyQuests = gamificationState.dailyQuests;
    final theme = Theme.of(context);

    // Calculate overall completion
    final completionRate = ref
        .read(gamificationControllerProvider.notifier)
        .dailyQuestCompletionRate;
    final earnedXP =
        ref.read(gamificationControllerProvider.notifier).earnedDailyQuestXP;
    final totalXP =
        ref.read(gamificationControllerProvider.notifier).totalDailyQuestXP;

    if (dailyQuests.isEmpty) {
      // Show empty state with a retry option
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Daily Quests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Icon(
                PhosphorIconsFill.clipboard,
                size: 50,
                color: Color(0xFFDDDDDD),
              ),
              const SizedBox(height: 16),
              Text(
                'No quests available right now',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Come back tomorrow for new quests',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Reload gamification data to try loading quests again
                  ref
                      .read(gamificationControllerProvider.notifier)
                      .loadGamificationData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Row(
            children: [
              const Icon(
                PhosphorIconsFill.trophy,
                size: 20,
                color: Color(0xFF0056D2), // Brand blue
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Quests',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000), // Brand black
                ),
              ),
              const Spacer(),

              // XP summary
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsFill.star,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$earnedXP/$totalXP XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Overall progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0056D2).withOpacity(0.9), // Brand blue
                const Color(0xFF33A1FD).withOpacity(0.9), // Light blue
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF33A1FD).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Progress circle
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: completionRate,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 8,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(completionRate * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dailyQuests.where((q) => q.completed).length} of ${dailyQuests.length} quests completed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          completionRate >= 1.0
                              ? 'All quests completed today!'
                              : 'Complete quests to earn XP',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
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

        // Quest cards
        ...dailyQuests
            .map((quest) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DailyQuestCard(
                    quest: quest,
                    onTap: () => _handleQuestTap(context, quest, ref),
                  ),
                ))
            .toList(),
      ],
    );
  }

  void _handleQuestTap(BuildContext context, DailyQuest quest, WidgetRef ref) {
    if (quest.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quest already completed!')),
      );
      return;
    }

    // Show quest details or relevant action
    final questAction = _getQuestAction(quest.questType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quest.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quest.description),
            const SizedBox(height: 16),
            Text('Progress: ${quest.progressText}'),
            const SizedBox(height: 8),
            Text('Reward: +${quest.xpReward} XP'),
            const SizedBox(height: 16),
            Text('Go to ${questAction.name} to make progress on this quest.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to the relevant feature
              // This is just a placeholder - actual navigation would depend on your app's routing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navigating to ${questAction.name}')),
              );
            },
            child: Text('Go to ${questAction.name}'),
          ),
        ],
      ),
    );
  }

  _QuestAction _getQuestAction(String questType) {
    switch (questType) {
      case 'complete_quiz':
        return _QuestAction('Quizzes', PhosphorIconsFill.exam);
      case 'write_note':
        return _QuestAction('Notes', PhosphorIconsFill.notepad);
      case 'review_flashcards':
        return _QuestAction('Flashcards', PhosphorIconsFill.cards);
      default:
        return _QuestAction('Dashboard', PhosphorIconsFill.house);
    }
  }
}

class _QuestAction {
  final String name;
  final IconData icon;

  _QuestAction(this.name, this.icon);
}
