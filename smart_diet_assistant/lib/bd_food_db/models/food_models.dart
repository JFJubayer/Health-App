// food_models.dart
//
// Core data models for the Bangladeshi Food Database + cost-aware planning.
//
// ⚠️ HIVE TYPE ID WARNING ⚠️
// This file registers Hive typeIds 20–29. Before merging into
// smart_diet_assistant, check your existing @HiveType(typeId: ...)
// declarations and shift these numbers if there's a collision.
// Hive will silently corrupt data (or throw at runtime) if two
// different classes share a typeId.
//
// After editing this file, regenerate the adapters with:
//   dart run build_runner build --delete-conflicting-outputs
//
// Then register adapters once at startup (e.g. in main.dart):
//   Hive.registerAdapter(FoodCategoryAdapter());
//   Hive.registerAdapter(RegionAdapter());
//   Hive.registerAdapter(MealSlotAdapter());
//   Hive.registerAdapter(IngredientQtyAdapter());
//   Hive.registerAdapter(NutritionInfoAdapter());
//   Hive.registerAdapter(GlycemicImpactAdapter());
//   Hive.registerAdapter(ConditionFlagAdapter());
//   Hive.registerAdapter(ConditionConsiderationsAdapter());
//   Hive.registerAdapter(FoodItemAdapter());
//   Hive.registerAdapter(IngredientPriceAdapter());
//
// ⚠️ NOT MEDICAL ADVICE ⚠️
// `sodiumMg`, `glycemicImpact`, and `conditionNotes` on FoodItem are
// systematic estimates derived from each dish's ingredients and cooking
// method (refined-carb-heavy → higher glycemic impact, dried
// fish/added-salt-heavy → higher sodium, etc.) — not values checked
// dish-by-dish against a lab reference or reviewed by a dietitian. Treat
// them as a reasonable starting filter, not a clinical certification.
// Before shipping any UI copy that reads like medical guidance (e.g. "safe
// for diabetics"), get these reviewed by a qualified dietitian, and keep
// language in the app itself to informational framing ("lower glycemic
// impact") rather than diagnostic framing ("diabetes-approved"). Always
// keep a visible "consult your doctor" nudge next to condition-based
// filtering — this dataset is a planning aid, not a substitute for one.

import 'package:hive/hive.dart';

part 'food_models.g.dart';

/// Broad category used both for browsing the DB and for slotting
/// items into a meal template (e.g. "lunch needs 1 riceBased + 1 curry").
@HiveType(typeId: 20)
enum FoodCategory {
  @HiveField(0)
  riceBased,
  @HiveField(1)
  bhorta,
  @HiveField(2)
  dal,
  @HiveField(3)
  fishCurry,
  @HiveField(4)
  meatCurry,
  @HiveField(5)
  eggDish,
  @HiveField(6)
  vegetableCurry,
  @HiveField(7)
  shak, // leafy greens, usually stir-fried
  @HiveField(8)
  snack,
  @HiveField(9)
  breakfast,
  @HiveField(10)
  sweet,
  @HiveField(11)
  soupStew,
}

@HiveType(typeId: 21)
enum Region {
  @HiveField(0)
  general, // eaten nationwide, no strong regional identity
  @HiveField(1)
  sylhet,
  @HiveField(2)
  chittagong,
  @HiveField(3)
  noakhali,
  @HiveField(4)
  barisal,
  @HiveField(5)
  rajshahi,
  @HiveField(6)
  khulna,
  @HiveField(7)
  mymensingh,
  @HiveField(8)
  dhaka,
}

@HiveType(typeId: 22)
enum MealSlot {
  @HiveField(0)
  breakfast,
  @HiveField(1)
  lunch,
  @HiveField(2)
  dinner,
  @HiveField(3)
  snackTime,
}

/// Coarse, ingredient-derived estimate of a portion's glycemic impact —
/// not a lab-measured glycemic index. Rice/refined-flour/sugar-heavy
/// dishes skew high; protein/fat/fiber-dominant or non-starchy-vegetable
/// dishes skew low.
@HiveType(typeId: 27)
enum GlycemicImpact {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

/// A soft, non-diagnostic signal for condition-aware filtering — see the
/// "NOT MEDICAL ADVICE" note at the top of this file before surfacing
/// this in any UI copy.
@HiveType(typeId: 28)
enum ConditionFlag {
  @HiveField(0)
  favorable,
  @HiveField(1)
  neutral,
  @HiveField(2)
  useCaution,
}

/// Per-dish, per-condition flags + a short human-readable reason. Kept
/// deliberately shallow (flag + one-line note, not a numeric score) so
/// it's obvious in the UI that this is a rough planning signal, not a
/// medical verdict.
@HiveType(typeId: 29)
class ConditionConsiderations {
  @HiveField(0)
  final ConditionFlag diabetes;
  @HiveField(1)
  final String? diabetesNote;
  @HiveField(2)
  final ConditionFlag hypertension;
  @HiveField(3)
  final String? hypertensionNote;
  @HiveField(4)
  final ConditionFlag pcos;
  @HiveField(5)
  final String? pcosNote;

  const ConditionConsiderations({
    required this.diabetes,
    this.diabetesNote,
    required this.hypertension,
    this.hypertensionNote,
    required this.pcos,
    this.pcosNote,
  });
}

/// How much of one raw ingredient a single FoodItem *portion* (see
/// [FoodItem.portionGrams]) actually uses. This is what makes cost
/// calculation possible — nutrition and price are derived from the
/// same recipe, not hand-entered twice.
@HiveType(typeId: 23)
class IngredientQty {
  @HiveField(0)
  final String ingredientId; // matches IngredientPrice.id

  @HiveField(1)
  final double grams; // grams of raw ingredient per FoodItem portion

  const IngredientQty({required this.ingredientId, required this.grams});
}

@HiveType(typeId: 24)
class NutritionInfo {
  @HiveField(0)
  final double calories;
  @HiveField(1)
  final double proteinG;
  @HiveField(2)
  final double carbsG;
  @HiveField(3)
  final double fatG;
  @HiveField(4)
  final double fiberG;

  const NutritionInfo({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  NutritionInfo scaled(double factor) => NutritionInfo(
        calories: calories * factor,
        proteinG: proteinG * factor,
        carbsG: carbsG * factor,
        fatG: fatG * factor,
        fiberG: fiberG * factor,
      );

  NutritionInfo operator +(NutritionInfo other) => NutritionInfo(
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
        fiberG: fiberG + other.fiberG,
      );

  static const zero =
      NutritionInfo(calories: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0);
}

/// One dish, at one realistic serving size — expressed the way people
/// in Bangladesh actually describe portions (bati, plate, piece, golla),
/// not "1 cup".
@HiveType(typeId: 25)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String nameEn;
  @HiveField(2)
  final String nameBn;
  @HiveField(3)
  final FoodCategory category;
  @HiveField(4)
  final Region region;

  /// Human-readable local portion, e.g. "1 bati bhaat (~180g cooked)".
  @HiveField(5)
  final String portionDescription;

  /// Same portion, in grams, used for scaling nutrition/cost math.
  @HiveField(6)
  final double portionGrams;

  /// Nutrition FOR THIS PORTION (not per 100g).
  @HiveField(7)
  final NutritionInfo nutrition;

  /// Raw ingredients that make up this portion — the basis for cost.
  @HiveField(8)
  final List<IngredientQty> ingredients;

  @HiveField(9)
  final bool isVegetarian;

  @HiveField(10)
  final List<String> tags; // e.g. ['spicy','kids-friendly','quick']

  @HiveField(11)
  final List<MealSlot> suitableSlots;

  /// Short, ordered cooking steps — enough for someone to actually make
  /// the dish, not a full restaurant-recipe writeup.
  @HiveField(12, defaultValue: [])
  final List<String> prepSteps;

  /// Estimated sodium in mg for this portion (see file-level disclaimer).
  @HiveField(13)
  final double? sodiumMg;

  @HiveField(14, defaultValue: GlycemicImpact.medium)
  final GlycemicImpact glycemicImpact;

  @HiveField(15, defaultValue: ConditionConsiderations(
    diabetes: ConditionFlag.neutral,
    hypertension: ConditionFlag.neutral,
    pcos: ConditionFlag.neutral,
  ))
  final ConditionConsiderations conditionNotes;

  /// A short, neutral search phrase (e.g. "aloo bhorta bangladeshi food")
  /// for the app to use with a properly licensed image source at runtime.
  /// Deliberately NOT a hardcoded image URL — see ai/README.md for why.
  @HiveField(16)
  final String? imageQuery;

  // NOTE: not `const` — HiveObject (the superclass) has mutable internal
  // fields (_box, _key), so subclasses can never have const constructors.
  FoodItem({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.category,
    required this.region,
    required this.portionDescription,
    required this.portionGrams,
    required this.nutrition,
    required this.ingredients,
    required this.isVegetarian,
    this.tags = const [],
    this.suitableSlots = const [MealSlot.lunch, MealSlot.dinner],
    this.prepSteps = const [],
    this.sodiumMg,
    this.glycemicImpact = GlycemicImpact.medium,
    this.conditionNotes = const ConditionConsiderations(
      diabetes: ConditionFlag.neutral,
      hypertension: ConditionFlag.neutral,
      pcos: ConditionFlag.neutral,
    ),
    this.imageQuery,
  });

  /// Cost of ONE portion, in BDT, computed from live/current ingredient
  /// prices rather than a hardcoded number — this is the whole point of
  /// keeping price and recipe data separate.
  double costBDT(Map<String, IngredientPrice> priceDb) {
    double total = 0;
    for (final iq in ingredients) {
      final price = priceDb[iq.ingredientId];
      if (price == null) continue; // missing price: skip, don't crash
      total += (iq.grams / 1000.0) * price.pricePerKgBDT;
    }
    return total;
  }

  /// Nutrition-per-taka score used by the optimizer. Weighted toward
  /// protein and fiber because those are the nutrients low-budget
  /// Bangladeshi diets (rice-heavy, protein-poor) most often lack —
  /// so a taka spent on dal/egg/small fish should outscore a taka
  /// spent on plain rice, even though rice is cheaper per calorie.
  double valueScore(Map<String, IngredientPrice> priceDb) {
    final cost = costBDT(priceDb);
    if (cost <= 0) return 0;
    final n = nutrition;
    final weighted = (n.proteinG * 4) + (n.fiberG * 3) + (n.calories * 0.15);
    return weighted / cost;
  }
}

/// A single raw ingredient's current market price. Stored separately
/// from FoodItem so the user can update prices (they fluctuate a lot
/// in Bangladesh) without touching recipe data.
@HiveType(typeId: 26)
class IngredientPrice extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String nameEn;
  @HiveField(2)
  final String nameBn;

  /// Always normalized to price per KG, even for items usually sold
  /// by piece/dozen/liter (see [displayUnit] + [unitsPerKg] for
  /// converting back to how it's actually bought).
  @HiveField(3)
  final double pricePerKgBDT;

  @HiveField(4)
  final String displayUnit; // 'kg' | 'liter' | 'piece' | 'dozen'

  @HiveField(5)
  final String category; // grain, vegetable, fish, meat, spice, dairy, oil...

  @HiveField(6)
  final DateTime lastUpdated;

  // NOTE: not `const`, for the same reason as FoodItem above.
  IngredientPrice({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.pricePerKgBDT,
    required this.displayUnit,
    required this.category,
    required this.lastUpdated,
  });

  IngredientPrice copyWithPrice(double newPricePerKgBDT) => IngredientPrice(
        id: id,
        nameEn: nameEn,
        nameBn: nameBn,
        pricePerKgBDT: newPricePerKgBDT,
        displayUnit: displayUnit,
        category: category,
        lastUpdated: DateTime.now(),
      );
}
