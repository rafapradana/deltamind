import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for streak and gamification data
class GamificationState {
  final UserStreak? userStreak;
  final UserLevel? userLevel;
  final StreakFreeze? streakFreeze;
  final List<Achievement> achievements;
  final List<Achievement> earnedAchievements;
  final bool isLoading;
  final String? error;

  GamificationState({
    this.userStreak,
    this.userLevel,
    this.streakFreeze,
    this.achievements = const [],
    this.earnedAchievements = const [],
    this.isLoading = false,
    this.error,
  });

  GamificationState copyWith({
    UserStreak? userStreak,
    UserLevel? userLevel,
    StreakFreeze? streakFreeze,
    List<Achievement>? achievements,
    List<Achievement>? earnedAchievements,
    bool? isLoading,
    String? error,
  }) {
    return GamificationState(
      userStreak: userStreak ?? this.userStreak,
      userLevel: userLevel ?? this.userLevel,
      streakFreeze: streakFreeze ?? this.streakFreeze,
      achievements: achievements ?? this.achievements,
      earnedAchievements: earnedAchievements ?? this.earnedAchievements,
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

  /// Load all gamification data
  Future<void> loadGamificationData() async {
    if (!mounted) return;

    try {
      _safeUpdateState(state.copyWith(isLoading: true, error: null));

      // Load streak data
      final userStreak = await StreakService.getUserStreak();

      // Load user level data
      final userLevel = await StreakService.getUserLevel();

      // Load streak freezes data
      final streakFreeze = await StreakService.getAvailableStreakFreezes();

      // Load achievements
      final achievements = await StreakService.getAchievements();

      // Filter earned achievements
      final earnedAchievements = achievements.where((a) => a.isEarned).toList();

      if (mounted) {
        _safeUpdateState(
          state.copyWith(
            userStreak: userStreak,
            userLevel: userLevel,
            streakFreeze: streakFreeze,
            achievements: achievements,
            earnedAchievements: earnedAchievements,
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading gamification data: $e');

      if (mounted) {
        _safeUpdateState(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  /// Use a streak freeze and refresh the data
  Future<bool> useStreakFreeze() async {
    try {
      final result = await StreakService.useStreakFreeze();

      if (result) {
        // Refresh streak freeze data
        final streakFreeze = await StreakService.getAvailableStreakFreezes();
        if (mounted) {
          _safeUpdateState(state.copyWith(streakFreeze: streakFreeze));
        }
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

    final streakAchievements =
        state.achievements
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
