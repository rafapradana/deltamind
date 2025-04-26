import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dashboard page
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Quiz> _recentQuizzes = [];
  Map<String, dynamic> _quizHistoryStats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load dashboard data
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get recent quizzes
      final quizzes = await QuizService.getUserQuizzes();
      _recentQuizzes = quizzes.take(5).toList();

      // Get quiz history statistics
      _quizHistoryStats = await SupabaseService.getStatistics();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createQuiz),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build the main body of the dashboard
  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            _buildWelcomeCard(context),
            const SizedBox(height: 24),
            
            // Quiz history stats
            _buildHistoryStats(),
            const SizedBox(height: 24),
            
            // Recent quizzes
            Text(
              'Recent Quizzes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _recentQuizzes.isEmpty
                ? _buildEmptyQuizzes()
                : _buildRecentQuizzes(),
            const SizedBox(height: 32),
            
            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 100), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  /// Build welcome card
  Widget _buildWelcomeCard(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome back, ${user?.email?.split('@').first ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to train your brain today?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.createQuiz),
              child: const Text('Create New Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quiz history statistics
  Widget _buildHistoryStats() {
    final totalQuizzes = _quizHistoryStats['totalQuizzes'] ?? 0;
    final completedToday = _quizHistoryStats['completedToday'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Quizzes',
                      totalQuizzes.toString(),
                      Icons.list,
                    ),
                    _buildStatItem(
                      'Completed Today',
                      completedToday.toString(),
                      Icons.check,
                    ),
                    _buildStatItem(
                      'This Week',
                      (_quizHistoryStats['weekly'] ?? 0).toString(),
                      Icons.calendar_today,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: completedToday > 0
                      ? () {
                          context.push(AppRoutes.history);
                        }
                      : null,
                  child: Text(
                    completedToday > 0
                        ? 'Review $completedToday Quizzes'
                        : 'No Quizzes Completed',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build a statistic item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build recent quizzes list
  Widget _buildRecentQuizzes() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _recentQuizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(quiz.title),
            subtitle: Text(
              'Type: ${quiz.quizType} • Difficulty: ${quiz.difficulty}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to quiz details page
              context.go('/quiz/${quiz.id}');
            },
          ),
        );
      },
    );
  }

  /// Build empty quizzes message
  Widget _buildEmptyQuizzes() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No quizzes created yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.createQuiz),
              child: const Text('Create Your First Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick actions
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickAction(
          'Create Quiz',
          Icons.add_circle,
          AppColors.primary,
          () => context.push(AppRoutes.createQuiz),
        ),
        _buildQuickAction(
          'Browse Quizzes',
          Icons.list,
          AppColors.secondary,
          () => context.push(AppRoutes.quizList),
        ),
        _buildQuickAction(
          'My Profile',
          Icons.person,
          AppColors.accent,
          () => context.push(AppRoutes.profile),
        ),
      ],
    );
  }

  /// Build quick action button
  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
} 