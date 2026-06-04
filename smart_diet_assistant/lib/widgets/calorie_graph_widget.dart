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
  double _touchedValue = -1;

  @override
  void initState() {
    super.initState();
    _touchedValue = -1;
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
    maxY = maxY * 1.1;
    if (maxY == 0) maxY = 2000;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: primaryColor,
                  strokeWidth: 4,
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 8,
                      color: Colors.white,
                      strokeWidth: 5,
                      strokeColor: primaryColor,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => primaryColor,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = data[barSpot.x.toInt()]['date'] as DateTime;
                String dateStr = DateFormat('MMM d').format(date);
                if (isWeek) {
                  dateStr = DateFormat('E').format(date);
                }

                return LineTooltipItem(
                  '$dateStr \n',
                  GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: barSpot.y.round().toString(),
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' kcal',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? lineTouch) {
            if (!event.isInterestedForInteractions || lineTouch == null || lineTouch.lineBarSpots == null) {
              setState(() {
                _touchedValue = -1;
              });
              return;
            }
            final value = lineTouch.lineBarSpots![0].x;
            setState(() {
              _touchedValue = value;
            });
          },
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: widget.userProvider.tdee,
              color: Colors.redAccent.withValues(alpha: 0.8),
              strokeWidth: 2,
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
        lineBarsData: [
          LineChartBarData(
            isStepLineChart: true,
            spots: List.generate(data.length, (index) {
              return FlSpot(index.toDouble(), (data[index]['calories'] as num).toDouble());
            }),
            isCurved: false,
            barWidth: 4,
            color: primaryColor,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.5),
                  primaryColor.withValues(alpha: 0),
                ],
                stops: const [0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              spotsLine: BarAreaSpotsLine(
                show: true,
                flLineStyle: FlLine(
                  color: primaryColor.withValues(alpha: 0.2),
                  strokeWidth: 2,
                ),
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: primaryColor.withValues(alpha: 0.5),
                );
              },
            ),
          ),
        ],
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 4,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return FlLine(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                strokeWidth: 2,
              );
            }
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            if (value == 0) {
              return FlLine(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                strokeWidth: 2,
              );
            }
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value % 1 != 0) return const SizedBox.shrink();
                // show in k if >= 1000
                String text;
                if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
                } else {
                  text = value.toInt().toString();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    text,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();

                final isTouched = index == _touchedValue;
                final date = data[index]['date'] as DateTime;
                String text = '';

                if (isWeek) {
                  text = DateFormat('E').format(date);
                } else {
                  if (index % 5 == 0 || index == data.length - 1) {
                    text = DateFormat('d').format(date);
                  }
                }

                if (text.isEmpty) return const SizedBox.shrink();

                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
                  child: Text(
                    text,
                    style: GoogleFonts.outfit(
                      color: isTouched
                          ? primaryColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
