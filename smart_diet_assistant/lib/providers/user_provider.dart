import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../services/health_service.dart';
import '../services/diet_service.dart';
import '../services/persistence_service.dart';
import '../services/notification_service.dart';
import '../services/meal_feedback_service.dart';
import '../services/meal_selector_service.dart';
import '../models/gamification_model.dart';
import '../hive/entities/day_plan_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import '../services/weekly_plan_service.dart';
import '../models/shopping_item.dart';
import '../models/macro_targets.dart';
import '../models/sugar_reading.dart';
import '../bd_food_db/models/food_models.dart';
import '../bd_food_db/services/meal_plan_optimizer.dart';
import '../hive/entities/ingredient_portion_entity.dart';
import '../bd_food_db/data/food_database.dart' as bd_db;
import '../bd_food_db/data/ingredient_prices.dart' as bd_prices;

class UserProvider with ChangeNotifier {
  UserModel? _user;
  double _bmr = 0.0;
  double _tdee = 0.0;
  double _calorieTarget = 0.0;
  String _calorieTier = '';
  List<MealModel> _mealPlan = [];
  bool _isLoading = true;
  int _waterIntake = 0;
  int _waterGoal = 2500; // Default
  Set<String> _checkedIngredients = {};
  List<ShoppingItem> _customShoppingItems = [];
  
  int _fastingDurationHours = 16;
  DateTime? _fastingStartTime;
  int _fastingReminderOffset = 0;

  DayPlanEntity? _currentDayPlan;
  GamificationModel _gamification = GamificationModel();
  List<MealModel> _customMealsCache = [];
  bool _hydrationRemindersEnabled = true;
  final MealFeedbackService _mealFeedback = MealFeedbackService();
  Map<String, SugarReading> _sugarReadings = {};
  int _burnedCalories = 0;
  List<Map<String, dynamic>> _workoutLogs = [];
  int _workoutDailyTarget = 300;

  String? _activeWorkoutName;
  String? _activeWorkoutIcon;
  double? _activeWorkoutCaloriesPerMinute;
  DateTime? _activeWorkoutStartTime;
  int? _activeWorkoutDurationMinutes;
  bool _isActiveWorkoutRunning = false;
  bool _isActiveWorkoutComplete = false;
  int _activeWorkoutElapsedSeconds = 0;
  Timer? _activeWorkoutTimer;

  Map<String, IngredientPrice> _bdIngredientPrices = {};
  List<FoodItem> _bdFoodItems = [];

  Map<String, IngredientPrice> get bdIngredientPrices => _bdIngredientPrices;
  List<FoodItem> get bdFoodItems => _bdFoodItems;

  UserModel? get user => _user;
  double get bmr => _bmr;
  double get tdee => _tdee;
  double get calorieTarget => _calorieTarget;
  String get calorieTier => _calorieTier;
  List<MealModel> get mealPlan => _mealPlan;
  bool get isLoading => _isLoading;
  int get waterIntake => _waterIntake;
  int get waterGoal => _waterGoal;
  Set<String> get checkedIngredients => _checkedIngredients;

  bool get isWeightManagementActive =>
      _user != null &&
      _user!.weightManagementEnabled &&
      HealthService.isHighBmi(_user!.weightKg, _user!.heightCm);

  double get proteinTarget {
    final ratio = isWeightManagementActive ? 0.35 : 0.30;
    return (_calorieTarget * ratio) / 4;
  }

  double get carbsTarget {
    final ratio = isWeightManagementActive ? 0.35 : 0.40;
    return (_calorieTarget * ratio) / 4;
  }

  double get fatTarget {
    final ratio = isWeightManagementActive ? 0.30 : 0.30;
    return (_calorieTarget * ratio) / 9;
  }

  int get fastingDurationHours => _fastingDurationHours;
  DateTime? get fastingStartTime => _fastingStartTime;
  int get fastingReminderOffset => _fastingReminderOffset;
  bool get isFasting => _fastingStartTime != null;
  GamificationModel get gamification => _gamification;
  bool get hydrationRemindersEnabled => _hydrationRemindersEnabled;
  List<ShoppingItem> get customShoppingItems => _customShoppingItems;
  Map<String, SugarReading> get sugarReadings => _sugarReadings;
  int get burnedCalories => _burnedCalories;
  List<Map<String, dynamic>> get workoutLogs => _workoutLogs;
  int get workoutDailyTarget => _workoutDailyTarget;
  int get netCalories => totalConsumedCalories - _burnedCalories;

  String? get activeWorkoutName => _activeWorkoutName;
  String? get activeWorkoutIcon => _activeWorkoutIcon;
  double? get activeWorkoutCaloriesPerMinute => _activeWorkoutCaloriesPerMinute;
  DateTime? get activeWorkoutStartTime => _activeWorkoutStartTime;
  int? get activeWorkoutDurationMinutes => _activeWorkoutDurationMinutes;
  bool get isActiveWorkoutRunning => _isActiveWorkoutRunning;
  bool get isActiveWorkoutComplete => _isActiveWorkoutComplete;
  int get activeWorkoutElapsedSeconds => _activeWorkoutElapsedSeconds;

  SugarReading? getSugarReading(String mealId, String dateStr) {
    return _sugarReadings['${mealId}_$dateStr'];
  }

  SugarReading? getSugarReadingForToday(String mealId) {
    return getSugarReading(mealId, _todayDateStr);
  }

  Future<void> recordSugarReading(
    String mealId, {
    double? preMeal,
    double? postMeal,
    bool clearPre = false,
    bool clearPost = false,
  }) async {
    final key = '${mealId}_$_todayDateStr';
    final existing = _sugarReadings[key] ?? SugarReading();
    _sugarReadings[key] = SugarReading(
      preMeal: clearPre ? null : (preMeal ?? existing.preMeal),
      postMeal: clearPost ? null : (postMeal ?? existing.postMeal),
    );
    await PersistenceService.saveSugarReadings(_sugarReadings);
    notifyListeners();
  }

  String get _todayDateStr =>
      DateTime.now().toIso8601String().substring(0, 10);

  bool isMainPlanMeal(String mealId) {
    if (_currentDayPlan == null) return false;
    return mealId == _currentDayPlan!.breakfastId ||
        mealId == _currentDayPlan!.lunchId ||
        mealId == _currentDayPlan!.dinnerId;
  }

  List<String> get shoppingList {
    final ingredients = <String>{};
    for (var meal in _mealPlan) {
      ingredients.addAll(meal.ingredients);
    }
    return ingredients.toList();
  }

  Future<List<String>> getWeeklyShoppingList() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekPlans = await getWeeklyPlans(weekStart);
    final ingredients = <String>{};
    
    for (var plan in weekPlans) {
      void addIng(String? id) {
        if (id != null) {
          final meal = resolveMealById(id);
          if (meal != null) {
            ingredients.addAll(meal.ingredients);
          }
        }
      }
      addIng(plan.breakfastId);
      addIng(plan.lunchId);
      addIng(plan.dinnerId);
      for (var snackId in plan.snackIds) {
        addIng(snackId);
      }
    }
    return ingredients.toList();
  }

  int get totalConsumedCalories => _mealPlan.where((m) => m.isConsumed).fold(0, (sum, m) => sum + m.calories);
  double get totalConsumedProtein => _mealPlan.where((m) => m.isConsumed).fold(0.0, (sum, m) => sum + m.protein);
  double get totalConsumedCarbs => _mealPlan.where((m) => m.isConsumed).fold(0.0, (sum, m) => sum + m.carbs);
  double get totalConsumedFat => _mealPlan.where((m) => m.isConsumed).fold(0.0, (sum, m) => sum + m.fat);

  void burnCalories(int calories) {
    _burnedCalories += calories;
    PersistenceService.saveBurnedCalories(_burnedCalories);
    _saveCurrentDailySummary();
    notifyListeners();
  }

  void resetBurnedCalories() {
    _burnedCalories = 0;
    _workoutLogs = [];
    PersistenceService.saveBurnedCalories(_burnedCalories);
    PersistenceService.saveWorkoutLogs(_todayDateStr, _workoutLogs);
    _saveCurrentDailySummary();
    notifyListeners();
  }

  Future<void> logWorkout({
    required String name,
    required int durationMinutes,
    required int caloriesBurned,
    String? icon,
  }) async {
    _workoutLogs.add({
      'name': name,
      'duration': durationMinutes,
      'calories': caloriesBurned,
      'icon': icon ?? '🏋️',
      'time': DateTime.now().toIso8601String(),
    });
    _burnedCalories += caloriesBurned;
    await PersistenceService.saveBurnedCalories(_burnedCalories);
    await PersistenceService.saveWorkoutLogs(_todayDateStr, _workoutLogs);
    _saveCurrentDailySummary();
    notifyListeners();
  }

  void _startLocalTimer() {
    _activeWorkoutTimer?.cancel();
    _activeWorkoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeWorkoutStartTime == null || _activeWorkoutDurationMinutes == null) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(_activeWorkoutStartTime!).inSeconds;
      final total = _activeWorkoutDurationMinutes! * 60;
      if (elapsed >= total) {
        timer.cancel();
        _isActiveWorkoutRunning = false;
        _isActiveWorkoutComplete = true;
        _activeWorkoutElapsedSeconds = total;
      } else {
        _isActiveWorkoutRunning = true;
        _isActiveWorkoutComplete = false;
        _activeWorkoutElapsedSeconds = elapsed;
      }
      notifyListeners();
    });
  }

  Future<void> startWorkout(String name, String icon, double caloriesPerMinute, int durationMinutes) async {
    _activeWorkoutName = name;
    _activeWorkoutIcon = icon;
    _activeWorkoutCaloriesPerMinute = caloriesPerMinute;
    _activeWorkoutStartTime = DateTime.now();
    _activeWorkoutDurationMinutes = durationMinutes;
    _isActiveWorkoutRunning = true;
    _isActiveWorkoutComplete = false;
    _activeWorkoutElapsedSeconds = 0;

    await PersistenceService.saveActiveWorkoutName(name);
    await PersistenceService.saveActiveWorkoutIcon(icon);
    await PersistenceService.saveActiveWorkoutCaloriesPerMinute(caloriesPerMinute);
    await PersistenceService.saveActiveWorkoutStartTime(_activeWorkoutStartTime);
    await PersistenceService.saveActiveWorkoutDurationMinutes(durationMinutes);

    // Schedule background notification
    await NotificationService.scheduleWorkoutEndNotification(name, _activeWorkoutStartTime!, durationMinutes);

    _startLocalTimer();
    notifyListeners();
  }

  Future<void> stopWorkoutEarly() async {
    if (_activeWorkoutStartTime != null) {
      final elapsed = DateTime.now().difference(_activeWorkoutStartTime!).inSeconds;
      final actualMinutes = (elapsed / 60).ceil();
      
      _activeWorkoutTimer?.cancel();
      _isActiveWorkoutRunning = false;
      _isActiveWorkoutComplete = true;
      _activeWorkoutElapsedSeconds = elapsed;

      // Persist the completed-early state by setting the duration to match the actual elapsed minutes
      _activeWorkoutDurationMinutes = actualMinutes;
      await PersistenceService.saveActiveWorkoutDurationMinutes(actualMinutes);
      
      // Update notification
      await NotificationService.cancelWorkoutNotifications();
      
      notifyListeners();
    }
  }

  Future<void> completeWorkout() async {
    if (_activeWorkoutStartTime != null) {
      final total = (_activeWorkoutDurationMinutes ?? 0) * 60;
      final elapsed = _isActiveWorkoutRunning 
          ? DateTime.now().difference(_activeWorkoutStartTime!).inSeconds
          : _activeWorkoutElapsedSeconds;
      final finalElapsed = elapsed.clamp(0, total);
      
      final actualMinutes = (finalElapsed / 60).ceil();
      final caloriesBurned = ((_activeWorkoutCaloriesPerMinute ?? 0) * (finalElapsed / 60)).toInt();

      await logWorkout(
        name: _activeWorkoutName ?? 'Workout',
        durationMinutes: actualMinutes,
        caloriesBurned: caloriesBurned,
        icon: _activeWorkoutIcon,
      );
    }
    await cancelActiveWorkout();
  }

  Future<void> cancelActiveWorkout() async {
    _activeWorkoutTimer?.cancel();
    _activeWorkoutName = null;
    _activeWorkoutIcon = null;
    _activeWorkoutCaloriesPerMinute = null;
    _activeWorkoutStartTime = null;
    _activeWorkoutDurationMinutes = null;
    _isActiveWorkoutRunning = false;
    _isActiveWorkoutComplete = false;
    _activeWorkoutElapsedSeconds = 0;

    await PersistenceService.clearActiveWorkout();
    await NotificationService.cancelWorkoutNotifications();
    notifyListeners();
  }

  @override
  void dispose() {
    _activeWorkoutTimer?.cancel();
    super.dispose();
  }

  void setWorkoutDailyTarget(int calories) {
    _workoutDailyTarget = calories;
    PersistenceService.saveWorkoutDailyTarget(calories);
    notifyListeners();
  }

  void addCustomShoppingItem(ShoppingItem item) {
    _customShoppingItems.add(item);
    PersistenceService.saveCustomShoppingItems(_customShoppingItems);
    notifyListeners();
  }

  void removeCustomShoppingItem(String id) {
    _customShoppingItems.removeWhere((i) => i.id == id);
    PersistenceService.saveCustomShoppingItems(_customShoppingItems);
    notifyListeners();
  }

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

    final customById = {for (var m in _customMealsCache) m.id: m};
    for (final snackId in _currentDayPlan!.snackIds) {
      final custom = customById[snackId];
      if (custom != null) {
        custom.isConsumed = _currentDayPlan!.consumedSlots[snackId] ?? false;
        _mealPlan.add(custom);
      }
    }

    notifyListeners();
  }

  Future<void> _loadCustomMealsCache() async {
    _customMealsCache =
        await PersistenceService.getCustomMealsForDate(_todayDateStr);
  }

  Future<void> _persistCustomMeals() async {
    await PersistenceService.saveCustomMealsForDate(
      _todayDateStr,
      _customMealsCache,
    );
  }

  List<String> _recentMealIdsFromDayPlan() {
    if (_currentDayPlan == null) return [];
    return [
      _currentDayPlan!.breakfastId,
      _currentDayPlan!.lunchId,
      _currentDayPlan!.dinnerId,
      ..._currentDayPlan!.snackIds,
    ].whereType<String>().toList();
  }

  double _targetCaloriesForMealType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return _tdee * 0.3;
      case MealType.lunch:
        return _tdee * 0.4;
      case MealType.dinner:
        return _tdee * 0.3;
      case MealType.snack:
        return _tdee * 0.15;
    }
  }

  Future<void> _initialLoad() async {
    try {
      debugPrint('UserProvider: Starting initial load...');
      _user = await PersistenceService.getUser();
      debugPrint('UserProvider: User data loaded: ${_user != null}');
      
      if (_user != null) {
        _bmr = HealthService.calculateBMR(_user!);
        _tdee = HealthService.calculateTDEE(_bmr);
        _calorieTarget = HealthService.calculateCalorieTarget(_user!);
        _calorieTier = DietService.getCalorieTier(_calorieTarget);
        
        debugPrint('UserProvider: Loading meals...');
        await DietService.seedDataIfNeeded();
        final nowStr = DateTime.now().toIso8601String().substring(0, 10);
        _currentDayPlan = PersistenceService.getDayPlan(nowStr);
        _currentDayPlan ??= await DietService.generateDayPlan(
          _calorieTarget,
          _user!.conditions,
        );
        await _loadCustomMealsCache();
        _buildMealPlanFromDayPlan();
        
        debugPrint('UserProvider: Loading water data...');
        _waterIntake = await PersistenceService.getWaterIntake();
        _waterGoal = await PersistenceService.getWaterGoal() ?? (_user!.weightKg * 35).toInt();
        
        debugPrint('UserProvider: Loading checked ingredients...');
        _checkedIngredients = await PersistenceService.getCheckedIngredients();
        _customShoppingItems = await PersistenceService.getCustomShoppingItems();

        _bdIngredientPrices = PersistenceService.getBdIngredientPricesMap();
        _bdFoodItems = PersistenceService.getAllBdFoodItems();
        
        debugPrint('UserProvider: Loading sugar readings...');
        _sugarReadings = await PersistenceService.getSugarReadings();

        debugPrint('UserProvider: Loading workout data...');
        _burnedCalories = await PersistenceService.getBurnedCalories();
        _workoutLogs = await PersistenceService.getWorkoutLogs(_todayDateStr);
        _workoutDailyTarget = await PersistenceService.getWorkoutDailyTarget();

        // Load active workout data
        _activeWorkoutName = await PersistenceService.getActiveWorkoutName();
        _activeWorkoutIcon = await PersistenceService.getActiveWorkoutIcon();
        _activeWorkoutCaloriesPerMinute = await PersistenceService.getActiveWorkoutCaloriesPerMinute();
        _activeWorkoutStartTime = await PersistenceService.getActiveWorkoutStartTime();
        _activeWorkoutDurationMinutes = await PersistenceService.getActiveWorkoutDurationMinutes();
        
        if (_activeWorkoutStartTime != null && _activeWorkoutDurationMinutes != null) {
          final elapsed = DateTime.now().difference(_activeWorkoutStartTime!).inSeconds;
          final total = _activeWorkoutDurationMinutes! * 60;
          if (elapsed >= total) {
            _isActiveWorkoutRunning = false;
            _isActiveWorkoutComplete = true;
            _activeWorkoutElapsedSeconds = total;
          } else {
            _isActiveWorkoutRunning = true;
            _isActiveWorkoutComplete = false;
            _activeWorkoutElapsedSeconds = elapsed;
            _startLocalTimer();
          }
        }

        debugPrint('UserProvider: Loading fasting data...');
        _fastingDurationHours = await PersistenceService.getFastingDuration();
        _fastingStartTime = await PersistenceService.getFastingStartTime();
        _fastingReminderOffset =
            await PersistenceService.getFastingReminderOffset();

        _hydrationRemindersEnabled =
            await PersistenceService.getHydrationRemindersEnabled();

        // Initialize notifications
        debugPrint('UserProvider: Initializing NotificationService...');
        try {
          await NotificationService.initialize(this);
          await NotificationService.requestPermissions();
          _rescheduleNotifications();
          debugPrint('UserProvider: NotificationService initialized.');
        } catch (e, stackTrace) {
          debugPrint('UserProvider: NotificationService init failed: $e');
          debugPrint(stackTrace.toString());
        }
        
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
    PersistenceService.saveDailySummary(nowStr, totalConsumedCalories, _waterIntake, burnedCalories: _burnedCalories);
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
    if (_user == null) return;
    
    // Hydration reminders
    if (!_hydrationRemindersEnabled) {
      NotificationService.cancelWaterReminders();
    } else {
      NotificationService.scheduleSmartWaterReminders(_waterIntake, _waterGoal);
    }

    // Weight management reminders
    if (isWeightManagementActive) {
      NotificationService.scheduleWeightManagementReminder(_calorieTarget);
    } else {
      NotificationService.cancelWeightManagementReminder();
    }
  }

  void setWaterGoal(int ml) {
    _waterGoal = ml;
    PersistenceService.saveWaterGoal(_waterGoal);
    _rescheduleNotifications();
    notifyListeners();
  }

  void setHydrationRemindersEnabled(bool enabled) {
    _hydrationRemindersEnabled = enabled;
    PersistenceService.saveHydrationRemindersEnabled(enabled);
    _rescheduleNotifications();
    notifyListeners();
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

  void setUserData(UserModel user) async {
    _user = user;
    _bmr = HealthService.calculateBMR(user);
    _tdee = HealthService.calculateTDEE(_bmr);
    _calorieTarget = HealthService.calculateCalorieTarget(user);
    _calorieTier = DietService.getCalorieTier(_calorieTarget);

    await _generateAndSetNewPlan();
    
    // Set default water goal
    _waterGoal = (user.weightKg * 35).toInt();
    _waterIntake = 0; // Reset for new user profile
    _checkedIngredients.clear();
    
    PersistenceService.saveUser(_user!);
    PersistenceService.saveWaterGoal(_waterGoal);
    PersistenceService.saveWaterIntake(_waterIntake);
    PersistenceService.saveCheckedIngredients(_checkedIngredients);

    try {
      await NotificationService.initialize(this);
      await NotificationService.requestPermissions();
    } catch (e, stackTrace) {
      debugPrint('UserProvider: Notification init on setUserData failed: $e');
      debugPrint(stackTrace.toString());
    }

    _rescheduleNotifications();
    notifyListeners();
  }

  Future<void> _generateAndSetNewPlan({List<String>? recentMealIds}) async {
    _currentDayPlan = await DietService.generateDayPlan(
      _calorieTarget,
      _user!.conditions,
      recentMealIds: recentMealIds ?? _recentMealIdsFromDayPlan(),
    );
    _buildMealPlanFromDayPlan();
  }

  void regenerateMeals() async {
    if (_currentDayPlan != null) {
      bool needsSave = false;
      final templates = PersistenceService.getAllTemplates();
      final ingredientsMap = { for (var i in PersistenceService.getAllIngredients()) i.id: i };
      final selector = MealSelectorService(allMeals: templates, ingredients: ingredientsMap);
      final macros = isWeightManagementActive
          ? MacroTargets.weightManagement(_calorieTarget)
          : MacroTargets.balanced(_calorieTarget);

      if (!_currentDayPlan!.breakfastLocked) {
         final options = selector.selectMeals(targetCalories: _calorieTarget*0.3, macros: macros, conditions: _user?.conditions ?? [], type: MealType.breakfast);
         if (options.isNotEmpty) {
           _currentDayPlan!.breakfastId = options.first.id;
           needsSave = true;
         }
      }
      if (!_currentDayPlan!.lunchLocked) {
         final options = selector.selectMeals(targetCalories: _calorieTarget*0.4, macros: macros, conditions: _user?.conditions ?? [], type: MealType.lunch);
         if (options.isNotEmpty) {
           _currentDayPlan!.lunchId = options.first.id;
           needsSave = true;
         }
      }
      if (!_currentDayPlan!.dinnerLocked) {
         final options = selector.selectMeals(targetCalories: _calorieTarget*0.3, macros: macros, conditions: _user?.conditions ?? [], type: MealType.dinner);
         if (options.isNotEmpty) {
           _currentDayPlan!.dinnerId = options.first.id;
           needsSave = true;
         }
      }
      
      if (needsSave) {
        await PersistenceService.saveDayPlan(_currentDayPlan!);
        _buildMealPlanFromDayPlan();
      }
    } else {
      await _generateAndSetNewPlan();
    }
  }

  Future<List<MealModel>> getMealAlternativesFor(String mealId, {MealType? mealType}) async {
    final currentMeal = resolveMealById(mealId);
    final targetType = currentMeal?.type ?? mealType ?? MealType.lunch;

    final templates = await DietService.getMealAlternatives(
      targetType,
      _targetCaloriesForMealType(targetType),
      _user?.conditions ?? [],
      mealId,
    );
    return templates.map(DietService.resolveMealModel).toList();
  }

  Future<void> replaceMeal(String mealId, {String? selectedTemplateId}) async {
    if (_currentDayPlan == null) return;
    if (!isMainPlanMeal(mealId)) return;

    final currentMeal = resolveMealById(mealId);
    if (currentMeal == null) return;


    MealTemplateEntity altTemplate;
    if (selectedTemplateId != null) {
      final templates = PersistenceService.getAllTemplates();
      altTemplate = templates.firstWhere(
        (t) => t.id == selectedTemplateId,
        orElse: () => templates.firstWhere((t) => t.type == currentMeal.type),
      );
    } else {
      altTemplate = await DietService.getAlternativeMeal(
        currentMeal.type,
        _targetCaloriesForMealType(currentMeal.type),
        _user?.conditions ?? [],
        mealId,
      );
    }

    await _mealFeedback.recordMealSwap(
      oldMealId: mealId,
      newMealId: altTemplate.id,
    );

    if (currentMeal.type == MealType.breakfast) {
      _currentDayPlan!.breakfastId = altTemplate.id;
    } else if (currentMeal.type == MealType.lunch) {
      _currentDayPlan!.lunchId = altTemplate.id;
    } else if (currentMeal.type == MealType.dinner) {
      _currentDayPlan!.dinnerId = altTemplate.id;
    }

    _currentDayPlan!.consumedSlots.remove(mealId);
    _currentDayPlan!.consumedSlots[altTemplate.id] = false;

    await PersistenceService.saveDayPlan(_currentDayPlan!);
    _buildMealPlanFromDayPlan();
  }

  Future<void> avoidMeal(String mealId) async {
    await _mealFeedback.addToAvoidedMeals(mealId);
    if (isMainPlanMeal(mealId)) {
      await replaceMeal(mealId);
    } else {
      deleteMeal(mealId);
    }
  }

  Future<void> addMealTags(List<String> tags) async {
    await _mealFeedback.addPreferredTags(tags);
  }

  void toggleMealConsumed(String mealId) {
    if (_currentDayPlan == null) return;

    final isConsumed = _currentDayPlan!.consumedSlots[mealId] ?? false;
    _currentDayPlan!.consumedSlots[mealId] = !isConsumed;
    PersistenceService.saveDayPlan(_currentDayPlan!);

    _buildMealPlanFromDayPlan();
    _saveCurrentDailySummary();
    notifyListeners();
  }

  Future<void> toggleMealConsumedWithFeedback(
    String mealId, {
    required double satisfaction,
  }) async {
    if (_currentDayPlan == null) return;

    final wasConsumed = _currentDayPlan!.consumedSlots[mealId] ?? false;
    if (!wasConsumed) {
      _currentDayPlan!.consumedSlots[mealId] = true;
      await PersistenceService.saveDayPlan(_currentDayPlan!);
      await _mealFeedback.recordMealConsumed(
        mealId: mealId,
        satisfaction: satisfaction,
      );
      _buildMealPlanFromDayPlan();
      _saveCurrentDailySummary();
      notifyListeners();
    } else {
      toggleMealConsumed(mealId);
    }
  }

  Future<void> skipMeal(String mealId) async {
    if (_currentDayPlan == null) return;

    await _mealFeedback.recordMealSkipped(mealId: mealId);
    _currentDayPlan!.consumedSlots[mealId] = false;
    await PersistenceService.saveDayPlan(_currentDayPlan!);
    _buildMealPlanFromDayPlan();
    _saveCurrentDailySummary();
    notifyListeners();
  }

  void updateUserProfile(UserModel user) async {
    final previousConditions = List<String>.from(_user?.conditions ?? []);
    final previousWeightManagementEnabled = _user?.weightManagementEnabled ?? true;
    final previousWeightDeficitCal = _user?.weightDeficitCal ?? 500.0;

    _user = user;
    _bmr = HealthService.calculateBMR(user);
    _tdee = HealthService.calculateTDEE(_bmr);
    _calorieTarget = HealthService.calculateCalorieTarget(user);
    _calorieTier = DietService.getCalorieTier(_calorieTarget);
    _waterGoal = (user.weightKg * 35).toInt();

    await PersistenceService.saveUser(_user!);
    await PersistenceService.saveWaterGoal(_waterGoal);

    if (!_listsEqualSorted(previousConditions, user.conditions) ||
        previousWeightManagementEnabled != user.weightManagementEnabled ||
        previousWeightDeficitCal != user.weightDeficitCal) {
      await _generateAndSetNewPlan();
    } else {
      _buildMealPlanFromDayPlan();
    }

    _rescheduleNotifications();
    notifyListeners();
  }

  bool _listsEqualSorted(List<String> a, List<String> b) {
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    if (sortedA.length != sortedB.length) return false;
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  void addCustomMeal(MealModel meal) async {
    if (_currentDayPlan == null) return;

    _customMealsCache.removeWhere((m) => m.id == meal.id);
    _customMealsCache.add(meal);
    if (!_currentDayPlan!.snackIds.contains(meal.id)) {
      _currentDayPlan!.snackIds.add(meal.id);
    }

    await PersistenceService.saveDayPlan(_currentDayPlan!);
    await _persistCustomMeals();
    _buildMealPlanFromDayPlan();
  }

  void deleteMeal(String mealId) async {
    if (_currentDayPlan == null) return;

    if (_currentDayPlan!.snackIds.contains(mealId)) {
      _currentDayPlan!.snackIds.remove(mealId);
      _customMealsCache.removeWhere((m) => m.id == mealId);
    } else if (_currentDayPlan!.breakfastId == mealId) {
      _currentDayPlan!.breakfastId = null;
    } else if (_currentDayPlan!.lunchId == mealId) {
      _currentDayPlan!.lunchId = null;
    } else if (_currentDayPlan!.dinnerId == mealId) {
      _currentDayPlan!.dinnerId = null;
    }

    _currentDayPlan!.consumedSlots.remove(mealId);

    await PersistenceService.saveDayPlan(_currentDayPlan!);
    await _persistCustomMeals();
    _buildMealPlanFromDayPlan();
  }

  Future<List<DayPlanEntity>> getWeeklyPlans(DateTime weekStart) async {
    if (_user == null) return [];
    return await WeeklyPlanService.generateWeek(weekStart, _user!, _tdee);
  }

  Future<List<Map<String, dynamic>>> getCalorieHistory(int days) async {
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      
      final summary = await PersistenceService.getDailySummary(dateStr);
      result.add({
        'date': date,
        'calories': summary != null ? (summary['calories'] as int) : 0,
        'water': summary != null ? (summary['water'] as int) : 0,
        'burnedCalories': summary != null ? (summary['burnedCalories'] as int? ?? 0) : 0,
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutHistory(int days) async {
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final logs = await PersistenceService.getWorkoutLogs(dateStr);
      final totalBurned = logs.fold<int>(0, (sum, l) => sum + ((l['calories'] as num?)?.toInt() ?? 0));
      result.add({
        'date': date,
        'logs': logs,
        'totalBurned': totalBurned,
      });
    }
    return result;
  }

  Future<void> regenerateUnlockedSlots(DateTime weekStart) async {
    final existingPlans = PersistenceService.getAllDayPlansInRange(
      weekStart,
      weekStart.add(const Duration(days: 6)),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var plan in existingPlans) {
      if (plan.date.isBefore(today)) continue;
      
      bool changed = false;
      if (!plan.breakfastLocked) { plan.breakfastId = null; changed = true; }
      if (!plan.lunchLocked) { plan.lunchId = null; changed = true; }
      if (!plan.dinnerLocked) { plan.dinnerId = null; changed = true; }
      
      if (changed) {
        await PersistenceService.saveDayPlan(plan);
      }
    }

    // Generate week will automatically fill in the null slots we just created
    await getWeeklyPlans(weekStart);
    
    // Update today's plan if it was in the regenerated week
    final nowStr = now.toIso8601String().substring(0, 10);
    _currentDayPlan = PersistenceService.getDayPlan(nowStr);
    _buildMealPlanFromDayPlan();
  }

  Future<void> updateDayPlan(DayPlanEntity plan) async {
    await PersistenceService.saveDayPlan(plan);
    if (plan.date.toIso8601String().substring(0, 10) == _todayDateStr) {
      _currentDayPlan = plan;
      _buildMealPlanFromDayPlan();
    }
  }

  MealModel? resolveMealById(String id) {
    // check custom cache first
    try {
      return _customMealsCache.firstWhere((m) => m.id == id);
    } catch (_) {}

    // check all templates
    final templates = PersistenceService.getAllTemplates();
    try {
      final template = templates.firstWhere((t) => t.id == id);
      return DietService.resolveMealModel(template);
    } catch (_) {
      return null;
    }
  }
  
  Future<void> updateIngredientPrice(String id, double newPricePerKg) async {
    final price = _bdIngredientPrices[id];
    if (price != null) {
      final updated = price.copyWithPrice(newPricePerKg);
      _bdIngredientPrices[id] = updated;
      await PersistenceService.saveBdIngredientPrice(updated);
      _buildMealPlanFromDayPlan(); // Rebuild today's meal plan costs dynamically
      notifyListeners();
    }
  }

  Future<List<String>> generateWeeklyBudgetPlan({
    required double weeklyBudget,
    required double dailyCalorieTarget,
    required bool vegetarianOnly,
    required DateTime weekStart,
  }) async {
    // 1. Initialize MealPlanOptimizer
    final optimizer = MealPlanOptimizer(
      foodDb: _bdFoodItems.isNotEmpty ? _bdFoodItems : bd_db.foodDatabase,
      priceDb: _bdIngredientPrices.isNotEmpty ? _bdIngredientPrices : bd_prices.ingredientPriceDb,
    );

    // 2. Generate plan
    final plan = optimizer.generate(
      weeklyBudgetBDT: weeklyBudget,
      dailyCalorieTarget: dailyCalorieTarget,
      vegetarianOnly: vegetarianOnly,
    );

    // 3. Save generated plan to day plans
    for (final dailyPlan in plan.days) {
      final date = weekStart.add(Duration(days: dailyPlan.dayIndex));
      final dateStr = date.toIso8601String().substring(0, 10);

      // Resolve breakfast id
      String? breakfastId;
      if (dailyPlan.items[MealSlot.breakfast] != null &&
          dailyPlan.items[MealSlot.breakfast]!.isNotEmpty) {
        breakfastId = dailyPlan.items[MealSlot.breakfast]!.first.id;
      }

      // Resolve lunch id (create composite template if multiple items)
      String? lunchId;
      final lunchItems = dailyPlan.items[MealSlot.lunch] ?? [];
      if (lunchItems.length == 1) {
        lunchId = lunchItems.first.id;
      } else if (lunchItems.length > 1) {
        final compositeId = 'composite_lunch_$dateStr';
        final template = MealTemplateEntity(
          id: compositeId,
          name: lunchItems.map((f) => f.nameEn).join(' + '),
          type: MealType.lunch,
          ingredients: lunchItems.expand((f) => f.ingredients).map((iq) => IngredientPortion(
            ingredientId: iq.ingredientId,
            grams: iq.grams,
          )).toList(),
          tags: ['composite', ...lunchItems.map((f) => f.id)],
          prepTimeMinutes: 15,
        );
        await PersistenceService.saveMealTemplate(template);
        lunchId = compositeId;
      }

      // Resolve dinner id (create composite template if multiple items)
      String? dinnerId;
      final dinnerItems = dailyPlan.items[MealSlot.dinner] ?? [];
      if (dinnerItems.length == 1) {
        dinnerId = dinnerItems.first.id;
      } else if (dinnerItems.length > 1) {
        final compositeId = 'composite_dinner_$dateStr';
        final template = MealTemplateEntity(
          id: compositeId,
          name: dinnerItems.map((f) => f.nameEn).join(' + '),
          type: MealType.dinner,
          ingredients: dinnerItems.expand((f) => f.ingredients).map((iq) => IngredientPortion(
            ingredientId: iq.ingredientId,
            grams: iq.grams,
          )).toList(),
          tags: ['composite', ...dinnerItems.map((f) => f.id)],
          prepTimeMinutes: 15,
        );
        await PersistenceService.saveMealTemplate(template);
        dinnerId = compositeId;
      }

      // Resolve snack ids
      final snackIds = <String>[];
      final snackItems = dailyPlan.items[MealSlot.snackTime] ?? [];
      for (final snack in snackItems) {
        snackIds.add(snack.id);
      }

      // Create or update DayPlanEntity
      final dayPlan = DayPlanEntity(
        id: dateStr,
        date: date,
        breakfastId: breakfastId,
        lunchId: lunchId,
        dinnerId: dinnerId,
        snackIds: snackIds,
        isLocked: true, // Lock generated plan so it doesn't get auto-regenerated by standard selector
      );
      await PersistenceService.saveDayPlan(dayPlan);
    }

    // Refresh current day plan if today is within generated week
    final nowStr = DateTime.now().toIso8601String().substring(0, 10);
    _currentDayPlan = PersistenceService.getDayPlan(nowStr);
    _buildMealPlanFromDayPlan();

    return plan.notes;
  }

  void clearUser() {
    _user = null;
    _bmr = 0.0;
    _tdee = 0.0;
    _calorieTier = '';
    _mealPlan = [];
    _fastingStartTime = null;
    _burnedCalories = 0;
    _workoutLogs = [];
    PersistenceService.clearAll();
    notifyListeners();
  }
}
