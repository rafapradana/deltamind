import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../services/analytics_service.dart';

/// Calendar showing daily quiz activity
class ActivityCalendar extends StatefulWidget {
  const ActivityCalendar({super.key});

  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  Map<String, int> _activityData = {};
  bool _isLoading = true;
  String _selectedDate = '';
  int _selectedCount = 0;
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AnalyticsService.getDailyActivityAnalytics();
      setState(() {
        _activityData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading activity data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Color _getColorForCount(int count) {
    if (count == 0) return Colors.grey.withOpacity(0.2);
    if (count <= 2) return AppColors.primary.withOpacity(0.3);
    if (count <= 4) return AppColors.primary.withOpacity(0.6);
    return AppColors.primary;
  }

  Widget _buildDayCell(DateTime date) {
    final dateKey = _formatDate(date);
    final count = _activityData[dateKey] ?? 0;
    final isSelected = dateKey == _selectedDate;

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _hasSelection = false;
            _selectedDate = '';
            _selectedCount = 0;
          } else {
            _hasSelection = true;
            _selectedDate = dateKey;
            _selectedCount = count;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _getColorForCount(count),
          borderRadius: BorderRadius.circular(4),
          border:
              isSelected
                  ? Border.all(color: AppColors.secondary, width: 2)
                  : null,
        ),
      ),
    );
  }

  List<Widget> _buildCalendarDays() {
    final now = DateTime.now();
    final daysToShow = 30;
    final startDate = now.subtract(Duration(days: daysToShow - 1));

    List<Widget> days = [];
    for (int i = 0; i < daysToShow; i++) {
      final date = startDate.add(Duration(days: i));
      days.add(_buildDayCell(date));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Calendar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 30 Days Quiz Activity',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: GridView.count(
                        crossAxisCount: 6,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: _buildCalendarDays(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_hasSelection) ...[
                      Text(
                        'Selected Date: $_selectedDate',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_selectedCount ${_selectedCount == 1 ? "quiz" : "quizzes"} completed',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildLegendItem('0', Colors.grey.withOpacity(0.2)),
                        const SizedBox(width: 8),
                        _buildLegendItem(
                          '1-2',
                          AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(width: 8),
                        _buildLegendItem(
                          '3-4',
                          AppColors.primary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        _buildLegendItem('5+', AppColors.primary),
                      ],
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
