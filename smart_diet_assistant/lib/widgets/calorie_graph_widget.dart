import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';

class CalorieGraphWidget extends StatefulWidget {
  final UserProvider userProvider;

  const CalorieGraphWidget({super.key, required this.userProvider});

  @override
  State<CalorieGraphWidget> createState() => _CalorieGraphWidgetState();
}

class _CalorieGraphWidgetState extends State<CalorieGraphWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _weekData = [];
  List<Map<String, dynamic>> _monthData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild chart on tab change
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final week = await widget.userProvider.getCalorieHistory(7);
    final month = await widget.userProvider.getCalorieHistory(30);
    
    // If today is tracked in the week data, we might want to update it to current consumed calories
    if (week.isNotEmpty) {
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      for (var day in week) {
        if ((day['date'] as DateTime).toIso8601String().substring(0, 10) == nowStr) {
          day['calories'] = widget.userProvider.totalConsumedCalories;
        }
      }
    }

    if (month.isNotEmpty) {
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      for (var day in month) {
        if ((day['date'] as DateTime).toIso8601String().substring(0, 10) == nowStr) {
          day['calories'] = widget.userProvider.totalConsumedCalories;
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _weekData = week;
        _monthData = month;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calorie Tracking',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  Icons.bar_chart_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Week'),
                  Tab(text: 'Month'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, left: 8),
                child: _buildChart(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final isWeek = _tabController.index == 0;
    final data = isWeek ? _weekData : _monthData;
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    double maxY = widget.userProvider.tdee;
    for (var day in data) {
      if (day['calories'] > maxY) {
        maxY = (day['calories'] as num).toDouble();
      }
    }
    // Give 10% padding on top
    maxY = maxY * 1.1;
    // ensure at least some Y axis if all zeros
    if (maxY == 0) maxY = 2000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} kcal\n',
                GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: DateFormat('MMM d').format(data[group.x.toInt()]['date']),
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                
                final date = data[index]['date'] as DateTime;
                String text = '';
                
                if (isWeek) {
                  text = DateFormat('E').format(date); // Mon, Tue, etc.
                } else {
                  // For month, show fewer labels to avoid clutter
                  if (index % 5 == 0 || index == data.length - 1) {
                    text = DateFormat('d').format(date);
                  }
                }
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 36,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (index) {
          final cal = (data[index]['calories'] as num).toDouble();
          final isToday = index == data.length - 1;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: cal,
                color: isToday 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                width: isWeek ? 22 : 6,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: widget.userProvider.tdee,
              color: Colors.redAccent.withValues(alpha: 0.8),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => 'Goal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
