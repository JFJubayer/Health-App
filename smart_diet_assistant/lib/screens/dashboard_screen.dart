import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';
import 'meal_detail_screen.dart';
import 'add_meal_screen.dart';
import '../widgets/water_tracker_widget.dart';
import '../widgets/fasting_timer_widget.dart';
import '../widgets/greeting_header.dart';
import '../widgets/enhanced_energy_ring.dart';
import '../widgets/smart_meal_card.dart';
import '../services/recommendation_generator.dart';
import '../services/persistence_service.dart';

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
    // ignore: unused_local_variable
    final remaining = (totalTarget - consumed).clamp(0.0, totalTarget);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GreetingHeader(
              userName: userProvider.user!.name,
              streakCount: userProvider.gamification.currentStreak,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnhancedEnergyRing(
                    consumed: consumed,
                    target: totalTarget,
                    proteinConsumed: userProvider.totalConsumedProtein,
                    proteinTarget: (totalTarget * 0.3) / 4,
                    carbsConsumed: userProvider.totalConsumedCarbs,
                    carbsTarget: (totalTarget * 0.4) / 4,
                    fatConsumed: userProvider.totalConsumedFat,
                    fatTarget: (totalTarget * 0.3) / 9,
                    mealsConsumed: userProvider.mealPlan.where((m) => m.isConsumed).length,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  const SizedBox(height: 20),
                  const WaterTrackerWidget().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 30),
                  const FastingTimerWidget().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 30),
                  _buildSmartRecommendations(context, userProvider),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Plan',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMealScreen())),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: Text('Manual Entry', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Meal', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 1000.ms).fadeIn(),
    );
  }

  Widget _buildMetabolicSummary(BuildContext context, UserProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(
                provider.calorieTier,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              side: BorderSide.none,
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: meal.isConsumed ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                  color: _getMealColor(meal.type).withValues(alpha: 0.1),
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
                      child: Text(meal.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    ),
                  ),
                  Text(
                    '${meal.calories} kcal • ${meal.type.name.capitalize()} • ${meal.prepTimeMinutes} min',
                    style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: meal.isConsumed,
              activeColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildSmartRecommendations(BuildContext context, UserProvider userProvider) {
    try {
      final allMeals = PersistenceService.getAllTemplates();
      final mealTypeToShow = _getNextMealType();

      final recommendations = RecommendationGenerator.generateRecommendations(
        meals: allMeals,
        proteinConsumed: userProvider.totalConsumedProtein,
        proteinTarget: (userProvider.tdee * 0.3) / 4,
        carbsConsumed: userProvider.totalConsumedCarbs,
        carbsTarget: (userProvider.tdee * 0.4) / 4,
        fatConsumed: userProvider.totalConsumedFat,
        fatTarget: (userProvider.tdee * 0.3) / 9,
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
          }).toList(),
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

