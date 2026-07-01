import 'package:hive/hive.dart';

part 'user_meal_preference_entity.g.dart';

@HiveType(typeId: 5)
class UserMealPreferenceEntity {
  @HiveField(0)
  String userId;

  @HiveField(1, defaultValue: [])
  List<String> favoriteMealIds;

  @HiveField(2, defaultValue: [])
  List<String> dislikedIngredientIds;

  @HiveField(3, defaultValue: [])
  List<String> dietaryRestrictions;

  @HiveField(4, defaultValue: {})
  Map<String, double> mealRatings; // mealId -> rating 0-5

  @HiveField(5, defaultValue: [])
  List<String> preferredTags;

  @HiveField(6, defaultValue: [])
  List<String> avoidedMealIds;

  @HiveField(7)
  DateTime? lastUpdated;

  UserMealPreferenceEntity({
    required this.userId,
    this.favoriteMealIds = const [],
    this.dislikedIngredientIds = const [],
    this.dietaryRestrictions = const [],
    this.mealRatings = const {},
    this.preferredTags = const [],
    this.avoidedMealIds = const [],
    this.lastUpdated,
  });
}
