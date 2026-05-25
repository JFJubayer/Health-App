import '../models/meal_model.dart';
import '../models/recommendation_reason.dart';
import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/meal_memory_entity.dart';
import '../hive/entities/ingredient_entity.dart';
import '../services/persistence_service.dart';

class RecommendationGenerator {
  static List<MapEntry<MealModel, List<RecommendationReason>>> generateRecommendations({
    required List<MealTemplateEntity> meals,
    required double proteinConsumed,
    required double proteinTarget,
    required double carbsConsumed,
    required double carbsTarget,
    required double fatConsumed,
    required double fatTarget,
    required List<String> conditions,
    required MealType mealType,
    String? userId,
    int maxRecommendations = 3,
  }) {
    final scored = <MapEntry<MealTemplateEntity, List<RecommendationReason>>>[];
    final ingredientsMap = _buildIngredientsMap();

    for (final meal in meals) {
      if (meal.type != mealType) continue;

      final reasons = <RecommendationReason>[];

      // Calculate macros from ingredients
      final (mealCalories, mealProtein, mealCarbs, mealFat) = _calculateMealMacros(meal, ingredientsMap);

      // Check macro needs
      if (proteinConsumed < proteinTarget * 0.7) {
        if (mealProtein > 20) {
          reasons.add(RecommendationReason(
            type: RecommendationReasonType.lowProtein,
            displayText: 'High protein (${mealProtein.toInt()}g)',
            confidence: 0.95,
          ));
        }
      }

      if (carbsConsumed < carbsTarget * 0.7) {
        if (mealCarbs > 30) {
          reasons.add(RecommendationReason(
            type: RecommendationReasonType.lowCarbs,
            displayText: 'Good carbs (${mealCarbs.toInt()}g)',
            confidence: 0.9,
          ));
        }
      }

      // Check conditions
      final mealConditions = _getMealConditionMatch(meal, conditions);
      reasons.addAll(mealConditions);

      // Check if recently consumed
      final recentlyConsumed = _isRecentlyConsumed(meal.id, userId);
      if (!recentlyConsumed) {
        reasons.add(RecommendationReason(
          type: RecommendationReasonType.notEatenRecently,
          displayText: 'Not eaten recently',
          confidence: 0.7,
        ));
      }

      // Check macro balance
      if ((mealProtein / mealCalories * 4 > 0.25) &&
          (mealCarbs / mealCalories * 4 > 0.3) &&
          (mealFat / mealCalories * 9 < 0.35)) {
        reasons.add(RecommendationReason(
          type: RecommendationReasonType.balancedMeal,
          displayText: 'Well-balanced macros',
          confidence: 0.85,
        ));
      }

      if (reasons.isNotEmpty) {
        scored.add(MapEntry(meal, reasons));
      }
    }

    // Sort by reason count and confidence
    scored.sort((a, b) {
      final scoreA = a.value.fold<double>(0, (sum, r) => sum + r.confidence);
      final scoreB = b.value.fold<double>(0, (sum, r) => sum + r.confidence);
      return scoreB.compareTo(scoreA);
    });

    return scored
        .take(maxRecommendations)
        .map((entry) {
          final (calories, protein, carbs, fat) = _calculateMealMacros(entry.key, ingredientsMap);
          final mealModel = MealModel(
            id: entry.key.id,
            name: entry.key.name,
            type: entry.key.type,
            calories: calories.toInt(),
            protein: protein,
            carbs: carbs,
            fat: fat,
            ingredients: entry.key.ingredients.map((ip) => ip.ingredientId).toList(),
          );
          return MapEntry(mealModel, entry.value);
        })
        .toList();
  }

  static List<RecommendationReason> _getMealConditionMatch(
    MealTemplateEntity meal,
    List<String> conditions,
  ) {
    final reasons = <RecommendationReason>[];

    if (conditions.contains('Diabetes') && meal.conditions.contains('Diabetes')) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.diabetesFriendly,
        displayText: 'Diabetes friendly',
        confidence: 0.85,
      ));
    }

    if (conditions.contains('Hypertension') && meal.conditions.contains('Hypertension')) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.hypertensionFriendly,
        displayText: 'Hypertension friendly',
        confidence: 0.8,
      ));
    }

    if (conditions.contains('PCOS') && meal.conditions.contains('PCOS')) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.pcosOptimized,
        displayText: 'PCOS optimized',
        confidence: 0.82,
      ));
    }

    return reasons;
  }

  static bool _isRecentlyConsumed(String mealId, String? userId) {
    if (userId == null) return false;
    try {
      final memories = PersistenceService.getMealMemories(userId);
      final mealMemory =
          memories.firstWhere(
            (m) => m.mealTemplateId == mealId,
            orElse: () => MealMemoryEntity(
              id: '',
              userId: userId,
              mealTemplateId: '',
              consumedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );

      if (mealMemory.mealTemplateId.isEmpty) return false;

      final daysSinceLastConsumed = DateTime.now().difference(mealMemory.consumedAt).inDays;
      return daysSinceLastConsumed < 3;
    } catch (e) {
      return false;
    }
  }

  static double calculateConfidenceScore(List<RecommendationReason> reasons) {
    if (reasons.isEmpty) return 0.5;
    final avgConfidence = reasons.fold<double>(0, (sum, r) => sum + r.confidence) / reasons.length;
    return avgConfidence.clamp(0.0, 1.0);
  }

  static Map<String, IngredientEntity> _buildIngredientsMap() {
    final ingredients = PersistenceService.getAllIngredients();
    return {for (var i in ingredients) i.id: i};
  }

  static (double, double, double, double) _calculateMealMacros(
    MealTemplateEntity meal,
    Map<String, IngredientEntity> ingredientsMap,
  ) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final portion in meal.ingredients) {
      final ingredient = ingredientsMap[portion.ingredientId];
      if (ingredient != null) {
        final factor = portion.grams / 100.0;
        calories += ingredient.caloriesPer100g * factor;
        protein += ingredient.protein * factor;
        carbs += ingredient.carbs * factor;
        fat += ingredient.fat * factor;
      }
    }

    return (calories, protein, carbs, fat);
  }
}
