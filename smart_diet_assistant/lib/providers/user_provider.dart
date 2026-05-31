import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../services/health_service.dart';
import '../services/diet_service.dart';
import '../services/persistence_service.dart';
import '../services/notification_service.dart';
import '../services/meal_feedback_service.dart';
import '../models/gamification_model.dart';
import '../hive/entities/day_plan_entity.dart';
import '../hive/entities/meal_template_entity.dart';
import '../services/weekly_plan_service.dart';

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
  List<MealModel> _customMealsCache = [];
  bool _hydrationRemindersEnabled = true;
  final MealFeedbackService _mealFeedback = MealFeedbackService();

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
  bool get hydrationRemindersEnabled => _hydrationRemindersEnabled;

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
        _calorieTier = DietService.getCalorieTier(_tdee);
        
        debugPrint('UserProvider: Loading meals...');
        await DietService.seedDataIfNeeded();
        final nowStr = DateTime.now().toIso8601String().substring(0, 10);
        _currentDayPlan = PersistenceService.getDayPlan(nowStr);
        _currentDayPlan ??= await DietService.generateDayPlan(
          _tdee,
          _user!.conditions,
        );
        await _loadCustomMealsCache();
        _buildMealPlanFromDayPlan();
        
        debugPrint('UserProvider: Loading water data...');
        _waterIntake = await PersistenceService.getWaterIntake();
        _waterGoal = await PersistenceService.getWaterGoal() ?? (_user!.weightKg * 35).toInt();
        
        debugPrint('UserProvider: Loading checked ingredients...');
        _checkedIngredients = await PersistenceService.getCheckedIngredients();
        
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
    if (_user == null) return;
    if (!_hydrationRemindersEnabled) {
      NotificationService.cancelWaterReminders();
      return;
    }
    NotificationService.scheduleSmartWaterReminders(_waterIntake, _waterGoal);
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
    _calorieTier = DietService.getCalorieTier(_tdee);

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
      _tdee,
      _user!.conditions,
      recentMealIds: recentMealIds ?? _recentMealIdsFromDayPlan(),
    );
    _buildMealPlanFromDayPlan();
  }

  void regenerateMeals() async {
    await _generateAndSetNewPlan();
  }

  Future<List<MealModel>> getMealAlternativesFor(String mealId) async {
    final currentMeal = resolveMealById(mealId);
    if (currentMeal == null) return [];

    final templates = await DietService.getMealAlternatives(
      currentMeal.type,
      _targetCaloriesForMealType(currentMeal.type),
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
    _user = user;
    _bmr = HealthService.calculateBMR(user);
    _tdee = HealthService.calculateTDEE(_bmr);
    _calorieTier = DietService.getCalorieTier(_tdee);
    _waterGoal = (user.weightKg * 35).toInt();

    await PersistenceService.saveUser(_user!);
    await PersistenceService.saveWaterGoal(_waterGoal);

    if (!_listsEqualSorted(previousConditions, user.conditions)) {
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

  Future<void> regenerateUnlockedSlots(DateTime weekStart) async {
    // Generate week will automatically fill in null (unlocked) slots
    await getWeeklyPlans(weekStart);
    // Also regenerate today's plan if today is in the week
    await _initialLoad(); 
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
