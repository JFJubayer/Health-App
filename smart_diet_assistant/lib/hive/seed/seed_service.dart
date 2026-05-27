import '../entities/ingredient_entity.dart';
import '../entities/meal_template_entity.dart';
import '../entities/ingredient_portion_entity.dart';
import '../../models/meal_model.dart';
import '../utils/deterministic_id.dart';
import '../../services/persistence_service.dart';

class SeedService {
  static Future<void> seedIfNeeded() async {
    await _seedIngredients();
    await _seedMealTemplates();
  }

  static Future<void> _seedIngredients() async {
    final existing = PersistenceService.getAllIngredients();

    if (existing.isNotEmpty) {
      return;
    }

    final ingredients = [
      IngredientEntity(
        id: DeterministicId.ingredient('Chicken Breast'),
        name: 'Chicken Breast',
        caloriesPer100g: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        tags: ['high-protein'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Egg'),
        name: 'Egg',
        caloriesPer100g: 155,
        protein: 13,
        carbs: 1.1,
        fat: 11,
        tags: ['high-protein'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Rui Fish'),
        name: 'Rui Fish',
        caloriesPer100g: 110,
        protein: 19,
        carbs: 0,
        fat: 3.5,
        tags: ['high-protein', 'omega-3'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Beef (Lean)'),
        name: 'Beef (Lean)',
        caloriesPer100g: 250,
        protein: 26,
        carbs: 0,
        fat: 15,
        tags: ['high-protein'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Tofu'),
        name: 'Tofu',
        caloriesPer100g: 76,
        protein: 8,
        carbs: 1.9,
        fat: 4.8,
        tags: ['vegetarian', 'high-protein'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Prawns'),
        name: 'Prawns',
        caloriesPer100g: 99,
        protein: 24,
        carbs: 0.2,
        fat: 0.3,
        tags: ['high-protein', 'low-fat'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Lentils (Dal)'),
        name: 'Lentils (Dal)',
        caloriesPer100g: 116,
        protein: 9,
        carbs: 20,
        fat: 0.4,
        tags: ['vegetarian', 'high-protein'],
      ),

// Carbs
      IngredientEntity(
        id: DeterministicId.ingredient('Brown Rice'),
        name: 'Brown Rice',
        caloriesPer100g: 110,
        protein: 2.6,
        carbs: 23,
        fat: 0.9,
        tags: ['complex-carbs', 'diabetic-safe'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Oats'),
        name: 'Oats',
        caloriesPer100g: 389,
        protein: 17,
        carbs: 66,
        fat: 7,
        tags: ['complex-carbs', 'diabetic-safe'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('White Rice'),
        name: 'White Rice',
        caloriesPer100g: 130,
        protein: 2.7,
        carbs: 28,
        fat: 0.3,
        tags: ['carbs'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Whole Wheat Roti'),
        name: 'Whole Wheat Roti',
        caloriesPer100g: 264,
        protein: 9,
        carbs: 55,
        fat: 0.9,
        tags: ['complex-carbs'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Quinoa'),
        name: 'Quinoa',
        caloriesPer100g: 120,
        protein: 4.4,
        carbs: 21,
        fat: 1.9,
        tags: ['complex-carbs', 'gluten-free'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Banana'),
        name: 'Banana',
        caloriesPer100g: 89,
        protein: 1.1,
        carbs: 23,
        fat: 0.3,
        tags: ['fruit'],
      ),

// Fats & Dairy
      IngredientEntity(
        id: DeterministicId.ingredient('Olive Oil'),
        name: 'Olive Oil',
        caloriesPer100g: 884,
        protein: 0,
        carbs: 0,
        fat: 100,
        tags: ['healthy-fats'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Almonds'),
        name: 'Almonds',
        caloriesPer100g: 579,
        protein: 21,
        carbs: 22,
        fat: 50,
        tags: ['healthy-fats', 'snack'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Greek Yogurt'),
        name: 'Greek Yogurt',
        caloriesPer100g: 59,
        protein: 10,
        carbs: 3.6,
        fat: 0.4,
        tags: ['high-protein', 'dairy'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Peanut Butter'),
        name: 'Peanut Butter',
        caloriesPer100g: 588,
        protein: 25,
        carbs: 20,
        fat: 50,
        tags: ['healthy-fats'],
      ),

// Vegetables
      IngredientEntity(
        id: DeterministicId.ingredient('Broccoli'),
        name: 'Broccoli',
        caloriesPer100g: 34,
        protein: 2.8,
        carbs: 7,
        fat: 0.4,
        tags: ['veg', 'low-cal'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Spinach'),
        name: 'Spinach',
        caloriesPer100g: 23,
        protein: 2.9,
        carbs: 3.6,
        fat: 0.4,
        tags: ['veg', 'iron-rich'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Bell Peppers'),
        name: 'Bell Peppers',
        caloriesPer100g: 31,
        protein: 1,
        carbs: 6,
        fat: 0.3,
        tags: ['veg', 'vitamin-c'],
      ),

      IngredientEntity(
        id: DeterministicId.ingredient('Chickpeas'),
        name: 'Chickpeas',
        caloriesPer100g: 164,
        protein: 8.9,
        carbs: 27,
        fat: 2.6,
        tags: ['vegetarian', 'high-fiber'],
      ),
    ];

    await PersistenceService.saveAllIngredients(ingredients);

    print('Seeded ${ingredients.length} ingredients');
  }
}

  Future<void> _seedMealTemplates() async {
    final existing = PersistenceService.getAllTemplates();

    if (existing.isNotEmpty) {
      return;
    }

    final templates = [
      // templates here
      // ─── BREAKFASTS ─────────────────────────────────────
      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.breakfast.name,
          'Oatmeal & Almonds',
        ),
        name: 'Oatmeal & Almonds',
        type: MealType.breakfast,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Oats'),
            grams: 50,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Almonds'),
            grams: 20,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 10,
        recipeSteps: [
          'Boil oats in water.',
          'Top with crushed almonds.',
        ],
        instructions: 'Mix and serve warm.',
        imageUrl:
            'https://images.unsplash.com/photo-1517673400267-0251440c45dc?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.breakfast.name,
          'Boiled Eggs & Yogurt',
        ),
        name: 'Boiled Eggs & Yogurt',
        type: MealType.breakfast,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Egg'),
            grams: 100,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Greek Yogurt'),
            grams: 150,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 12,
        recipeSteps: [
          'Boil eggs for 8 minutes.',
          'Serve with a bowl of greek yogurt.',
        ],
        instructions: 'Simple high protein breakfast.',
        imageUrl:
            'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.breakfast.name,
          'Banana Peanut Butter Toast',
        ),
        name: 'Banana Peanut Butter Toast',
        type: MealType.breakfast,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Banana'),
            grams: 120,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Peanut Butter'),
            grams: 30,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Whole Wheat Roti'),
            grams: 50,
          ),
        ],
        conditions: ['Hypertension'],
        prepTimeMinutes: 5,
        recipeSteps: [
          'Toast roti until crispy.',
          'Spread peanut butter.',
          'Slice banana on top.',
        ],
        instructions: 'Quick energy-dense breakfast.',
        imageUrl:
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.breakfast.name,
          'Egg Spinach Scramble',
        ),
        name: 'Egg Spinach Scramble',
        type: MealType.breakfast,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Egg'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Spinach'),
            grams: 80,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 5,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 8,
        recipeSteps: [
          'Saute spinach in olive oil.',
          'Scramble eggs into the pan.',
          'Season and serve.',
        ],
        instructions: 'Iron-rich, high protein start.',
        imageUrl:
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=500',
      ),

  // ─── LUNCHES ────────────────────────────────────────
      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.lunch.name,
          'Grilled Chicken & Brown Rice',
        ),
        name: 'Grilled Chicken & Brown Rice',
        type: MealType.lunch,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Chicken Breast'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Brown Rice'),
            grams: 200,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 10,
          ),
        ],
        conditions: ['Hypertension', 'Diabetes'],
        prepTimeMinutes: 25,
        recipeSteps: [
          'Grill chicken with olive oil.',
          'Serve with steamed brown rice.',
        ],
        instructions: 'Classic healthy lunch.',
        imageUrl:
            'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.lunch.name,
          'Fish Curry & Rice',
        ),
        name: 'Fish Curry & Rice',
        type: MealType.lunch,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Rui Fish'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('White Rice'),
            grams: 250,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 10,
          ),
        ],
        conditions: ['Hypertension'],
        prepTimeMinutes: 30,
        recipeSteps: [
          'Cook fish in local spices.',
          'Serve with steamed rice.',
        ],
        instructions: 'Rich omega-3 lunch.',
        imageUrl:
            'https://images.unsplash.com/photo-1626777552726-4a6b52c67ad4?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.lunch.name,
          'Quinoa Chickpea Bowl',
        ),
        name: 'Quinoa Chickpea Bowl',
        type: MealType.lunch,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Quinoa'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Chickpeas'),
            grams: 100,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Bell Peppers'),
            grams: 80,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 10,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 20,
        recipeSteps: [
          'Boil quinoa.',
          'Mix with chickpeas and diced bell peppers.',
          'Drizzle olive oil.',
        ],
        instructions: 'Vegetarian, fiber-rich, and filling.',
        imageUrl:
            'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.lunch.name,
          'Beef Lentil Stew',
        ),
        name: 'Beef Lentil Stew',
        type: MealType.lunch,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Beef (Lean)'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Lentils (Dal)'),
            grams: 100,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Brown Rice'),
            grams: 200,
          ),
        ],
        conditions: ['Diabetes'],
        prepTimeMinutes: 40,
        recipeSteps: [
          'Slow-cook beef with lentils and spices.',
          'Serve over brown rice.',
        ],
        instructions: 'Hearty, high-calorie lunch.',
        imageUrl:
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?q=80&w=500',
      ),

  // ─── DINNERS ────────────────────────────────────────
      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.dinner.name,
          'Chicken Broccoli Stir-Fry',
        ),
        name: 'Chicken Broccoli Stir-Fry',
        type: MealType.dinner,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Chicken Breast'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Broccoli'),
            grams: 200,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 10,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 15,
        recipeSteps: [
          'Saute chicken in olive oil.',
          'Add broccoli and stir fry 5 min.',
        ],
        instructions: 'Low carb, high protein dinner.',
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.dinner.name,
          'Tofu Bell Pepper Stir-Fry',
        ),
        name: 'Tofu Bell Pepper Stir-Fry',
        type: MealType.dinner,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Tofu'),
            grams: 200,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Bell Peppers'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 10,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 15,
        recipeSteps: [
          'Press and cube tofu.',
          'Saute with sliced bell peppers.',
          'Season with soy sauce.',
        ],
        instructions: 'Plant-based, low calorie dinner.',
        imageUrl:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.dinner.name,
          'Prawn Spinach with Roti',
        ),
        name: 'Prawn Spinach with Roti',
        type: MealType.dinner,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Prawns'),
            grams: 150,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Spinach'),
            grams: 100,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Whole Wheat Roti'),
            grams: 80,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 20,
        recipeSteps: [
          'Saute prawns with garlic.',
          'Wilt spinach into the pan.',
          'Serve with warm roti.',
        ],
        instructions: 'Lean protein with iron-rich greens.',
        imageUrl:
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=500',
      ),

      MealTemplateEntity(
        id: DeterministicId.meal(
          MealType.dinner.name,
          'Chicken Salad & Yogurt',
        ),
        name: 'Chicken Salad & Yogurt',
        type: MealType.dinner,
        ingredients: [
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Chicken Breast'),
            grams: 120,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Spinach'),
            grams: 80,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Greek Yogurt'),
            grams: 100,
          ),
          IngredientPortion(
            ingredientId: DeterministicId.ingredient('Olive Oil'),
            grams: 5,
          ),
        ],
        conditions: ['Diabetes', 'Hypertension'],
        prepTimeMinutes: 10,
        recipeSteps: [
          'Grill chicken and slice.',
          'Toss with spinach.',
          'Serve with a side of yogurt.',
        ],
        instructions: 'Light, refreshing, and protein-packed.',
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=500',
      ),
    ];

    await PersistenceService.saveAllTemplates(templates);

    print('Seeded ${templates.length} meal templates');
}
