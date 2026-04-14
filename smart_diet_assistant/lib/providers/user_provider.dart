import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../services/health_service.dart';
import '../services/diet_service.dart';
import '../services/persistence_service.dart';
import '../services/notification_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  double _bmr = 0.0;
  double _tdee = 0.0;
  String _calorieTier = '';
  List<MealModel> _mealPlan = [];
  bool _isLoading = true;
  int _waterIntake = 0;
  int _waterGoal = 2500; // Default
  Set<String> _checkedIngredients = {};

  UserModel? get user => _user;
  double get bmr => _bmr;
  double get tdee => _tdee;
  String get calorieTier => _calorieTier;
  List<MealModel> get mealPlan => _mealPlan;
  bool get isLoading => _isLoading;
  int get waterIntake => _waterIntake;
  int get waterGoal => _waterGoal;
  Set<String> get checkedIngredients => _checkedIngredients;

  List<String> get shoppingList {
    final ingredients = <String>{};
    for (var meal in _mealPlan) {
      ingredients.addAll(meal.ingredients);
    }
    return ingredients.toList();
  }

  int get totalConsumedCalories => _mealPlan.where((m) => m.isConsumed).fold(0, (sum, m) => sum + m.calories);
  double get totalConsumedProtein => _mealPlan.where((m) => m.isConsumed).fold(0.0, (sum, m) => sum + m.protein);
  double get totalConsumedCarbs => _mealPlan.where((m) => m.isConsumed).fold(0.0, (sum, m) => sum + m.carbs);
  double get totalConsumedFat => _mealPlan.where((m) => m.isConsumed).fold(0.0, (sum, m) => sum + m.fat);

  UserProvider() {
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    _user = await PersistenceService.getUser();
    if (_user != null) {
      _bmr = HealthService.calculateBMR(_user!);
      _tdee = HealthService.calculateTDEE(_bmr);
      _calorieTier = DietService.getCalorieTier(_tdee);
      _mealPlan = await PersistenceService.getMeals() ?? [];
      _waterIntake = await PersistenceService.getWaterIntake();
      _waterGoal = await PersistenceService.getWaterGoal() ?? (_user!.weightKg * 35).toInt();
      _checkedIngredients = await PersistenceService.getCheckedIngredients();
      
      // Initialize notifications
      await NotificationService.initialize(this);
      _rescheduleNotifications();
    }
    _isLoading = false;
    notifyListeners();
  }

  void addWater(int ml) {
    _waterIntake += ml;
    PersistenceService.saveWaterIntake(_waterIntake);
    _rescheduleNotifications();
    notifyListeners();
  }

  void resetWater() {
    _waterIntake = 0;
    PersistenceService.saveWaterIntake(_waterIntake);
    _rescheduleNotifications();
    notifyListeners();
  }
  
  void _rescheduleNotifications() {
    if (_user != null) {
      NotificationService.scheduleSmartWaterReminders(_waterIntake, _waterGoal);
    }
  }

  void toggleIngredient(String ingredient) {
    if (_checkedIngredients.contains(ingredient)) {
      _checkedIngredients.remove(ingredient);
    } else {
      _checkedIngredients.add(ingredient);
    }
    PersistenceService.saveCheckedIngredients(_checkedIngredients);
    notifyListeners();
  }

  void clearCheckedIngredients() {
    _checkedIngredients.clear();
    PersistenceService.saveCheckedIngredients(_checkedIngredients);
    notifyListeners();
  }

  void setUserData(UserModel user) {
    _user = user;
    _bmr = HealthService.calculateBMR(user);
    _tdee = HealthService.calculateTDEE(_bmr);
    _calorieTier = DietService.getCalorieTier(_tdee);
    _mealPlan = DietService.generateMealPlan(_calorieTier, conditions: user.conditions);
    
    // Set default water goal
    _waterGoal = (user.weightKg * 35).toInt();
    _waterIntake = 0; // Reset for new user profile
    _checkedIngredients.clear();
    
    PersistenceService.saveUser(_user!);
    PersistenceService.saveMeals(_mealPlan);
    PersistenceService.saveWaterGoal(_waterGoal);
    PersistenceService.saveWaterIntake(_waterIntake);
    PersistenceService.saveCheckedIngredients(_checkedIngredients);
    
    _rescheduleNotifications();
    notifyListeners();
  }
  
  void regenerateMeals() {
    _mealPlan = DietService.generateMealPlan(_calorieTier, conditions: _user?.conditions ?? []);
    PersistenceService.saveMeals(_mealPlan);
    notifyListeners();
  }

  void replaceMeal(String mealId) {
    int index = _mealPlan.indexWhere((m) => m.id == mealId);
    if (index != -1) {
      final currentMeal = _mealPlan[index];
      _mealPlan[index] = DietService.getAlternativeMeal(
        currentMeal.type, 
        _calorieTier, 
        _user?.conditions ?? [], 
        currentMeal
      );
      PersistenceService.saveMeals(_mealPlan);
      notifyListeners();
    }
  }

  void toggleMealConsumed(String mealId) {
    int index = _mealPlan.indexWhere((m) => m.id == mealId);
    if (index != -1) {
      _mealPlan[index].isConsumed = !_mealPlan[index].isConsumed;
      PersistenceService.saveMeals(_mealPlan);
      notifyListeners();
    }
  }
  
  void addCustomMeal(MealModel meal) {
    _mealPlan.add(meal);
    PersistenceService.saveMeals(_mealPlan);
    notifyListeners();
  }

  void deleteMeal(String mealId) {
    _mealPlan.removeWhere((m) => m.id == mealId);
    PersistenceService.saveMeals(_mealPlan);
    notifyListeners();
  }
  
  void clearUser() {
    _user = null;
    _bmr = 0.0;
    _tdee = 0.0;
    _calorieTier = '';
    _mealPlan = [];
    PersistenceService.clearAll();
    notifyListeners();
  }
}
