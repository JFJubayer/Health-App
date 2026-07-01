import 'package:hive/hive.dart';

part 'ingredient_entity.g.dart';

@HiveType(typeId: 0)
class IngredientEntity {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double caloriesPer100g;

  @HiveField(3)
  double protein;

  @HiveField(4)
  double carbs;

  @HiveField(5)
  double fat;

  @HiveField(6, defaultValue: [])
  List<String> tags;

  @HiveField(7, defaultValue: false)
  bool isCustom;

  IngredientEntity({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.tags = const [],
    this.isCustom = false,
  });
}
