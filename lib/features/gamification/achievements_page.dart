import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/features/gamification/widgets/achievement_card.dart';
import 'package:deltamind/features/gamification/widgets/streak_card.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Load achievements data when page is opened
    Future.microtask(() {
      ref.read(gamificationControllerProvider.notifier).loadGamificationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gamificationState = ref.watch(gamificationControllerProvider);
    final theme = Theme.of(context);

    // Get next streak achievement
    final nextStreakAchievement =
        ref
            .read(gamificationControllerProvider.notifier)
            .getNextStreakAchievement();

    // Filter achievements by selected category
    final filteredAchievements =
        gamificationState.achievements.where((achievement) {
          if (_selectedCategory == 'All') {
            return true;
          }
          return achievement.category == _selectedCategory;
        }).toList();

    // Sort achievements: earned first, then by name
    filteredAchievements.sort((a, b) {
      if (a.isEarned && !b.isEarned) return -1;
      if (!a.isEarned && b.isEarned) return 1;
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsFill.trophy),
            onPressed: () {
              // Refresh achievements
              ref
                  .read(gamificationControllerProvider.notifier)
                  .loadGamificationData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(gamificationControllerProvider.notifier)
              .loadGamificationData();
        },
        child:
            gamificationState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Streak card
                    if (gamificationState.userStreak != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: StreakCard(
                          streak: gamificationState.userStreak!,
                          level: gamificationState.userLevel,
                          nextAchievement: nextStreakAchievement,
                        ),
                      ),

                    // Category filter chips
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: AppConstants.achievementCategories.length,
                        itemBuilder: (context, index) {
                          final category =
                              AppConstants.achievementCategories[index];
                          final isSelected = _selectedCategory == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              backgroundColor: theme.colorScheme.surface,
                              selectedColor: theme.colorScheme.primaryContainer,
                              checkmarkColor: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),

                    // Achievements stats
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            'Earned: ${gamificationState.earnedAchievements.length}/${gamificationState.achievements.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (gamificationState.userLevel != null)
                            Text(
                              'Total XP: ${gamificationState.userLevel!.totalXpEarned}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Achievements list
                    Expanded(
                      child:
                          filteredAchievements.isEmpty
                              ? Center(
                                child: Text(
                                  'No achievements in this category yet.',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredAchievements.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: AchievementCard(
                                      achievement: filteredAchievements[index],
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
