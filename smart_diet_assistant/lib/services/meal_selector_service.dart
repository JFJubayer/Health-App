import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/ingredient_entity.dart';
import '../models/meal_model.dart';
import '../models/macro_targets.dart';
import 'meal_memory_service.dart';
import 'persistence_service.dart';

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
    final prefs = PersistenceService.getPreferences(MealMemoryService.localUserId);
    final avoidedMealIds = prefs?.avoidedMealIds ?? [];
    final dislikedIngredients = prefs?.dislikedIngredientIds ?? [];
    final preferredTags = prefs?.preferredTags ?? [];

    var validMeals = allMeals
        .where((m) => m.type == type)
        .where((m) => !avoidedMealIds.contains(m.id)) // Hard filter: avoided meals
        .where((m) => _isSafeForConditions(m, conditions))
        .toList();

    // Fallback guarantee: if empty after preference filter, just take condition-safe meals
    if (validMeals.isEmpty) {
      validMeals = allMeals
          .where((m) => m.type == type)
          .where((m) => _isSafeForConditions(m, conditions))
          .toList();
      
      // Sort by least used
      validMeals.sort((a, b) => a.timesUsed.compareTo(b.timesUsed));
      return validMeals.take(3).toList();
    }

    validMeals.sort((a, b) {
      final scoreA = _score(a, targetCalories, macros, dislikedIngredients, preferredTags);
      final scoreB = _score(b, targetCalories, macros, dislikedIngredients, preferredTags);
      return scoreB.compareTo(scoreA); // Highest score first
    });

    // Fallback: if STILL empty (e.g. no condition safe meals at all), just return any meals of that type
    if (validMeals.isEmpty) {
       validMeals = allMeals.where((m) => m.type == type).toList();
       validMeals.sort((a, b) => a.timesUsed.compareTo(b.timesUsed));
    }

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
    List<String> dislikedIngredients,
    List<String> preferredTags,
  ) {
    // 0. Hard filter checks inside score (for ingredients)
    bool hasDisliked = meal.ingredients.any((p) => dislikedIngredients.contains(p.ingredientId));
    if (hasDisliked) return 0.0; // Penalty for disliked ingredients

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

    // 1. Calorie Fit (Weight 0.35)
    double calorieDiff = (calories - targetCalories).abs();
    double calorieFit = targetCalories > 0 ? 1.0 - (calorieDiff / targetCalories).clamp(0.0, 1.0) : 0.0;

    // 2. Macro Fit (Weight 0.25)
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

    // 3. Variety Score (Weight 0.20)
    double varietyScore = 1.0;
    final lastServed = MealMemoryService.getLastServedDate(meal.id);
    
    if (lastServed != null) {
      final daysSince = DateTime.now().difference(lastServed).inDays;
      if (daysSince <= 2) {
        varietyScore = 0.0;
      } else if (daysSince <= 5) {
        varietyScore = 0.5;
      } else if (daysSince <= 13) {
        varietyScore = 0.8;
      } else {
        varietyScore = 1.0;
      }
    }

    // Swap Rate Penalty
    final swapRate = MealMemoryService.getSwapRate(meal.id);
    varietyScore -= (swapRate * 0.5);
    varietyScore = varietyScore.clamp(0.0, 1.0);

    // 4. Preference Score (Weight 0.15)
    double preferenceScore = 0.5; // default
    final prefs = PersistenceService.getPreferences(MealMemoryService.localUserId);
    if (prefs != null) {
      final rating = prefs.mealRatings[meal.id];
      if (rating != null) {
        preferenceScore = rating / 5.0;
      }
      
      // Boost for preferred tags
      if (meal.tags.any((tag) => preferredTags.contains(tag))) {
        preferenceScore = (preferenceScore + 0.2).clamp(0.0, 1.0);
      }
    }

    // 5. User Rating (Weight 0.05)
    double ratingScore = meal.rating / 5.0;

    // Frequency penalty (custom)
    final memories = MealMemoryService.getMealHistory();
    int recentCount = memories.where((m) => m.mealTemplateId == meal.id).length;
    double frequencyPenalty = (recentCount * 0.05).clamp(0.0, 0.3);

    final finalScore =
        (calorieFit * 0.35) +
        (macroFit * 0.25) +
        (varietyScore * 0.20) +
        (preferenceScore * 0.15) +
        (ratingScore * 0.05);

    return finalScore - frequencyPenalty;
  }
}
