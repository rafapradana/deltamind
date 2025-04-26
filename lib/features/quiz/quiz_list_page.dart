import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/quiz/quiz_controller.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Quiz list page
class QuizListPage extends ConsumerStatefulWidget {
  const QuizListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends ConsumerState<QuizListPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Quiz> _quizzes = [];
  String _searchQuery = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    // Delay loading quizzes slightly to ensure the widget is fully initialized
    Future.microtask(() => _loadQuizzes());
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
  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
        final success = await ref
            .read(quizControllerProvider.notifier)
            .deleteQuiz(quiz.id);

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

  @override
  Widget build(BuildContext context) {
    // Use try-catch for the controller interaction
    List<Quiz> quizzes = [];
    try {
      final quizState = ref.watch(quizControllerProvider);
      _quizzes = quizState.userQuizzes;
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _quizzes = _quizzes
            .where((quiz) =>
                quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
  
      // Apply type filter
      if (_filter != 'All') {
        _quizzes = _quizzes
            .where((quiz) => quiz.quizType == _filter)
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
        title: const Text('My Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuizzes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search quizzes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Multiple Choice'),
                      _buildFilterChip('True/False'),
                      _buildFilterChip('Fill in the Blank'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quiz list
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createQuiz),
        tooltip: 'Create Quiz',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _filter == label,
        onSelected: (selected) {
          setState(() {
            _filter = selected ? label : 'All';
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No quizzes found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filter != 'All'
                ? 'Try changing your search or filter'
                : 'Create your first quiz to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.createQuiz),
            icon: const Icon(Icons.add),
            label: const Text('Create Quiz'),
          ),
        ],
      ),
    );
  }

  /// Build quiz list
  Widget _buildQuizList() {
    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () {
                // Navigate to quiz details page
                context.go('/quiz/${quiz.id}');
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            quiz.title,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'take',
                              child: Row(
                                children: [
                                  Icon(Icons.play_arrow),
                                  SizedBox(width: 8),
                                  Text('Take Quiz'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'take':
                                // Navigate to take quiz page
                                context.go('/quiz/${quiz.id}');
                                break;
                              case 'edit':
                                // TODO: Navigate to edit quiz page
                                break;
                              case 'delete':
                                _deleteQuiz(quiz);
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                    if (quiz.description != null && quiz.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          quiz.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuizChip(quiz.quizType, Icons.question_answer),
                        const SizedBox(width: 8),
                        _buildQuizChip(quiz.difficulty, Icons.fitness_center),
                        const SizedBox(width: 8),
                        if (quiz.createdAt != null)
                          _buildQuizChip(
                            _formatDate(quiz.createdAt!),
                            Icons.calendar_today,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to take quiz page with quiz ID
                          context.go('/quiz/${quiz.id}');
                        },
                        child: const Text('Start Quiz'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build quiz info chip
  Widget _buildQuizChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 