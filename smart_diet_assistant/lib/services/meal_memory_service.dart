import '../hive/entities/meal_memory_entity.dart';
import '../services/persistence_service.dart';

class MealMemoryService {
  static const String localUserId = 'local';

  static Future<void> logMeal({
    required String mealId,
    required bool consumed,
    double satisfaction = 0,
    bool wasSwapped = false,
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
      wasSwapped: wasSwapped,
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

  static DateTime? getLastServedDate(String mealId) {
    final memories = PersistenceService.getMealMemories(localUserId);
    final mealMemories = memories.where((m) => m.mealTemplateId == mealId).toList();
    if (mealMemories.isEmpty) return null;
    mealMemories.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    return mealMemories.first.consumedAt;
  }

  static double getSwapRate(String mealId) {
    final memories = PersistenceService.getMealMemories(localUserId);
    final mealMemories = memories.where((m) => m.mealTemplateId == mealId).toList();
    if (mealMemories.isEmpty) return 0.0;
    
    final swappedCount = mealMemories.where((m) => m.wasSwapped).length;
    return swappedCount / mealMemories.length;
  }
}