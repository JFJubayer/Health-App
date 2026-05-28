class MacroTargets {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const MacroTargets({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  factory MacroTargets.balanced(double targetCalories) {
    return MacroTargets(
      proteinGrams: (targetCalories * 0.3) / 4,
      carbsGrams: (targetCalories * 0.4) / 4,
      fatGrams: (targetCalories * 0.3) / 9,
    );
  }

  factory MacroTargets.highProtein(double targetCalories) {
    return MacroTargets(
      proteinGrams: (targetCalories * 0.4) / 4,
      carbsGrams: (targetCalories * 0.3) / 4,
      fatGrams: (targetCalories * 0.3) / 9,
    );
  }

  factory MacroTargets.lowCarb(double targetCalories) {
    return MacroTargets(
      proteinGrams: (targetCalories * 0.3) / 4,
      carbsGrams: (targetCalories * 0.2) / 4,
      fatGrams: (targetCalories * 0.5) / 9,
    );
  }
}
