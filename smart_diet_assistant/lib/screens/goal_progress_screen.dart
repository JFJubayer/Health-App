import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../services/health_service.dart';

class GoalProgressScreen extends StatefulWidget {
  final bool showBackButton;
  const GoalProgressScreen({super.key, this.showBackButton = false});

  @override
  State<GoalProgressScreen> createState() => _GoalProgressScreenState();
}

class _GoalProgressScreenState extends State<GoalProgressScreen> {
  String _timeframe = 'Weekly'; // 'Weekly' or 'Monthly'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final user = provider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double goalWeight = user.goalWeightKg;
    final double currentWeight = user.weightKg;
    final double heightCm = user.heightCm;
    final double bmi = HealthService.calculateBMI(currentWeight, heightCm);
    final String bmiCategory = HealthService.getBMICategory(bmi);

    // Map categories to match mock UI labels
    String displayBmiCategory = 'Healthy';
    Color bmiColor = const Color(0xFF4CAF50);
    if (bmiCategory == 'Underweight') {
      displayBmiCategory = 'Underweight';
      bmiColor = Colors.blue;
    } else if (bmiCategory == 'Normal Weight') {
      displayBmiCategory = 'Healthy';
      bmiColor = const Color(0xFF4CAF50);
    } else if (bmiCategory == 'Overweight') {
      displayBmiCategory = 'Overweight';
      bmiColor = Colors.orange;
    } else {
      displayBmiCategory = 'Obese';
      bmiColor = Colors.red;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3EEFF), // Soft lilac top glow
              Color(0xFFF9F7FC), // White-lilac base
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 12),
                    _buildGoalWeightCard(context, provider, goalWeight),
                    const SizedBox(height: 16),
                    _buildCurrentWeightCard(context, provider, currentWeight),
                    const SizedBox(height: 24),
                    _buildGoalProgressChartCard(context, provider),
                    const SizedBox(height: 24),
                    _buildBMICard(context, bmi, displayBmiCategory, bmiColor),
                    const SizedBox(height: 100), // Navigation spacing
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
              ),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 48), // Align spacer
          Text(
            'Goal Progress',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.black87),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGoalWeightCard(BuildContext context, UserProvider provider, double goalWeight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${goalWeight.toStringAsFixed(1)} kg',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Goal weight',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showWeightUpdateDialog(context, provider, isGoalWeight: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'Update my goal',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildCurrentWeightCard(BuildContext context, UserProvider provider, double currentWeight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${currentWeight.toStringAsFixed(1)} kg',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Current weight',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showWeightUpdateDialog(context, provider, isGoalWeight: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'Update weight',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildGoalProgressChartCard(BuildContext context, UserProvider provider) {
    // Sort dates to show weight trend chronologically
    final history = provider.weightHistory;
    final sortedKeys = history.keys.toList()..sort();
    
    // Fallback if empty (should already be seeded in UserProvider initialization load)
    final points = <FlSpot>[];
    final displayDates = <String>[];
    
    final daysToShow = _timeframe == 'Weekly' ? 7 : 30;
    final recentKeys = sortedKeys.length > daysToShow 
        ? sortedKeys.sublist(sortedKeys.length - daysToShow) 
        : sortedKeys;

    for (int i = 0; i < recentKeys.length; i++) {
      final key = recentKeys[i];
      final val = history[key]!;
      points.add(FlSpot(i.toDouble(), val));
      
      try {
        final parsedDate = DateTime.parse(key);
        if (_timeframe == 'Weekly') {
          displayDates.add(DateFormat('E').format(parsedDate)); // e.g. Mon, Tue
        } else {
          displayDates.add(DateFormat('d').format(parsedDate)); // e.g. 16, 17
        }
      } catch (_) {
        displayDates.add(key.substring(5)); // e.g. 07-16
      }
    }

    if (points.isEmpty) {
      points.add(const FlSpot(0, 72.0));
      points.add(const FlSpot(1, 71.5));
      displayDates.add('Sat');
      displayDates.add('Sun');
    }

    final double minWeight = points.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final double maxWeight = points.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Progress',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '84%', // A mock percentage matching the active visual spot
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Good',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9E7BFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _timeframe,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.black54),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                items: ['Weekly', 'Monthly'].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _timeframe = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} lbs', // Display weight value
                          style: GoogleFonts.outfit(
                            color: Colors.black45,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < displayDates.length) {
                          // Highlight the "Sun" day to match the mock design exactly
                          final dateStr = displayDates[index];
                          final isHighlighted = dateStr == 'Sun';
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              dateStr,
                              style: GoogleFonts.outfit(
                                color: isHighlighted ? const Color(0xFF9E7BFF) : Colors.black45,
                                fontSize: 10,
                                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: minWeight,
                maxY: maxWeight,
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9E7BFF), Color(0xFFC084FC)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Highlight the Sunday point as selected (or last point if not weekly)
                        final isSun = index < displayDates.length && displayDates[index] == 'Sun';
                        if (isSun) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: const Color(0xFF9E7BFF),
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                          strokeColor: Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF9E7BFF).withValues(alpha: 0.25),
                          const Color(0xFFC084FC).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildBMICard(BuildContext context, double bmi, String category, Color color) {
    // Normal BMI is 18.5 - 24.9. Map the BMI value to a range of 0.0 to 1.0 on our custom scale slider
    // Min mapped BMI is 15.0, Max is 35.0
    final double progress = ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your BMI (Body Mass Index)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your weight is',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // BMI multi-colored slider gauge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blue,       // Underweight
                      Colors.green,      // Healthy
                      Colors.orange,     // Overweight
                      Colors.red,        // Obese
                    ],
                    stops: [0.15, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
              // Indicator thumb positioning
              Align(
                alignment: Alignment(progress * 2 - 1, 0),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9E7BFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBMILabel('Underweight', Colors.blue),
              _buildBMILabel('Healthy', Colors.green),
              _buildBMILabel('Overweight', Colors.orange),
              _buildBMILabel('Obese', Colors.red),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildBMILabel(String text, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: Colors.black45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showWeightUpdateDialog(BuildContext context, UserProvider provider, {required bool isGoalWeight}) {
    final controller = TextEditingController(
      text: (isGoalWeight ? provider.user!.goalWeightKg : provider.user!.weightKg).toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isGoalWeight ? 'Update Goal Weight' : 'Log Current Weight',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isGoalWeight 
                  ? 'Set your target goal weight (kg):' 
                  : 'Enter your weight for today (kg):',
              style: GoogleFonts.outfit(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: 'kg',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final double? newWeight = double.tryParse(controller.text);
              if (newWeight != null && newWeight > 0) {
                if (isGoalWeight) {
                  provider.updateGoalWeight(newWeight);
                } else {
                  provider.updateCurrentWeight(newWeight);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isGoalWeight 
                          ? 'Goal weight updated successfully!' 
                          : 'Today\'s weight logged successfully!',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9E7BFF),
              minimumSize: const Size(80, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
