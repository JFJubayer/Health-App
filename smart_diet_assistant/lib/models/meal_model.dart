enum MealType { breakfast, lunch, dinner }

class MealModel {
  final String name;
  final int calories;
  final MealType type;

  MealModel({
    required this.name,
    required this.calories,
    required this.type,
  });
}
