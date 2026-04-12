import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../services/health_service.dart';
import '../services/diet_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  double _bmr = 0.0;
  double _tdee = 0.0;
  String _calorieTier = '';
  List<MealModel> _mealPlan = [];

  UserModel? get user => _user;
  double get bmr => _bmr;
  double get tdee => _tdee;
  String get calorieTier => _calorieTier;
  List<MealModel> get mealPlan => _mealPlan;

  void setUserData(UserModel user) {
    _user = user;
    _bmr = HealthService.calculateBMR(user);
    _tdee = HealthService.calculateTDEE(_bmr);
    _calorieTier = DietService.getCalorieTier(_tdee);
    _mealPlan = DietService.generateMealPlan(_calorieTier, conditions: user.conditions);
    notifyListeners();
  }
  
  void regenerateMeals() {
    _mealPlan = DietService.generateMealPlan(_calorieTier, conditions: _user?.conditions ?? []);
    notifyListeners();
  }

  void replaceMeal(MealModel currentMeal) {
    int index = _mealPlan.indexOf(currentMeal);
    if (index != -1) {
      _mealPlan[index] = DietService.getAlternativeMeal(
        currentMeal.type, 
        _calorieTier, 
        _user?.conditions ?? [], 
        currentMeal
      );
      notifyListeners();
    }
  }
  
  void clearUser() {
    _user = null;
    _bmr = 0.0;
    _tdee = 0.0;
    _calorieTier = '';
    _mealPlan = [];
    notifyListeners();
  }
}
