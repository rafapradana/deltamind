import 'package:deltamind/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuizAccuracyChart extends StatefulWidget {
  final List<Map<String, dynamic>> accuracyData;

  const QuizAccuracyChart({Key? key, required this.accuracyData})
    : super(key: key);

  @override
  State<QuizAccuracyChart> createState() => _QuizAccuracyChartState();
}

class _QuizAccuracyChartState extends State<QuizAccuracyChart> {
  List<Color> gradientColors = [
    AppColors.primary,
    AppColors.primary.withOpacity(0.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quiz Accuracy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child:
                  widget.accuracyData.isEmpty
                      ? Center(
                        child: Text(
                          'No quiz data available yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                      : _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider.withOpacity(0.3),
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
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: widget.accuracyData.length.toDouble() - 1,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(),
            isCurved: true,
            gradient: LinearGradient(colors: gradientColors),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors:
                    gradientColors
                        .map((color) => color.withOpacity(0.3))
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    if (value < 0 || value >= widget.accuracyData.length) {
      return const SizedBox.shrink();
    }

    final DateTime date = DateTime.parse(
      widget.accuracyData[value.toInt()]['attempt_date'],
    );
    final String text = DateFormat('MM/dd').format(date);

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      '${value.toInt()}%',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.left,
    );
  }

  List<FlSpot> _createSpots() {
    return List.generate(widget.accuracyData.length, (index) {
      final data = widget.accuracyData[index];
      final accuracy = data['accuracy_percentage'].toDouble();
      return FlSpot(index.toDouble(), accuracy > 100 ? 100 : accuracy);
    });
  }
}

// Utility class to fetch quiz accuracy data
class QuizAccuracyData {
  static Future<List<Map<String, dynamic>>> fetchAccuracyData() async {
    try {
      // This would typically call a service method, but we'll simulate direct from controller
      // Normally we would use SupabaseService or another service to fetch this data
      return [
        {'attempt_date': '2025-04-26 00:00:00+00', 'accuracy_percentage': 48.0},
        {
          'attempt_date': '2025-04-27 00:00:00+00',
          'accuracy_percentage': 70.6, // Capping at a sensible value
        },
        {'attempt_date': '2025-04-28 00:00:00+00', 'accuracy_percentage': 75.0},
        {
          'attempt_date': '2025-04-29 00:00:00+00',
          'accuracy_percentage': 51.85,
        },
      ];
    } catch (e) {
      print('Error fetching accuracy data: $e');
      return [];
    }
  }
}
