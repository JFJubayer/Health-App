import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';
import '../services/export_service.dart';
import 'meal_detail_screen.dart';
import 'add_meal_screen.dart';
import '../widgets/water_tracker_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalTarget = userProvider.tdee;
    final consumed = userProvider.totalConsumedCalories.toDouble();
    final remaining = (totalTarget - consumed).clamp(0.0, totalTarget);
    final progress = (consumed / totalTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthRing(context, consumed, totalTarget, progress).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  const SizedBox(height: 30),
                  _buildMacroRow(userProvider).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 30),
                  const WaterTrackerWidget().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Plan',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMealScreen())),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: Text('Manual Entry', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...userProvider.mealPlan.map((meal) => _buildMealListCard(context, userProvider, meal).animate().fadeIn().slideX(begin: 0.05)),
                  const SizedBox(height: 100), // Extra space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMealScreen())),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Meal', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 1000.ms).fadeIn(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'My Dashboard',
          style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 22),
        ),
        background: Container(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF059669)),
          onPressed: () {
            final provider = Provider.of<UserProvider>(context, listen: false);
            if (provider.user != null) {
              ExportService.exportToPdf(provider.user!, provider.mealPlan);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF059669).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xFF059669)),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthRing(BuildContext context, double consumed, double target, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 55,
                      startDegreeOffset: 270,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF059669),
                          value: progress * 100,
                          radius: 12,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFF3F4F6),
                          value: (1 - progress) * 100,
                          radius: 10,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${consumed.toInt()}',
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                      ),
                      Text(
                        'of ${target.toInt()} kcal',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Daily Progress', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'You have consumed ${(progress * 100).toInt()}% of your daily goal.',
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'On Track!',
                    style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(UserProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroCard('Protein', provider.totalConsumedProtein, 'g', Colors.orange),
        _buildMacroCard('Carbs', provider.totalConsumedCarbs, 'g', Colors.blue),
        _buildMacroCard('Fats', provider.totalConsumedFat, 'g', Colors.purple),
      ],
    );
  }

  Widget _buildMacroCard(String title, double value, String unit, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Text(
              '${value.toInt()}$unit',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealListCard(BuildContext context, UserProvider provider, MealModel meal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailScreen(meal: meal),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: meal.isConsumed ? const Color(0xFF059669).withOpacity(0.2) : Colors.transparent),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'meal_icon_${meal.id}',
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getMealColor(meal.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_getMealIcon(meal.type), color: _getMealColor(meal.type)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'meal_name_${meal.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(meal.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Text(
                    '${meal.calories} kcal • ${meal.type.name.capitalize()}',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: meal.isConsumed,
              activeColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (_) => provider.toggleMealConsumed(meal.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              onPressed: () {
                _showDeleteDialog(context, provider, meal);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, UserProvider provider, MealModel meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Meal?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${meal.name}" from your plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMeal(meal.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast: return Icons.wb_sunny_rounded;
      case MealType.lunch: return Icons.fastfood_rounded;
      case MealType.dinner: return Icons.nightlight_round;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.breakfast: return Colors.orange;
      case MealType.lunch: return Colors.green;
      case MealType.dinner: return Colors.indigo;
    }
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}

