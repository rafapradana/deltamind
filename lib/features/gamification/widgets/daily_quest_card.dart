import 'package:deltamind/models/daily_quest.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DailyQuestCard extends StatelessWidget {
  final DailyQuest quest;
  final VoidCallback? onTap;

  const DailyQuestCard({super.key, required this.quest, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = quest.completed;

    // Set colors based on completion state
    final Color progressColor = completed
        ? const Color(0xFF4CAF50) // Green when completed
        : const Color(0xFF0056D2); // Brand blue for incomplete

    // Get appropriate icon based on quest type
    IconData getIconData() {
      switch (quest.questType) {
        case 'complete_quiz':
          return PhosphorIconsFill.exam;
        case 'write_note':
          return PhosphorIconsFill.notepad;
        case 'review_flashcards':
          return PhosphorIconsFill.cards;
        default:
          return PhosphorIconsFill.list;
      }
    }

    return Card(
      elevation: completed ? 1 : 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: completed
              ? progressColor.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: completed ? 1 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: progressColor.withOpacity(0.1),
        highlightColor: progressColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Quest icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(completed ? 1.0 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        getIconData(),
                        color: completed ? Colors.white : progressColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Quest title and XP reward
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                quest.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: completed
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.85),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: completed
                                    ? Colors.amber.withOpacity(0.2)
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIconsFill.star,
                                    size: 14,
                                    color: completed
                                        ? Colors.amber
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${quest.xpReward} XP',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: completed
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: completed
                                          ? Colors.amber.shade800
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          quest.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              Stack(
                children: [
                  // Background track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: quest.progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: completed
                            ? [
                                BoxShadow(
                                  color: progressColor.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Status footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress text
                  Text(
                    '${quest.progressText} completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  // Status or time remaining
                  Row(
                    children: [
                      Icon(
                        completed
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsFill.clock,
                        size: 14,
                        color: completed
                            ? Colors.green
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        completed ? 'Completed' : quest.timeRemainingText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              completed ? FontWeight.w600 : FontWeight.w400,
                          color: completed
                              ? Colors.green
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
