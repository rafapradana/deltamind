import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:deltamind/features/auth/auth_controller.dart';

/// History page displays past quiz attempts
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _quizAttempts = [];
  List<dynamic> _filteredAttempts = [];

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
      final response = await SupabaseService.client
          .from('quiz_attempts')
          .select('''
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
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

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
  Future<void> _deleteQuizAttempt(String attemptId) async {
    // Create a local variable to track this specific deletion
    bool isDeleting = true;

    // Store the index for the item being deleted for UI updates
    int? deletingIndex;
    for (int i = 0; i < _filteredAttempts.length; i++) {
      if (_filteredAttempts[i]['id'] == attemptId) {
        deletingIndex = i;
        break;
      }
    }

    // Update UI to show deleting state for this specific card
    if (deletingIndex != null) {
      setState(() {
        _filteredAttempts[deletingIndex!]['_isDeleting'] = true;
      });
    }

    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Quiz Result'),
              content: const Text(
                'Are you sure you want to delete this quiz result? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (confirm != true) {
        // User canceled, reset deleting state
        if (deletingIndex != null && mounted) {
          setState(() {
            _filteredAttempts[deletingIndex!].remove('_isDeleting');
          });
        }
        return;
      }

      // Debug logging
      debugPrint('User confirmed deletion of quiz attempt: $attemptId');

      // Use our enhanced deletion method from SupabaseService
      final success = await SupabaseService.deleteQuizAttempt(attemptId);

      debugPrint('Deletion ${success ? 'successful' : 'failed'}');

      if (!success) {
        throw Exception('Failed to delete quiz attempt. Please try again.');
      }

      // Update UI on success
      if (mounted) {
        // Find and remove from both lists
        setState(() {
          _quizAttempts.removeWhere((attempt) => attempt['id'] == attemptId);
          _filteredAttempts.removeWhere(
            (attempt) => attempt['id'] == attemptId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz result deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting quiz attempt: $e');
      if (!mounted) return;

      // Show error to user with more details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting quiz: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );

      // Reset deleting state on error for all items
      if (mounted) {
        setState(() {
          for (final attempt in _filteredAttempts) {
            attempt.remove('_isDeleting');
          }
        });
      }
    }
  }

  /// Apply filters to quiz attempts
  void _applyFilters() {
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
      if (!_isDateInRange(createdAt, _dateFilter)) {
        continue;
      }

      filtered.add(attempt);
    }

    setState(() {
      _filteredAttempts = filtered;
    });
  }

  /// Check if date is in selected range
  bool _isDateInRange(DateTime date, String filter) {
    final now = DateTime.now();

    switch (filter) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        return date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
      case 'Last 3 Months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return date.isAfter(threeMonthsAgo);
      case 'All Time':
      default:
        return true;
    }
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      _searchController.text = '';
      _searchQuery = '';
      _selectedDifficulty = 'All';
      _selectedQuizType = 'All';
      _dateFilter = 'All Time';
      _filteredAttempts = List.from(_quizAttempts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.sliders()),
            onPressed: () => _showFilterBottomSheet(),
            tooltip: 'Filters',
          ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise()),
            onPressed: _isLoading ? null : _loadQuizHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildActiveFilters(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildContent(),
                      key: ValueKey<int>(_filteredAttempts.length),
                    ),
          ),
        ],
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search quiz titles...',
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(),
            color: AppColors.textSecondary,
          ),
          suffixIcon:
              _searchQuery.isEmpty
                  ? null
                  : IconButton(
                    icon: Icon(PhosphorIcons.x(), size: 18),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                  ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  /// Build active filters display
  Widget _buildActiveFilters() {
    final hasActiveFilters =
        _selectedDifficulty != 'All' ||
        _selectedQuizType != 'All' ||
        _dateFilter != 'All Time';

    if (!hasActiveFilters) return const SizedBox(height: 8);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedDifficulty != 'All')
            _buildFilterChip('Difficulty: $_selectedDifficulty'),
          if (_selectedQuizType != 'All')
            _buildFilterChip('Type: $_selectedQuizType'),
          if (_dateFilter != 'All Time') _buildFilterChip('Date: $_dateFilter'),
          OutlinedButton.icon(
            onPressed: () {
              _resetFilters();
            },
            icon: Icon(PhosphorIcons.x(), size: 14),
            label: const Text('Clear All'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              side: BorderSide(color: AppColors.divider),
              minimumSize: const Size(0, 30),
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Quiz History',
                        style: AppTheme.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.x()),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Difficulty',
                    style: AppTheme.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _difficulties
                              .map(
                                (difficulty) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(difficulty),
                                    selected: _selectedDifficulty == difficulty,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          _selectedDifficulty = difficulty;
                                        });
                                        setState(() {
                                          _selectedDifficulty = difficulty;
                                        });
                                      }
                                    },
                                    backgroundColor: Colors.grey[50],
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.15),
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedDifficulty == difficulty
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                      fontWeight:
                                          _selectedDifficulty == difficulty
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Quiz Type',
                    style: AppTheme.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _quizTypes
                              .map(
                                (type) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: _selectedQuizType == type,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          _selectedQuizType = type;
                                        });
                                        setState(() {
                                          _selectedQuizType = type;
                                        });
                                      }
                                    },
                                    backgroundColor: Colors.grey[50],
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.15),
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedQuizType == type
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                      fontWeight:
                                          _selectedQuizType == type
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Date Range',
                    style: AppTheme.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _dateFilters
                              .map(
                                (filter) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(filter),
                                    selected: _dateFilter == filter,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          _dateFilter = filter;
                                        });
                                        setState(() {
                                          _dateFilter = filter;
                                        });
                                      }
                                    },
                                    backgroundColor: Colors.grey[50],
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.15),
                                    labelStyle: TextStyle(
                                      color:
                                          _dateFilter == filter
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                      fontWeight:
                                          _dateFilter == filter
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedDifficulty = 'All';
                              _selectedQuizType = 'All';
                              _dateFilter = 'All Time';
                            });
                          },
                          child: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build content
  Widget _buildContent() {
    if (_filteredAttempts.isEmpty) {
      if (_searchQuery.isNotEmpty ||
          _selectedDifficulty != 'All' ||
          _selectedQuizType != 'All' ||
          _dateFilter != 'All Time') {
        // No results with filters
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.magnifyingGlass(),
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: AppTheme.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try changing your search or filters',
                style: AppTheme.bodyText.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: Icon(PhosphorIcons.arrowCounterClockwise()),
                label: const Text('Reset Filters'),
              ),
            ],
          ),
        );
      } else {
        // No quiz history at all
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.clipboard(),
                size: 64,
                color: AppColors.primary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No quiz history yet',
                style: AppTheme.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a quiz to see your results here',
                style: AppTheme.bodyText.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadQuizHistory,
      color: AppColors.primary,
      child: ListView.separated(
        key: ValueKey<int>(_filteredAttempts.length),
        padding: const EdgeInsets.all(16),
        controller: _scrollController,
        itemCount: _filteredAttempts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final attempt = _filteredAttempts[index];
          final quiz = attempt['quizzes'];
          final score = attempt['score'];
          final totalQuestions = attempt['total_questions'];
          final percentage =
              totalQuestions > 0 ? (score / totalQuestions * 100).round() : 0;
          final createdAt = DateTime.parse(attempt['created_at']);
          final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

          // Check if this item is being deleted
          final bool isDeleting = attempt['_isDeleting'] == true;

          return Card(
            elevation: 1,
            shadowColor: AppColors.shadow.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child:
                isDeleting
                    ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Deleting quiz...',
                            style: AppTheme.bodyText.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quiz['title'] ?? 'Untitled Quiz',
                                  style: AppTheme.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  PhosphorIcons.dotsThree(),
                                  color: AppColors.textSecondary,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteQuizAttempt(attempt['id']);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              PhosphorIcons.trash(),
                                              color: AppColors.error,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateFormat.format(createdAt),
                            style: AppTheme.smallText.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildInfoChip(
                                quiz['difficulty'] ?? 'Unknown',
                                PhosphorIcons.barbell(),
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                quiz['quiz_type'] ?? 'Unknown',
                                PhosphorIcons.clipboardText(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Score progress indicator
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  flex: percentage.toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getAccuracyColor(percentage),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  flex:
                                      percentage > 0
                                          ? (100 - percentage).toInt()
                                          : 100,
                                  child: Container(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Score',
                                      style: AppTheme.smallText.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$score/$totalQuestions',
                                      style: AppTheme.subtitle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Accuracy',
                                      style: AppTheme.smallText.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$percentage%',
                                      style: AppTheme.subtitle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getAccuracyColor(percentage),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _viewQuizDetails(attempt['id']),
                              icon: Icon(PhosphorIcons.arrowSquareOut()),
                              label: const Text('View Details'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.smallText.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(int percentage) {
    if (percentage >= 80) {
      return AppColors.success;
    } else if (percentage >= 60) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  void _viewQuizDetails(String attemptId) {
    // Navigate to quiz details/review page
    context.push('/quiz-review/$attemptId');
  }
}
