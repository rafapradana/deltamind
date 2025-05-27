import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DailyStreakGraph extends StatefulWidget {
  final Map<String, dynamic> streakData;

  const DailyStreakGraph({Key? key, required this.streakData})
    : super(key: key);

  @override
  State<DailyStreakGraph> createState() => _DailyStreakGraphState();
}

class _DailyStreakGraphState extends State<DailyStreakGraph> {

  @override
  Widget build(BuildContext context) {
    // Get current streak value
    final currentStreak = widget.streakData['current_streak'] as int? ?? 0;

    // Generate graph data using currentStreak
    final List<Map<String, dynamic>> streakHistory = _generateStreakHistory(
      currentStreak,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withAlpha(76)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily Streak',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currentStreak',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'days',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            streakHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No streak data available',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : _buildCalendarView(streakHistory),
            if (widget.streakData['longest_streak'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Longest streak: ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: '${widget.streakData['longest_streak']} days',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(List<Map<String, dynamic>> streakHistory) {
    // Group days into rows (3 rows of 5 days each)
    List<List<Map<String, dynamic>>> rows = [];
    
    for (int i = 0; i < 3; i++) {
      int startIndex = i * 5;
      int endIndex = startIndex + 5;
      if (endIndex > streakHistory.length) endIndex = streakHistory.length;
      
      if (startIndex < streakHistory.length) {
        rows.add(streakHistory.sublist(startIndex, endIndex));
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Table(
        // Use a table layout which handles distribution automatically
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows.map((rowData) {
          return TableRow(
            children: rowData.map((data) {
              final DateTime date = DateTime.parse(data['date']);
              final bool hasStreak = data['streak'] > 0;
              
              return _buildDayItem(
                date: date,
                hasStreak: hasStreak,
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildDayItem({required DateTime date, required bool hasStreak}) {
    final String dayLabel = DateFormat('E').format(date).substring(0, 1);
    final String dateLabel = date.day.toString();
    final bool isToday = _isToday(date);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important: use minimum space needed
        children: [
          // Day of week (Mon, Tue, etc.)
          Text(
            dayLabel,
            style: TextStyle(
              fontSize: 10, // Smaller font
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          
          // Date with circle background for today
          Container(
            width: 24,
            height: 24,
            decoration: isToday ? BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ) : null,
            child: Center(
              child: Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          
          // Fire icon (blue for streak, grey for no streak)
          Icon(
            PhosphorIconsFill.fire,
            color: hasStreak ? AppColors.primary : Colors.grey.shade400,
            size: 20, // Smaller icon
          ),
        ],
      ),
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Generate a simulated streak history based on the current streak
  List<Map<String, dynamic>> _generateStreakHistory(int currentStreak) {
    final List<Map<String, dynamic>> history = [];
    final today = DateTime.now();

    // Show the past 15 days for the 5x3 grid
    final daysToShow = 15;

    for (int i = daysToShow - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      
      // If we're within the streak days, mark as active
      if (i < currentStreak) {
        // Day has an active streak
        history.add({'date': date.toIso8601String(), 'streak': 1});
      } else {
        // Day doesn't have an active streak
        history.add({'date': date.toIso8601String(), 'streak': 0});
      }
    }

    return history;
  }
}
