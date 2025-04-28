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

  @override
  void initState() {
    super.initState();
    _loadQuizHistory();
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
        setState(() {
          _quizAttempts = response;
          _isLoading = false;
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
    for (int i = 0; i < _quizAttempts.length; i++) {
      if (_quizAttempts[i]['id'] == attemptId) {
        deletingIndex = i;
        break;
      }
    }

    // Update UI to show deleting state for this specific card
    if (deletingIndex != null) {
      setState(() {
        _quizAttempts[deletingIndex!]['_isDeleting'] = true;
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
            _quizAttempts[deletingIndex!].remove('_isDeleting');
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
      if (deletingIndex != null && mounted) {
        setState(() {
          _quizAttempts.removeAt(deletingIndex!);
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

      // Reset deleting state on error if the item still exists
      if (deletingIndex != null && deletingIndex < _quizAttempts.length) {
        setState(() {
          _quizAttempts[deletingIndex!].remove('_isDeleting');
        });
      }
    } finally {
      // Force hard refresh of the entire list
      if (mounted) {
        debugPrint('Refreshing quiz history list');
        _loadQuizHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuizHistory,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildContent(),
                key: ValueKey<int>(_quizAttempts.length),
              ),
    );
  }

  /// Build content
  Widget _buildContent() {
    if (_quizAttempts.isEmpty) {
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
              style: AppTheme.bodyText.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizHistory,
      child: ListView.separated(
        key: ValueKey<int>(_quizAttempts.length),
        padding: const EdgeInsets.all(16),
        itemCount: _quizAttempts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final attempt = _quizAttempts[index];
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
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                                  color: AppColors.divider,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteQuizAttempt(attempt['id']);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
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
        borderRadius: BorderRadius.circular(4),
        color: AppColors.divider.withOpacity(0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.smallText.copyWith(color: AppColors.textSecondary),
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
