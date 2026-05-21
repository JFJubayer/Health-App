import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../services/health_service.dart';
import '../services/diet_service.dart';
import '../services/persistence_service.dart';
import '../services/notification_service.dart';
import '../models/gamification_model.dart';

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
  
  int _fastingDurationHours = 16;
  DateTime? _fastingStartTime;
  int _fastingReminderOffset = 0;

  GamificationModel _gamification = GamificationModel();

  UserModel? get user => _user;
  double get bmr => _bmr;
  double get tdee => _tdee;
  String get calorieTier => _calorieTier;
  List<MealModel> get mealPlan => _mealPlan;
  bool get isLoading => _isLoading;
  int get waterIntake => _waterIntake;
  int get waterGoal => _waterGoal;
  Set<String> get checkedIngredients => _checkedIngredients;

  int get fastingDurationHours => _fastingDurationHours;
  DateTime? get fastingStartTime => _fastingStartTime;
  int get fastingReminderOffset => _fastingReminderOffset;
  bool get isFasting => _fastingStartTime != null;
  GamificationModel get gamification => _gamification;

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
    try {
      debugPrint('UserProvider: Starting initial load...');
      _user = await PersistenceService.getUser();
      debugPrint('UserProvider: User data loaded: ${_user != null}');
      
      if (_user != null) {
        _bmr = HealthService.calculateBMR(_user!);
        _tdee = HealthService.calculateTDEE(_bmr);
        _calorieTier = DietService.getCalorieTier(_tdee);
        
        debugPrint('UserProvider: Loading meals...');
        _mealPlan = await PersistenceService.getMeals() ?? [];
        
        debugPrint('UserProvider: Loading water data...');
        _waterIntake = await PersistenceService.getWaterIntake();
        _waterGoal = await PersistenceService.getWaterGoal() ?? (_user!.weightKg * 35).toInt();
        
        debugPrint('UserProvider: Loading checked ingredients...');
        _checkedIngredients = await PersistenceService.getCheckedIngredients();
        
        debugPrint('UserProvider: Loading fasting data...');
        _fastingDurationHours = await PersistenceService.getFastingDuration();
        _fastingStartTime = await PersistenceService.getFastingStartTime();
        _fastingReminderOffset = await PersistenceService.getFastingReminderOffset();
        
        // Initialize notifications
        debugPrint('UserProvider: Initializing NotificationService...');
        await NotificationService.initialize(this);
        await NotificationService.requestPermissions();
        _rescheduleNotifications();
        debugPrint('UserProvider: NotificationService initialized.');
        
        debugPrint('UserProvider: Loading gamification data...');
        _gamification = await PersistenceService.getGamification();
        await _checkDailyReset();
      }
    } catch (e, stackTrace) {
      debugPrint('Error during UserProvider initial load: $e');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('UserProvider: Initial load complete, isLoading = false');
    }
  }

  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    
    if (_gamification.lastActiveDate != null) {
      final lastActiveStr = _gamification.lastActiveDate!.toIso8601String().substring(0, 10);
      if (lastActiveStr != todayStr) {
        final lastSummary = await PersistenceService.getDailySummary(lastActiveStr);
        if (lastSummary != null) {
          final int consumedCal = lastSummary['calories'] ?? 0;
          final int water = lastSummary['water'] ?? 0;
          
          bool perfectWater = water >= _waterGoal;
          bool perfectCals = consumedCal >= (_tdee * 0.9) && consumedCal <= (_tdee * 1.1);
          
          if (perfectWater) {
            _gamification.consecutivePerfectWaterDays++;
          } else {
            _gamification.consecutivePerfectWaterDays = 0;
          }
          
          if (perfectCals) {
            _gamification.consecutivePerfectGoalDays++;
          } else {
            _gamification.consecutivePerfectGoalDays = 0;
          }
        } else {
           _gamification.consecutivePerfectWaterDays = 0;
           _gamification.consecutivePerfectGoalDays = 0;
        }

        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr = yesterday.toIso8601String().substring(0, 10);
        
        if (lastActiveStr == yesterdayStr) {
          _gamification.currentStreak++;
        } else {
          _gamification.currentStreak = 1;
        }
        
        if (_gamification.currentStreak > _gamification.longestStreak) {
          _gamification.longestStreak = _gamification.currentStreak;
        }
        
        if (_gamification.consecutivePerfectWaterDays >= 7 && !_gamification.badges.contains('Hydration Hero')) {
          _gamification.badges.add('Hydration Hero');
        }
        if (_gamification.consecutivePerfectGoalDays >= 7 && !_gamification.badges.contains('Nutrition Master')) {
          _gamification.badges.add('Nutrition Master');
        }
        if (_gamification.currentStreak >= 7 && !_gamification.badges.contains('Consistency King')) {
          _gamification.badges.add('Consistency King');
        }
        
        for (var meal in _mealPlan) {
          meal.isConsumed = false;
        }
        PersistenceService.saveMeals(_mealPlan);
      }
    } else {
      _gamification.currentStreak = 1;
    }
    
    _gamification.lastActiveDate = now;
    PersistenceService.saveGamification(_gamification);
    _saveCurrentDailySummary();
  }

  void _saveCurrentDailySummary() {
    final nowStr = DateTime.now().toIso8601String().substring(0, 10);
    PersistenceService.saveDailySummary(nowStr, totalConsumedCalories, _waterIntake);
  }

  void addWater(int ml) {
    _waterIntake += ml;
    PersistenceService.saveWaterIntake(_waterIntake);
    _saveCurrentDailySummary();
    _rescheduleNotifications();
    notifyListeners();
  }

  void resetWater() {
    _waterIntake = 0;
    PersistenceService.saveWaterIntake(_waterIntake);
    _saveCurrentDailySummary();
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

  void startFasting() {
    _fastingStartTime = DateTime.now();
    PersistenceService.saveFastingStartTime(_fastingStartTime);
    _rescheduleFastingNotifications();
    notifyListeners();
  }

  void endFasting() {
    _fastingStartTime = null;
    PersistenceService.saveFastingStartTime(null);
    NotificationService.cancelFastingNotifications();
    notifyListeners();
  }

  void setFastingSettings({int? durationHours, int? reminderOffsetMinutes}) {
    if (durationHours != null) {
      _fastingDurationHours = durationHours;
      PersistenceService.saveFastingDuration(durationHours);
    }
    if (reminderOffsetMinutes != null) {
      _fastingReminderOffset = reminderOffsetMinutes;
      PersistenceService.saveFastingReminderOffset(reminderOffsetMinutes);
    }
    if (isFasting) {
      _rescheduleFastingNotifications();
    }
    notifyListeners();
  }

  void _rescheduleFastingNotifications() {
    if (_fastingStartTime != null) {
      NotificationService.scheduleFastingEndNotification(
        _fastingStartTime!,
        _fastingDurationHours,
        _fastingReminderOffset,
      );
    }
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
      _saveCurrentDailySummary();
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
    _fastingStartTime = null;
    PersistenceService.clearAll();
    notifyListeners();
  }
}
