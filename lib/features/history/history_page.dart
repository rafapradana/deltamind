import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
            quizzes (
              id, 
              title, 
              quiz_type,
              difficulty
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _quizAttempts = response;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading quiz history: $e';
      });
      debugPrint('Error loading quiz history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete a quiz attempt
  Future<void> _deleteQuizAttempt(String attemptId) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Quiz Result'),
          content: const Text('Are you sure you want to delete this quiz result? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() {
        _isLoading = true;
      });

      // Delete user answers first (foreign key constraint)
      await SupabaseService.client
          .from('user_answers')
          .delete()
          .eq('quiz_attempt_id', attemptId);

      // Delete quiz attempt
      await SupabaseService.client
          .from('quiz_attempts')
          .delete()
          .eq('id', attemptId);

      // Refresh the list
      await _loadQuizHistory();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz result deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error deleting quiz attempt: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildContent(),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No quiz history yet',
              style: AppTheme.subtitle.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a quiz to see your results here',
              style: AppTheme.bodyText.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _quizAttempts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final attempt = _quizAttempts[index];
          final quiz = attempt['quizzes'];
          final score = attempt['score'];
          final totalQuestions = attempt['total_questions'];
          final percentage = totalQuestions > 0 
              ? (score / totalQuestions * 100).round() 
              : 0;
          final createdAt = DateTime.parse(attempt['created_at']);
          final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
          
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
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
                          color: Colors.grey[600],
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteQuizAttempt(attempt['id']);
                          }
                        },
                        itemBuilder: (context) => [
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
                    style: AppTheme.smallText.copyWith(color: Colors.grey[600]),
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
                              style: AppTheme.smallText.copyWith(color: Colors.grey[600]),
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
                              style: AppTheme.smallText.copyWith(color: Colors.grey[600]),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.smallText.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(int percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  void _viewQuizDetails(String attemptId) {
    // Navigate to quiz details/review page
    context.push('/quiz-review/$attemptId');
  }
} 