import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/analytics/analytics_controller.dart';
import 'package:deltamind/features/analytics/widgets/category_performance_chart.dart';
import 'package:deltamind/features/analytics/widgets/daily_streak_graph.dart';
import 'package:deltamind/features/analytics/widgets/quiz_totals_card.dart';
import 'package:deltamind/features/analytics/widgets/streak_analytics_card.dart';
import 'package:deltamind/features/dashboard/widgets/quiz_accuracy_chart.dart';
import 'package:deltamind/features/gamification/widgets/activity_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Analytics page to display charts and insights
class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Delay loading data to avoid modifying provider during build
    Future.microtask(() => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't call _loadData directly, use a microtask to avoid provider errors
    // This delays the operation until after the current build cycle
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(analyticsControllerProvider.notifier).loadAnalyticsData();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Jalankan animasi
    if (!_animationController.isAnimating) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Analytics',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIconsFill.arrowClockwise,
              color: AppColors.primary,
            ),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingView()
              : (analyticsState.errorMessage != null)
              ? _buildErrorView(analyticsState.errorMessage!)
              : _buildAnalyticsView(analyticsState),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading your analytics...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsFill.warning, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(PhosphorIconsFill.arrowClockwise),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView(AnalyticsState state) {
    // Generate sample data for testing if state.dailyActivity is empty
    Map<String, int> activityData = state.dailyActivity;

    // If activity data is empty, add some sample data for demonstration
    if (activityData.isEmpty) {
      final now = DateTime.now();
      for (int i = 0; i < 10; i++) {
        final date = now.subtract(Duration(days: i * 2));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        activityData[dateStr] = (i % 5) + 1; // Varies between 1-5
      }
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quiz Totals Card
            QuizTotalsCard(
              totalCreated: state.totalQuizzesCreated,
              totalCompleted: state.totalQuizzesCompleted,
            ),
            const SizedBox(height: 20),

            // Quiz Accuracy Chart - added at the top
            FutureBuilder<List<Map<String, dynamic>>>(
              future:
                  ref
                      .read(analyticsControllerProvider.notifier)
                      .loadQuizAccuracyData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'Error loading quiz accuracy data: ${snapshot.error}',
                  );
                  // Return chart with empty data
                  return QuizAccuracyChart(accuracyData: []);
                }

                final accuracyData = snapshot.data ?? [];
                return QuizAccuracyChart(accuracyData: accuracyData);
              },
            ),
            const SizedBox(height: 20),

            // Daily Streak Graph
            DailyStreakGraph(streakData: state.streakData),
            const SizedBox(height: 20),

            // Streak analytics
            StreakAnalyticsCard(streakData: state.streakData),
            const SizedBox(height: 20),

            // Only show category performance if we have categories
            if (state.categoryAnalytics.isNotEmpty) ...[
              CategoryPerformanceChart(
                categoryAnalytics: state.categoryAnalytics,
              ),
              const SizedBox(height: 20),
            ],

            // Activity calendar
            ActivityCalendarCard(activityData: activityData),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
