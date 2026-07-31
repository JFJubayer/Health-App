import 'dart:math';
import '../models/user_model.dart';
import '../hive/entities/day_plan_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import 'persistence_service.dart';
import 'meal_selector_service.dart';
import '../models/macro_targets.dart';
import '../models/meal_model.dart';
import '../hive/entities/ingredient_entity.dart';

class WeeklyPlanService {
  static Future<List<DayPlanEntity>> generateWeek(
    DateTime weekStart,
    UserModel user,
    double tdee, {
    Set<String> previousPlanMealIds = const {},
  }) async {
    final List<DayPlanEntity> weekPlans = [];
    final existingPlans = PersistenceService.getAllDayPlansInRange(
      weekStart,
      weekStart.add(const Duration(days: 6)),
    );
    // Key by date string for lookup
    final Map<String, DayPlanEntity> existingPlanMap = {
      for (var plan in existingPlans)
        plan.date.toIso8601String().substring(0, 10): plan
    };

    final allTemplates = PersistenceService.getAllTemplates();
    final ingredientsList = PersistenceService.getAllIngredients();
    final Map<String, IngredientEntity> ingredientsMap = {
      for (var i in ingredientsList) i.id: i
    };

    final selector = MealSelectorService(
      allMeals: allTemplates,
      ingredients: ingredientsMap,
    );

    final breakfastTarget = tdee * 0.3;
    final lunchTarget = tdee * 0.4;
    final dinnerTarget = tdee * 0.3;

    final macros = MacroTargets.balanced(tdee);
    
    // Track selections this week to avoid repeats
    final Set<String> weekSelectedMealIds = {};

    final rng = Random();

    // Helper function to pick a meal from options with high variety across database
    String? pickMeal(List<MealTemplateEntity> options, Set<String> usedThisWeek, Set<String> previousMealIds) {
      if (options.isEmpty) return null;

      // 1. First priority: Not used this week AND not in previous plan
      final freshOptions = options.where((o) => !usedThisWeek.contains(o.id) && !previousMealIds.contains(o.id)).toList();
      if (freshOptions.isNotEmpty) {
        final candidatePoolSize = min(8, freshOptions.length);
        final selected = freshOptions[rng.nextInt(candidatePoolSize)];
        usedThisWeek.add(selected.id);
        return selected.id;
      }

      // 2. Second priority: Not used this week (even if in previous plan)
      final unusedThisWeek = options.where((o) => !usedThisWeek.contains(o.id)).toList();
      if (unusedThisWeek.isNotEmpty) {
        final candidatePoolSize = min(8, unusedThisWeek.length);
        final selected = unusedThisWeek[rng.nextInt(candidatePoolSize)];
        usedThisWeek.add(selected.id);
        return selected.id;
      }

      // 3. Fallback: Pick randomly from top scored options
      final candidatePoolSize = min(8, options.length);
      final selected = options[rng.nextInt(candidatePoolSize)];
      usedThisWeek.add(selected.id);
      return selected.id;
    }

    for (int i = 0; i < 7; i++) {
      final currentDay = weekStart.add(Duration(days: i));
      final dateStr = currentDay.toIso8601String().substring(0, 10);
      
      DayPlanEntity? dayPlan = existingPlanMap[dateStr];
      final isPastDay = currentDay.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      dayPlan ??= DayPlanEntity(
        id: dateStr,
        date: currentDay,
      );

      if (!isPastDay) {
        // Breakfast
        if (!dayPlan.breakfastLocked && dayPlan.breakfastId == null) {
           final options = selector.selectMeals(
             targetCalories: breakfastTarget,
             macros: macros,
             conditions: user.conditions,
             type: MealType.breakfast,
             limit: null, // Return all candidate meals from large database
           );
           final chosenId = pickMeal(options, weekSelectedMealIds, previousPlanMealIds);
           if (chosenId != null) {
             dayPlan.breakfastId = chosenId;
           }
        } else if (dayPlan.breakfastId != null) {
           weekSelectedMealIds.add(dayPlan.breakfastId!);
        }

        // Lunch
        if (!dayPlan.lunchLocked && dayPlan.lunchId == null) {
           final options = selector.selectMeals(
             targetCalories: lunchTarget,
             macros: macros,
             conditions: user.conditions,
             type: MealType.lunch,
             limit: null, // Return all candidate meals from large database
           );
           final chosenId = pickMeal(options, weekSelectedMealIds, previousPlanMealIds);
           if (chosenId != null) {
             dayPlan.lunchId = chosenId;
           }
        } else if (dayPlan.lunchId != null) {
           weekSelectedMealIds.add(dayPlan.lunchId!);
        }

        // Dinner
        if (!dayPlan.dinnerLocked && dayPlan.dinnerId == null) {
           final options = selector.selectMeals(
             targetCalories: dinnerTarget,
             macros: macros,
             conditions: user.conditions,
             type: MealType.dinner,
             limit: null, // Return all candidate meals from large database
           );
           final chosenId = pickMeal(options, weekSelectedMealIds, previousPlanMealIds);
           if (chosenId != null) {
             dayPlan.dinnerId = chosenId;
           }
        } else if (dayPlan.dinnerId != null) {
           weekSelectedMealIds.add(dayPlan.dinnerId!);
        }
      }

      // Past days are implicitly locked
      if (isPastDay) {
         dayPlan.breakfastLocked = true;
         dayPlan.lunchLocked = true;
         dayPlan.dinnerLocked = true;
      }

      await PersistenceService.saveDayPlan(dayPlan);
      weekPlans.add(dayPlan);
    }

    return weekPlans;
  }
}
