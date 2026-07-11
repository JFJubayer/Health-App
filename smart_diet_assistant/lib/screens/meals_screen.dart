import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';
import '../services/export_service.dart';
import '../services/persistence_service.dart';
import '../services/recommendation_generator.dart';
import '../widgets/smart_meal_card.dart';
import 'meal_detail_screen.dart';
import '../widgets/meal_picker_sheet.dart';
import 'weekly_plan_screen.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null || userProvider.mealPlan.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Meals')),
        body: const Center(child: Text('No meal plan available.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Your Diet Plan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Weekly Plan',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyPlanScreen())),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Regenerate Plan',
            onPressed: () => userProvider.regenerateMeals(),
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Export PDF',
            onPressed: () => ExportService.exportToPdf(userProvider.user!, userProvider.mealPlan),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Plan",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...userProvider.mealPlan.map((meal) => _buildMealCard(context, userProvider, meal).animate().fadeIn().slideX(begin: 0.05)),
            const SizedBox(height: 10),
            _buildSmartRecommendations(context, userProvider),
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartRecommendations(BuildContext context, UserProvider userProvider) {
    try {
      final allMeals = PersistenceService.getAllTemplates();
      final mealTypeToShow = _getNextMealType();

      final recommendations = RecommendationGenerator.generateRecommendations(
        meals: allMeals,
        proteinConsumed: userProvider.totalConsumedProtein,
        proteinTarget: userProvider.proteinTarget,
        carbsConsumed: userProvider.totalConsumedCarbs,
        carbsTarget: userProvider.carbsTarget,
        fatConsumed: userProvider.totalConsumedFat,
        fatTarget: userProvider.fatTarget,
        conditions: userProvider.user?.conditions ?? [],
        mealType: mealTypeToShow,
        userId: userProvider.user?.name,
        maxRecommendations: 2,
      );

      if (recommendations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${mealTypeToShow.name.capitalize()} 🎯',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((entry) {
            final confidence = RecommendationGenerator.calculateConfidenceScore(entry.value);
            return SmartMealCard(
              meal: entry.key,
              reasons: entry.value,
              confidenceScore: confidence,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealDetailScreen(meal: entry.key),
                  ),
                );
              },
              onAddMeal: () {
                userProvider.addCustomMeal(entry.key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${entry.key.name} added to your plan!'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  MealType _getNextMealType() {
    final hour = DateTime.now().hour;
    if (hour < 12) return MealType.breakfast;
    if (hour < 17) return MealType.lunch;
    return MealType.dinner;
  }

  Widget _buildMealCard(BuildContext context, UserProvider provider, MealModel meal) {
    final color = _getMealColor(meal.type);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Hero(
                    tag: 'meal_icon_${meal.id}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(_getMealIcon(meal.type), color: color, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meal.type.name.toUpperCase()} · ${meal.prepTimeMinutes} MIN',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Hero(
                          tag: 'meal_name_${meal.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              meal.name,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${meal.calories} kcal',
                      style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${meal.protein.toInt()}g P • ${meal.carbs.toInt()}g C • ${meal.fat.toInt()}g F',
                    style: GoogleFonts.outfit(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                  if (provider.isMainPlanMeal(meal.id))
                    TextButton.icon(
                      onPressed: () => showMealPickerSheet(context, meal.id),
                      icon: Icon(Icons.swap_horiz, size: 18, color: color),
                      label: Text('Swap', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: color.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast: return Icons.wb_sunny_rounded;
      case MealType.lunch: return Icons.fastfood_rounded;
      case MealType.dinner: return Icons.nightlight_round;
      case MealType.snack: return Icons.apple_rounded;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.breakfast: return Colors.orange;
      case MealType.lunch: return Colors.green;
      case MealType.dinner: return Colors.indigo;
      case MealType.snack: return Colors.teal;
    }
  }
}

extension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}

