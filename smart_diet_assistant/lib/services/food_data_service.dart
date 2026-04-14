import '../models/food_item_model.dart';
import '../models/meal_model.dart';

class FoodDataService {
  static const List<FoodItemModel> _foodLibrary = [
    // Proteins
    FoodItemModel(name: 'Chicken Breast', caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6),
    FoodItemModel(name: 'Beef (Lean)', caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15),
    FoodItemModel(name: 'Egg (Large Boiled)', caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11),
    FoodItemModel(name: 'Rui Fish', caloriesPer100g: 110, proteinPer100g: 19, carbsPer100g: 0, fatPer100g: 3.5),
    FoodItemModel(name: 'Prawns', caloriesPer100g: 99, proteinPer100g: 24, carbsPer100g: 0.2, fatPer100g: 0.3),
    FoodItemModel(name: 'Tofu', caloriesPer100g: 76, proteinPer100g: 8, carbsPer100g: 1.9, fatPer100g: 4.8),
    FoodItemModel(name: 'Lentils (Dal cooked)', caloriesPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4),

    // Carbs
    FoodItemModel(name: 'White Rice (Cooked)', caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3),
    FoodItemModel(name: 'Brown Rice (Cooked)', caloriesPer100g: 110, proteinPer100g: 2.6, carbsPer100g: 23, fatPer100g: 0.9),
    FoodItemModel(name: 'White Roti', caloriesPer100g: 264, proteinPer100g: 9, carbsPer100g: 55, fatPer100g: 0.9),
    FoodItemModel(name: 'Oats', caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7),
    FoodItemModel(name: 'Potato (Boiled)', caloriesPer100g: 87, proteinPer100g: 1.9, carbsPer100g: 20, fatPer100g: 0.1),
    FoodItemModel(name: 'Banana', caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3),

    // Veggies
    FoodItemModel(name: 'Broccoli', caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4),
    FoodItemModel(name: 'Spinach', caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4),
    FoodItemModel(name: 'Cabbage', caloriesPer100g: 25, proteinPer100g: 1.3, carbsPer100g: 6, fatPer100g: 0.1),
  ];

  static List<FoodItemModel> getSuggestions(String query) {
    if (query.isEmpty) return [];
    return _foodLibrary
        .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static double getRecommendedPortion(String name, MealType type) {
    String lname = name.toLowerCase();
    
    // Logic for Proteins (Chicken, Fish, Beef)
    if (lname.contains('chicken') || lname.contains('fish') || lname.contains('beef')) {
      switch (type) {
        case MealType.breakfast: return 100;
        case MealType.lunch: return 200;
        case MealType.dinner: return 150;
      }
    }
    
    // Logic for Rice/Grains
    if (lname.contains('rice') || lname.contains('oats')) {
      switch (type) {
        case MealType.breakfast: return 80;
        case MealType.lunch: return 250;
        case MealType.dinner: return 150;
      }
    }

    // Default
    return 100;
  }
}
