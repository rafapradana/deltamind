import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Model class for user streak information
class UserStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final DateTime? streakStartDate;
  final bool isStreakFreezeActive;
  final DateTime? streakFreezeExpiry;

  UserStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    this.streakStartDate,
    this.isStreakFreezeActive = false,
    this.streakFreezeExpiry,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      userId: json['user_id'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastActivityDate: DateTime.parse(json['last_activity_date']),
      streakStartDate:
          json['streak_start_date'] != null
              ? DateTime.parse(json['streak_start_date'])
              : null,
      isStreakFreezeActive: json['is_streak_freeze_active'] ?? false,
      streakFreezeExpiry:
          json['streak_freeze_expiry'] != null
              ? DateTime.parse(json['streak_freeze_expiry'])
              : null,
    );
  }
}

/// Model class for streak freezes
class StreakFreeze {
  final String userId;
  final int availableFreezes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StreakFreeze({
    required this.userId,
    required this.availableFreezes,
    this.createdAt,
    this.updatedAt,
  });

  factory StreakFreeze.fromJson(Map<String, dynamic> json) {
    return StreakFreeze(
      userId: json['user_id'],
      availableFreezes: json['available_freezes'] ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }
}

/// Model class for achievements
class Achievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final String requirementType;
  final int requirementValue;
  final int xpReward;
  final String? iconName;
  final bool isEarned;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requirementType,
    required this.requirementValue,
    required this.xpReward,
    this.iconName,
    this.isEarned = false,
    this.earnedAt,
  });

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    bool? earned,
    DateTime? earnedDate,
  }) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      requirementType: json['requirement_type'],
      requirementValue: json['requirement_value'],
      xpReward: json['xp_reward'],
      iconName: json['icon_name'],
      isEarned: earned ?? false,
      earnedAt: earnedDate,
    );
  }
}

/// Model class for user level information
class UserLevel {
  final String userId;
  final int currentLevel;
  final int currentXp;
  final int totalXpEarned;
  final int xpNeededForNextLevel;

  UserLevel({
    required this.userId,
    required this.currentLevel,
    required this.currentXp,
    required this.totalXpEarned,
    required this.xpNeededForNextLevel,
  });

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      userId: json['user_id'],
      currentLevel: json['current_level'] ?? 1,
      currentXp: json['current_xp'] ?? 0,
      totalXpEarned: json['total_xp_earned'] ?? 0,
      xpNeededForNextLevel:
          (json['current_level'] ?? 1) * 100, // Same formula as in DB
    );
  }

  /// Get progress percentage towards next level (0.0 to 1.0)
  double get levelProgress {
    return xpNeededForNextLevel > 0
        ? (currentXp / xpNeededForNextLevel).clamp(0.0, 1.0)
        : 0.0;
  }
}

/// Service for managing streaks and achievements
class StreakService {
  /// Get the current user's streak information
  static Future<UserStreak?> getUserStreak() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await SupabaseService.client
              .from('user_streaks')
              .select()
              .eq('user_id', userId)
              .single();

      return UserStreak.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user streak: $e');
      return null;
    }
  }

  /// Get the user's level information
  static Future<UserLevel?> getUserLevel() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await SupabaseService.client
              .from('user_levels')
              .select()
              .eq('user_id', userId)
              .single();

      return UserLevel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user level: $e');
      return null;
    }
  }

  /// Get all available achievements
  static Future<List<Achievement>> getAchievements() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all achievements
      final achievementsResponse =
          await SupabaseService.client.from('achievements').select();

      // Get user's earned achievements
      final userAchievementsResponse = await SupabaseService.client
          .from('user_achievements')
          .select('achievement_id, earned_at')
          .eq('user_id', userId);

      // Convert to a map for easy lookup
      final Map<String, DateTime> earnedAchievements = {};
      for (final item in userAchievementsResponse) {
        earnedAchievements[item['achievement_id']] = DateTime.parse(
          item['earned_at'],
        );
      }

      // Create achievement objects with earned status
      final achievements =
          achievementsResponse.map<Achievement>((json) {
            final achievementId = json['id'];
            final isEarned = earnedAchievements.containsKey(achievementId);
            final earnedAt =
                isEarned ? earnedAchievements[achievementId] : null;

            return Achievement.fromJson(
              json,
              earned: isEarned,
              earnedDate: earnedAt,
            );
          }).toList();

      return achievements;
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  /// Get user's earned achievements only
  static Future<List<Achievement>> getEarnedAchievements() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client
          .from('user_achievements')
          .select('achievements(*), earned_at')
          .eq('user_id', userId);

      return response.map<Achievement>((item) {
        final achievementJson = item['achievements'];
        final earnedAt = DateTime.parse(item['earned_at']);

        return Achievement.fromJson(
          achievementJson,
          earned: true,
          earnedDate: earnedAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting earned achievements: $e');
      return [];
    }
  }

  /// Get the number of available streak freezes for the current user
  static Future<StreakFreeze?> getAvailableStreakFreezes() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await SupabaseService.client
              .from('streak_freezes')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) {
        return StreakFreeze(userId: userId, availableFreezes: 0);
      }

      return StreakFreeze.fromJson(response);
    } catch (e) {
      debugPrint('Error getting streak freezes: $e');
      return null;
    }
  }

  /// Use a streak freeze for the current user
  /// Returns true if successfully used, false if none available or error
  static Future<bool> useStreakFreeze() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client.rpc(
        'use_streak_freeze',
        params: {'user_id_param': userId},
      );

      return response ?? false;
    } catch (e) {
      debugPrint('Error using streak freeze: $e');
      return false;
    }
  }
}
