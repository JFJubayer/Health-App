import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

class PersistenceService {
  static const String _keyUser = 'user_data';
  static const String _keyMeals = 'meal_plan';

  static const String _keyCheckedIngredients = 'checked_ingredients';

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

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
