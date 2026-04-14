import '../models/meal_model.dart';
import 'dart:math';

class DietService {
  static String getCalorieTier(double tdee) {
    if (tdee < 1800) return 'Low Calorie Plan';
    if (tdee <= 2500) return 'Moderate Calorie Plan';
    return 'High Calorie Plan';
  }

  static List<MealModel> generateMealPlan(String tier, {List<String> conditions = const []}) {
    bool isDiabetic = conditions.contains('Diabetes');
    bool hasHypertension = conditions.contains('Hypertension');
    
    if (tier == 'Low Calorie Plan') {
      return [
        _createMeal(
          id: 'l_br_1',
          name: isDiabetic ? 'Steel-Cut Oats with Berries' : 'Egg & Whole Wheat Roti',
          calories: 350,
          type: MealType.breakfast,
          protein: 15, carbs: 45, fat: 8,
          ingredients: isDiabetic ? ['Oats', 'Blueberries', 'Skim Milk'] : ['1 Egg', '2 Roti', 'Vegetable fry'],
          recipeSteps: [
            'Rinse the grains thoroughly.',
            'Boil with skim milk on low heat.',
            'Add fresh blueberries on top once cooked.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?q=80&w=500',
          instructions: 'Prepare oats with milk and top with berries. For egg, scramble with minimal oil.',
        ),
        _createMeal(
          id: 'l_lu_1',
          name: 'Grilled Fish with Steamed Veggies',
          calories: 500,
          type: MealType.lunch,
          protein: 35, carbs: 40, fat: 12,
          ingredients: ['150g Rui Fish', 'Broccoli', 'Carrots', hasHypertension ? 'Lemon' : 'Salt/Pepper'],
          recipeSteps: [
            'Marinate fish with lemon and spices.',
            'Grill for 5-7 minutes each side.',
            'Steam veggies separately for 4 minutes.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=500',
          instructions: 'Grill fish with lemon and spices. Steam vegetables until tender.',
        ),
        _createMeal(
          id: 'l_di_1',
          name: 'Clear Vegetable Soup with Chicken',
          calories: 350,
          type: MealType.dinner,
          protein: 25, carbs: 20, fat: 10,
          ingredients: ['Chicken Breast', 'Papaya', 'Cabbage', 'Ginger'],
          recipeSteps: [
            'Boil chicken until tender.',
            'Add sliced cabbage and papaya.',
            'Season with ginger and garlic, simmer for 10 mins.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?q=80&w=500',
          instructions: 'Boil chicken and veggies together. Season with ginger and garlic.',
        ),
      ];
    } else if (tier == 'Moderate Calorie Plan') {
      return [
        _createMeal(
          id: 'm_br_1',
          name: 'Peanut Butter Toast & Eggs',
          calories: 450,
          type: MealType.breakfast,
          protein: 20, carbs: 55, fat: 15,
          ingredients: ['2 slices Brown Bread', 'PB', '2 Boiled Eggs'],
          recipeSteps: [
            'Toast the brown bread.',
            'Spread peanut butter evenly.',
            'Serve with boiled eggs on the side.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=500',
          instructions: 'Toast bread, spread peanut butter. Enjoy with boiled eggs.',
        ),
        _createMeal(
          id: 'm_lu_1',
          name: isDiabetic ? 'Brown Rice with Chicken Curry' : 'White Rice with Chicken Curry',
          calories: 750,
          type: MealType.lunch,
          protein: 40, carbs: 90, fat: 20,
          ingredients: [isDiabetic ? '1.5 cups Brown Rice' : '1.5 cups Rice', 'Chicken', 'Lentils', 'Spinach'],
          recipeSteps: [
            'Prepare the rice according to package.',
            'Sauté chicken with lentils and spices.',
            'Wiltered spinach into the curry at the end.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?q=80&w=500',
          instructions: 'Cook rice. Prepare chicken curry with moderate oil and spices.',
        ),
        _createMeal(
          id: 'm_di_1',
          name: 'Grilled Chicken Salad & Roti',
          calories: 600,
          type: MealType.dinner,
          protein: 35, carbs: 60, fat: 18,
          ingredients: ['Chicken', 'Mixed Greens', '1 Roti', 'Olive Oil dressing'],
          recipeSteps: [
            'Grill chicken breast until charred.',
            'Toss fresh greens in olive oil.',
            'Serve with warm whole wheat roti.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=500',
          instructions: 'Grill chicken. Toss greens with dressing. Serve with warm roti.',
        ),
      ];
    } else {
      return [
        _createMeal(
          id: 'h_br_1',
          name: 'Omelet, Toast & Fruit Platter',
          calories: 600,
          type: MealType.breakfast,
          protein: 25, carbs: 75, fat: 22,
          ingredients: ['3 Eggs', '2 Bread', 'Banana', 'Apple'],
          recipeSteps: [
            'Whisk eggs with a splash of milk.',
            'Cook omelet with desired veggies.',
            'Slice fruits and serve with toast.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=500',
          instructions: 'Make a 3-egg omelet with veggies. Serve with bread and fruits.',
        ),
        _createMeal(
          id: 'h_lu_1',
          name: 'Beef Stew with Rice & Dal',
          calories: 1000,
          type: MealType.lunch,
          protein: 50, carbs: 120, fat: 35,
          ingredients: ['Beef', '2.5 cups Rice', 'Thick Dal', 'Potatoes'],
          recipeSteps: [
            'Slow-cook beef with spices and potatoes.',
            'Prepare thick dal separately.',
            'Serve over a large portion of rice.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?q=80&w=500',
          instructions: 'Slow-cook beef with spices. Serve with rice and thick lentils.',
        ),
        _createMeal(
          id: 'h_di_1',
          name: 'Fish Curry, Rice & Yogurt',
          calories: 800,
          type: MealType.dinner,
          protein: 40, carbs: 100, fat: 25,
          ingredients: ['Fish', '2 cups Rice', isDiabetic ? 'Plain Yogurt' : 'Sweet Yogurt'],
          recipeSteps: [
            'Cook fish in local spices and light gravy.',
            'Steam rice until fluffy.',
            'Serve with a chilled bowl of yogurt.'
          ],
          imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b52c67ad4?q=80&w=500',
          instructions: 'Cook fish in local spices. Serve with steamed rice and yogurt.',
        ),
      ];
    }
  }

  static MealModel getAlternativeMeal(MealType type, String tier, List<String> conditions, MealModel currentMeal) {
    bool isDiabetic = conditions.contains('Diabetes');
    
    if (type == MealType.breakfast) {
      return _createMeal(
        id: 'alt_br_${Random().nextInt(100)}',
        name: isDiabetic ? 'Greek Yogurt with Nuts' : 'Banana Pancakes',
        calories: currentMeal.calories,
        type: type,
        protein: 20, carbs: 40, fat: 12,
        ingredients: ['Yogurt/Pancake Mix', 'Almonds', 'Honey/No-Sugar Syrup'],
        recipeSteps: ['Mix base ingredients.', 'Cook or top as directed.', 'Serve immediately.'],
        imageUrl: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=500',
        instructions: 'Mix ingredients and serve fresh.',
      );
    } else if (type == MealType.lunch) {
      return _createMeal(
        id: 'alt_lu_${Random().nextInt(100)}',
        name: 'Quinoa & Chickpea Bowl',
        calories: currentMeal.calories,
        type: type,
        protein: 25, carbs: 70, fat: 15,
        ingredients: ['Quinoa', 'Chickpeas', 'Cucumber', 'Tahini'],
        recipeSteps: ['Boil quinoa.', 'Add chickpeas and chopped cucumber.', 'Drizzle tahini on top.'],
        imageUrl: 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?q=80&w=500',
        instructions: 'Boil quinoa. Mix with chickpeas and veggies.',
      );
    } else {
      return _createMeal(
        id: 'alt_di_${Random().nextInt(100)}',
        name: 'Stir-fry Tofu & Mixed Veggies',
        calories: currentMeal.calories,
        type: type,
        protein: 30, carbs: 30, fat: 20,
        ingredients: ['Tofu', 'Bell Peppers', 'Soy Sauce', 'Sesame Oil'],
        recipeSteps: ['Press and sauté tofu.', 'Add sliced bell peppers.', 'Stir in soy sauce and oil.'],
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500',
        instructions: 'Sauté tofu until golden. Add veggies and sauce.',
      );
    }
  }

  static MealModel _createMeal({
    required String id,
    required String name,
    required int calories,
    required MealType type,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    List<String> ingredients = const [],
    String instructions = '',
    List<String> recipeSteps = const [],
    String? imageUrl,
  }) {
    return MealModel(
      id: id,
      name: name,
      calories: calories,
      type: type,
      protein: protein,
      carbs: carbs,
      fat: fat,
      ingredients: ingredients,
      instructions: instructions,
      recipeSteps: recipeSteps,
      imageUrl: imageUrl,
    );
  }
}

