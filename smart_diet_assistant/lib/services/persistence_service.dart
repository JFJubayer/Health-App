import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../models/gamification_model.dart';
import '../hive/entities/ingredient_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/day_plan_entity.dart';
import '../hive/entities/meal_memory_entity.dart';
import '../hive/entities/user_meal_preference_entity.dart';
import '../models/shopping_item.dart';
import '../models/sugar_reading.dart';
import '../bd_food_db/models/food_models.dart';

class PersistenceService {
  static Box<IngredientEntity>? _ingredientsBox;
  static Box<MealTemplateEntity>? _templatesBox;
  static Box<DayPlanEntity>? _dayPlansBox;
  static Box<MealMemoryEntity>? _mealMemoryBox;
  static Box<UserMealPreferenceEntity>? _preferencesBox;
  static Box<dynamic>? _metaBox;
  static Box<FoodItem>? _bdFoodItemBox;
  static Box<IngredientPrice>? _bdIngredientPriceBox;

  static Future<void> initHive() async {
    _ingredientsBox = await Hive.openBox<IngredientEntity>('ingredients');
    _templatesBox = await Hive.openBox<MealTemplateEntity>('meal_templates');
    _dayPlansBox = await Hive.openBox<DayPlanEntity>('day_plans');
    _mealMemoryBox = await Hive.openBox<MealMemoryEntity>('meal_memory');
    _preferencesBox = await Hive.openBox<UserMealPreferenceEntity>('user_preferences');
    _metaBox = await Hive.openBox<dynamic>('meta');
    _bdFoodItemBox = await Hive.openBox<FoodItem>('bd_food_items');
    _bdIngredientPriceBox = await Hive.openBox<IngredientPrice>('bd_ingredient_prices');
  }

  static Future<void> setSeedVersion(int version) async {
    await _metaBox?.put('seed_version', version);
  }

  static int getSeedVersion() {
    return _metaBox?.get('seed_version', defaultValue: 0) as int? ?? 0;
  }

  static Future<void> saveDayPlan(DayPlanEntity plan) async {
    await _dayPlansBox?.put(plan.id, plan);
  }

  static DayPlanEntity? getDayPlan(String id) {
    return _dayPlansBox?.get(id);
  }

  static List<DayPlanEntity> getAllDayPlansInRange(DateTime start, DateTime end) {
    if (_dayPlansBox == null) return [];
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _dayPlansBox!.values.where((plan) {
      return !plan.date.isBefore(startDay) && !plan.date.isAfter(endDay);
    }).toList();
  }

  static Future<void> saveMealTemplate(MealTemplateEntity template) async {
    await _templatesBox?.put(template.id, template);
  }

  static Future<void> saveMealMemory(
    MealMemoryEntity memory,
) async {
  await _mealMemoryBox?.put(memory.id, memory);
}

  static List<MealMemoryEntity> getMealMemories(
      String userId,
  ) {
    return _mealMemoryBox?.values
            .where((m) => m.userId == userId)
            .toList() ??
        [];
  }

  static Future<void> savePreferences(
      UserMealPreferenceEntity pref,
  ) async {
    await _preferencesBox?.put(pref.userId, pref);
  }

  static UserMealPreferenceEntity? getPreferences(
      String userId,
  ) {
    return _preferencesBox?.get(userId);
  }

  static List<MealTemplateEntity> getAllTemplates() {
    return _templatesBox?.values.toList() ?? [];
  }

  static Future<void> saveIngredient(IngredientEntity ingredient) async {
    await _ingredientsBox?.put(ingredient.id, ingredient);
  }

  static List<IngredientEntity> getAllIngredients() {
    return _ingredientsBox?.values.toList() ?? [];
  }

  static Future<void> saveAllIngredients(List<IngredientEntity> ingredients) async {
    final Map<String, IngredientEntity> map = {};
    for (var i in ingredients) {
      map[i.id] = i;
    }
    await _ingredientsBox?.putAll(map);
  }

  static Future<void> saveAllTemplates(List<MealTemplateEntity> templates) async {
    final Map<String, MealTemplateEntity> map = {};
    for (var t in templates) {
      map[t.id] = t;
    }
    await _templatesBox?.putAll(map);
  }

  static const String _keyUser = 'user_data';
  static const String _keyMeals = 'meal_plan';

  static const String _keyCheckedIngredients = 'checked_ingredients';

  static const String _keyFastingDuration = 'fasting_duration';
  static const String _keyFastingStartTime = 'fasting_start_time';
  static const String _keyFastingReminderOffset = 'fasting_reminder_offset';

  static const String _keyGamification = 'gamification_data';

  static Future<void> saveGamification(GamificationModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGamification, jsonEncode(data.toMap()));
  }

  static Future<GamificationModel> getGamification() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyGamification);
    if (data == null) return GamificationModel();
    return GamificationModel.fromMap(jsonDecode(data));
  }

  static Future<void> saveDailySummary(String dateStr, int consumedCalories, int waterIntake, {int burnedCalories = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('summary_$dateStr', jsonEncode({
      'calories': consumedCalories,
      'water': waterIntake,
      'burnedCalories': burnedCalories,
    }));
  }

  static Future<Map<String, dynamic>?> getDailySummary(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('summary_$dateStr');
    if (data == null) return null;
    return jsonDecode(data);
  }

  // Workout logs persistence
  static String _workoutLogsKey(String dateStr) => 'workout_logs_$dateStr';

  static Future<void> saveWorkoutLogs(String dateStr, List<Map<String, dynamic>> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workoutLogsKey(dateStr), jsonEncode(logs));
  }

  static Future<List<Map<String, dynamic>>> getWorkoutLogs(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_workoutLogsKey(dateStr));
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // Burned calories persistence (separate key for quick access)
  static Future<void> saveBurnedCalories(int calories) async {
    final prefs = await SharedPreferences.getInstance();
    final String dateKey = 'burned_${DateTime.now().toIso8601String().substring(0, 10)}';
    await prefs.setInt(dateKey, calories);
  }

  static Future<int> getBurnedCalories() async {
    final prefs = await SharedPreferences.getInstance();
    final String dateKey = 'burned_${DateTime.now().toIso8601String().substring(0, 10)}';
    return prefs.getInt(dateKey) ?? 0;
  }

  // Workout daily target persistence
  static Future<void> saveWorkoutDailyTarget(int calories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workout_daily_target', calories);
  }

  static Future<int> getWorkoutDailyTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('workout_daily_target') ?? 300;
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toMap()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUser);
    if (data == null) return null;
    return UserModel.fromMap(jsonDecode(data));
  }

  static Future<void> saveMeals(List<MealModel> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final mealList = meals.map((m) => m.toMap()).toList();
    await prefs.setString(_keyMeals, jsonEncode(mealList));
  }

  static Future<List<MealModel>?> getMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyMeals);
    if (data == null) return null;
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((m) => MealModel.fromMap(m)).toList();
  }

  static Future<void> saveWaterIntake(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final String dateKey = 'water_${DateTime.now().toIso8601String().substring(0, 10)}';
    await prefs.setInt(dateKey, ml);
  }

  static Future<int> getWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final String dateKey = 'water_${DateTime.now().toIso8601String().substring(0, 10)}';
    return prefs.getInt(dateKey) ?? 0;
  }

  static Future<void> saveWaterGoal(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal', ml);
  }

  static Future<int?> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('water_goal');
  }

  static Future<void> saveCheckedIngredients(Set<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCheckedIngredients, items.toList());
  }

  static Future<Set<String>> getCheckedIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCheckedIngredients);
    return list?.toSet() ?? {};
  }

  static Future<void> saveFastingDuration(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFastingDuration, hours);
  }

  static Future<int> getFastingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFastingDuration) ?? 16;
  }

  static Future<void> saveFastingStartTime(DateTime? startTime) async {
    final prefs = await SharedPreferences.getInstance();
    if (startTime == null) {
      await prefs.remove(_keyFastingStartTime);
    } else {
      await prefs.setString(_keyFastingStartTime, startTime.toIso8601String());
    }
  }

  static Future<DateTime?> getFastingStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyFastingStartTime);
    if (data == null) return null;
    return DateTime.tryParse(data);
  }

  static Future<void> saveFastingReminderOffset(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFastingReminderOffset, minutes);
  }

  static Future<int> getFastingReminderOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFastingReminderOffset) ?? 0; // Default: at time of end
  }

  static String _customMealsKey(String dateStr) => 'custom_meals_$dateStr';

  static Future<void> saveCustomMealsForDate(
    String dateStr,
    List<MealModel> meals,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final mealList = meals.map((m) => m.toMap()).toList();
    await prefs.setString(_customMealsKey(dateStr), jsonEncode(mealList));
  }

  static Future<List<MealModel>> getCustomMealsForDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_customMealsKey(dateStr));
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((m) => MealModel.fromMap(m)).toList();
  }

  static const String _keyHydrationReminders = 'hydration_reminders_enabled';

  static Future<void> saveHydrationRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHydrationReminders, enabled);
  }

  static Future<bool> getHydrationRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHydrationReminders) ?? true;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static const String _keyCustomShoppingItems = 'custom_shopping_items';

  static Future<void> saveCustomShoppingItems(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemList = items.map((i) => i.toMap()).toList();
    await prefs.setString(_keyCustomShoppingItems, jsonEncode(itemList));
  }

  static Future<List<ShoppingItem>> getCustomShoppingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyCustomShoppingItems);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((m) => ShoppingItem.fromMap(m)).toList();
  }

  static const String _keySugarReadings = 'sugar_readings';

  static Future<void> saveSugarReadings(Map<String, SugarReading> readings) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, Map<String, dynamic>> serialized = readings.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    await prefs.setString(_keySugarReadings, jsonEncode(serialized));
  }

  static Future<Map<String, SugarReading>> getSugarReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keySugarReadings);
    if (data == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map(
        (key, value) => MapEntry(key, SugarReading.fromMap(value)),
      );
    } catch (_) {
      return {};
    }
  }

  // bd_food_db helper methods
  static List<FoodItem> getAllBdFoodItems() {
    return _bdFoodItemBox?.values.toList() ?? [];
  }

  static FoodItem? getBdFoodItem(String id) {
    return _bdFoodItemBox?.get(id);
  }

  static Future<void> saveBdFoodItem(FoodItem item) async {
    await _bdFoodItemBox?.put(item.id, item);
  }

  static Future<void> saveAllBdFoodItems(List<FoodItem> items) async {
    final Map<String, FoodItem> map = {for (var i in items) i.id: i};
    await _bdFoodItemBox?.putAll(map);
  }

  static List<IngredientPrice> getAllBdIngredientPrices() {
    return _bdIngredientPriceBox?.values.toList() ?? [];
  }

  static Map<String, IngredientPrice> getBdIngredientPricesMap() {
    if (_bdIngredientPriceBox == null) return {};
    return {for (var p in _bdIngredientPriceBox!.values) p.id: p};
  }

  static Future<void> saveBdIngredientPrice(IngredientPrice price) async {
    await _bdIngredientPriceBox?.put(price.id, price);
  }

  static Future<void> saveAllBdIngredientPrices(List<IngredientPrice> prices) async {
    final Map<String, IngredientPrice> map = {for (var p in prices) p.id: p};
    await _bdIngredientPriceBox?.putAll(map);
  }
}
