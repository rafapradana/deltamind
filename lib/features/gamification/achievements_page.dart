import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/core/theme/app_colors.dart';
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

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _flameAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load achievements data when page is opened
    Future.microtask(() {
      ref.read(gamificationControllerProvider.notifier).loadGamificationData();
    });

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFFFFFFF), // Brand white
      body: SafeArea(
        child:
            gamificationState.isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0056D2)),
                ) // Brand blue
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Clean, modern app bar
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        backgroundColor: const Color(0xFFFFFFFF), // Brand white
                        elevation: 0,
                        leadingWidth: 60,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0x3333A1FD,
                              ), // Light blue with opacity
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                PhosphorIconsFill.trophy,
                                color: Color(0xFF0056D2), // Brand blue
                              ),
                              onPressed: null,
                            ),
                          ),
                        ),
                        title: Text(
                          'Achievements',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: 'Inter', // Brand font
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0056D2), // Brand blue
                          ),
                        ),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0x3333A1FD,
                                ), // Light blue with opacity
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: Color(0xFF0056D2), // Brand blue
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Main content
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // User Level Display with XP Progress
                            if (gamificationState.userLevel != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0056D2), // Brand blue
                                      Color(0xFF33A1FD), // Light blue
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(
                                        0x6633A1FD,
                                      ), // Light blue with opacity
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Level Circle
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${gamificationState.userLevel!.currentLevel}',
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Inter', // Brand font
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Level ${gamificationState.userLevel!.currentLevel}',
                                                style: const TextStyle(
                                                  fontFamily:
                                                      'Inter', // Brand font
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Total XP: ${gamificationState.userLevel!.totalXpEarned}',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Inter', // Brand font
                                                  fontSize: 14,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // XP Progress bar
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${gamificationState.userLevel!.currentXp} / ${gamificationState.userLevel!.xpNeededForNextLevel} XP',
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Inter', // Brand font
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Next: Level ${gamificationState.userLevel!.currentLevel + 1}',
                                              style: TextStyle(
                                                fontFamily:
                                                    'Inter', // Brand font
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Stack(
                                          children: [
                                            // Background track
                                            Container(
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            // Progress fill
                                            FractionallySizedBox(
                                              widthFactor:
                                                  gamificationState
                                                      .userLevel!
                                                      .levelProgress,
                                              child: Container(
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // Streak Card
                            if (gamificationState.userStreak != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: StreakCard(
                                  streak: gamificationState.userStreak!,
                                  streakFreeze: gamificationState.streakFreeze,
                                  isDetailed: true,
                                ),
                              ),

                            // Progress summary with improved design
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF), // Brand white
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4A4A4A).withOpacity(
                                      0.1,
                                    ), // Brand gray with opacity
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0x3333A1FD,
                                          ), // Light blue with opacity
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          PhosphorIconsFill.chartBar,
                                          color: Color(
                                            0xFF0056D2,
                                          ), // Brand blue
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Your Progress',
                                        style: TextStyle(
                                          fontFamily: 'Inter', // Brand font
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(
                                            0xFF000000,
                                          ), // Brand black
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontFamily: 'Inter', // Brand font
                                        fontSize: 14,
                                        color: Color(0xFF4A4A4A), // Brand gray
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: 'You have completed ',
                                        ),
                                        TextSpan(
                                          text:
                                              '${gamificationState.earnedAchievements.length}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(
                                              0xFF0056D2,
                                            ), // Brand blue
                                          ),
                                        ),
                                        const TextSpan(text: ' out of '),
                                        TextSpan(
                                          text:
                                              '${gamificationState.achievements.length}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(
                                              0xFF000000,
                                            ), // Brand black
                                          ),
                                        ),
                                        const TextSpan(text: ' achievements.'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Stack(
                                    children: [
                                      // Background track
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0x3333A1FD,
                                          ), // Light blue with opacity
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      // Progress fill
                                      FractionallySizedBox(
                                        widthFactor:
                                            gamificationState
                                                    .earnedAchievements
                                                    .isEmpty
                                                ? 0.0
                                                : gamificationState
                                                        .earnedAchievements
                                                        .length /
                                                    gamificationState
                                                        .achievements
                                                        .length,
                                        child: Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF0056D2,
                                            ), // Brand blue
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${((gamificationState.earnedAchievements.length / gamificationState.achievements.length) * 100).toInt()}% complete',
                                      style: const TextStyle(
                                        fontFamily: 'Inter', // Brand font
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0056D2), // Brand blue
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Category filter section
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Categories',
                                style: TextStyle(
                                  fontFamily: 'Inter', // Brand font
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000), // Brand black
                                ),
                              ),
                            ),

                            // Category filter chips with improved design
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: const Text('All'),
                                      selected: _selectedCategory == 'All',
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = 'All';
                                        });
                                      },
                                      backgroundColor: const Color(
                                        0xFFFFFFFF,
                                      ), // Brand white
                                      selectedColor: const Color(
                                        0x3333A1FD,
                                      ), // Light blue with opacity
                                      checkmarkColor: const Color(
                                        0xFF0056D2,
                                      ), // Brand blue
                                      labelStyle: TextStyle(
                                        fontFamily: 'Inter', // Brand font
                                        color:
                                            _selectedCategory == 'All'
                                                ? const Color(0xFF0056D2)
                                                : const Color(
                                                  0xFF4A4A4A,
                                                ), // Brand blue or gray
                                        fontWeight:
                                            _selectedCategory == 'All'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color:
                                              _selectedCategory == 'All'
                                                  ? const Color(0xFF0056D2)
                                                  : const Color(
                                                    0xFF4A4A4A,
                                                  ).withOpacity(
                                                    0.3,
                                                  ), // Brand blue or gray
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                  // Safely handle categories from constants
                                  if (AppConstants
                                      .achievementCategories
                                      .isNotEmpty)
                                    ...AppConstants.achievementCategories
                                        .where(
                                          (category) =>
                                              category != 'All' &&
                                              category.isNotEmpty,
                                        )
                                        .map((category) {
                                          final isSelected =
                                              _selectedCategory == category;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: FilterChip(
                                              label: Text(category),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                setState(() {
                                                  _selectedCategory = category;
                                                });
                                              },
                                              backgroundColor: const Color(
                                                0xFFFFFFFF,
                                              ), // Brand white
                                              selectedColor: const Color(
                                                0x3333A1FD,
                                              ), // Light blue with opacity
                                              checkmarkColor: const Color(
                                                0xFF0056D2,
                                              ), // Brand blue
                                              labelStyle: TextStyle(
                                                fontFamily:
                                                    'Inter', // Brand font
                                                color:
                                                    isSelected
                                                        ? const Color(
                                                          0xFF0056D2,
                                                        )
                                                        : const Color(
                                                          0xFF4A4A4A,
                                                        ), // Brand blue or gray
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFF0056D2,
                                                          )
                                                          : const Color(
                                                            0xFF4A4A4A,
                                                          ).withOpacity(
                                                            0.3,
                                                          ), // Brand blue or gray
                                                  width: 1,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),

                      // Achievements list
                      if (gamificationState.achievements.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIconsFill.trophy,
                                    size: 50,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Loading achievements...',
                                    style: TextStyle(
                                      fontFamily: 'Inter', // Brand font
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000000), // Brand black
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (filteredAchievements.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIconsFill.trophy,
                                    size: 50,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No achievements found',
                                    style: TextStyle(
                                      fontFamily: 'Inter', // Brand font
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000000), // Brand black
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedCategory != 'All'
                                        ? 'Try selecting a different category'
                                        : 'Complete quizzes to unlock achievements',
                                    style: TextStyle(
                                      fontFamily: 'Inter', // Brand font
                                      fontSize: 14,
                                      color: Color(0xFF4A4A4A), // Brand gray
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategory = 'All';
                                      });
                                    },
                                    icon: const Icon(
                                      PhosphorIconsFill.listBullets,
                                      size: 16,
                                    ),
                                    label: const Text('Show all achievements'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF0056D2,
                                      ), // Brand blue
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                          sliver: SliverAnimatedList(
                            initialItemCount: filteredAchievements.length,
                            itemBuilder: (context, index, animation) {
                              // Guard against index out of range errors
                              if (index >= filteredAchievements.length) {
                                return const SizedBox.shrink();
                              }

                              final achievement = filteredAchievements[index];

                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.5, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutQuart,
                                  ),
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AchievementCard(
                                      achievement: achievement,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  // Helper function to get color for streak
  Color _getStreakColor(int streakDays) {
    if (streakDays >= 30) {
      return Colors.deepPurple;
    } else if (streakDays >= 14) {
      return Colors.deepOrange;
    } else if (streakDays >= 7) {
      return Colors.orange;
    } else if (streakDays >= 3) {
      return Colors.amber;
    } else {
      return Colors.grey.shade600;
    }
  }

  // Helper function to get color for category
  Color _getCategoryColor(String category) {
    // Default fallback color
    const Color defaultColor = Color(0xFF4A4A4A); // Brand gray

    try {
      switch (category) {
        case 'All':
          return const Color(0xFF33A1FD); // Light blue
        case 'Beginner':
          return const Color(0xFF0056D2); // Brand blue
        case 'Intermediate':
          return const Color(0xFF4A4A4A); // Brand gray
        case 'Advanced':
          return const Color(0xFF000000); // Brand black
        case 'Streak':
          return Colors.orange; // Keep as is for streak
        case 'Performance':
          return const Color(0xFF33A1FD); // Light blue
        case 'Creation':
          return const Color(0xFF0056D2); // Brand blue
        default:
          return defaultColor;
      }
    } catch (e) {
      debugPrint('Error getting category color: $e');
      return defaultColor;
    }
  }
}
