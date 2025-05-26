import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/dashboard/profile_avatar.dart';
import 'package:deltamind/features/quiz/quiz_controller.dart';
import 'package:deltamind/features/quiz/quiz_history_tab.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

/// Quiz list page with tabbed interface for Quizzes and History
class QuizListPage extends ConsumerStatefulWidget {
  /// The initial tab index to show (0 for Quizzes, 1 for History)
  final int initialTabIndex;

  /// Creates a QuizListPage with the given initial tab index
  const QuizListPage({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  ConsumerState<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends ConsumerState<QuizListPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  List<Quiz> _quizzes = [];
  String _searchQuery = '';
  String _selectedQuizType = 'All';
  String _selectedDifficulty = 'All';
  bool _showFilters = false;

  // Tab controller
  late TabController _tabController;

  // For filtering
  final TextEditingController _searchController = TextEditingController();
  final List<String> _quizTypes = [
    'All',
    'Multiple Choice',
    'True/False',
    'Fill in the Blank',
  ];
  final List<String> _difficulties = [
    'All',
    'Easy',
    'Medium',
    'Hard',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 2 tabs
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Delay loading quizzes slightly to ensure the widget is fully initialized
    Future.microtask(() => _loadQuizzes());

    // Add listener to tab controller to handle tab changes
    _tabController.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(QuizListPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if initialTabIndex has changed due to navigation
    final extra = GoRouterState.of(context).extra;
    if (extra != null && extra is int && extra != _tabController.index) {
      _tabController.animateTo(extra);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Handle tab change to refresh content
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Clear search and filters when switching tabs
      setState(() {
        _searchQuery = '';
        _searchController.clear();
        _selectedQuizType = 'All';
        _selectedDifficulty = 'All';
        _showFilters = false;
      });

      // Reload appropriate content based on selected tab
      if (_tabController.index == 0) {
        _loadQuizzes();
      } else {
        // History tab handles its own loading
      }
    }
  }

  /// Load quizzes from database
  Future<void> _loadQuizzes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use try-catch for the controller interaction
      try {
        await ref.read(quizControllerProvider.notifier).loadUserQuizzes();
      } catch (e) {
        _safeHandleError('loading quizzes from controller', e);
        return;
      }
    } catch (e) {
      _safeHandleError('loading quizzes', e);
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Delete a quiz
  Future<void> _deleteQuiz(String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
          'Are you sure you want to delete this quiz? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final success =
            await ref.read(quizControllerProvider.notifier).deleteQuiz(quizId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        _safeHandleError('deleting quiz', e);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Safe error handler for provider operations
  void _safeHandleError(String operation, Object error) {
    if (mounted) {
      debugPrint('Error during $operation: $error');
      setState(() {
        _errorMessage = 'Error: $operation failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Toggle filters visibility
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedQuizType = 'All';
      _selectedDifficulty = 'All';
    });
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }

  /// Build filter chip
  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onSelected,
  ) {
    final isSelected = label == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(isSelected ? 'All' : label),
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty ||
        _selectedDifficulty != 'All' ||
        _selectedQuizType != 'All';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off : Icons.quiz,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No matching quizzes' : 'No quizzes available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isFiltered
                  ? 'Try adjusting your filters or search terms'
                  : 'Create your first quiz to see it here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          if (isFiltered)
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear Filters'),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                context.go('/create-quiz');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
            ),
        ],
      ),
    );
  }

  /// Build quiz list
  Widget _buildQuizList() {
    return ListView.builder(
      itemCount: _quizzes.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];

        // Create display description without repetition
        String displayDescription = "Generated quiz";
        if (quiz.description != null && quiz.description!.isNotEmpty) {
          if (quiz.description!.toLowerCase().contains("elon")) {
            displayDescription = "Generated quiz based on elon.png";
          } else if (quiz.description!.toLowerCase().contains("poem")) {
            displayDescription = "Generated quiz based on provided content";
          } else {
            displayDescription = "Generated quiz based on content";
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
          ),
          elevation: 1,
          child: InkWell(
            onTap: () {
              context.go('/quiz/${quiz.id}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          quiz.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteQuiz(quiz.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description - fixed to avoid duplication
                  Text(
                    displayDescription,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Date display matching history tab
                  if (quiz.createdAt != null) ...[
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(quiz.createdAt!),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quiz type and difficulty badges
                  Row(
                    children: [
                      _buildBadge(quiz.quizType, Icons.quiz, AppColors.primary),
                      const SizedBox(width: 8),
                      _buildBadge(quiz.difficulty, Icons.fitness_center,
                          _getDifficultyColor(quiz.difficulty)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Start Quiz button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/quiz/${quiz.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Start Quiz'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get color for difficulty
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'hard':
        return Colors.red.shade600;
      case 'expert':
        return Colors.purple.shade600;
      default:
        return AppColors.primary;
    }
  }

  /// Build badge for quiz type and difficulty
  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use try-catch for the controller interaction
    try {
      final quizState = ref.watch(quizControllerProvider);
      _quizzes = quizState.userQuizzes;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _quizzes = _quizzes
            .where(
              (quiz) => quiz.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }

      // Apply type filter
      if (_selectedQuizType != 'All') {
        _quizzes = _quizzes
            .where((quiz) => quiz.quizType == _selectedQuizType)
            .toList();
      }

      // Apply difficulty filter
      if (_selectedDifficulty != 'All') {
        _quizzes = _quizzes
            .where((quiz) => quiz.difficulty == _selectedDifficulty)
            .toList();
      }
    } catch (e) {
      debugPrint('Error watching quiz controller: $e');
      if (_errorMessage == null) {
        _errorMessage = 'Error loading quizzes: $e';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quizzes', icon: Icon(Icons.quiz)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
        actions: [
          // Profile avatar
          const ProfileAvatar(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () {
                    if (_tabController.index == 0) {
                      _loadQuizzes();
                    }
                  },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Quizzes Tab
          SafeArea(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search quizzes...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: _showFilters
                              ? Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                )
                              : null,
                        ),
                        child: IconButton(
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: _showFilters
                                    ? AppColors.primary
                                    : Colors.grey[700],
                              ),
                              if (_selectedQuizType != 'All' ||
                                  _selectedDifficulty != 'All')
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: _toggleFilters,
                          tooltip: 'Toggle Filters',
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters section (collapsible)
                if (_showFilters) ...[
                  const SizedBox(height: 16),

                  // Quiz type filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quiz type label
                      Text(
                        'Quiz Type:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quiz type chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quizTypes
                              .map(
                                (type) => _buildFilterChip(
                                  type,
                                  _selectedQuizType,
                                  _quizTypes,
                                  (value) {
                                    setState(() {
                                      _selectedQuizType = value;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Difficulty label
                      Text(
                        'Difficulty:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Difficulty chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _difficulties
                              .map(
                                (difficulty) => _buildFilterChip(
                                  difficulty,
                                  _selectedDifficulty,
                                  _difficulties,
                                  (value) {
                                    setState(() {
                                      _selectedDifficulty = value;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filter actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Only show reset button if filters are applied
                      if (_selectedQuizType != 'All' ||
                          _selectedDifficulty != 'All')
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],

                // Active filters display (when filters are collapsed)
                if (!_showFilters &&
                    (_selectedQuizType != 'All' ||
                        _selectedDifficulty != 'All'))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Active filters:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedQuizType != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(_selectedQuizType),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedQuizType = 'All';
                                });
                              },
                              visualDensity: VisualDensity.compact,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        if (_selectedDifficulty != 'All')
                          Chip(
                            label: Text(_selectedDifficulty),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedDifficulty = 'All';
                              });
                            },
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quiz list or empty state
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(child: Text(_errorMessage!))
                          : _quizzes.isEmpty
                              ? _buildEmptyState()
                              : _buildQuizList(),
                ),
              ],
            ),
          ),

          // History Tab
          const SafeArea(child: QuizHistoryTab()),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.createQuiz),
              tooltip: 'Create Quiz',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
