// meal_plan_optimizer.dart
//
// Generates a 7-day meal plan that tries to hit a daily calorie target
// while staying inside a weekly BDT budget.
//
// HOW IT WORKS (be upfront about this in any UI copy — it's a fast
// heuristic suitable for a mobile app, not a true linear-programming
// solver):
//   1. Every FoodItem gets a "value score" = nutrition-per-taka, weighted
//      toward protein + fiber (see FoodItem.valueScore). This is what
//      lets the planner notice that, taka for taka, dal/egg/small fish
//      beat plain rice or premium fish on nutrition delivered.
//   2. Each meal slot (breakfast / lunch-main / lunch-protein / ...)
//      rotates through the top few highest-value candidates in its
//      category, so the plan doesn't just repeat the single "best" dish
//      every day — variety is capped by [maxRepeatsPerItemPerWeek].
//   3. If the week comes in over budget, a downgrade pass swaps the
//      costliest items for cheaper same-category alternatives until
//      it fits (or gives up after a bounded number of tries and reports
//      the shortfall honestly rather than silently failing).
//
// This is intentionally simple enough to run instantly on-device with
// no external solver dependency.

import 'dart:math';
import '../models/food_models.dart';

class DailyMealPlan {
  final int dayIndex; // 0 = day 1
  final Map<MealSlot, List<FoodItem>> items;

  DailyMealPlan(this.dayIndex, this.items);

  List<FoodItem> get allItems => items.values.expand((l) => l).toList();

  double costBDT(Map<String, IngredientPrice> priceDb) => allItems
      .map((f) => f.costBDT(priceDb))
      .fold(0.0, (a, b) => a + b);

  NutritionInfo get nutrition =>
      allItems.map((f) => f.nutrition).fold(NutritionInfo.zero, (a, b) => a + b);
}

class WeeklyMealPlan {
  final List<DailyMealPlan> days;
  final double weeklyBudgetBDT;
  final double totalCostBDT;
  final NutritionInfo totalNutrition;
  final double dailyCalorieTarget;
  final List<String> notes;

  WeeklyMealPlan({
    required this.days,
    required this.weeklyBudgetBDT,
    required this.totalCostBDT,
    required this.totalNutrition,
    required this.dailyCalorieTarget,
    required this.notes,
  });

  double get remainingBudgetBDT => weeklyBudgetBDT - totalCostBDT;
  bool get isWithinBudget => totalCostBDT <= weeklyBudgetBDT + 0.01;
  double get avgDailyCalories => totalNutrition.calories / days.length;
}

class MealPlanOptimizer {
  final List<FoodItem> foodDb;
  final Map<String, IngredientPrice> priceDb;
  final Random _random;

  MealPlanOptimizer({
    required this.foodDb,
    required this.priceDb,
    int? randomSeed,
  }) : _random = Random(randomSeed ?? 42);

  static const _proteinCategories = [
    FoodCategory.dal,
    FoodCategory.fishCurry,
    FoodCategory.eggDish,
    FoodCategory.meatCurry,
  ];

  static const _sideCategories = [
    FoodCategory.bhorta,
    FoodCategory.vegetableCurry,
    FoodCategory.shak,
  ];

  WeeklyMealPlan generate({
    required double weeklyBudgetBDT,
    required double dailyCalorieTarget,
    bool vegetarianOnly = false,
    int maxRepeatsPerItemPerWeek = 3,
    bool includeSnacks = true,
  }) {
    final eligible = foodDb
        .where((f) => !vegetarianOnly || f.isVegetarian)
        .toList();

    final riceRotator = _CategoryRotator(
      _sortedByValue(eligible, [FoodCategory.riceBased]),
      maxRepeats: maxRepeatsPerItemPerWeek,
      random: _random,
    );
    final proteinRotator = _CategoryRotator(
      _sortedByValue(eligible, _proteinCategories),
      maxRepeats: maxRepeatsPerItemPerWeek,
      random: _random,
    );
    final sideRotator = _CategoryRotator(
      _sortedByValue(eligible, _sideCategories),
      maxRepeats: maxRepeatsPerItemPerWeek,
      random: _random,
    );
    final breakfastRotator = _CategoryRotator(
      _sortedByValue(eligible, [FoodCategory.breakfast]),
      maxRepeats: maxRepeatsPerItemPerWeek,
      random: _random,
    );
    final snackRotator = _CategoryRotator(
      _sortedByValue(eligible, [FoodCategory.snack, FoodCategory.sweet]),
      maxRepeats: 2,
      random: _random,
    );

    final days = <DailyMealPlan>[];
    for (int d = 0; d < 7; d++) {
      final Map<MealSlot, List<FoodItem>> slots = {
        MealSlot.breakfast: _nonNull([breakfastRotator.next()]),
        MealSlot.lunch: _nonNull(
            [riceRotator.next(), proteinRotator.next(), sideRotator.next()]),
        MealSlot.dinner: _nonNull(
            [riceRotator.next(), proteinRotator.next(), sideRotator.next()]),
      };
      days.add(DailyMealPlan(d, slots));
    }

    var totalCost = days.fold(0.0, (a, d) => a + d.costBDT(priceDb));
    final notes = <String>[];

    // --- Downgrade pass if over budget ---
    if (totalCost > weeklyBudgetBDT) {
      final result = _downgradeToFitBudget(
        days: days,
        eligible: eligible,
        weeklyBudgetBDT: weeklyBudgetBDT,
      );
      totalCost = result.newTotalCost;
      notes.addAll(result.notes);
    }

    // --- Optional snacks if there's slack left in the budget ---
    if (includeSnacks) {
      for (final day in days) {
        if (totalCost >= weeklyBudgetBDT) break;
        final snack = snackRotator.next();
        if (snack == null) break;
        final snackCost = snack.costBDT(priceDb);
        if (totalCost + snackCost > weeklyBudgetBDT) continue;
        day.items[MealSlot.snackTime] = [snack];
        totalCost += snackCost;
      }
    }

    final totalNutrition =
        days.map((d) => d.nutrition).fold(NutritionInfo.zero, (a, b) => a + b);

    if (days.isNotEmpty) {
      final avgCal = totalNutrition.calories / days.length;
      if (avgCal < dailyCalorieTarget * 0.9) {
        notes.add(
            'Average day is ~${avgCal.round()} kcal, below your ${dailyCalorieTarget.round()} kcal target — '
            'consider a larger rice portion or an extra side within budget.');
      } else if (avgCal > dailyCalorieTarget * 1.15) {
        notes.add(
            'Average day is ~${avgCal.round()} kcal, above your ${dailyCalorieTarget.round()} kcal target — '
            'consider trimming portion sizes.');
      }
    }

    if (totalCost > weeklyBudgetBDT) {
      notes.add(
          'Could not fit fully within budget even after downgrading — short by '
          '৳${(totalCost - weeklyBudgetBDT).toStringAsFixed(0)}. Consider raising the budget '
          'or relying more on rice + dal + shak days.');
    }

    return WeeklyMealPlan(
      days: days,
      weeklyBudgetBDT: weeklyBudgetBDT,
      totalCostBDT: totalCost,
      totalNutrition: totalNutrition,
      dailyCalorieTarget: dailyCalorieTarget,
      notes: notes,
    );
  }

  List<FoodItem> _sortedByValue(
      List<FoodItem> pool, List<FoodCategory> categories) {
    final filtered =
        pool.where((f) => categories.contains(f.category)).toList();
    filtered.sort(
        (a, b) => b.valueScore(priceDb).compareTo(a.valueScore(priceDb)));
    return filtered;
  }

  List<FoodItem> _nonNull(List<FoodItem?> items) =>
      items.whereType<FoodItem>().toList();

  _DowngradeResult _downgradeToFitBudget({
    required List<DailyMealPlan> days,
    required List<FoodItem> eligible,
    required double weeklyBudgetBDT,
  }) {
    final notes = <String>[];
    var totalCost = days.fold(0.0, (a, d) => a + d.costBDT(priceDb));
    int guard = 0;

    while (totalCost > weeklyBudgetBDT && guard < 200) {
      guard++;
      // Find the single most expensive item currently in the plan.
      FoodItem? costliest;
      DailyMealPlan? costliestDay;
      MealSlot? costliestSlot;
      int costliestIndex = -1;
      double costliestPrice = -1;

      for (final day in days) {
        for (final slot in day.items.keys) {
          final list = day.items[slot]!;
          for (int i = 0; i < list.length; i++) {
            final price = list[i].costBDT(priceDb);
            if (price > costliestPrice) {
              costliestPrice = price;
              costliest = list[i];
              costliestDay = day;
              costliestSlot = slot;
              costliestIndex = i;
            }
          }
        }
      }

      if (costliest == null || costliestDay == null || costliestSlot == null) {
        break; // nothing left to downgrade
      }
      // Copy into a final local: Dart won't treat `costliest` as
      // non-null inside the closure below since it's a mutable var.
      final costliestItem = costliest;

      final alternatives = eligible
          .where((f) =>
              f.category == costliestItem.category && f.id != costliestItem.id)
          .toList()
        ..sort((a, b) => a.costBDT(priceDb).compareTo(b.costBDT(priceDb)));

      if (alternatives.isEmpty || alternatives.first.costBDT(priceDb) >= costliestPrice) {
        // No cheaper option exists in this category — stop trying this item
        // by nudging its price down artificially won't help; just break to
        // avoid an infinite loop, and let the caller report the shortfall.
        break;
      }

      final replacement = alternatives.first;
      final savedAmount = costliestPrice - replacement.costBDT(priceDb);
      costliestDay.items[costliestSlot]![costliestIndex] = replacement;
      totalCost -= savedAmount;

      notes.add(
          'Swapped ${costliestItem.nameEn} → ${replacement.nameEn} on day ${costliestDay.dayIndex + 1} '
          '(saves ~৳${savedAmount.toStringAsFixed(0)}).');
    }

    return _DowngradeResult(newTotalCost: totalCost, notes: notes);
  }
}

class _DowngradeResult {
  final double newTotalCost;
  final List<String> notes;
  _DowngradeResult({required this.newTotalCost, required this.notes});
}

/// Cycles through the top-K highest value-per-taka candidates in a
/// category so the plan gets variety instead of always repeating the
/// single best-scoring dish, while still respecting a repeat cap.
class _CategoryRotator {
  final List<FoodItem> sortedByValue;
  final int topK;
  final int maxRepeats;
  final Random random;
  final Map<String, int> _usage = {};
  int _cursor = 0;

  _CategoryRotator(
    this.sortedByValue, {
    this.topK = 5,
    this.maxRepeats = 3,
    required this.random,
  });

  FoodItem? next() {
    if (sortedByValue.isEmpty) return null;
    final pool = sortedByValue.take(topK).toList();

    for (int i = 0; i < pool.length; i++) {
      final idx = (_cursor + i) % pool.length;
      final item = pool[idx];
      final used = _usage[item.id] ?? 0;
      if (used < maxRepeats) {
        _usage[item.id] = used + 1;
        _cursor = (idx + 1) % pool.length;
        return item;
      }
    }

    // Everything in the top-K is maxed out — fall back to the
    // least-used item across the whole category so we don't stall.
    final byUsage = List<FoodItem>.from(sortedByValue)
      ..sort((a, b) =>
          (_usage[a.id] ?? 0).compareTo(_usage[b.id] ?? 0));
    final fallback = byUsage.first;
    _usage[fallback.id] = (_usage[fallback.id] ?? 0) + 1;
    return fallback;
  }
}
