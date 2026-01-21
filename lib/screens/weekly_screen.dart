import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';

/// Weekly summary screen showing calorie trends.
class WeeklyScreen extends StatefulWidget {
  const WeeklyScreen({super.key});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  late DateTime _weekStart;
  Map<DateTime, int> _weeklyTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _loadWeekData();
  }

  /// Get the Monday of the given week.
  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    _weeklyTotals = await provider.getWeeklyTotals(_weekStart);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _loadWeekData();
  }

  void _nextWeek() {
    final nextWeekStart = _weekStart.add(const Duration(days: 7));
    if (nextWeekStart.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      setState(() {
        _weekStart = nextWeekStart;
      });
      _loadWeekData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dailyGoal = provider.dailyGoal;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');

    // Calculate statistics
    int totalCalories = 0;
    int daysWithEntries = 0;
    int daysOverGoal = 0;
    int daysUnderGoal = 0;

    for (int i = 0; i < 7; i++) {
      final date = _weekStart.add(Duration(days: i));
      final dayDate = DateTime(date.year, date.month, date.day);
      final calories = _weeklyTotals[dayDate] ?? 0;

      if (calories > 0) {
        totalCalories += calories;
        daysWithEntries++;
        if (calories > dailyGoal) {
          daysOverGoal++;
        } else {
          daysUnderGoal++;
        }
      }
    }

    final avgCalories = daysWithEntries > 0
        ? (totalCalories / daysWithEntries).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Summary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Week navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousWeek,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${dateFormat.format(_weekStart)} - ${dateFormat.format(weekEnd)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextWeek,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total',
                          value: '$totalCalories',
                          subtitle: 'kcal',
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Average',
                          value: '$avgCalories',
                          subtitle: 'kcal/day',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Under Goal',
                          value: '$daysUnderGoal',
                          subtitle: 'days',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Over Goal',
                          value: '$daysOverGoal',
                          subtitle: 'days',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Calories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _WeeklyChart(
                              weekStart: _weekStart,
                              totals: _weeklyTotals,
                              goal: dailyGoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Daily breakdown
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(7, (index) {
                    final date = _weekStart.add(Duration(days: index));
                    final dayDate = DateTime(date.year, date.month, date.day);
                    final calories = _weeklyTotals[dayDate] ?? 0;
                    final isToday = _isToday(date);

                    return _DayRow(
                      date: date,
                      calories: calories,
                      goal: dailyGoal,
                      isToday: isToday,
                    );
                  }),
                ],
              ),
            ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Summary card widget.
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Weekly bar chart widget.
class _WeeklyChart extends StatelessWidget {
  final DateTime weekStart;
  final Map<DateTime, int> totals;
  final int goal;

  const _WeeklyChart({
    required this.weekStart,
    required this.totals,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find max value for chart scaling
    int maxValue = goal;
    for (final value in totals.values) {
      if (value > maxValue) maxValue = value;
    }
    maxValue = ((maxValue / 500).ceil() * 500).toInt();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} kcal',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayLabels[value.toInt()],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxValue / 2 || value == maxValue) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 4,
          getDrawingHorizontalLine: (value) {
            if (value == goal) {
              return FlLine(
                color: Colors.red.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final dayDate = DateTime(date.year, date.month, date.day);
          final calories = totals[dayDate] ?? 0;
          final isOverGoal = calories > goal;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: calories.toDouble(),
                color: isOverGoal ? Colors.orange : Colors.teal,
                width: 24,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Day row widget for breakdown list.
class _DayRow extends StatelessWidget {
  final DateTime date;
  final int calories;
  final int goal;
  final bool isToday;

  const _DayRow({
    required this.date,
    required this.calories,
    required this.goal,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('EEE, MMM d');
    final isOverGoal = calories > goal;
    final progress = goal > 0 ? (calories / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isToday ? Colors.teal.shade50 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              dayFormat.format(date),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  isOverGoal ? Colors.orange : Colors.teal,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              calories > 0 ? '$calories kcal' : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOverGoal ? Colors.orange : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
