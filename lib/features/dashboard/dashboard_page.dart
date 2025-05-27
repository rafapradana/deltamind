import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/features/dashboard/profile_avatar.dart';
import 'package:deltamind/features/gamification/gamification_controller.dart';
import 'package:deltamind/features/gamification/widgets/dashboard_streak_summary.dart';
import 'package:deltamind/features/search/search_bar_widget.dart';
import 'package:deltamind/models/learning_path.dart';
import 'package:deltamind/services/learning_path_service.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Dashboard page
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Quiz> _recentQuizzes = [];
  Map<String, dynamic> _quizHistoryStats = {};
  LearningPath? _activePath;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadDashboardData();

    // Also load gamification data
    Future.microtask(() {
      ref.read(gamificationControllerProvider.notifier).loadGamificationData();
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

      // Get active learning path
      try {
        _activePath = await LearningPathService.getActiveLearningPath();
      } catch (e) {
        // Ignore errors with learning path, it's not critical
        debugPrint('Error loading active learning path: $e');
      }

      // Show success notification for refreshes (not initial load)
      if (!_animationController.isAnimating && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dashboard refreshed'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');

      // Show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing dashboard: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // App bar with safer height and better accessibility
                      SliverAppBar(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        toolbarHeight: 60.0, // Reduced from 70.0
                        pinned: true,
                        elevation: 0,
                        centerTitle: false,
                        title: Text(
                          'DeltaMind',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0, // Smaller font size
                              ),
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(PhosphorIconsFill.arrowClockwise),
                            onPressed: _loadDashboardData,
                            tooltip: 'Refresh',
                          ),
                          const ProfileAvatar(),
                        ],
                      ),

                      // Main content
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 8),

                            // Global search bar
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: GlobalSearchBar(),
                            ),

                            // Welcome message in a card
                            _buildWelcomeCard(user),
                            const SizedBox(height: 16),

                            // Streak summary with animation
                            const DashboardStreakSummary(),
                            const SizedBox(height: 16),

                            // Learning Path card (if available)
                            if (_activePath != null) ...[
                              _buildLearningPathCard(),
                              const SizedBox(height: 16),
                            ] else ...[
                              _buildLearningPathsCard(),
                              const SizedBox(height: 16),
                            ],

                            // Analytics card
                            _buildAnalyticsCard(),
                            const SizedBox(height: 16),

                            // Recent quizzes with visual enhancements
                            _buildRecentQuizzesSection(),
                            const SizedBox(height: 80), // Extra space for FAB
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createQuiz),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      // Remove duplicated bottom navigation bar - use only the one from ScaffoldWithNavBar
    );
  }

  /// Build welcome message in a card
  Widget _buildWelcomeCard(user) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>?>( // <--- Modified this line
      future: user != null ? SupabaseService.getUserProfile(user.id) : null, // <--- Modified this line
      builder: (context, snapshot) {
        // Get username from profile or fallback to email
        String displayName = 'User';
        
        if (snapshot.hasData && snapshot.data != null) {
          // Use username from profile
          displayName = snapshot.data!['username'] ?? 'User';
        } else if (user?.email != null) {
          // Fallback to email-based name if profile not loaded yet
          displayName = user!.email.split('@').first;
        }
        
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.withOpacity(
                  0.05), // Light blue with low opacity instead of gradient
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      radius: 20,
                      child: Icon(
                        PhosphorIconsFill.brain,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: 'Welcome back, '),
                            TextSpan(
                              text: displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ready to train your mind today?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.quizList),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Start a Quiz'),
                ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.learningPaths),
                        icon: Icon(
                          PhosphorIconsFill.roadHorizon,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text('Learning Paths'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build learning path card (for active path)
  Widget _buildLearningPathCard() {
    if (_activePath == null) return const SizedBox();

    final path = _activePath!;

    // Find the first in-progress module if any
    final inProgressModule = path.modules.firstWhere(
      (module) => module.status == ModuleStatus.inProgress,
      orElse: () => path.modules.isNotEmpty
          ? path.modules.first
          : LearningPathModule(
              pathId: path.id,
              title: 'No modules available',
              description: 'This path has no modules.',
              moduleId: '0',
              position: 0,
            ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => context.push('/learning-paths/${path.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsFill.roadHorizon,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Path',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          path.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        '${path.progress}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: path.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      path.progress >= 100 ? Colors.green : AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),

            // Current module
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Module',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            PhosphorIconsFill.caretRight,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Module ${inProgressModule.moduleId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                inProgressModule.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIconsFill.caretRight,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a card to access Learning Paths when no active path exists
  Widget _buildLearningPathsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.learningPaths),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIconsFill.roadHorizon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Paths',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Generate AI learning paths for any topic',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsFill.arrowRight,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build analytics card
  Widget _buildAnalyticsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.analytics),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIconsFill.chartLine,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Learning Analytics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Icon(
                PhosphorIconsFill.arrowRight,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build recent quizzes section
  Widget _buildRecentQuizzesSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Recent Quizzes',
            style: theme.textTheme.bodyLarge?.copyWith(
              // Reduced from titleSmall
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _recentQuizzes.isEmpty
            ? _buildEmptyState(
                'No quizzes yet',
                'Create your first quiz to get started',
                PhosphorIconsFill.clipboard,
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _recentQuizzes.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final quiz = _recentQuizzes[index];
                  return _buildQuizItem(quiz, index);
                },
              ),
      ],
    );
  }

  /// Build empty state placeholder
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build quiz item card with theme-consistent colors
  Widget _buildQuizItem(Quiz quiz, int index) {
    final theme = Theme.of(context);

    // Use app theme colors
    final bgColors = [
      AppColors.primary.withOpacity(0.05),
      AppColors.primary.withOpacity(0.08),
      AppColors.primary.withOpacity(0.12),
    ];

    final iconColors = [
      AppColors.primary,
      AppColors.primary,
      AppColors.primary,
    ];

    final colorIndex = index % bgColors.length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        tileColor: bgColors[colorIndex],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Center(
            child: Icon(
              PhosphorIconsFill.fileText,
              color: iconColors[colorIndex],
              size: 18,
            ),
          ),
        ),
        title: Text(
          quiz.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          quiz.description ?? 'No description',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: InkWell(
          onTap: () {
            // Handle play quiz
            context.push('/quiz/${quiz.id}');
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Icon(
              PhosphorIconsFill.play,
              color: iconColors[colorIndex],
              size: 18,
            ),
          ),
        ),
        onTap: () {
          context.push('/quiz/${quiz.id}');
        },
      ),
    );
  }
}

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      toolbarHeight: 60.0, // Reduced from 70.0
      pinned: true,
      elevation: 0,
      centerTitle: false,
      title: Text(
        'DeltaMind',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22.0, // Smaller font size
            ),
      ),
      actions: const [ProfileAvatar()],
    );
  }
}

class DashboardGreeting extends ConsumerWidget {
  const DashboardGreeting({super.key, this.todaysQuestion});

  final String? todaysQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final greeting = _getGreeting();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  radius: 18,
                  child: Icon(
                    PhosphorIconsFill.user,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Hello, ${user?.email?.split('@').first ?? 'User'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (todaysQuestion != null) ...[
              const SizedBox(height: 16),
              Text(
                'Today\'s question:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                todaysQuestion!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    // Implement your logic to determine the greeting based on the current time
    return 'Good morning';
  }
}

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YourStats extends ConsumerWidget {
  const YourStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, use default values until we can properly connect with the stats
    const quizCounter = 0;
    const totalScore = 0;
    const learningHours = 0.0;
    const daysActive = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Your Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            StatsCard(
              title: 'Quizzes Completed',
              value: quizCounter?.toString() ?? '0',
              icon: PhosphorIconsFill.checkSquare,
              color: Colors.green,
              onTap: () => context.push(AppRoutes.quizList, extra: 1),
            ),
            StatsCard(
              title: 'Total Score',
              value: totalScore?.toString() ?? '0',
              icon: PhosphorIconsFill.star,
              color: Colors.amber.shade700,
              onTap: () => context.push(AppRoutes.quizList, extra: 1),
            ),
            StatsCard(
              title: 'Learning Hours',
              value: '${learningHours?.toStringAsFixed(1) ?? '0'}h',
              icon: PhosphorIconsFill.lightbulb,
              color: Colors.blue,
              onTap: () => context.push(AppRoutes.quizList, extra: 1),
            ),
            StatsCard(
              title: 'Days Active',
              value: daysActive?.toString() ?? '0',
              icon: PhosphorIconsFill.calendar,
              color: Colors.purple,
              onTap: () => context.push(AppRoutes.achievements),
            ),
          ],
        ),
      ],
    );
  }
}

// Update the NavBar if it exists in this file
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBar(
        onDestinationSelected: onTap,
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(PhosphorIconsFill.house),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsFill.books),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsFill.lightningSlash),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsFill.trophy),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }
}
