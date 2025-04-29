import 'package:deltamind/services/analytics_service.dart';
import 'package:deltamind/services/streak_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics state with loading indicators and data
class AnalyticsState {
  final bool isLoading;
  final String? errorMessage;
  final QuizAnalytics overallAnalytics;
  final List<QuizAnalytics> categoryAnalytics;
  final Map<String, dynamic> streakData;
  final Map<String, int> dailyActivity;
  final List<Map<String, dynamic>> recentPerformance;
  final int totalQuizzesCreated;
  final int totalQuizzesCompleted;

  AnalyticsState({
    this.isLoading = true,
    this.errorMessage,
    QuizAnalytics? overallAnalytics,
    this.categoryAnalytics = const [],
    this.streakData = const {},
    this.dailyActivity = const {},
    this.recentPerformance = const [],
    this.totalQuizzesCreated = 0,
    this.totalQuizzesCompleted = 0,
  }) : overallAnalytics =
           overallAnalytics ??
           QuizAnalytics(
             userId: 'unknown',
             totalAttempts: 0,
             totalCorrectAnswers: 0,
             totalQuestionsAttempted: 0,
             averageScore: 0,
           );

  /// Creates a copy of the state with specified fields updated
  AnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    QuizAnalytics? overallAnalytics,
    List<QuizAnalytics>? categoryAnalytics,
    Map<String, dynamic>? streakData,
    Map<String, int>? dailyActivity,
    List<Map<String, dynamic>>? recentPerformance,
    int? totalQuizzesCreated,
    int? totalQuizzesCompleted,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      overallAnalytics: overallAnalytics ?? this.overallAnalytics,
      categoryAnalytics: categoryAnalytics ?? this.categoryAnalytics,
      streakData: streakData ?? this.streakData,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      recentPerformance: recentPerformance ?? this.recentPerformance,
      totalQuizzesCreated: totalQuizzesCreated ?? this.totalQuizzesCreated,
      totalQuizzesCompleted:
          totalQuizzesCompleted ?? this.totalQuizzesCompleted,
    );
  }
}

/// Analytics controller to load and manage analytics data
class AnalyticsController extends StateNotifier<AnalyticsState> {
  AnalyticsController() : super(AnalyticsState()) {
    loadAnalyticsData();
  }

  /// Load all analytics data
  Future<void> loadAnalyticsData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Load data in parallel for better performance
      final overallFuture = AnalyticsService.getOverallQuizAnalytics();
      final categoryFuture = AnalyticsService.getQuizAnalyticsByCategory();
      final streakFuture = AnalyticsService.getStreakAnalytics();
      final activityFuture = AnalyticsService.getDailyActivityAnalytics();
      final performanceFuture =
          AnalyticsService.getRecentPerformanceByCategory();
      final quizzesCreatedFuture = AnalyticsService.getTotalQuizzesCreated();
      final quizzesCompletedFuture =
          AnalyticsService.getTotalQuizzesCompleted();

      // Wait for all data to be loaded
      final results = await Future.wait([
        overallFuture,
        categoryFuture,
        streakFuture,
        activityFuture,
        performanceFuture,
        quizzesCreatedFuture,
        quizzesCompletedFuture,
      ]);

      // Update state with loaded data
      state = state.copyWith(
        isLoading: false,
        overallAnalytics: results[0] as QuizAnalytics,
        categoryAnalytics: results[1] as List<QuizAnalytics>,
        streakData: results[2] as Map<String, dynamic>,
        dailyActivity: results[3] as Map<String, int>,
        recentPerformance: results[4] as List<Map<String, dynamic>>,
        totalQuizzesCreated: results[5] as int,
        totalQuizzesCompleted: results[6] as int,
      );
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load analytics data: $e',
      );
    }
  }

  /// Get the most improved category
  String? getMostImprovedCategory() {
    if (state.recentPerformance.isEmpty) return null;

    final categoryPerformance = <String, List<double>>{};

    // Group performance data by category
    for (final performance in state.recentPerformance) {
      final categoryName = performance['category_name'] as String? ?? 'Unknown';
      final percentageCorrect =
          (performance['percentage_correct'] as num?)?.toDouble() ?? 0.0;

      if (!categoryPerformance.containsKey(categoryName)) {
        categoryPerformance[categoryName] = [];
      }
      categoryPerformance[categoryName]!.add(percentageCorrect);
    }

    // Calculate improvement (compare first and last attempt for each category)
    String? mostImprovedCategory;
    double maxImprovement = 0.0;

    categoryPerformance.forEach((category, scores) {
      if (scores.length >= 2) {
        // Compare oldest to newest score
        final oldestScore = scores.last;
        final newestScore = scores.first;
        final improvement = newestScore - oldestScore;

        if (improvement > maxImprovement) {
          maxImprovement = improvement;
          mostImprovedCategory = category;
        }
      }
    });

    return mostImprovedCategory;
  }

  /// Get the weakest category based on performance
  String? getWeakestCategory() {
    if (state.categoryAnalytics.isEmpty) {
      return null;
    }

    return state.overallAnalytics.weakestCategoryName;
  }

  /// Get the strongest category based on performance
  String? getStrongestCategory() {
    if (state.categoryAnalytics.isEmpty) {
      return null;
    }

    return state.overallAnalytics.strongestCategoryName;
  }

  /// Get study consistency percentage (days active in last 30 days)
  double getStudyConsistency() {
    if (state.dailyActivity.isEmpty) return 0.0;

    // Calculate percentage of days with activity in the last 30 days
    return (state.dailyActivity.length / 30) * 100;
  }

  /// Load quiz accuracy data for the chart
  Future<List<Map<String, dynamic>>> loadQuizAccuracyData() async {
    try {
      return await AnalyticsService.getQuizAccuracyData();
    } catch (e) {
      debugPrint('Error loading quiz accuracy data: $e');
      return [];
    }
  }
}

/// Provider for analytics state
final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
      return AnalyticsController();
    });
