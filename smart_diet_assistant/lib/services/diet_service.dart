import '../hive/entities/meal_model.dart';
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
    final ingredients = PersistenceService.getAllIngredients();
    if (ingredients.isEmpty) {
      await _seedIngredients();
    }
    
    final templates = PersistenceService.getAllTemplates();
    if (templates.isEmpty) {
      await _seedTemplates();
    }
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

    final breakfasts = selector.selectMeals(targetCalories: breakfastTarget, macros: macros, conditions: conditions, recentMealIds: recentMealIds, type: MealType.breakfast);
    final lunches = selector.selectMeals(targetCalories: lunchTarget, macros: macros, conditions: conditions, recentMealIds: recentMealIds, type: MealType.lunch);
    final dinners = selector.selectMeals(targetCalories: dinnerTarget, macros: macros, conditions: conditions, recentMealIds: recentMealIds, type: MealType.dinner);

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
    );
  }

  static Future<void> _seedIngredients() async {
    final data = [
      // Proteins
      IngredientEntity(id: 'i1', name: 'Chicken Breast', caloriesPer100g: 165, protein: 31, carbs: 0, fat: 3.6, tags: ['high-protein']),
      IngredientEntity(id: 'i5', name: 'Egg', caloriesPer100g: 155, protein: 13, carbs: 1.1, fat: 11, tags: ['high-protein']),
      IngredientEntity(id: 'i9', name: 'Rui Fish', caloriesPer100g: 110, protein: 19, carbs: 0, fat: 3.5, tags: ['high-protein', 'omega-3']),
      IngredientEntity(id: 'i10', name: 'Beef (Lean)', caloriesPer100g: 250, protein: 26, carbs: 0, fat: 15, tags: ['high-protein']),
      IngredientEntity(id: 'i11', name: 'Tofu', caloriesPer100g: 76, protein: 8, carbs: 1.9, fat: 4.8, tags: ['vegetarian', 'high-protein']),
      IngredientEntity(id: 'i12', name: 'Prawns', caloriesPer100g: 99, protein: 24, carbs: 0.2, fat: 0.3, tags: ['high-protein', 'low-fat']),
      IngredientEntity(id: 'i13', name: 'Lentils (Dal)', caloriesPer100g: 116, protein: 9, carbs: 20, fat: 0.4, tags: ['vegetarian', 'high-protein']),
      // Carbs
      IngredientEntity(id: 'i2', name: 'Brown Rice', caloriesPer100g: 110, protein: 2.6, carbs: 23, fat: 0.9, tags: ['complex-carbs', 'diabetic-safe']),
      IngredientEntity(id: 'i6', name: 'Oats', caloriesPer100g: 389, protein: 17, carbs: 66, fat: 7, tags: ['complex-carbs', 'diabetic-safe']),
      IngredientEntity(id: 'i14', name: 'White Rice', caloriesPer100g: 130, protein: 2.7, carbs: 28, fat: 0.3, tags: ['carbs']),
      IngredientEntity(id: 'i15', name: 'Whole Wheat Roti', caloriesPer100g: 264, protein: 9, carbs: 55, fat: 0.9, tags: ['complex-carbs']),
      IngredientEntity(id: 'i16', name: 'Quinoa', caloriesPer100g: 120, protein: 4.4, carbs: 21, fat: 1.9, tags: ['complex-carbs', 'gluten-free']),
      IngredientEntity(id: 'i17', name: 'Banana', caloriesPer100g: 89, protein: 1.1, carbs: 23, fat: 0.3, tags: ['fruit']),
      // Fats & Dairy
      IngredientEntity(id: 'i3', name: 'Olive Oil', caloriesPer100g: 884, protein: 0, carbs: 0, fat: 100, tags: ['healthy-fats']),
      IngredientEntity(id: 'i7', name: 'Almonds', caloriesPer100g: 579, protein: 21, carbs: 22, fat: 50, tags: ['healthy-fats', 'snack']),
      IngredientEntity(id: 'i8', name: 'Greek Yogurt', caloriesPer100g: 59, protein: 10, carbs: 3.6, fat: 0.4, tags: ['high-protein', 'dairy']),
      IngredientEntity(id: 'i18', name: 'Peanut Butter', caloriesPer100g: 588, protein: 25, carbs: 20, fat: 50, tags: ['healthy-fats']),
      // Vegetables
      IngredientEntity(id: 'i4', name: 'Broccoli', caloriesPer100g: 34, protein: 2.8, carbs: 7, fat: 0.4, tags: ['veg', 'low-cal']),
      IngredientEntity(id: 'i19', name: 'Spinach', caloriesPer100g: 23, protein: 2.9, carbs: 3.6, fat: 0.4, tags: ['veg', 'iron-rich']),
      IngredientEntity(id: 'i20', name: 'Bell Peppers', caloriesPer100g: 31, protein: 1, carbs: 6, fat: 0.3, tags: ['veg', 'vitamin-c']),
      IngredientEntity(id: 'i21', name: 'Chickpeas', caloriesPer100g: 164, protein: 8.9, carbs: 27, fat: 2.6, tags: ['vegetarian', 'high-fiber']),
    ];
    await PersistenceService.saveAllIngredients(data);
  }

  static Future<void> _seedTemplates() async {
    final data = [
      // ─── BREAKFASTS ─────────────────────────────────────
      MealTemplateEntity(id: 't_br_1', name: 'Oatmeal & Almonds', type: MealType.breakfast,
        ingredients: [IngredientPortion(ingredientId: 'i6', grams: 50), IngredientPortion(ingredientId: 'i7', grams: 20)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 10,
        recipeSteps: ['Boil oats in water.', 'Top with crushed almonds.'],
        instructions: 'Mix and serve warm.',
        imageUrl: 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?q=80&w=500'),
      MealTemplateEntity(id: 't_br_2', name: 'Boiled Eggs & Yogurt', type: MealType.breakfast,
        ingredients: [IngredientPortion(ingredientId: 'i5', grams: 100), IngredientPortion(ingredientId: 'i8', grams: 150)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 12,
        recipeSteps: ['Boil eggs for 8 minutes.', 'Serve with a bowl of greek yogurt.'],
        instructions: 'Simple high protein breakfast.',
        imageUrl: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=500'),
      MealTemplateEntity(id: 't_br_3', name: 'Banana Peanut Butter Toast', type: MealType.breakfast,
        ingredients: [IngredientPortion(ingredientId: 'i17', grams: 120), IngredientPortion(ingredientId: 'i18', grams: 30), IngredientPortion(ingredientId: 'i15', grams: 50)],
        conditions: ['Hypertension'], prepTimeMinutes: 5,
        recipeSteps: ['Toast roti until crispy.', 'Spread peanut butter.', 'Slice banana on top.'],
        instructions: 'Quick energy-dense breakfast.',
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=500'),
      MealTemplateEntity(id: 't_br_4', name: 'Egg Spinach Scramble', type: MealType.breakfast,
        ingredients: [IngredientPortion(ingredientId: 'i5', grams: 150), IngredientPortion(ingredientId: 'i19', grams: 80), IngredientPortion(ingredientId: 'i3', grams: 5)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 8,
        recipeSteps: ['Saute spinach in olive oil.', 'Scramble eggs into the pan.', 'Season and serve.'],
        instructions: 'Iron-rich, high protein start.',
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=500'),

      // ─── LUNCHES ────────────────────────────────────────
      MealTemplateEntity(id: 't_lu_1', name: 'Grilled Chicken & Brown Rice', type: MealType.lunch,
        ingredients: [IngredientPortion(ingredientId: 'i1', grams: 150), IngredientPortion(ingredientId: 'i2', grams: 200), IngredientPortion(ingredientId: 'i3', grams: 10)],
        conditions: ['Hypertension', 'Diabetes'], prepTimeMinutes: 25,
        recipeSteps: ['Grill chicken with olive oil.', 'Serve with steamed brown rice.'],
        instructions: 'Classic healthy lunch.',
        imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?q=80&w=500'),
      MealTemplateEntity(id: 't_lu_2', name: 'Fish Curry & Rice', type: MealType.lunch,
        ingredients: [IngredientPortion(ingredientId: 'i9', grams: 150), IngredientPortion(ingredientId: 'i14', grams: 250), IngredientPortion(ingredientId: 'i3', grams: 10)],
        conditions: ['Hypertension'], prepTimeMinutes: 30,
        recipeSteps: ['Cook fish in local spices.', 'Serve with steamed rice.'],
        instructions: 'Rich omega-3 lunch.',
        imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b52c67ad4?q=80&w=500'),
      MealTemplateEntity(id: 't_lu_3', name: 'Quinoa Chickpea Bowl', type: MealType.lunch,
        ingredients: [IngredientPortion(ingredientId: 'i16', grams: 150), IngredientPortion(ingredientId: 'i21', grams: 100), IngredientPortion(ingredientId: 'i20', grams: 80), IngredientPortion(ingredientId: 'i3', grams: 10)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 20,
        recipeSteps: ['Boil quinoa.', 'Mix with chickpeas and diced bell peppers.', 'Drizzle olive oil.'],
        instructions: 'Vegetarian, fiber-rich, and filling.',
        imageUrl: 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?q=80&w=500'),
      MealTemplateEntity(id: 't_lu_4', name: 'Beef Lentil Stew', type: MealType.lunch,
        ingredients: [IngredientPortion(ingredientId: 'i10', grams: 150), IngredientPortion(ingredientId: 'i13', grams: 100), IngredientPortion(ingredientId: 'i2', grams: 200)],
        conditions: ['Diabetes'], prepTimeMinutes: 40,
        recipeSteps: ['Slow-cook beef with lentils and spices.', 'Serve over brown rice.'],
        instructions: 'Hearty, high-calorie lunch.',
        imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?q=80&w=500'),

      // ─── DINNERS ────────────────────────────────────────
      MealTemplateEntity(id: 't_di_1', name: 'Chicken Broccoli Stir-Fry', type: MealType.dinner,
        ingredients: [IngredientPortion(ingredientId: 'i1', grams: 150), IngredientPortion(ingredientId: 'i4', grams: 200), IngredientPortion(ingredientId: 'i3', grams: 10)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 15,
        recipeSteps: ['Saute chicken in olive oil.', 'Add broccoli and stir fry 5 min.'],
        instructions: 'Low carb, high protein dinner.',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=500'),
      MealTemplateEntity(id: 't_di_2', name: 'Tofu Bell Pepper Stir-Fry', type: MealType.dinner,
        ingredients: [IngredientPortion(ingredientId: 'i11', grams: 200), IngredientPortion(ingredientId: 'i20', grams: 150), IngredientPortion(ingredientId: 'i3', grams: 10)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 15,
        recipeSteps: ['Press and cube tofu.', 'Saute with sliced bell peppers.', 'Season with soy sauce.'],
        instructions: 'Plant-based, low calorie dinner.',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500'),
      MealTemplateEntity(id: 't_di_3', name: 'Prawn Spinach with Roti', type: MealType.dinner,
        ingredients: [IngredientPortion(ingredientId: 'i12', grams: 150), IngredientPortion(ingredientId: 'i19', grams: 100), IngredientPortion(ingredientId: 'i15', grams: 80)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 20,
        recipeSteps: ['Saute prawns with garlic.', 'Wilt spinach into the pan.', 'Serve with warm roti.'],
        instructions: 'Lean protein with iron-rich greens.',
        imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=500'),
      MealTemplateEntity(id: 't_di_4', name: 'Chicken Salad & Yogurt', type: MealType.dinner,
        ingredients: [IngredientPortion(ingredientId: 'i1', grams: 120), IngredientPortion(ingredientId: 'i19', grams: 80), IngredientPortion(ingredientId: 'i8', grams: 100), IngredientPortion(ingredientId: 'i3', grams: 5)],
        conditions: ['Diabetes', 'Hypertension'], prepTimeMinutes: 10,
        recipeSteps: ['Grill chicken and slice.', 'Toss with spinach.', 'Serve with a side of yogurt.'],
        instructions: 'Light, refreshing, and protein-packed.',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=500'),
    ];
    await PersistenceService.saveAllTemplates(data);
  }



  static Future<MealTemplateEntity> getAlternativeMeal(MealType type, double targetCalories, List<String> conditions, String currentMealId) async {
    final allTemplates = PersistenceService.getAllTemplates();
    final ingredientsList = PersistenceService.getAllIngredients();
    final Map<String, IngredientEntity> ingredientsMap = {};
    for (var i in ingredientsList) {
      ingredientsMap[i.id] = i;
    }
    final selector = MealSelectorService(allMeals: allTemplates, ingredients: ingredientsMap);
    final macros = MacroTargets(proteinGrams: 50, carbsGrams: 50, fatGrams: 20); // Base macro for alternative
    final options = selector.selectMeals(targetCalories: targetCalories, macros: macros, conditions: conditions, recentMealIds: [currentMealId], type: type);
    
    return options.firstWhere((m) => m.id != currentMealId, orElse: () => options.isNotEmpty ? options.first : allTemplates.firstWhere((t) => t.type == type));
  }
}
