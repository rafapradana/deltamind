import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for streak and gamification data
class GamificationState {
  final UserStreak? userStreak;
  final StreakFreeze? streakFreeze;
  final UserLevel? userLevel;
  final List<Achievement> achievements;
  final List<Achievement> earnedAchievements;
  final List<StreakFreezeHistory> freezeHistory;
  final bool isLoading;
  final String? error;

  GamificationState({
    this.userStreak,
    this.streakFreeze,
    this.userLevel,
    this.achievements = const [],
    this.earnedAchievements = const [],
    this.freezeHistory = const [],
    this.isLoading = false,
    this.error,
  });

  GamificationState copyWith({
    UserStreak? userStreak,
    StreakFreeze? streakFreeze,
    UserLevel? userLevel,
    List<Achievement>? achievements,
    List<Achievement>? earnedAchievements,
    List<StreakFreezeHistory>? freezeHistory,
    bool? isLoading,
    String? error,
  }) {
    return GamificationState(
      userStreak: userStreak ?? this.userStreak,
      streakFreeze: streakFreeze ?? this.streakFreeze,
      userLevel: userLevel ?? this.userLevel,
      achievements: achievements ?? this.achievements,
      earnedAchievements: earnedAchievements ?? this.earnedAchievements,
      freezeHistory: freezeHistory ?? this.freezeHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for gamification controller
final gamificationControllerProvider =
    StateNotifierProvider<GamificationController, GamificationState>((ref) {
  return GamificationController();
});

/// Controller for managing streaks and achievements
class GamificationController extends StateNotifier<GamificationState> {
  GamificationController() : super(GamificationState());

  /// Safe state update method to prevent errors during widget building
  void _safeUpdateState(GamificationState newState) {
    if (mounted) {
      try {
        state = newState;
      } catch (e) {
        debugPrint('Error updating gamification state: $e');
      }
    }
  }

  /// Load all gamification data for the current user
  Future<void> loadGamificationData() async {
    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      // Load user streak data
      final userStreak = await StreakService.getUserStreak();

      // Load streak freezes
      final streakFreeze = await StreakService.getUserStreakFreezes();

      // Load user level data
      final userLevel = await StreakService.getUserLevel();

      // Load achievements
      final achievements = await StreakService.getAchievements();
      final earnedAchievements = achievements.where((a) => a.isEarned).toList();

      // Load streak freeze history
      final freezeHistory = await StreakService.getStreakFreezeHistory();

      // Update state with all data
      state = state.copyWith(
        userStreak: userStreak,
        streakFreeze: streakFreeze,
        userLevel: userLevel,
        achievements: achievements,
        earnedAchievements: earnedAchievements,
        freezeHistory: freezeHistory,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
      // Update state with error
      state = state.copyWith(isLoading: false);
    }
  }

  /// Use a streak freeze and refresh the data
  Future<bool> useStreakFreeze() async {
    try {
      final result = await StreakService.useStreakFreeze();

      if (result) {
        // Refresh all relevant data
        await loadGamificationData();
      }

      return result;
    } catch (e) {
      debugPrint('Error using streak freeze: $e');
      return false;
    }
  }

  /// Check if a streak achievement has been earned
  bool hasEarnedStreakAchievement(int days) {
    final streakAchievements = state.earnedAchievements.where(
      (a) => a.requirementType == 'streak_days' && a.requirementValue == days,
    );

    return streakAchievements.isNotEmpty;
  }

  /// Get next streak achievement to earn
  Achievement? getNextStreakAchievement() {
    if (state.userStreak == null) return null;

    final currentStreak = state.userStreak!.currentStreak;

    final streakAchievements = state.achievements
        .where((a) => a.requirementType == 'streak_days')
        .toList()
      ..sort((a, b) => a.requirementValue.compareTo(b.requirementValue));

    for (final achievement in streakAchievements) {
      if (achievement.requirementValue > currentStreak &&
          !achievement.isEarned) {
        return achievement;
      }
    }

    return null;
  }

  /// Get recently earned achievements (last 7 days)
  List<Achievement> getRecentAchievements() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return state.earnedAchievements
        .where((a) => a.earnedAt != null && a.earnedAt!.isAfter(sevenDaysAgo))
        .toList()
      ..sort((a, b) => b.earnedAt!.compareTo(a.earnedAt!));
  }
}
