import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/core/utils/formatters.dart';
import 'package:deltamind/models/learning_path.dart';
import 'package:deltamind/services/learning_path_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Learning path detail page
class LearningPathDetailPage extends StatefulWidget {
  final String pathId;

  const LearningPathDetailPage({
    Key? key,
    required this.pathId,
  }) : super(key: key);

  @override
  State<LearningPathDetailPage> createState() => _LearningPathDetailPageState();
}

class _LearningPathDetailPageState extends State<LearningPathDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  LearningPath? _path;
  String? _errorMessage;
  LearningPathModule? _selectedModule;
  late TabController _tabController;

  // For detecting mobile view
  bool get _isMobileView => MediaQuery.of(context).size.width < 800;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLearningPath();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load learning path details
  Future<void> _loadLearningPath() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedModule = null;
    });

    try {
      final path = await LearningPathService.getLearningPath(widget.pathId);

      if (!mounted) return;

      setState(() {
        _path = path;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load learning path: $e';
          _isLoading = false;
        });
      }
    }
  }



  /// Update a module's status
  Future<void> _updateModuleStatus(
    LearningPathModule module,
    ModuleStatus newStatus,
  ) async {
    try {
      setState(() => _isLoading = true);

      final updatedModule = await LearningPathService.updateModuleStatus(
        module.id,
        newStatus,
      );

      if (!mounted) return;

      // Update the module in the path
      final moduleIndex = _path!.modules.indexWhere(
        (m) => m.id == updatedModule.id,
      );

      if (moduleIndex != -1) {
        setState(() {
          _path!.modules[moduleIndex] = updatedModule;
          _selectedModule = updatedModule;
          _isLoading = false;
        });


      } else {
        // If module isn't found, refresh the entire path
        await _loadLearningPath();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error updating module status: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_path?.title ?? 'Learning Path'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.fill)),
            onPressed: _loadLearningPath,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildPathView(),
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
            onPressed: _loadLearningPath,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build the path view
  Widget _buildPathView() {
    if (_path == null) {
      return const Center(child: Text('Path not found'));
    }

    // Mobile view 
    if (_isMobileView) {
      return Column(
        children: [
          _buildPathHeader(),
          Expanded(
            child: _selectedModule == null
                ? _buildPathOverview()
                : _buildModuleDetail(),
          ),
        ],
      );
    }

    // Desktop view
    return Column(
      children: [
        _buildPathHeader(),
        Expanded(
          child: _selectedModule == null
              ? _buildPathOverview()
              : _buildModuleDetail(),
        ),
      ],
    );
  }

  /// Build path header with title and progress
  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with active badge and star icon
          Row(
            children: [
              if (_path!.isActive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active Path',
                    style: TextStyle(
                      fontSize: 10, // Smaller font
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _path!.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _path!.isActive
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.star(PhosphorIconsStyle.fill),
                  color: _path!.isActive ? Colors.green : null,
                  size: 20, // Smaller icon
                ),
                onPressed: _path!.isActive
                    ? null
                    : () async {
                        await LearningPathService.setActiveLearningPath(
                          _path!.id,
                        );
                        _loadLearningPath();
                      },
                tooltip: _path!.isActive ? 'Active Path' : 'Set as Active Path',
                padding: EdgeInsets.zero, // Reduce padding on the icon button
                visualDensity:
                    VisualDensity.compact, // Make the button more compact
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Compact progress section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress indicator with percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Progress: ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${_path!.progress}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        // Created date
                        Text(
                          formatDate(_path!.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar with full width
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _path!.progress / 100,
                        minHeight: 4, // Make the bar thinner
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _path!.progress >= 100
                              ? Colors.green
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build module selector for mobile view - more compact
  Widget _buildMobileModuleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 6, horizontal: 10), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: Icon(
            PhosphorIcons.caretDown(PhosphorIconsStyle.fill),
            size: 16, // Smaller icon
          ),
          hint: Text(
            'Select a module',
            style: TextStyle(fontSize: 12), // Smaller font
          ),
          value: _selectedModule?.id,
          items: _path!.modules.map((module) {
            return DropdownMenuItem<String>(
              value: module.id,
              child: Text(
                '${module.moduleId}: ${module.title}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 12), // Smaller font
              ),
            );
          }).toList(),
          onChanged: (moduleId) {
            if (moduleId != null) {
              final module = _path!.modules.firstWhere((m) => m.id == moduleId);
              setState(() => _selectedModule = module);

              // Switch to overview tab to show the selected module
              if (_isMobileView) {
                _tabController.animateTo(0);
              }
            }
          },
          isDense: true, // Make dropdown more compact
        ),
      ),
    );
  }

  /// Build a module node for the graph with improved design
  Widget _buildModuleNode(LearningPathModule module) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconBgColor;
    IconData iconData;
    bool isSelected =
        _selectedModule != null && _selectedModule!.id == module.id;

    // Determine colors based on status with enhanced visual hierarchy
    switch (module.status) {
      case ModuleStatus.done:
        bgColor = Colors.green.withOpacity(0.08);
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
        iconBgColor = Colors.green;
        iconData = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
        break;
      case ModuleStatus.inProgress:
        bgColor = AppColors.primary.withOpacity(0.08);
        borderColor = AppColors.primary;
        textColor = AppColors.primary;
        iconBgColor = AppColors.primary;
        iconData = PhosphorIcons.playCircle(PhosphorIconsStyle.fill);
        break;
      case ModuleStatus.locked:
      default:
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        iconBgColor = Colors.grey.shade400;
        iconData = PhosphorIcons.lock(PhosphorIconsStyle.fill);
        break;
    }

    if (isSelected) {
      borderColor = Colors.blue.shade400;
      bgColor = Colors.blue.withOpacity(0.05);
    }

    // Helper function to get color for difficulty level
    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return Colors.green;
        case 'intermediate':
          return Colors.orange;
        case 'advanced':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    // Enhanced module card with better visual hierarchy and information display
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedModule = module;
        });

        // Switch to overview tab on mobile
        if (_isMobileView) {
          _tabController.animateTo(0);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: _isMobileView ? 120 : 180,
          minWidth: _isMobileView ? 100 : 150,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge and module number with color coding
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconData,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        module.status == ModuleStatus.done
                            ? 'Completed'
                            : module.status == ModuleStatus.inProgress
                                ? 'In Progress'
                                : 'Locked',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Module number with emphasized styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: textColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'M${module.moduleId}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Difficulty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: getDifficultyColor(module.difficulty).withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: getDifficultyColor(module.difficulty),
                  width: 0.5,
                ),
              ),
              child: Text(
                module.difficulty.substring(0, 1).toUpperCase() +
                    module.difficulty.substring(1).toLowerCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: getDifficultyColor(module.difficulty),
                ),
              ),
            ),

            const SizedBox(height: 4),
            // Module title with better prominence
            Text(
              module.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Time estimate with icon
            if (module.estimatedDuration != null) ...[
              Row(
                children: [
                  Icon(
                    PhosphorIcons.clock(PhosphorIconsStyle.fill),
                    size: 10,
                    color: textColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      module.estimatedDuration!,
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            // Dependencies indicator for better visualization of relationships
            if (module.dependencies.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    PhosphorIcons.arrowsIn(PhosphorIconsStyle.fill),
                    size: 10,
                    color: textColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Depends on: ${module.dependencies.map((e) => 'M$e').join(', ')}',
                      style: TextStyle(
                        fontSize: 9,
                        color: textColor.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build legend for graph symbols with improved design
  Widget _buildGraphLegend() {
    // Helper function to get color for difficulty levels
    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return Colors.green;
        case 'intermediate':
          return Colors.orange;
        case 'advanced':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Module status section
          Text(
            'Module Status:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'In Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.lock(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Locked',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Difficulty section
          const SizedBox(height: 8),
          Text(
            'Difficulty Level:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: getDifficultyColor('beginner').withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: getDifficultyColor('beginner'),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Beginner',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: getDifficultyColor('beginner'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          getDifficultyColor('intermediate').withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: getDifficultyColor('intermediate'),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Intermediate',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: getDifficultyColor('intermediate'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: getDifficultyColor('advanced').withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: getDifficultyColor('advanced'),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Advanced',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: getDifficultyColor('advanced'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the path overview (when no module is selected)
  Widget _buildPathOverview() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.list(PhosphorIconsStyle.fill),
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Path Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_path!.description != null && _path!.description!.isNotEmpty) ...[
            Text(
              _path!.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],

          // Module count and filter options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modules (${_path!.modules.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_isMobileView)
                IconButton(
                  icon: Icon(PhosphorIcons.graph(PhosphorIconsStyle.fill)),
                  onPressed: () => _tabController.animateTo(1),
                  tooltip: 'Show Graph View',
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Module status stats
          _buildModuleStats(),
          const SizedBox(height: 16),

          // Module list
          ...List.generate(
            _path!.modules.length,
            (index) {
              final module = _path!.modules[index];
              return _buildModuleListItem(module);
            },
          ),
        ],
      ),
    );
  }

  /// Build module stats section - fix ParentDataWidget errors
  Widget _buildModuleStats() {
    final totalModules = _path!.modules.length;
    final completedModules =
        _path!.modules.where((m) => m.status == ModuleStatus.done).length;
    final inProgressModules =
        _path!.modules.where((m) => m.status == ModuleStatus.inProgress).length;
    final lockedModules =
        _path!.modules.where((m) => m.status == ModuleStatus.locked).length;

    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            count: completedModules,
            total: totalModules,
            label: 'Completed',
            color: Colors.green,
            icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          ),
          _buildStatDivider(),
          _buildStatItem(
            count: inProgressModules,
            total: totalModules,
            label: 'In Progress',
            color: AppColors.primary,
            icon: PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
          ),
          _buildStatDivider(),
          _buildStatItem(
            count: lockedModules,
            total: totalModules,
            label: 'Locked',
            color: Colors.grey.shade600,
            icon: PhosphorIcons.lock(PhosphorIconsStyle.fill),
          ),
        ],
      ),
    );
  }

  /// Build a stat item without Expanded to fix ParentDataWidget error
  Widget _buildStatItem({
    required int count,
    required int total,
    required String label,
    required Color color,
    required PhosphorIconData icon,
  }) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    // Using Container instead of Expanded to fix ParentDataWidget error
    return Container(
      width: 70, // Fixed width for consistent sizing
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14), // Smaller icon
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12, // Smaller font
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, // Smaller font
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a stat divider
  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade300,
    );
  }

  /// Build module list item
  Widget _buildModuleListItem(LearningPathModule module) {
    Color color;
    IconData iconData;

    switch (module.status) {
      case ModuleStatus.done:
        color = Colors.green;
        iconData = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
        break;
      case ModuleStatus.inProgress:
        color = AppColors.primary;
        iconData = PhosphorIcons.caretRight(PhosphorIconsStyle.fill);
        break;
      case ModuleStatus.locked:
      default:
        color = Colors.grey.shade600;
        iconData = PhosphorIcons.lock(PhosphorIconsStyle.fill);
        break;
    }

    // Helper function to get color for difficulty level
    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return Colors.green;
        case 'intermediate':
          return Colors.orange;
        case 'advanced':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedModule = module),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Module ${module.moduleId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Difficulty indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: getDifficultyColor(module.difficulty)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: getDifficultyColor(module.difficulty),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            module.difficulty.substring(0, 1).toUpperCase() +
                                module.difficulty.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: getDifficultyColor(module.difficulty),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      module.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (module.estimatedDuration != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        module.estimatedDuration!,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the module detail panel
  Widget _buildModuleDetail() {
    if (_selectedModule == null) return Container();

    final module = _selectedModule!;

    // Helper function to get color for difficulty level
    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return Colors.green;
        case 'intermediate':
          return Colors.orange;
        case 'advanced':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 12), // Reduced margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1, // Reduced elevation
      child: ListView(
        padding: const EdgeInsets.all(12), // Reduced padding
        children: [
          // Header with close button and module info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Module ${module.moduleId}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        // Module difficulty indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: getDifficultyColor(module.difficulty)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: getDifficultyColor(module.difficulty),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            module.difficulty.substring(0, 1).toUpperCase() +
                                module.difficulty.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: getDifficultyColor(module.difficulty),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              if (!_isMobileView)
                IconButton(
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.fill)),
                  onPressed: () => setState(() => _selectedModule = null),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero, // Remove padding
                  visualDensity: VisualDensity.compact, // Make button compact
                ),
            ],
          ),

          // Mobile navigation buttons
          if (_isMobileView) ...[
            const SizedBox(height: 12), // Reduced spacing
            _buildModuleNavigationButtons(module),
            // No additional space needed here
          ],

          const SizedBox(height: 12), // Reduced spacing
          _buildStatusSelector(module),
          const SizedBox(height: 12), // Reduced spacing
          const Divider(height: 1), // Make divider thinner
          const SizedBox(height: 12), // Reduced spacing

          // Description
          _buildSectionHeader('Description'),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            module.description,
            style: Theme.of(context).textTheme.bodySmall, // Smaller text
          ),
          const SizedBox(height: 12), // Reduced spacing

          // Dependencies
          if (module.dependencies.isNotEmpty) ...[
            _buildSectionHeader('Dependencies'),
            const SizedBox(height: 6), // Reduced spacing
            Wrap(
              spacing: 6, // Reduced spacing
              runSpacing: 6, // Reduced spacing
              children: module.dependencies.map((dep) {
                // Find the module with this ID
                final depModule = _path!.modules.firstWhere(
                  (m) => m.moduleId == dep,
                  orElse: () => module,
                );

                return ActionChip(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  label: Text(
                    'Module $dep',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11, // Smaller font
                    ),
                  ),
                  avatar: Icon(
                    PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
                    color: AppColors.primary,
                    size: 14, // Smaller icon
                  ),
                  padding: EdgeInsets.zero, // Reduce padding
                  visualDensity: VisualDensity.compact, // Make chip compact
                  onPressed: () {
                    setState(() {
                      _selectedModule = depModule;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12), // Reduced spacing
          ],

          // Learning objectives
          if (module.learningObjectives.isNotEmpty) ...[
            _buildSectionHeader('Learning Objectives'),
            const SizedBox(height: 6), // Reduced spacing
            ...module.learningObjectives.map((objective) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6), // Reduced spacing
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
                      size: 14, // Smaller icon
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8), // Reduced spacing
                    Expanded(
                      child: Text(
                        objective,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall, // Smaller font
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12), // Reduced spacing
          ],

          // Resources
          if (module.resources.isNotEmpty) ...[
            _buildSectionHeader('Resources'),
            const SizedBox(height: 6), // Reduced spacing
            ...List.generate(module.resources.length, (index) {
              final resource = module.resources[index];

              // Get the difficulty for this resource
              String difficultyLevel = 'intermediate'; // Default fallback

              // Find matching resource difficulty by index if available
              if (module.resourceDifficulties.isNotEmpty) {
                final difficultyItem = module.resourceDifficulties.firstWhere(
                    (d) => d['index'] == index,
                    orElse: () => {'difficulty': difficultyLevel});
                difficultyLevel =
                    difficultyItem['difficulty'] ?? difficultyLevel;
              }

              return Padding(
                padding: const EdgeInsets.only(
                    bottom: 8), // Increased spacing for readability
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.link(PhosphorIconsStyle.fill),
                      size: 14, // Smaller icon
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8), // Reduced spacing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 12, // Smaller font
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: getDifficultyColor(difficultyLevel)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: getDifficultyColor(difficultyLevel),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              difficultyLevel.substring(0, 1).toUpperCase() +
                                  difficultyLevel.substring(1).toLowerCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: getDifficultyColor(difficultyLevel),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12), // Reduced spacing
          ],

          // Linked content
          if (module.noteId != null ||
              module.quizId != null ||
              module.deckId != null) ...[
            _buildSectionHeader('Linked Content'),
            const SizedBox(height: 6), // Reduced spacing
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (module.noteId != null)
                    SizedBox(
                      height: 32, // Fixed height for consistent sizing
                      child: ElevatedButton.icon(
                        icon: Icon(
                          PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                          size: 16, // Smaller icon
                        ),
                        label: Text(
                          'View Note',
                          style: TextStyle(fontSize: 11), // Smaller font
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/notes/${module.noteId}',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0), // Reduced padding
                        ),
                      ),
                    ),
                  if (module.noteId != null &&
                      (module.quizId != null || module.deckId != null))
                    const SizedBox(width: 8),
                  if (module.quizId != null)
                    SizedBox(
                      height: 32, // Fixed height for consistent sizing
                      child: ElevatedButton.icon(
                        icon: Icon(
                          PhosphorIcons.exam(PhosphorIconsStyle.fill),
                          size: 16, // Smaller icon
                        ),
                        label: Text(
                          'Take Quiz',
                          style: TextStyle(fontSize: 11), // Smaller font
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/quiz/${module.quizId}',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0), // Reduced padding
                        ),
                      ),
                    ),
                  if (module.quizId != null && module.deckId != null)
                    const SizedBox(width: 8),
                  if (module.deckId != null)
                    SizedBox(
                      height: 32, // Fixed height for consistent sizing
                      child: ElevatedButton.icon(
                        icon: Icon(
                          PhosphorIcons.cards(PhosphorIconsStyle.fill),
                          size: 16, // Smaller icon
                        ),
                        label: Text(
                          'Study Cards',
                          style: TextStyle(fontSize: 11), // Smaller font
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/flashcards/${module.deckId}/view',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0), // Reduced padding
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12), // Reduced spacing
          ],

          // Estimated duration
          if (module.estimatedDuration != null) ...[
            Row(
              children: [
                Icon(
                  PhosphorIcons.clock(PhosphorIconsStyle.fill),
                  size: 14, // Smaller icon
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8), // Reduced spacing
                Text(
                  'Estimated time: ${module.estimatedDuration}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced spacing
          ],

          // Assessment
          if (module.assessment != null) ...[
            _buildSectionHeader('Assessment'),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              module.assessment!,
              style: Theme.of(context).textTheme.bodySmall, // Smaller font
            ),
            const SizedBox(height: 12), // Reduced spacing
          ],

          // Additional notes
          if (module.additionalNotes != null) ...[
            _buildSectionHeader('Additional Notes'),
            const SizedBox(height: 6), // Reduced spacing
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6), // Smaller radius
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Text(
                module.additionalNotes!,
                style: Theme.of(context).textTheme.bodySmall, // Smaller font
              ),
            ),
            const SizedBox(height: 12), // Reduced spacing
          ],

          // Navigation buttons at bottom on mobile
          if (_isMobileView) ...[
            const Divider(height: 1), // Make divider thinner
            const SizedBox(height: 12), // Reduced spacing
            _buildModuleNavigationButtons(module),
            const SizedBox(height: 4), // Reduced spacing
          ],
        ],
      ),
    );
  }

  /// Build a section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
    );
  }

  /// Build module navigation buttons for mobile - fix ParentDataWidget errors
  Widget _buildModuleNavigationButtons(LearningPathModule currentModule) {
    // Find previous and next modules
    int currentIndex =
        _path!.modules.indexWhere((m) => m.id == currentModule.id);
    LearningPathModule? previousModule =
        currentIndex > 0 ? _path!.modules[currentIndex - 1] : null;
    LearningPathModule? nextModule = currentIndex < _path!.modules.length - 1
        ? _path!.modules[currentIndex + 1]
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        TextButton.icon(
          icon: Icon(
            PhosphorIcons.caretLeft(PhosphorIconsStyle.fill),
            size: 16,
          ),
          label: const Text('Previous'),
          onPressed: previousModule != null
              ? () => setState(() => _selectedModule = previousModule)
              : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
                horizontal: 8, vertical: 6), // Reduced padding
          ),
        ),

        // Close button
        IconButton(
          icon: Icon(
            PhosphorIcons.arrowUpRight(PhosphorIconsStyle.fill),
            size: 20,
          ),
          onPressed: () => setState(() => _selectedModule = null),
          tooltip: 'Show all modules',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),

        // Next button
        TextButton.icon(
          icon: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
            size: 16,
          ),
          label: const Text('Next'),
          onPressed: nextModule != null
              ? () => setState(() => _selectedModule = nextModule)
              : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
                horizontal: 8, vertical: 6), // Reduced padding
          ),
        ),
      ],
    );
  }

  /// Build module status selector - fix ParentDataWidget errors
  Widget _buildStatusSelector(LearningPathModule module) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        // Wrap in horizontal scrollview for smaller screens
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Locked
              SizedBox(
                height: 36, // Fixed height for consistent sizing
                child: _buildStatusButton(
                  module: module,
                  status: ModuleStatus.locked,
                  icon: PhosphorIcons.lock(PhosphorIconsStyle.fill),
                  label: 'Locked',
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),

              // In Progress
              SizedBox(
                height: 36, // Fixed height for consistent sizing
                child: _buildStatusButton(
                  module: module,
                  status: ModuleStatus.inProgress,
                  icon: PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
                  label: 'In Progress',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),

              // Done
              SizedBox(
                height: 36, // Fixed height for consistent sizing
                child: _buildStatusButton(
                  module: module,
                  status: ModuleStatus.done,
                  icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  label: 'Done',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a module status button
  Widget _buildStatusButton({
    required LearningPathModule module,
    required ModuleStatus status,
    required PhosphorIconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = module.status == status;

    return ElevatedButton.icon(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : color,
        size: 16, // Smaller icon
      ),
      label: Text(
        label,
        style: TextStyle(fontSize: 12), // Smaller font
      ),
      onPressed: () {
        if (!isSelected) {
          _updateModuleStatus(module, status);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color, width: 1),
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6), // Reduced padding
      ),
    );
  }
}
