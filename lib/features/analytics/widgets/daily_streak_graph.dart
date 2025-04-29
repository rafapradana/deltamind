import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DailyStreakGraph extends StatefulWidget {
  final Map<String, dynamic> streakData;

  const DailyStreakGraph({Key? key, required this.streakData})
    : super(key: key);

  @override
  State<DailyStreakGraph> createState() => _DailyStreakGraphState();
}

class _DailyStreakGraphState extends State<DailyStreakGraph> {
  List<Color> gradientColors = [
    AppColors.primary,
    AppColors.primary.withAlpha(128),
  ];

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
            SizedBox(
              height: 200,
              child:
                  streakHistory.isEmpty
                      ? Center(
                        child: Text(
                          'No streak data available',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                      : _buildLineChart(streakHistory),
            ),
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

  Widget _buildLineChart(List<Map<String, dynamic>> streakHistory) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider.withAlpha(76),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget:
                  (double value, TitleMeta meta) =>
                      _bottomTitleWidgets(value, meta, streakHistory),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: streakHistory.length.toDouble() - 1,
        minY: 0,
        maxY: _getMaxY(streakHistory),
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(streakHistory),
            isCurved: true,
            gradient: LinearGradient(colors: gradientColors),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors:
                    gradientColors.map((color) => color.withAlpha(76)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> streakHistory) {
    if (streakHistory.isEmpty) return 5;
    double maxStreak = 0;
    for (var data in streakHistory) {
      final streak = data['streak'] as double;
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak + 1;
  }

  Widget _bottomTitleWidgets(
    double value,
    TitleMeta meta,
    List<Map<String, dynamic>> streakHistory,
  ) {
    if (value < 0 || value >= streakHistory.length) {
      return const SizedBox.shrink();
    }

    final DateTime date = DateTime.parse(streakHistory[value.toInt()]['date']);
    final String text = DateFormat('MM/dd').format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      value.toInt().toString(),
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.left,
    );
  }

  List<FlSpot> _createSpots(List<Map<String, dynamic>> streakHistory) {
    return List.generate(streakHistory.length, (index) {
      final data = streakHistory[index];
      final streak = data['streak'] as double;
      return FlSpot(index.toDouble(), streak);
    });
  }

  // Generate a simulated streak history based on the current streak
  List<Map<String, dynamic>> _generateStreakHistory(int currentStreak) {
    final List<Map<String, dynamic>> history = [];
    final today = DateTime.now();

    // If streak is 0, show empty graph
    if (currentStreak == 0) {
      return history;
    }

    // Generate the last 7 days or the current streak length, whichever is greater
    final daysToShow = currentStreak > 7 ? currentStreak : 7;

    // Start with a value of 1 (day 1 of streak)
    double streakValue = 1;

    for (int i = daysToShow - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));

      // If we're within the streak days, increment the streak value
      if (i < currentStreak) {
        history.add({'date': date.toIso8601String(), 'streak': streakValue});
        streakValue++;
      } else {
        // For days before the streak started, show 0
        history.add({'date': date.toIso8601String(), 'streak': 0});
      }
    }

    return history;
  }
}
