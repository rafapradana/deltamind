import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:deltamind/features/quiz/quiz_attempt_controller.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

/// Widget for the History tab in the QuizListPage
class QuizHistoryTab extends ConsumerStatefulWidget {
  /// Creates a QuizHistoryTab
  const QuizHistoryTab({Key? key}) : super(key: key);

  @override
  ConsumerState<QuizHistoryTab> createState() => _QuizHistoryTabState();
}

class _QuizHistoryTabState extends ConsumerState<QuizHistoryTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _quizAttempts = [];
  List<dynamic> _filteredAttempts = [];
  bool _showFilters = false;

  // Filters
  String _searchQuery = '';
  String _selectedDifficulty = 'All';
  String _selectedQuizType = 'All';
  String _dateFilter = 'All Time';

  // For dropdown filters
  List<String> _difficulties = ['All'];
  List<String> _quizTypes = ['All'];
  final List<String> _dateFilters = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'Last 3 Months',
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuizHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load quiz history data
  Future<void> _loadQuizHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get quiz attempts with quiz details
      final response =
          await SupabaseService.client.from('quiz_attempts').select('''
            id, 
            score, 
            total_questions, 
            time_taken, 
            created_at,
            user_id,
            quizzes (
              id, 
              title, 
              quiz_type,
              difficulty
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      if (mounted) {
        // Process the data for filters
        final difficulties = <String>{'All'};
        final quizTypes = <String>{'All'};

        for (final attempt in response) {
          final quiz = attempt['quizzes'];
          if (quiz != null) {
            if (quiz['difficulty'] != null) {
              difficulties.add(quiz['difficulty']);
            }
            if (quiz['quiz_type'] != null) {
              quizTypes.add(quiz['quiz_type']);
            }
          }
        }

        setState(() {
          _quizAttempts = response;
          _filteredAttempts = List.from(response);
          _isLoading = false;
          _difficulties = difficulties.toList()..sort();
          _quizTypes = quizTypes.toList()..sort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading quiz history: $e';
          _isLoading = false;
        });
        debugPrint('Error loading quiz history: $e');
      }
    }
  }

  /// Delete a quiz attempt
  Future<void> _deleteQuizAttempt(dynamic attempt) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz Attempt'),
        content: const Text(
          'Are you sure you want to delete this quiz attempt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      // Mark as deleting for UI update
      setState(() {
        attempt['_isDeleting'] = true;
      });

      // Delete the quiz attempt
      await SupabaseService.deleteQuizAttempt(attempt['id']);

      // Reload quiz history if successful
      await _loadQuizHistory();
    } catch (e) {
      // If there's an error, unmark as deleting and show error
      if (mounted) {
        setState(() {
          attempt['_isDeleting'] = false;
          _errorMessage = 'Error deleting quiz attempt: $e';
        });
      }
      debugPrint('Error deleting quiz attempt: $e');
    }
  }

  /// Apply all filters to the data
  void _applyFilters() {
    if (!mounted) return;

    final List<dynamic> filtered = [];

    for (final attempt in _quizAttempts) {
      final quiz = attempt['quizzes'];
      final quizTitle = quiz?['title'] ?? 'Untitled Quiz';
      final difficulty = quiz?['difficulty'] ?? 'Unknown';
      final quizType = quiz?['quiz_type'] ?? 'Unknown';
      final createdAt = DateTime.parse(attempt['created_at']);

      // Apply search filter
      if (_searchQuery.isNotEmpty &&
          !quizTitle.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }

      // Apply difficulty filter
      if (_selectedDifficulty != 'All' && difficulty != _selectedDifficulty) {
        continue;
      }

      // Apply quiz type filter
      if (_selectedQuizType != 'All' && quizType != _selectedQuizType) {
        continue;
      }

      // Apply date filter
      if (_dateFilter != 'All Time') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final createdDate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );

        switch (_dateFilter) {
          case 'Today':
            if (createdDate != today) continue;
            break;
          case 'This Week':
            final startOfWeek = today.subtract(
              Duration(days: today.weekday - 1),
            );
            if (createdDate.isBefore(startOfWeek)) continue;
            break;
          case 'This Month':
            final startOfMonth = DateTime(now.year, now.month, 1);
            if (createdDate.isBefore(startOfMonth)) continue;
            break;
          case 'Last 3 Months':
            final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
            if (createdDate.isBefore(threeMonthsAgo)) continue;
            break;
        }
      }

      filtered.add(attempt);
    }

    setState(() {
      _filteredAttempts = filtered;
    });
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }

  /// Toggle filter visibility
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
      _dateFilter = 'All Time';
    });
    _applyFilters();
  }

  /// Build filter chip for difficulty and quiz type
  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> values,
    Function(String) onSelected,
  ) {
    final isSelected = selectedValue == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => onSelected(isSelected ? 'All' : label),
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar with filter toggle
              Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search quiz history...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                  _applyFilters();
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
                        _applyFilters();
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Filter toggle button
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
                      icon: Badge(
                        isLabelVisible: _selectedQuizType != 'All' ||
                            _selectedDifficulty != 'All' ||
                            _dateFilter != 'All Time',
                        child: Icon(
                          Icons.filter_list,
                          color: _showFilters
                              ? AppColors.primary
                              : Colors.grey[700],
                        ),
                      ),
                      onPressed: _toggleFilters,
                      tooltip: 'Toggle Filters',
                    ),
                  ),
                ],
              ),

              // Filters section (collapsible)
              if (_showFilters) ...[
                const SizedBox(height: 16),

                // Quiz type filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  _applyFilters();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

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
                                  _applyFilters();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date range label
                    Text(
                      'Date Range:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Date range dropdown
                    DropdownButtonFormField<String>(
                      value: _dateFilter,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _dateFilters
                          .map(
                            (date) => DropdownMenuItem(
                              value: date,
                              child: Text(date),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _dateFilter = value;
                          });
                          _applyFilters();
                        }
                      },
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
                        _selectedDifficulty != 'All' ||
                        _dateFilter != 'All Time')
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
            ],
          ),
        ),

        // Active filters display (when filters are collapsed)
        if (!_showFilters &&
            (_selectedQuizType != 'All' ||
                _selectedDifficulty != 'All' ||
                _dateFilter != 'All Time'))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Active filters:'),
                  const SizedBox(width: 8),
                  if (_selectedDifficulty != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_selectedDifficulty),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedDifficulty = 'All';
                          });
                          _applyFilters();
                        },
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  if (_selectedQuizType != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_selectedQuizType),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedQuizType = 'All';
                          });
                          _applyFilters();
                        },
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  if (_dateFilter != 'All Time')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_dateFilter),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _dateFilter = 'All Time';
                          });
                          _applyFilters();
                        },
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Quiz history list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Quiz History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadQuizHistory,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : _filteredAttempts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadQuizHistory,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAttempts.length,
                            itemBuilder: (context, index) {
                              final attempt = _filteredAttempts[index];
                              final quiz = attempt['quizzes'];
                              final isDeleting = attempt['_isDeleting'] == true;

                              return _buildAttemptCard(
                                  attempt, quiz, isDeleting);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  /// Build empty state widget when no quiz history found
  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty ||
        _selectedDifficulty != 'All' ||
        _selectedQuizType != 'All' ||
        _dateFilter != 'All Time';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt : Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No matching quiz attempts' : 'No quiz history yet',
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
                  : 'Complete your first quiz to see your progress here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          if (isFiltered)
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  /// Build quiz attempt card
  Widget _buildAttemptCard(dynamic attempt, dynamic quiz, bool isDeleting) {
    // Quiz details
    final quizTitle = quiz?['title'] ?? 'Untitled Quiz';
    final quizType = quiz?['quiz_type'] ?? 'Unknown';
    final difficulty = quiz?['difficulty'] ?? 'Unknown';
    final quizId = quiz?['id'];

    // Attempt details
    final score = attempt['score'] ?? 0;
    final totalQuestions = attempt['total_questions'] ?? 0;
    final percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
    final createdAt = DateTime.parse(attempt['created_at']);
    final timeTaken = attempt['time_taken'] ?? 0;

    // Format time taken
    final minutes = (timeTaken / 60).floor();
    final seconds = timeTaken % 60;
    final formattedTime = '${minutes}m ${seconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () {
          if (!isDeleting) {
            // Navigate to quiz attempt details
            context.go('/quiz-review', extra: attempt['id']);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      quizTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Popup menu
                  if (!isDeleting)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'view') {
                          context.go('/quiz-review', extra: attempt['id']);
                        } else if (value == 'retake' && quizId != null) {
                          context.go('/quiz/$quizId');
                        } else if (value == 'delete') {
                          _deleteQuizAttempt(attempt);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        if (quizId != null)
                          const PopupMenuItem(
                            value: 'retake',
                            child: Row(
                              children: [
                                Icon(Icons.replay),
                                SizedBox(width: 8),
                                Text('Retake Quiz'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Date and time taken
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Score information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $score/$totalQuestions',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _getScoreColor(percentage),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              LinearPercentIndicator(
                percent: percentage > 100 ? 1.0 : percentage / 100,
                lineHeight: 12,
                animation: true,
                animationDuration: 500,
                backgroundColor: Colors.grey[200],
                progressColor: _getScoreColor(percentage),
                barRadius: const Radius.circular(8),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Difficulty and quiz type badges
              Row(
                children: [
                  _buildBadge(
                    difficulty,
                    Icons.fitness_center,
                    _getDifficultyColor(difficulty),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(quizType, Icons.quiz, AppColors.primary),
                ],
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDeleting
                          ? null
                          : () {
                              context.go(
                                '/quiz-review',
                                extra: attempt['id'],
                              );
                            },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isDeleting || quizId == null
                          ? null
                          : () {
                              context.go('/quiz/$quizId');
                            },
                      icon: const Icon(Icons.replay),
                      label: const Text('Retake Quiz'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build badge widget for difficulty and quiz type
  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Get score color based on percentage
  Color _getScoreColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.amber.shade700;
    } else if (percentage >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Get difficulty color
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
