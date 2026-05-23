import 'package:hive/hive.dart';

part 'ingredient_portion_entity.g.dart';

@HiveType(typeId: 3)
class IngredientPortion {
  @HiveField(0)
  String ingredientId;

  @HiveField(1)
  double grams;

  IngredientPortion({
    required this.ingredientId,
    required this.grams,
  });
}
