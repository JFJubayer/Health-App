import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../services/health_service.dart';
import '../services/diet_service.dart';
import '../services/persistence_service.dart';
import '../services/notification_service.dart';
import '../models/gamification_model.dart';
import '../models/day_plan_entity.dart';
import '../models/meal_template_entity.dart';

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

  DayPlanEntity? _currentDayPlan;
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

  void _buildMealPlanFromDayPlan() {
    if (_currentDayPlan == null) return;
    
    _mealPlan.clear();
    final allTemplates = PersistenceService.getAllTemplates();
    final Map<String, MealTemplateEntity> templateMap = {
      for (var t in allTemplates) t.id: t
    };

    void addMeal(String? id) {
      if (id != null && templateMap.containsKey(id)) {
        final meal = DietService.resolveMealModel(templateMap[id]!);
        meal.isConsumed = _currentDayPlan!.consumedSlots[id] ?? false;
        _mealPlan.add(meal);
      }
    }

    addMeal(_currentDayPlan!.breakfastId);
    addMeal(_currentDayPlan!.lunchId);
    addMeal(_currentDayPlan!.dinnerId);
    
    notifyListeners();
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
        await DietService.seedDataIfNeeded();
        final nowStr = DateTime.now().toIso8601String().substring(0, 10);
        _currentDayPlan = PersistenceService.getDayPlan(nowStr);
        if (_currentDayPlan == null) {
           _currentDayPlan = await DietService.generateDayPlan(_tdee, _user!.conditions);
        }
        _buildMealPlanFromDayPlan();
        
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
        
        if (_currentDayPlan != null) {
          _currentDayPlan!.consumedSlots.clear();
          await PersistenceService.saveDayPlan(_currentDayPlan!);
          _buildMealPlanFromDayPlan();
        }
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
    
    _generateAndSetNewPlan();
    
    // Set default water goal
    _waterGoal = (user.weightKg * 35).toInt();
    _waterIntake = 0; // Reset for new user profile
    _checkedIngredients.clear();
    
    PersistenceService.saveUser(_user!);
    PersistenceService.saveWaterGoal(_waterGoal);
    PersistenceService.saveWaterIntake(_waterIntake);
    PersistenceService.saveCheckedIngredients(_checkedIngredients);
    
    _rescheduleNotifications();
    notifyListeners();
  }
  
  Future<void> _generateAndSetNewPlan() async {
    _currentDayPlan = await DietService.generateDayPlan(_tdee, _user!.conditions);
    _buildMealPlanFromDayPlan();
  }
  
  void regenerateMeals() async {
    await _generateAndSetNewPlan();
  }

  void replaceMeal(String mealId) async {
    if (_currentDayPlan == null) return;
    
    final currentMeal = _mealPlan.firstWhere((m) => m.id == mealId, orElse: () => _mealPlan.first);
    final altTemplate = await DietService.getAlternativeMeal(currentMeal.type, _tdee * 0.35, _user?.conditions ?? [], mealId);
    
    if (currentMeal.type == MealType.breakfast) {
      _currentDayPlan!.breakfastId = altTemplate.id;
    } else if (currentMeal.type == MealType.lunch) {
      _currentDayPlan!.lunchId = altTemplate.id;
    } else if (currentMeal.type == MealType.dinner) {
      _currentDayPlan!.dinnerId = altTemplate.id;
    }
    
    await PersistenceService.saveDayPlan(_currentDayPlan!);
    _buildMealPlanFromDayPlan();
  }

  void toggleMealConsumed(String mealId) {
    if (_currentDayPlan != null) {
      bool isConsumed = _currentDayPlan!.consumedSlots[mealId] ?? false;
      _currentDayPlan!.consumedSlots[mealId] = !isConsumed;
      PersistenceService.saveDayPlan(_currentDayPlan!);
      
      _buildMealPlanFromDayPlan();
      _saveCurrentDailySummary();
    }
  }
  
  void addCustomMeal(MealModel meal) {
    _mealPlan.add(meal);
    // Ideally this would save as a MealTemplate and be added to snackIds in _currentDayPlan
    notifyListeners();
  }

  void deleteMeal(String mealId) {
    _mealPlan.removeWhere((m) => m.id == mealId);
    // Ideally this would remove the id from the corresponding slot in _currentDayPlan
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
