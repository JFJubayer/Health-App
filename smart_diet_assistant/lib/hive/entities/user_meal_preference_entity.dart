import 'package:hive/hive.dart';

part 'user_meal_preference_entity.g.dart';

@HiveType(typeId: 5)
class UserMealPreferenceEntity {
  @HiveField(0)
  String userId;

  @HiveField(1)
  List<String> favoriteMealIds;

  @HiveField(2)
  List<String> dislikedIngredientIds;

  @HiveField(3)
  List<String> dietaryRestrictions;

  @HiveField(4)
  Map<String, int> mealRatings; // mealId -> rating 0-5

  UserMealPreferenceEntity({
    required this.userId,
    this.favoriteMealIds = const [],
    this.dislikedIngredientIds = const [],
    this.dietaryRestrictions = const [],
    this.mealRatings = const {},
  });
}
