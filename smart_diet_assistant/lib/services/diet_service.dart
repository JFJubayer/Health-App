import '../models/meal_model.dart';
import '../hive/entities/ingredient_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/day_plan_entity.dart';
import 'persistence_service.dart';
import 'meal_selector_service.dart';

class DietService {
  static String getCalorieTier(double tdee) {
    if (tdee < 1800) return 'Low Calorie Plan';
    if (tdee <= 2500) return 'Moderate Calorie Plan';
    return 'High Calorie Plan';
  }

  static Future<void> seedDataIfNeeded() async {
    

    
  }

  static Future<DayPlanEntity> generateDayPlan(double tdee, List<String> conditions, {List<String> recentMealIds = const []}) async {
    await seedDataIfNeeded();

    final allTemplates = PersistenceService.getAllTemplates();
    final ingredientsList = PersistenceService.getAllIngredients();
    final Map<String, IngredientEntity> ingredientsMap = {};
    for (var i in ingredientsList) {
      ingredientsMap[i.id] = i;
    }

    final selector = MealSelectorService(allMeals: allTemplates, ingredients: ingredientsMap);

    // Targets for meals
    double breakfastTarget = tdee * 0.3;
    double lunchTarget = tdee * 0.4;
    double dinnerTarget = tdee * 0.3;

    // Standard macros
    final macros = MacroTargets(proteinGrams: (tdee * 0.3) / 4, carbsGrams: (tdee * 0.4) / 4, fatGrams: (tdee * 0.3) / 9);

    final breakfasts = selector.selectMeals(targetCalories: breakfastTarget, macros: macros, conditions: conditions,  type: MealType.breakfast);
    final lunches = selector.selectMeals(targetCalories: lunchTarget, macros: macros, conditions: conditions,  type: MealType.lunch);
    final dinners = selector.selectMeals(targetCalories: dinnerTarget, macros: macros, conditions: conditions,  type: MealType.dinner);

    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final dayPlan = DayPlanEntity(
      id: dateStr,
      date: DateTime.now(),
      breakfastId: breakfasts.isNotEmpty ? breakfasts.first.id : null,
      lunchId: lunches.isNotEmpty ? lunches.first.id : null,
      dinnerId: dinners.isNotEmpty ? dinners.first.id : null,
      isLocked: false,
    );

    await PersistenceService.saveDayPlan(dayPlan);
    return dayPlan;
  }

  static MealModel resolveMealModel(MealTemplateEntity template) {
    final ingredientsList = PersistenceService.getAllIngredients();
    final Map<String, IngredientEntity> ingredientsMap = {};
    for (var i in ingredientsList) {
      ingredientsMap[i.id] = i;
    }

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    List<String> ingredientNames = [];

    for (var portion in template.ingredients) {
      final ingredient = ingredientsMap[portion.ingredientId];
      if (ingredient != null) {
        final factor = portion.grams / 100.0;
        calories += ingredient.caloriesPer100g * factor;
        protein += ingredient.protein * factor;
        carbs += ingredient.carbs * factor;
        fat += ingredient.fat * factor;
        ingredientNames.add('${portion.grams}g ${ingredient.name}');
      }
    }

    return MealModel(
      id: template.id,
      name: template.name,
      type: template.type,
      calories: calories.toInt(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      ingredients: ingredientNames,
      recipeSteps: template.recipeSteps,
      instructions: template.instructions,
      imageUrl: template.imageUrl,
      prepTimeMinutes: template.prepTimeMinutes,
    );
  }

  static Future<List<MealTemplateEntity>> getMealAlternatives(
    MealType type,
    double targetCalories,
    List<String> conditions,
    String currentMealId,
  ) async {
    await seedDataIfNeeded();
    final allTemplates = PersistenceService.getAllTemplates();
    final ingredientsList = PersistenceService.getAllIngredients();
    final Map<String, IngredientEntity> ingredientsMap = {};
    for (var i in ingredientsList) {
      ingredientsMap[i.id] = i;
    }
    final selector = MealSelectorService(
      allMeals: allTemplates,
      ingredients: ingredientsMap,
    );
    final macros = MacroTargets(
      proteinGrams: 50,
      carbsGrams: 50,
      fatGrams: 20,
    );
    final options = selector.selectMeals(
      targetCalories: targetCalories,
      macros: macros,
      conditions: conditions,
      type: type,
    );
    return options.where((m) => m.id != currentMealId).take(3).toList();
  }

  static Future<MealTemplateEntity> getAlternativeMeal(
    MealType type,
    double targetCalories,
    List<String> conditions,
    String currentMealId,
  ) async {
    final alternatives = await getMealAlternatives(
      type,
      targetCalories,
      conditions,
      currentMealId,
    );
    if (alternatives.isNotEmpty) return alternatives.first;

    final allTemplates = PersistenceService.getAllTemplates();
    return allTemplates.firstWhere((t) => t.type == type);
  }
}
