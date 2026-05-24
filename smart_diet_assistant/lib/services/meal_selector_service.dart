import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/ingredient_entity.dart';
import '../models/meal_model.dart'; 
import 'meal_memory_service.dart';
import 'persistence_service.dart';

class MacroTargets {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  MacroTargets({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });
}

class MealSelectorService {
  final List<MealTemplateEntity> allMeals;
  final Map<String, IngredientEntity> ingredients;

  MealSelectorService({
    required this.allMeals,
    required this.ingredients,
  });

  List<MealTemplateEntity> selectMeals({
    required double targetCalories,
    required MacroTargets macros,
    required List<String> conditions, 
    required MealType type,
  }) {
    var validMeals = allMeals
        .where((m) => m.type == type)
        .where((m) => _isSafeForConditions(m, conditions))
        .toList();

    final recentMealIds =
    MealMemoryService.getRecentlyConsumedMealIds(); 

    validMeals.sort((a, b) {
      final scoreA = _score(a, targetCalories, macros, recentMealIds);
      final scoreB = _score(b, targetCalories, macros, recentMealIds);
      return scoreB.compareTo(scoreA); // Highest score first
    });

    return validMeals.take(3).toList();
  }

  bool _isSafeForConditions(MealTemplateEntity meal, List<String> userConditions) {
    if (userConditions.isEmpty) return true;
    for (var cond in userConditions) {
      if (!meal.conditions.any((c) => c.toLowerCase() == cond.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  double _score(
    MealTemplateEntity meal,
    double targetCalories,
    MacroTargets macros,
    List<String> recentMealIds,
  ) {
    double calories = 0.0;
    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;

    for (var portion in meal.ingredients) {
      final ingredient = ingredients[portion.ingredientId];
      if (ingredient != null) {
        final factor = portion.grams / 100.0;
        calories += ingredient.caloriesPer100g * factor;
        protein += ingredient.protein * factor;
        carbs += ingredient.carbs * factor;
        fat += ingredient.fat * factor;
      }
    }

    // Calorie Fit (Weight 0.4)
    double calorieDiff = (calories - targetCalories).abs();
    double calorieFit = targetCalories > 0 ? 1.0 - (calorieDiff / targetCalories).clamp(0.0, 1.0) : 0.0;

    // Macro Fit (Weight 0.3)
    double targetTotalMacros = macros.proteinGrams + macros.carbsGrams + macros.fatGrams;
    double targetProteinRatio = targetTotalMacros > 0 ? macros.proteinGrams / targetTotalMacros : 0;
    double targetCarbsRatio = targetTotalMacros > 0 ? macros.carbsGrams / targetTotalMacros : 0;
    double targetFatRatio = targetTotalMacros > 0 ? macros.fatGrams / targetTotalMacros : 0;

    double mealTotalMacros = protein + carbs + fat;
    double mealProteinRatio = mealTotalMacros > 0 ? protein / mealTotalMacros : 0;
    double mealCarbsRatio = mealTotalMacros > 0 ? carbs / mealTotalMacros : 0;
    double mealFatRatio = mealTotalMacros > 0 ? fat / mealTotalMacros : 0;

    double pDiff = (targetProteinRatio - mealProteinRatio).abs();
    double cDiff = (targetCarbsRatio - mealCarbsRatio).abs();
    double fDiff = (targetFatRatio - mealFatRatio).abs();

    double macroFit = 1.0 - ((pDiff + cDiff + fDiff) / 2.0).clamp(0.0, 1.0);

    // Variety Bonus (Weight 0.2)
    double varietyScore = 1.0;

    if (recentMealIds.contains(meal.id)) {
      varietyScore = 0.2;
    }

    // User Rating (Weight 0.1)
    double ratingScore = meal.rating / 5.0;

    double _frequencyPenalty(
      MealTemplateEntity meal,
    ) {
      final memories =
          MealMemoryService.getMealHistory();

      int recentCount = memories
          .where((m) => m.mealTemplateId == meal.id)
          .length;

      return (recentCount * 0.05)
          .clamp(0.0, 0.3);
    }

    double _preferenceScore(
      MealTemplateEntity meal,
    ) {
      final prefs =
          PersistenceService.getPreferences(
            MealMemoryService.localUserId,
          );

      if (prefs == null) {
        return 0.5;
      }

      final rating =
          prefs.mealRatings[meal.id];

      if (rating == null) {
        return 0.5;
      }

      return rating / 5.0;
    }

    final frequencyPenalty =
      _frequencyPenalty(meal);

    final preferenceScore =
        _preferenceScore(meal);

    final finalScore =
        (calorieFit * 0.35) +
        (macroFit * 0.25) +
        (varietyScore * 0.20) +
        (preferenceScore * 0.15) +
        (ratingScore * 0.05);

    return finalScore - frequencyPenalty;
  }
}
