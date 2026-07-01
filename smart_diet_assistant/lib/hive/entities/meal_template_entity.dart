import 'package:hive/hive.dart';
import '../../models/meal_model.dart'; // For MealType
import 'ingredient_portion_entity.dart';
part 'meal_template_entity.g.dart';



@HiveType(typeId: 1)
class MealTemplateEntity {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  MealType type;

  @HiveField(3)
  List<IngredientPortion> ingredients;

  @HiveField(4, defaultValue: [])
  List<String> tags;

  @HiveField(5, defaultValue: [])
  List<String> conditions;

  @HiveField(6)
  int prepTimeMinutes;

  @HiveField(7)
  double rating;

  @HiveField(8)
  int timesUsed;

  @HiveField(9, defaultValue: false)
  bool isCustom;
  
  @HiveField(10, defaultValue: [])
  List<String> recipeSteps;
  
  @HiveField(11)
  String instructions;
  
  @HiveField(12)
  String? imageUrl;

  MealTemplateEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.ingredients,
    this.tags = const [],
    this.conditions = const [],
    this.prepTimeMinutes = 15,
    this.rating = 0.0,
    this.timesUsed = 0,
    this.isCustom = false,
    this.recipeSteps = const [],
    this.instructions = '',
    this.imageUrl,
  });
}
