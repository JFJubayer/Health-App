import 'package:hive/hive.dart';

import 'ingredient_entity.dart';
import 'meal_template_entity.dart';
import 'ingredient_portion_entity.dart';
import 'day_plan_entity.dart';
import 'meal_memory_entity.dart';
import 'user_meal_preference_entity.dart';
import '../../models/meal_model.dart';

void registerHiveAdapters() {
  // Core entities
  Hive.registerAdapter(IngredientEntityAdapter());
  Hive.registerAdapter(MealTemplateEntityAdapter());
  Hive.registerAdapter(IngredientPortionAdapter());
  Hive.registerAdapter(DayPlanEntityAdapter());
  Hive.registerAdapter(MealMemoryEntityAdapter());
  Hive.registerAdapter(UserMealPreferenceEntityAdapter());

  // Existing enums/adapters from models
  Hive.registerAdapter(MealTypeAdapter());
}
