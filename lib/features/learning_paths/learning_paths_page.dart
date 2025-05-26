import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/models/learning_path.dart';
import 'package:deltamind/services/learning_path_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:deltamind/features/learning_paths/generate_path_dialog.dart';
import 'package:deltamind/features/learning_paths/learning_path_progress_widget.dart';
import 'package:deltamind/core/utils/formatters.dart';
import 'package:go_router/go_router.dart';

/// Learning paths list page
class LearningPathsPage extends StatefulWidget {
  const LearningPathsPage({Key? key}) : super(key: key);

  @override
  State<LearningPathsPage> createState() => _LearningPathsPageState();
}

class _LearningPathsPageState extends State<LearningPathsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<LearningPath> _paths = [];
  List<LearningPath> _filteredPaths = [];
  LearningPath? _activePath;
  String? _errorMessage;
  late TabController _tabController;

  // Filtering
  String? _selectedCategory;
  String? _selectedDifficulty;
  List<String> _selectedTags = [];
  String _searchQuery = '';

  // All available categories, difficulties, and tags
  Set<String?> _availableCategories = {};
  Set<String> _availableDifficulties = {'beginner', 'intermediate', 'advanced'};
  Set<String> _availableTags = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLearningPaths();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      // Find the active path
      final activePath = paths.where((path) => path.isActive).firstOrNull;

      // Collect all available categories and tags
      final categories = paths.map((path) => path.category).toSet();
      final tags = paths.fold<Set<String>>(
        {},
        (set, path) => set..addAll(path.tags),
      );

      if (mounted) {
        setState(() {
          _paths = paths;
          _filteredPaths = List.from(paths);
          _activePath = activePath;
          _availableCategories = categories;
          _availableTags = tags;
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

  /// Apply filters to the learning paths
  void _applyFilters() {
    if (_paths.isEmpty) return;

    setState(() {
      _filteredPaths = _paths.where((path) {
        // Filter by category
        if (_selectedCategory != null && path.category != _selectedCategory) {
          return false;
        }

        // Filter by difficulty
        if (_selectedDifficulty != null &&
            path.difficulty != _selectedDifficulty) {
          return false;
        }

        // Filter by tags (path must contain ANY of the selected tags)
        if (_selectedTags.isNotEmpty &&
            !_selectedTags.any((tag) => path.tags.contains(tag))) {
          return false;
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return path.title.toLowerCase().contains(query) ||
              (path.description?.toLowerCase().contains(query) ?? false) ||
              path.tags.any((tag) => tag.toLowerCase().contains(query));
        }

        return true;
      }).toList();
    });
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
      _selectedTags = [];
      _searchQuery = '';
      _filteredPaths = List.from(_paths);
    });
  }

  /// Handle tapping on a learning path
  void _onPathTap(LearningPath path) {
    context.push('/learning-paths/${path.id}');
  }

  /// Toggle a learning path's active status
  Future<void> _togglePathActive(LearningPath path, bool value) async {
    if (value == path.isActive) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        // Activate this path (and deactivate others)
        await LearningPathService.setActiveLearningPath(path.id);
      } else {
        // Deactivate this path
        await LearningPathService.deactivateLearningPath(path.id);
      }

      // Reload learning paths to refresh the UI
      await _loadLearningPaths();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update learning path status: $e';
        _isLoading = false;
      });
    }
  }

  /// Continue active learning path
  void _continueLearningPath() {
    if (_activePath != null) {
      _onPathTap(_activePath!);
    }
  }

  /// Show dialog to generate a new learning path
  void _showGeneratePathDialog() {
    showDialog(
      context: context,
      builder: (context) => const GeneratePathDialog(),
    ).then((_) => _loadLearningPaths());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Paths'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.fill)),
            onPressed: _loadLearningPaths,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'All Paths'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildAllPathsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGeneratePathDialog,
        tooltip: 'Generate Learning Path',
        child: Icon(PhosphorIcons.brain(PhosphorIconsStyle.fill)),
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView() {
    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
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
    );
  }

  /// Build the dashboard tab with active path and stats
  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Dashboard header
        Card(
          elevation: 1,
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
                    Icon(
                      PhosphorIcons.roadHorizon(PhosphorIconsStyle.fill),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Learning Paths Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your progress and continue your learning journey',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 16),

                // Quick stats
                _buildQuickStats(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Active learning path section
        if (_activePath != null) ...[
          Row(
            children: [
              Icon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Learning Path',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Active path progress widget
          LearningPathProgressWidget(
            learningPath: _activePath!,
            onContinue: _continueLearningPath,
          ),
        ] else ...[
          _buildNoActivePath(),
        ],

        const SizedBox(height: 24),

        // Recent paths section
        if (_paths.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Learning Paths',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Show the most recent 3 paths
          ...List.generate(
            _paths.length > 3 ? 3 : _paths.length,
            (index) => _buildRecentPathCard(_paths[index]),
          ),
        ],
      ],
    );
  }

  /// Build all paths tab
  Widget _buildAllPathsTab() {
    return _paths.isEmpty
        ? _buildEmptyState()
        : Column(
            children: [
              // Search and filter section
              _buildSearchAndFilterSection(),

              // Results count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Text(
                      '${_filteredPaths.length} ${_filteredPaths.length == 1 ? 'path' : 'paths'} found',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory != null ||
                        _selectedDifficulty != null ||
                        _selectedTags.isNotEmpty ||
                        _searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.fill),
                          size: 16,
                        ),
                        label: const Text('Clear Filters'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Learning paths list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredPaths.length,
                  itemBuilder: (context, index) =>
                      _buildPathCard(_filteredPaths[index]),
                ),
              ),
            ],
          );
  }

  /// Build search and filter section
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search learning paths...',
              prefixIcon: Icon(
                PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.fill),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),

          const SizedBox(height: 12),

          // Filter buttons
          Row(
            children: [
              // Category filter
              Expanded(
                child: _buildFilterDropdown(
                  hint: 'Category',
                  value: _selectedCategory,
                  items: _availableCategories
                      .where((c) => c != null)
                      .map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _applyFilters();
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Difficulty filter
              Expanded(
                child: _buildFilterDropdown(
                  hint: 'Difficulty',
                  value: _selectedDifficulty,
                  items: _availableDifficulties
                      .map((d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(
                              d[0].toUpperCase() + d.substring(1),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),

          if (_availableTags.isNotEmpty) ...[
            const SizedBox(height: 12),

            // Tags filter
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags
                  .take(10) // Limit to prevent overcrowding
                  .map((tag) => FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                            _applyFilters();
                          });
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _selectedTags.contains(tag)
                              ? AppColors.primary
                              : Colors.grey.shade800,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build filter dropdown
  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<String>(
        hint: Text(hint),
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(
          PhosphorIcons.caretDown(PhosphorIconsStyle.fill),
          size: 16,
        ),
      ),
    );
  }

  /// Build empty state when no paths exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
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
              icon: Icon(PhosphorIcons.brain(PhosphorIconsStyle.fill)),
              label: const Text('Generate Learning Path'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build no active path widget
  Widget _buildNoActivePath() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No Active Learning Path',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set a learning path as active to track your progress and continue learning from where you left off.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.fill)),
              label: const Text('Browse Learning Paths'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick stats widget
  Widget _buildQuickStats() {
    final totalPaths = _paths.length;
    final completedPaths = _paths.where((path) => path.progress >= 100).length;
    final inProgressPaths =
        _paths.where((path) => path.progress > 0 && path.progress < 100).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          label: 'Total Paths',
          value: totalPaths.toString(),
          icon: PhosphorIcons.books(PhosphorIconsStyle.fill),
          color: Colors.blue,
        ),
        _buildStatItem(
          label: 'Completed',
          value: completedPaths.toString(),
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          color: Colors.green,
        ),
        _buildStatItem(
          label: 'In Progress',
          value: inProgressPaths.toString(),
          icon: PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
          color: AppColors.primary,
        ),
      ],
    );
  }

  /// Build a stat item
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 80,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build a recent path card for the dashboard
  Widget _buildRecentPathCard(LearningPath path) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _onPathTap(path),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.roadHorizon(PhosphorIconsStyle.fill),
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
                          path.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (path.category != null) ...[
                              Text(
                                path.category!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            Text(
                              path.difficulty[0].toUpperCase() +
                                  path.difficulty.substring(1),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getDifficultyColor(path.difficulty),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (path.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LearningPathProgressWidget(
                learningPath: path,
                isCompact: true,
              ),
              // Tags
              if (path.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: path.tags
                        .take(3) // Limit to prevent overcrowding
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a learning path card
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
                      PhosphorIcons.roadHorizon(PhosphorIconsStyle.fill),
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
                        Row(
                          children: [
                        Text(
                              formatDate(path.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (path.category != null) ...[
                              const Text(' • '),
                              Text(
                                path.category!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  if (path.isActive)
                    Chip(
                      label: const Text('Active'),
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                            fontSize: 12,
                      ),
                      padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(path.difficulty)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          path.difficulty[0].toUpperCase() +
                              path.difficulty.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(path.difficulty),
                          ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress with new progress widget
            Padding(
              padding: const EdgeInsets.all(16),
              child: LearningPathProgressWidget(
                learningPath: path,
                isCompact: true,
              ),
            ),

            // Description
            if (path.description != null && path.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  path.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            // Tags
            if (path.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: path.tags
                      .take(5) // Limit to prevent overcrowding
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
              children: [
                  // View button
                  TextButton.icon(
                    onPressed: () => _onPathTap(path),
                        icon: Icon(
                      PhosphorIcons.arrowUpRight(PhosphorIconsStyle.fill),
                      size: 16,
                    ),
                    label: const Text('View'),
                        style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Set as active button (shown only if not active)
                  if (!path.isActive)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await LearningPathService.setActiveLearningPath(
                            path.id);
                        _loadLearningPaths();
                      },
                      icon: Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: 16,
                      ),
                      label: const Text('Set as Active'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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

  /// Get color for difficulty level
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
