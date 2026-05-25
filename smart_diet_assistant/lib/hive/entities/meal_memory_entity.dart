import 'package:hive/hive.dart';

part 'meal_memory_entity.g.dart';

@HiveType(typeId: 6)
class MealMemoryEntity {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String mealTemplateId;

  @HiveField(3)
  DateTime consumedAt;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  double satisfaction; // 0.0 - 5.0

  @HiveField(6)
  bool wasConsumed;

  MealMemoryEntity({
    required this.id,
    required this.userId,
    required this.mealTemplateId,
    required this.consumedAt,
    this.notes,
    this.satisfaction = 0.0,
    this.wasConsumed = true,
  });
}
