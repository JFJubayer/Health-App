// cost_calculator.dart
//
// Turns (FoodItem + IngredientPrice) into actual BDT figures. Nothing
// here is stored/cached long-term — cost is always computed fresh from
// whatever prices are currently in the price box, so editing a price
// immediately ripples through every past-and-future cost estimate.

import '../models/food_models.dart';

class CostCalculator {
  final Map<String, IngredientPrice> priceDb;

  CostCalculator(this.priceDb);

  /// Cost of one portion of [food], in BDT.
  double portionCost(FoodItem food) => food.costBDT(priceDb);

  /// Cost of [servings] portions of [food] (servings can be fractional,
  /// e.g. 1.5 plates of rice).
  double cost(FoodItem food, {double servings = 1}) =>
      portionCost(food) * servings;

  /// Total cost for a list of (food, servings) pairs — e.g. one full meal.
  double mealCost(List<MapEntry<FoodItem, double>> items) {
    double total = 0;
    for (final entry in items) {
      total += cost(entry.key, servings: entry.value);
    }
    return total;
  }

  /// Cheapest way to fill a nutrient/protein gap from a given category —
  /// handy for "swap this for something cheaper" suggestions.
  FoodItem? cheapestInCategory(
      FoodCategory category, List<FoodItem> database) {
    final candidates = database.where((f) => f.category == category);
    if (candidates.isEmpty) return null;
    return candidates.reduce(
        (a, b) => portionCost(a) <= portionCost(b) ? a : b);
  }

  /// Flags ingredients whose price hasn't been touched in a while, so the
  /// UI can nudge the user to confirm/update them before trusting the
  /// budget math.
  List<IngredientPrice> stalePrices({int staleAfterDays = 21}) {
    final cutoff = DateTime.now().subtract(Duration(days: staleAfterDays));
    return priceDb.values.where((p) => p.lastUpdated.isBefore(cutoff)).toList();
  }
}
