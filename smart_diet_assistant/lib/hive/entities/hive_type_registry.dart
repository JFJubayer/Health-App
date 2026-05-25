import 'package:hive/hive.dart';

import 'ingredient_entity.dart';
import 'meal_template_entity.dart';
import 'ingredient_portion_entity.dart';
import 'day_plan_entity.dart';
import 'meal_memory_entity.dart';
import 'user_meal_preference_entity.dart';
import '../../models/meal_model.dart';

void registerHiveAdapters() {
  void registerOnce<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  registerOnce(IngredientEntityAdapter());
  registerOnce(MealTemplateEntityAdapter());
  registerOnce(IngredientPortionAdapter());
  registerOnce(DayPlanEntityAdapter());
  registerOnce(MealMemoryEntityAdapter());
  registerOnce(UserMealPreferenceEntityAdapter());
  registerOnce(MealTypeAdapter());
}
