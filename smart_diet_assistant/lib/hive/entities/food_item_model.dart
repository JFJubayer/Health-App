class FoodItemModel {
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodItemModel({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    return FoodItemModel(
      name: map['name'],
      caloriesPer100g: map['caloriesPer100g'].toDouble(),
      proteinPer100g: map['proteinPer100g'].toDouble(),
      carbsPer100g: map['carbsPer100g'].toDouble(),
      fatPer100g: map['fatPer100g'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
    };
  }
}
