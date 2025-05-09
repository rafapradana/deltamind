import 'package:flutter/foundation.dart';

/// Model class for daily quests
class DailyQuest {
  final String id;
  final String userId;
  final String questType;
  final int targetCount;
  final int currentCount;
  final bool completed;
  final int xpReward;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime resetAt;

  DailyQuest({
    required this.id,
    required this.userId,
    required this.questType,
    required this.targetCount,
    required this.currentCount,
    required this.completed,
    required this.xpReward,
    required this.createdAt,
    required this.updatedAt,
    required this.resetAt,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'],
      userId: json['user_id'],
      questType: json['quest_type'],
      targetCount: json['target_count'] ?? 1,
      currentCount: json['current_count'] ?? 0,
      completed: json['completed'] ?? false,
      xpReward: json['xp_reward'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      resetAt: json['reset_at'] != null
          ? DateTime.parse(json['reset_at'])
          : DateTime.now().add(const Duration(days: 1)),
    );
  }

  // Convert the quest type to a readable title
  String get title {
    switch (questType) {
      case 'complete_quiz':
        return 'Complete Quizzes';
      case 'write_note':
        return 'Write Notes';
      case 'review_flashcards':
        return 'Review Flashcards';
      default:
        return 'Unknown Quest';
    }
  }

  // Get a description for the quest
  String get description {
    switch (questType) {
      case 'complete_quiz':
        return 'Complete $targetCount quizzes today';
      case 'write_note':
        return 'Write $targetCount new note${targetCount > 1 ? 's' : ''} today';
      case 'review_flashcards':
        return 'Review $targetCount flashcards today';
      default:
        return 'Complete this quest to earn XP';
    }
  }

  // Get progress percentage
  double get progress {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  // Get progress as a string
  String get progressText {
    return '$currentCount/$targetCount';
  }

  // Convert quest type to icon data (to be used in the UI)
  String get iconName {
    switch (questType) {
      case 'complete_quiz':
        return 'quiz';
      case 'write_note':
        return 'note';
      case 'review_flashcards':
        return 'cards';
      default:
        return 'task';
    }
  }

  // Get time remaining until reset
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(resetAt)) return Duration.zero;
    return resetAt.difference(now);
  }

  // Format time remaining as a string
  String get timeRemainingText {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    if (hours <= 0 && minutes <= 0) {
      return 'Resetting soon';
    }

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} left';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''} left';
    }
  }

  @override
  String toString() {
    return 'DailyQuest(id: $id, questType: $questType, progress: $progressText, completed: $completed)';
  }
}
