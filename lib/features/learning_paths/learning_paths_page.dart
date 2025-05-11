import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/models/learning_path.dart';
import 'package:deltamind/services/learning_path_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:deltamind/features/learning_paths/generate_path_dialog.dart';
import 'package:deltamind/features/learning_paths/learning_path_detail_page.dart';
import 'package:deltamind/core/utils/formatters.dart';
import 'package:go_router/go_router.dart';

/// Learning paths list page
class LearningPathsPage extends StatefulWidget {
  const LearningPathsPage({Key? key}) : super(key: key);

  @override
  State<LearningPathsPage> createState() => _LearningPathsPageState();
}

class _LearningPathsPageState extends State<LearningPathsPage> {
  bool _isLoading = true;
  List<LearningPath> _paths = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLearningPaths();
  }

  /// Load all learning paths
  Future<void> _loadLearningPaths() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final paths = await LearningPathService.getAllLearningPaths();

      if (mounted) {
        setState(() {
          _paths = paths;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load learning paths: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Handle tapping on a learning path
  void _onPathTap(LearningPath path) {
    context.push('/learning-paths/${path.id}');
  }

  /// Show dialog to generate a new learning path
  Future<void> _showGeneratePathDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const GeneratePathDialog(),
    );

    if (result == true) {
      // Dialog confirmed, refresh the list
      _loadLearningPaths();
    }
  }

  /// Delete a learning path
  Future<void> _deletePath(LearningPath path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Learning Path'),
        content: Text('Are you sure you want to delete "${path.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await LearningPathService.deleteLearningPath(path.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Learning path deleted')),
          );
          _loadLearningPaths();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to delete learning path: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Set a path as active
  Future<void> _setPathActive(LearningPath path) async {
    setState(() => _isLoading = true);

    try {
      await LearningPathService.setActiveLearningPath(path.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${path.title} set as active path')),
        );
        _loadLearningPaths();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to set active path: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Paths'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsFill.arrowClockwise),
            onPressed: _loadLearningPaths,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _paths.isEmpty
                  ? _buildEmptyView()
                  : _buildPathsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGeneratePathDialog,
        tooltip: 'Generate New Path',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build the error view
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsFill.warning,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLearningPaths,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state view
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsFill.bookOpen,
              size: 72,
              color: AppColors.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              "You don't have any learning paths yet",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Generate a new AI-powered learning path to start your journey",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showGeneratePathDialog,
              icon: const Icon(PhosphorIconsFill.brain),
              label: const Text('Generate Learning Path'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null &&
                _errorMessage!
                    .contains('AI service is temporarily unavailable'))
              TextButton.icon(
                onPressed: () {
                  // Here you would navigate to a manual creation page
                  // For now, we'll just show a dialog that this feature is coming soon
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Manual learning path creation coming soon!'),
                    ),
                  );
                },
                icon:
                    Icon(PhosphorIcons.pencilLine(PhosphorIconsStyle.regular)),
                label: const Text('Create Path Manually'),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the list of learning paths
  Widget _buildPathsList() {
    return RefreshIndicator(
      onRefresh: _loadLearningPaths,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _paths.length,
        itemBuilder: (context, index) {
          final path = _paths[index];
          return _buildPathCard(path);
        },
      ),
    );
  }

  /// Build a card for a learning path
  Widget _buildPathCard(LearningPath path) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: path.isActive
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _onPathTap(path),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: path.isActive
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsFill.roadHorizon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Created: ${formatDate(path.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (path.isActive)
                    Chip(
                      label: const Text('Active'),
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
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

            // Description
            if (path.description != null && path.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  path.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            // Actions
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                path.isActive
                    ? TextButton.icon(
                        onPressed: null, // Already active
                        icon: Icon(
                            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)),
                        label: const Text('Active'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () => _setPathActive(path),
                        icon: Icon(PhosphorIcons.star(PhosphorIconsStyle.fill)),
                        label: const Text('Set as Active'),
                      ),
                IconButton(
                  icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.fill)),
                  onPressed: () => _deletePath(path),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
