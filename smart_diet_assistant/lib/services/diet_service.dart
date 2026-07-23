import '../models/meal_model.dart';
import '../models/macro_targets.dart';
import '../hive/entities/ingredient_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/day_plan_entity.dart';
import 'health_service.dart';
import 'persistence_service.dart';
import 'meal_selector_service.dart';
import '../bd_food_db/models/food_models.dart' as bd;
import '../bd_food_db/data/food_database.dart' as bd_db;

class DietService {
  static String getCalorieTier(double tdee) {
    if (tdee < 1800) return 'Low';
    if (tdee <= 2500) return 'Moderate';
    return 'High';
  }

  static Future<void> seedDataIfNeeded() async {
    
  }

  static Future<DayPlanEntity> generateDayPlan(double tdee, List<String> conditions, {List<String> recentMealIds = const []}) async {
    await seedDataIfNeeded();

    final user = await PersistenceService.getUser();
    final isWeightLoss = user != null && user.weightManagementEnabled && HealthService.isHighBmi(user.weightKg, user.heightCm);

    final allTemplates = PersistenceService.getAllTemplates();
    final ingredientsList = PersistenceService.getAllIngredients();
    final Map<String, IngredientEntity> ingredientsMap = {};
    for (var i in ingredientsList) {
      ingredientsMap[i.id] = i;
    }

    final selector = MealSelectorService(
      allMeals: allTemplates,
      ingredients: ingredientsMap,
      isWeightLossPlan: isWeightLoss,
    );

    // Targets for meals
    double breakfastTarget = tdee * 0.3;
    double lunchTarget = tdee * 0.4;
    double dinnerTarget = tdee * 0.3;

    // Standard or weight management macros
    final macros = isWeightLoss
        ? MacroTargets.weightManagement(tdee)
        : MacroTargets.balanced(tdee);

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
    // Check if this is a composite (combined Bangladeshi) meal
    if (template.tags.contains('composite')) {
      final subFoodIds = template.tags.where((tag) => tag != 'composite').toList();
      final List<bd.FoodItem> subFoods = [];
      for (final id in subFoodIds) {
        final f = PersistenceService.getBdFoodItem(id) ?? bd_db.foodDatabaseById[id];
        if (f != null) subFoods.add(f);
      }

      if (subFoods.isNotEmpty) {
        final prices = PersistenceService.getBdIngredientPricesMap();
        final name = subFoods.map((f) => f.nameEn).join(' + ');
        final nameBn = subFoods.map((f) => f.nameBn).join(' + ');

        double calories = 0;
        double protein = 0;
        double carbs = 0;
        double fat = 0;
        double totalCost = 0;
        final List<String> ingredientsList = [];

        double? totalSodium;
        bd.GlycemicImpact glycemic = bd.GlycemicImpact.low;

        bd.ConditionFlag diabetesFlag = bd.ConditionFlag.favorable;
        bd.ConditionFlag hypertensionFlag = bd.ConditionFlag.favorable;
        bd.ConditionFlag pcosFlag = bd.ConditionFlag.favorable;

        final List<String> diabetesNotes = [];
        final List<String> hypertensionNotes = [];
        final List<String> pcosNotes = [];
        final List<String> allSteps = [];

        for (final food in subFoods) {
          calories += food.nutrition.calories;
          protein += food.nutrition.proteinG;
          carbs += food.nutrition.carbsG;
          fat += food.nutrition.fatG;
          totalCost += food.costBDT(prices);

          // Sodium
          if (food.sodiumMg != null) {
            totalSodium = (totalSodium ?? 0) + food.sodiumMg!;
          }

          // Glycemic Impact
          if (food.glycemicImpact == bd.GlycemicImpact.high) {
            glycemic = bd.GlycemicImpact.high;
          } else if (food.glycemicImpact == bd.GlycemicImpact.medium && glycemic != bd.GlycemicImpact.high) {
            glycemic = bd.GlycemicImpact.medium;
          }

          // Diabetes condition flag & notes
          if (food.conditionNotes.diabetes == bd.ConditionFlag.useCaution) {
            diabetesFlag = bd.ConditionFlag.useCaution;
          } else if (food.conditionNotes.diabetes == bd.ConditionFlag.neutral && diabetesFlag != bd.ConditionFlag.useCaution) {
            diabetesFlag = bd.ConditionFlag.neutral;
          }
          if (food.conditionNotes.diabetesNote != null && food.conditionNotes.diabetesNote!.isNotEmpty) {
            diabetesNotes.add('${food.nameEn}: ${food.conditionNotes.diabetesNote}');
          }

          // Hypertension condition flag & notes
          if (food.conditionNotes.hypertension == bd.ConditionFlag.useCaution) {
            hypertensionFlag = bd.ConditionFlag.useCaution;
          } else if (food.conditionNotes.hypertension == bd.ConditionFlag.neutral && hypertensionFlag != bd.ConditionFlag.useCaution) {
            hypertensionFlag = bd.ConditionFlag.neutral;
          }
          if (food.conditionNotes.hypertensionNote != null && food.conditionNotes.hypertensionNote!.isNotEmpty) {
            hypertensionNotes.add('${food.nameEn}: ${food.conditionNotes.hypertensionNote}');
          }

          // PCOS condition flag & notes
          if (food.conditionNotes.pcos == bd.ConditionFlag.useCaution) {
            pcosFlag = bd.ConditionFlag.useCaution;
          } else if (food.conditionNotes.pcos == bd.ConditionFlag.neutral && pcosFlag != bd.ConditionFlag.useCaution) {
            pcosFlag = bd.ConditionFlag.neutral;
          }
          if (food.conditionNotes.pcosNote != null && food.conditionNotes.pcosNote!.isNotEmpty) {
            pcosNotes.add('${food.nameEn}: ${food.conditionNotes.pcosNote}');
          }

          // Recipe preparation steps
          if (food.prepSteps.isNotEmpty) {
            allSteps.add('--- ${food.nameEn} ---');
            allSteps.addAll(food.prepSteps);
          }

          for (final iq in food.ingredients) {
            final price = prices[iq.ingredientId];
            final ingName = price != null ? '${price.nameEn} (${price.nameBn})' : iq.ingredientId;
            ingredientsList.add('${iq.grams.toStringAsFixed(0)}g $ingName');
          }
        }

        if (allSteps.isEmpty) {
          allSteps.add('Serve warm as a complete meal.');
        }

        return MealModel(
          id: template.id,
          name: '$name ($nameBn)',
          type: template.type,
          calories: calories.toInt(),
          protein: protein,
          carbs: carbs,
          fat: fat,
          ingredients: ingredientsList,
          recipeSteps: allSteps,
          instructions: 'Estimated Cost: ৳${totalCost.toStringAsFixed(1)}',
          imageUrl: template.imageUrl,
          tags: ['Bangladeshi', 'Composite'],
          prepTimeMinutes: 15,
          sodiumMg: totalSodium,
          glycemicImpact: glycemic.name,
          diabetesFlag: diabetesFlag.name,
          diabetesNote: diabetesNotes.isNotEmpty ? diabetesNotes.join('; ') : null,
          hypertensionFlag: hypertensionFlag.name,
          hypertensionNote: hypertensionNotes.isNotEmpty ? hypertensionNotes.join('; ') : null,
          pcosFlag: pcosFlag.name,
          pcosNote: pcosNotes.isNotEmpty ? pcosNotes.join('; ') : null,
          imageQuery: subFoods.map((f) => f.imageQuery).whereType<String>().join(', '),
          category: 'riceBased', // Default category for composite meal
        );
      }
    }

    // Check if this is a Bangladeshi food item database entry
    final baseFoodId = template.id.split('_').first;
    final bdFood = PersistenceService.getBdFoodItem(template.id) ??
        PersistenceService.getBdFoodItem(baseFoodId) ??
        bd_db.foodDatabaseById[template.id] ??
        bd_db.foodDatabaseById[baseFoodId];
    if (bdFood != null) {
      final prices = PersistenceService.getBdIngredientPricesMap();
      final cost = bdFood.costBDT(prices);
      return MealModel(
        id: template.id,
        name: '${bdFood.nameEn} (${bdFood.nameBn})',
        type: template.type,
        calories: bdFood.nutrition.calories.toInt(),
        protein: bdFood.nutrition.proteinG,
        carbs: bdFood.nutrition.carbsG,
        fat: bdFood.nutrition.fatG,
        ingredients: bdFood.ingredients.map((iq) {
          final price = prices[iq.ingredientId];
          final ingName = price != null ? '${price.nameEn} (${price.nameBn})' : iq.ingredientId;
          return '${iq.grams.toStringAsFixed(0)}g $ingName';
        }).toList(),
        recipeSteps: bdFood.prepSteps.isNotEmpty ? bdFood.prepSteps : bdFood.tags,
        instructions: 'Portion: ${bdFood.portionDescription}\nEstimated Cost: ৳${cost.toStringAsFixed(1)}',
        imageUrl: template.imageUrl,
        tags: ['Bangladeshi', ...template.tags],
        prepTimeMinutes: template.prepTimeMinutes,
        sodiumMg: bdFood.sodiumMg,
        glycemicImpact: bdFood.glycemicImpact.name,
        diabetesFlag: bdFood.conditionNotes.diabetes.name,
        diabetesNote: bdFood.conditionNotes.diabetesNote,
        hypertensionFlag: bdFood.conditionNotes.hypertension.name,
        hypertensionNote: bdFood.conditionNotes.hypertensionNote,
        pcosFlag: bdFood.conditionNotes.pcos.name,
        pcosNote: bdFood.conditionNotes.pcosNote,
        imageQuery: bdFood.imageQuery,
        category: bdFood.category.name,
      );
    }

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
      tags: template.tags,
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
    final user = await PersistenceService.getUser();
    final isWeightLoss = user != null && user.weightManagementEnabled && HealthService.isHighBmi(user.weightKg, user.heightCm);

    final selector = MealSelectorService(
      allMeals: allTemplates,
      ingredients: ingredientsMap,
      isWeightLossPlan: isWeightLoss,
    );
    final macros = isWeightLoss
        ? MacroTargets.weightManagement(targetCalories)
        : MacroTargets.balanced(targetCalories);
        
    final options = selector.selectMeals(
      targetCalories: targetCalories,
      macros: macros,
      conditions: conditions,
      type: type,
      limit: null,
    );
    return options.where((m) => m.id != currentMealId).toList();
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
