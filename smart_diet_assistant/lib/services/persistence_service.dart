import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../hive/entities/user_model.dart';
import '../hive/entities/meal_model.dart';
import '../hive/entities/gamification_model.dart';
import '../hive/entities/ingredient_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import '../hive/entities/day_plan_entity.dart';

class PersistenceService {
  static Box<IngredientEntity>? _ingredientsBox;
  static Box<MealTemplateEntity>? _templatesBox;
  static Box<DayPlanEntity>? _dayPlansBox;

  static Future<void> initHive() async {
    _ingredientsBox = await Hive.openBox<IngredientEntity>('ingredients');
    _templatesBox = await Hive.openBox<MealTemplateEntity>('meal_templates');
    _dayPlansBox = await Hive.openBox<DayPlanEntity>('day_plans');
  }

  static Future<void> saveDayPlan(DayPlanEntity plan) async {
    await _dayPlansBox?.put(plan.id, plan);
  }

  static DayPlanEntity? getDayPlan(String id) {
    return _dayPlansBox?.get(id);
  }

  static Future<void> saveMealTemplate(MealTemplateEntity template) async {
    await _templatesBox?.put(template.id, template);
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

  static Future<void> saveDailySummary(String dateStr, int consumedCalories, int waterIntake) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('summary_$dateStr', jsonEncode({
      'calories': consumedCalories,
      'water': waterIntake,
    }));
  }

  static Future<Map<String, dynamic>?> getDailySummary(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('summary_$dateStr');
    if (data == null) return null;
    return jsonDecode(data);
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

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
