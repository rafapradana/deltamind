import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

class ActivityCalendarCard extends StatelessWidget {
  final Map<String, int> activityData;

  const ActivityCalendarCard({Key? key, required this.activityData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: 20),

            // Calendar grid
            _buildCalendarGrid(context),

            const SizedBox(height: 16),

            // Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            PhosphorIconsFill.calendar,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Calendar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Track your daily learning progress',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    // Calculate the first day of the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Calculate the first day to display (go back to previous month if needed)
    final firstDayToDisplay = _findFirstDayToDisplay(firstDayOfMonth);

    // Build day headers (S M T W T F S)
    final dayLabels = _buildDayLabels(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayLabels,
        ),
        const SizedBox(height: 8),

        // Calendar grid - using a more structured approach
        Container(
          constraints: const BoxConstraints(
            minHeight: 200, // Ensure enough height for the calendar
          ),
          child: Column(
            children: _buildCalendarWeeks(context, firstDayToDisplay),
          ),
        ),
      ],
    );
  }

  // Find the first day to display (previous month's last days to fill the first row)
  DateTime _findFirstDayToDisplay(DateTime firstDayOfMonth) {
    // Find the first day of the first week to display
    // If the month doesn't start on Sunday, we need to include some days from the previous month
    int daysToSubtract = firstDayOfMonth.weekday % 7;
    return firstDayOfMonth.subtract(Duration(days: daysToSubtract));
  }

  // Build the entire calendar grid week by week
  List<Widget> _buildCalendarWeeks(BuildContext context, DateTime firstDay) {
    final now = DateTime.now();
    List<Widget> weeks = [];
    DateTime currentDay = firstDay;

    // Build 5 weeks (enough to show a full month plus padding)
    for (int week = 0; week < 5; week++) {
      List<Widget> days = [];

      // Build 7 days for each week
      for (int day = 0; day < 7; day++) {
        // Skip future days
        if (currentDay.isAfter(now)) {
          days.add(
            const SizedBox(width: 30, height: 30),
          ); // Empty space for future days
        } else {
          days.add(_buildDayCell(context, currentDay));
        }
        currentDay = currentDay.add(const Duration(days: 1));
      }

      // Add the week row
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days,
          ),
        ),
      );
    }

    return weeks;
  }

  List<Widget> _buildDayLabels(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return days
        .map(
          (day) => SizedBox(
            width: 30,
            child: Text(
              day,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
        .toList();
  }

  Widget _buildDayCell(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final count = activityData[dateStr] ?? 0;

    // Determine color based on activity count
    final color = _getColorForCount(count);

    // Check if date is today
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    // Check if date is in current month
    final isCurrentMonth = date.month == DateTime.now().month;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isCurrentMonth ? color : color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: AppColors.accent, width: 2) : null,
      ),
      child: Center(
        child:
            count > 0
                ? Text(
                  count.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: count > 3 ? Colors.white : AppColors.primary,
                  ),
                )
                : null,
      ),
    );
  }

  Color _getColorForCount(int count) {
    if (count == 0) return Colors.grey.withOpacity(0.1);
    if (count <= 2) return AppColors.primary.withOpacity(0.2);
    if (count <= 4) return AppColors.primary.withOpacity(0.5);
    return AppColors.primary.withOpacity(0.8);
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildLegendItem(context, '0', Colors.grey.withOpacity(0.1)),
        const SizedBox(width: 12),
        _buildLegendItem(context, '1-2', AppColors.primary.withOpacity(0.2)),
        const SizedBox(width: 12),
        _buildLegendItem(context, '3-4', AppColors.primary.withOpacity(0.5)),
        const SizedBox(width: 12),
        _buildLegendItem(context, '5+', AppColors.primary.withOpacity(0.8)),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
