import '../hive/entities/user_meal_preference_entity.dart';
import 'meal_memory_service.dart';
import 'persistence_service.dart';

class MealFeedbackService {
  static const String userId = 'local';

  Future<void> recordMealConsumed({
    required String mealId,
    double satisfaction = 4,
    String? notes,
  }) async {
    await MealMemoryService.logMeal(
      mealId: mealId,
      consumed: true,
      satisfaction: satisfaction,
      notes: notes,
    );

    await _updateMealRating(
      mealId,
      satisfaction,
    );
  }

   Future<void> recordMealSkipped({
    required String mealId,
  }) async {
    await MealMemoryService.logMeal(
      mealId: mealId,
      consumed: false,
      satisfaction: 0,
    );

    await _penalizeMeal(mealId);
  }

  Future<UserMealPreferenceEntity> _getOrCreatePreferences() async {
    final existing = PersistenceService.getPreferences(userId);

    if (existing != null) {
      return existing;
    }

    final prefs =
        UserMealPreferenceEntity(
      userId: userId,
    );

    await PersistenceService.savePreferences(
      prefs,
    );

    return prefs;
  }


  Future<void> _updateMealRating(String mealId,double newRating,) async {
    final prefs = await _getOrCreatePreferences();

    final current = prefs.mealRatings[mealId];

    double updated;

    if (current == null) {
      updated = newRating;
    } else {
      updated =
          ((current * 0.7) +
                  (newRating * 0.3))
              .clamp(0.0, 5.0);
    }

    prefs.mealRatings[mealId] =
        updated;

    // Auto favorite
    if (updated >= 4.5 && !prefs.favoriteMealIds.contains(mealId)) {
      prefs.favoriteMealIds.add(
        mealId,
      );
    }

    await PersistenceService.savePreferences(prefs);
  }


  Future<void> _penalizeMeal(String mealId,) async {
  final prefs = await _getOrCreatePreferences();

  final current = prefs.mealRatings[mealId] ?? 3.0;

  prefs.mealRatings[mealId] = (current - 0.5).clamp(0.0, 5.0);

  await PersistenceService.savePreferences(prefs);
}


  Future<void> recordMealSwap({required String oldMealId,required String newMealId,}) async {
    await _penalizeMeal(oldMealId);

    await _updateMealRating(newMealId,4.0,);   
  }

}

   