import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/core/utils/formatters.dart';
import 'package:deltamind/models/learning_path.dart';
import 'package:deltamind/services/learning_path_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Learning path detail page with node graph
class LearningPathDetailPage extends StatefulWidget {
  final String pathId;

  const LearningPathDetailPage({
    Key? key,
    required this.pathId,
  }) : super(key: key);

  @override
  State<LearningPathDetailPage> createState() => _LearningPathDetailPageState();
}

class _LearningPathDetailPageState extends State<LearningPathDetailPage> {
  bool _isLoading = true;
  LearningPath? _path;
  String? _errorMessage;
  LearningPathModule? _selectedModule;

  @override
  void initState() {
    super.initState();
    _loadLearningPath();
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

    return Column(
      children: [
        _buildPathHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Module list (2/3 of screen)
              Expanded(
                flex: 2,
                child: _buildModuleGraph(),
              ),

              // Details panel (1/3 of screen)
              Expanded(
                flex: 1,
                child: _selectedModule == null
                    ? _buildPathOverview()
                    : _buildModuleDetail(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build path header with title and progress
  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              if (_path!.isActive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active Path',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _path!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Progress: ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${_path!.progress}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _path!.progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _path!.progress >= 100
                            ? Colors.green
                            : AppColors.primary,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Created: ${formatDate(_path!.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a module flow visualization
  Widget _buildModuleGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.roadHorizon(PhosphorIconsStyle.fill),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Learning Module Flow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _path!.modules.length,
                  itemBuilder: (context, index) {
                    final module = _path!.modules[index];
                    final bool isSelected = _selectedModule != null &&
                        _selectedModule!.id == module.id;

                    return _buildModuleNode(module, index, isSelected);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a module node
  Widget _buildModuleNode(
      LearningPathModule module, int index, bool isSelected) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData iconData;

    switch (module.status) {
      case ModuleStatus.done:
        bgColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
        iconData = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
        break;
      case ModuleStatus.inProgress:
        bgColor = AppColors.primary.withOpacity(0.1);
        borderColor = AppColors.primary;
        textColor = AppColors.primary;
        iconData = PhosphorIcons.caretRight(PhosphorIconsStyle.fill);
        break;
      case ModuleStatus.locked:
      default:
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade400;
        textColor = Colors.grey.shade700;
        iconData = PhosphorIcons.lock(PhosphorIconsStyle.fill);
        break;
    }

    if (isSelected) {
      borderColor = Colors.blue;
    }

    // Show connector line between modules
    return Column(
      children: [
        // Show connector line except for the first module
        if (index > 0)
          Container(
            height: 30,
            width: 2,
            color: _path!.modules[index - 1].status == ModuleStatus.done
                ? Colors.green
                : Colors.grey.shade300,
          ),

        // Module card
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedModule = module;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(iconData, color: textColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Module ${module.moduleId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  module.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the path overview (when no module is selected)
  Widget _buildPathOverview() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Path Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (_path!.description != null && _path!.description!.isNotEmpty) ...[
            Text(
              _path!.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
          ],
          const SizedBox(height: 16),
          Text(
            'Modules',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
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

  /// Build the module detail panel
  Widget _buildModuleDetail() {
    if (_selectedModule == null) return Container();

    final module = _selectedModule!;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Module ${module.moduleId}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.fill)),
                onPressed: () => setState(() => _selectedModule = null),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            module.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatusSelector(module),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            module.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Learning objectives
          if (module.learningObjectives.isNotEmpty) ...[
            Text(
              'Learning Objectives',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...module.learningObjectives.map((objective) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(objective),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Resources
          if (module.resources.isNotEmpty) ...[
            Text(
              'Resources',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...module.resources.map((resource) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.link(PhosphorIconsStyle.fill),
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resource,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Estimated duration
          if (module.estimatedDuration != null) ...[
            Row(
              children: [
                Icon(
                  PhosphorIcons.clock(PhosphorIconsStyle.fill),
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estimated time: ${module.estimatedDuration}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Assessment
          if (module.assessment != null) ...[
            Text(
              'Assessment',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(module.assessment!),
            const SizedBox(height: 16),
          ],

          // Additional notes
          if (module.additionalNotes != null) ...[
            Text(
              'Additional Notes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Text(module.additionalNotes!),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                    Text(
                      'Module ${module.moduleId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      module.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
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

  /// Build module status selector
  Widget _buildStatusSelector(LearningPathModule module) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Status:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Locked
        Opacity(
          opacity: module.status == ModuleStatus.locked ? 1.0 : 0.5,
          child: ChoiceChip(
            label: const Text('Locked'),
            selected: module.status == ModuleStatus.locked,
            onSelected: (selected) {
              if (selected) {
                _updateModuleStatus(module, ModuleStatus.locked);
              }
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.grey.shade300,
            labelStyle: TextStyle(
              color: module.status == ModuleStatus.locked
                  ? Colors.grey.shade900
                  : Colors.grey.shade700,
              fontWeight: module.status == ModuleStatus.locked
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // In Progress
        Opacity(
          opacity: module.status == ModuleStatus.inProgress ? 1.0 : 0.5,
          child: ChoiceChip(
            label: const Text('In Progress'),
            selected: module.status == ModuleStatus.inProgress,
            onSelected: (selected) {
              if (selected) {
                _updateModuleStatus(module, ModuleStatus.inProgress);
              }
            },
            backgroundColor: AppColors.primary.withOpacity(0.1),
            selectedColor: AppColors.primary.withOpacity(0.3),
            labelStyle: TextStyle(
              color: module.status == ModuleStatus.inProgress
                  ? AppColors.primary
                  : Colors.grey.shade700,
              fontWeight: module.status == ModuleStatus.inProgress
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Done
        Opacity(
          opacity: module.status == ModuleStatus.done ? 1.0 : 0.5,
          child: ChoiceChip(
            label: const Text('Done'),
            selected: module.status == ModuleStatus.done,
            onSelected: (selected) {
              if (selected) {
                _updateModuleStatus(module, ModuleStatus.done);
              }
            },
            backgroundColor: Colors.green.withOpacity(0.1),
            selectedColor: Colors.green.withOpacity(0.3),
            labelStyle: TextStyle(
              color: module.status == ModuleStatus.done
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
              fontWeight: module.status == ModuleStatus.done
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
