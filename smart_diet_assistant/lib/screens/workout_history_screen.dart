import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _weekData = [];
  List<Map<String, dynamic>> _monthData = [];
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() => _touchedIndex = -1);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<UserProvider>();
    final week = await provider.getWorkoutHistory(7);
    final month = await provider.getWorkoutHistory(30);
    // patch today's data with live values
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    for (final d in [...week, ...month]) {
      if ((d['date'] as DateTime).toIso8601String().substring(0, 10) == todayStr) {
        d['totalBurned'] = provider.burnedCalories;
        d['logs'] = provider.workoutLogs;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Workout History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEBE5DF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: isDark ? const Color(0xFF3E3F43) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: const Color(0xFFF79E74),
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                      tabs: const [Tab(text: '7 Days'), Tab(text: '30 Days')],
                    ),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContent(_weekData, isDark, theme),
                      _buildContent(_monthData, isDark, theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> data, bool isDark, ThemeData theme) {
    final totalBurned = data.fold<int>(0, (s, d) => s + ((d['totalBurned'] as int?) ?? 0));
    final activeDays = data.where((d) => (d['totalBurned'] as int? ?? 0) > 0).length;
    final maxBurn = data.map((d) => (d['totalBurned'] as int? ?? 0)).fold<int>(0, (a, b) => b > a ? b : a);
    final allLogs = data.expand<Map<String, dynamic>>((d) {
      final logs = d['logs'] as List<dynamic>? ?? [];
      return logs.map((l) => {...(l as Map<String, dynamic>), 'date': d['date']});
    }).toList()
      ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Burned', '$totalBurned kcal', Icons.local_fire_department_rounded, const Color(0xFFFF6B6B), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Active Days', '$activeDays days', Icons.calendar_today_rounded, const Color(0xFF00B894), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Best Day', '$maxBurn kcal', Icons.emoji_events_rounded, const Color(0xFFF79E74), isDark)),
          ],
        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

        const SizedBox(height: 20),

        // Burn chart
        _buildBurnChart(data, isDark, theme)
            .animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

        const SizedBox(height: 20),

        // Session logs title
        if (allLogs.isNotEmpty) ...[
          Text(
            'Recent Sessions',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          ...allLogs.asMap().entries.map((entry) {
            final idx = entry.key;
            final log = entry.value;
            return _buildSessionTile(log, isDark, theme, idx)
                .animate().fadeIn(delay: Duration(milliseconds: 160 + idx * 40)).slideX(begin: -0.04);
          }),
        ] else
          _buildEmptyState(isDark, theme).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBurnChart(List<Map<String, dynamic>> data, bool isDark, ThemeData theme) {
    final spots = data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: ((e.value['totalBurned'] as int?) ?? 0).toDouble(),
            color: _touchedIndex == e.key
                ? const Color(0xFFF79E74)
                : const Color(0xFFF79E74).withValues(alpha: 0.55),
            width: data.length <= 7 ? 22 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    final maxY = data
        .map((d) => (d['totalBurned'] as int? ?? 0).toDouble())
        .fold<double>(100, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Calories Burned per Day',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = data[group.x];
                      final date = d['date'] as DateTime;
                      return BarTooltipItem(
                        '${DateFormat('EEE d').format(date)}\n${rod.toY.toInt()} kcal',
                        GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        final date = data[idx]['date'] as DateTime;
                        final isToday = date.toIso8601String().substring(0, 10) ==
                            DateTime.now().toIso8601String().substring(0, 10);
                        // For 30-day view, only show every 5th label
                        if (data.length > 7 && idx % 5 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            isToday ? 'Today' : DateFormat(data.length <= 7 ? 'E' : 'd').format(date),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday ? const Color(0xFFF79E74) : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: spots,
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> log, bool isDark, ThemeData theme, int index) {
    final icon = log['icon'] as String? ?? '🏋️';
    final name = log['name'] as String? ?? 'Workout';
    final calories = (log['calories'] as num?)?.toInt() ?? 0;
    final duration = (log['duration'] as num?)?.toInt() ?? 0;
    final date = log['date'] as DateTime;
    final isToday = date.toIso8601String().substring(0, 10) ==
        DateTime.now().toIso8601String().substring(0, 10);
    final dateLabel = isToday ? 'Today' : DateFormat('EEE, MMM d').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF79E74).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateLabel · $duration min',
                  style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Calorie badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '$calories kcal',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFFF6B6B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          const Text('🏃', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No workouts yet',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete a workout in the Workouts tab to see it here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
