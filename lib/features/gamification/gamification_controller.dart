import 'package:deltamind/models/daily_quest.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// State class for streak and gamification data
class GamificationState {
  final UserStreak? userStreak;
  final StreakFreeze? streakFreeze;
  final UserLevel? userLevel;
  final List<Achievement> achievements;
  final List<Achievement> earnedAchievements;
  final List<StreakFreezeHistory> freezeHistory;
  final List<DailyQuest> dailyQuests;
  final bool isLoading;
  final String? error;

  GamificationState({
    this.userStreak,
    this.streakFreeze,
    this.userLevel,
    this.achievements = const [],
    this.earnedAchievements = const [],
    this.freezeHistory = const [],
    this.dailyQuests = const [],
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
    List<DailyQuest>? dailyQuests,
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
      dailyQuests: dailyQuests ?? this.dailyQuests,
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

  /// Load gamification data when app is cold started
  void loadOnAppStart() {
    // Check if daily quests need to be refreshed
    _checkAndRefreshDailyQuests();
    
    // Load all gamification data
    Future.microtask(() => loadGamificationData());
  }
  
  /// Check if daily quests need to be refreshed based on last refresh time
  Future<void> _checkAndRefreshDailyQuests() async {
    try {
      // Get the last refresh time from secure storage
      final lastRefreshStr = await const FlutterSecureStorage().read(key: 'last_daily_quest_refresh');
      final now = DateTime.now().toUtc();
      bool needsRefresh = true;
      
      if (lastRefreshStr != null) {
        try {
          final lastRefresh = DateTime.parse(lastRefreshStr);
          final todayMidnight = DateTime.utc(
            now.year, 
            now.month, 
            now.day, 
            0, 0, 0
          );
          
          // If last refresh was after today's midnight UTC, no need to refresh
          if (lastRefresh.isAfter(todayMidnight)) {
            needsRefresh = false;
            debugPrint('Daily quests already refreshed today at ${lastRefresh.toIso8601String()}');
          }
        } catch (e) {
          debugPrint('Error parsing last refresh time: $e');
        }
      }
      
      if (needsRefresh) {
        // Force refresh the daily quests
        await refreshDailyQuests(forceRefresh: true);
        
        // Save the current time as the last refresh time
        await const FlutterSecureStorage().write(
          key: 'last_daily_quest_refresh', 
          value: now.toIso8601String()
        );
        debugPrint('Daily quests refreshed at ${now.toIso8601String()}');
      }
    } catch (e) {
      debugPrint('Error checking daily quests refresh: $e');
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

      // Load daily quests
      final dailyQuests = await StreakService.getDailyQuests();

      // Update state with all data
      state = state.copyWith(
        userStreak: userStreak,
        streakFreeze: streakFreeze,
        userLevel: userLevel,
        achievements: achievements,
        earnedAchievements: earnedAchievements,
        freezeHistory: freezeHistory,
        dailyQuests: dailyQuests,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
      // Update state with error
      state = state.copyWith(isLoading: false);
    }
  }

  /// Load only daily quests data (for refreshing quest progress)
  Future<void> refreshDailyQuests({bool forceRefresh = false}) async {
    try {
      final dailyQuests = await StreakService.getDailyQuests(forceRefresh: forceRefresh);
      state = state.copyWith(dailyQuests: dailyQuests);
    } catch (e) {
      debugPrint('Error refreshing daily quests: $e');
    }
  }

  /// Update progress for a specific quest type
  Future<bool> updateQuestProgress(String questType,
      [int incrementBy = 1]) async {
    try {
      final result =
          await StreakService.updateQuestProgress(questType, incrementBy);

      if (result) {
        // Refresh quests after updating
        await refreshDailyQuests();

        // Also refresh user level data as quest completion grants XP
        final userLevel = await StreakService.getUserLevel();
        state = state.copyWith(userLevel: userLevel);
      }

      return result;
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
      return false;
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

  /// Get the daily quest completion rate
  double get dailyQuestCompletionRate {
    if (state.dailyQuests.isEmpty) return 0.0;

    final completedQuests = state.dailyQuests.where((q) => q.completed).length;
    return completedQuests / state.dailyQuests.length;
  }

  /// Get the total XP that can be earned from current daily quests
  int get totalDailyQuestXP {
    return state.dailyQuests.fold(0, (sum, quest) => sum + quest.xpReward);
  }

  /// Get the total XP earned from completed daily quests
  int get earnedDailyQuestXP {
    return state.dailyQuests
        .where((quest) => quest.completed)
        .fold(0, (sum, quest) => sum + quest.xpReward);
  }
}
