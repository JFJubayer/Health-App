class MacroTargets {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  MacroTargets({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  double get totalCalories => (proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9);
}

class MacroCalculator {
  static MacroTargets calculateMacroTargets(double tdee) {
    return MacroTargets(
      proteinGrams: (tdee * 0.3) / 4,
      carbsGrams: (tdee * 0.4) / 4,
      fatGrams: (tdee * 0.3) / 9,
    );
  }

  static String getMacroImbalanceWarning({
    required double proteinConsumed,
    required double proteinTarget,
    required double carbsConsumed,
    required double carbsTarget,
    required double fatConsumed,
    required double fatTarget,
  }) {
    const threshold = 0.15;

    final proteinRatio = proteinTarget > 0 ? proteinConsumed / proteinTarget : 0;
    final carbsRatio = carbsTarget > 0 ? carbsConsumed / carbsTarget : 0;
    final fatRatio = fatTarget > 0 ? fatConsumed / fatTarget : 0;

    if (proteinRatio < 1 - threshold) {
      return 'Protein intake is low';
    }
    if (carbsRatio > 1 + threshold) {
      return 'Carbs exceeded target';
    }
    if (fatRatio > 1 + threshold) {
      return 'Fat exceeded target';
    }

    return 'Macros balanced!';
  }

  static double getProjectedIntake({
    required double consumed,
    required double target,
    required double mealsPerDay,
    required double mealsConsumed,
  }) {
    if (mealsConsumed == 0) return target;
    final avgMealSize = consumed / mealsConsumed;
    return avgMealSize * mealsPerDay;
  }
}
