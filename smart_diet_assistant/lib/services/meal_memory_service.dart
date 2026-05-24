import '../hive/entities/meal_memory_entity.dart';
import '../services/persistence_service.dart';

class MealMemoryService {
  static const String localUserId = 'local';

  static Future<void> logMeal({
    required String mealId,
    required bool consumed,
    double satisfaction = 0,
    String? notes,
  }) async {
    final now = DateTime.now();

    final id =
        'mem_${localUserId}_${mealId}_${now.year}_${now.month}_${now.day}';

    final memory = MealMemoryEntity(
      id: id,
      userId: localUserId,
      mealTemplateId: mealId,
      consumedAt: now,
      notes: notes,
      satisfaction: satisfaction,
      wasConsumed: consumed,
    );

    await PersistenceService.saveMealMemory(memory);
  }

  static List<MealMemoryEntity> getMealHistory() {
    return PersistenceService.getMealMemories(
      localUserId,
    );
  }

  static List<String> getRecentlyConsumedMealIds({
    int days = 3,
  }) {
    final memories =
        PersistenceService.getMealMemories(localUserId);

    final cutoff = DateTime.now().subtract(
      Duration(days: days),
    );

    return memories
        .where(
          (m) =>
              m.wasConsumed &&
              m.consumedAt.isAfter(cutoff),
        )
        .map((m) => m.mealTemplateId)
        .toSet()
        .toList();
  }
}