import '../models/meal_model.dart';
import 'dart:math';

class DietService {
  static String getCalorieTier(double tdee) {
    if (tdee < 1800) {
      return 'Low Calorie Plan';
    } else if (tdee <= 2500) {
      return 'Moderate Calorie Plan';
    } else {
      return 'High Calorie Plan';
    }
  }

  static List<MealModel> generateMealPlan(String tier, {List<String> conditions = const []}) {
    Random random = Random();
    int r = random.nextInt(3);
    
    bool isDiabetic = conditions.contains('Diabetes');
    bool hasHypertension = conditions.contains('Hypertension');
    
    String prepRiceStr() => isDiabetic ? "Brown Rice" : "White Rice";
    String prepRotiStr() => "Whole Wheat Roti";
    String prepDalStr() => hasHypertension ? "Low-Sodium Dal" : "Dal";
    String prepVegStr() => hasHypertension ? "Steamed Veg (No Salt)" : "Sabji";
    String prepSweetStr() => isDiabetic ? "Sugar-Free Yogurt" : "Sweets";

    if (tier == 'Low Calorie Plan') {
      return [
        MealModel(name: r == 0 ? "2 $prepRotiStr() + $prepDalStr() & $prepVegStr()" : "1 Egg + 2 $prepRotiStr()", calories: 350, type: MealType.breakfast),
        MealModel(name: r == 1 ? "1 Cup $prepRiceStr() + Rui Fish + $prepVegStr()" : "1 Cup $prepRiceStr() + Chicken Curry", calories: 500, type: MealType.lunch),
        MealModel(name: "2 $prepRotiStr() + Lentils (${prepDalStr()})", calories: 400, type: MealType.dinner),
      ];
    } else if (tier == 'Moderate Calorie Plan') {
      return [
        MealModel(name: "3 $prepRotiStr() + 1 Whole Egg + Banana", calories: 450, type: MealType.breakfast),
        MealModel(name: "2 Cups $prepRiceStr() + Chicken/Fish + $prepDalStr() & $prepVegStr()", calories: 750, type: MealType.lunch),
        MealModel(name: "2 $prepRotiStr() + Chicken Curry + $prepVegStr()", calories: 600, type: MealType.dinner),
      ];
    } else {
      // High Calorie Plan
      return [
        MealModel(name: "4 $prepRotiStr() + 2 Eggs + $prepDalStr() + Apple", calories: 600, type: MealType.breakfast),
        MealModel(name: "3 Cups $prepRiceStr() + Beef/Chicken + Thicker $prepDalStr() + $prepVegStr()", calories: 1000, type: MealType.lunch),
        MealModel(name: "3 $prepRotiStr() + Fish Curry + $prepDalStr() + ${prepSweetStr()}", calories: 800, type: MealType.dinner),
      ];
    }
  }

  static MealModel getAlternativeMeal(MealType type, String tier, List<String> conditions, MealModel currentMeal) {
    // Generates a random completely different meal option
    String newMealName = "Alternate Option";
    int cal = currentMeal.calories; 
    
    bool isDiabetic = conditions.contains('Diabetes');
    String prepCarb() => isDiabetic ? "Oats" : "Pancakes or Paratha";

    if (type == MealType.breakfast) {
      newMealName = "Sugar-Free Oats with Apples";
    } else if (type == MealType.lunch) {
      newMealName = "Grilled Chicken Salad with Cucumber";
    } else {
      newMealName = "2 Rooti + Mixed Vegetable Soup";
    }
    
    // Slight randomized increment to calories to fake dynamic data
    cal += (Random().nextBool() ? 10 : -10);

    return MealModel(name: newMealName, calories: cal, type: type);
  }
}
