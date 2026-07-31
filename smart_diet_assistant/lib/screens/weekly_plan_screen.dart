import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';
import '../hive/entities/day_plan_entity.dart';
import '../widgets/meal_picker_sheet.dart';
import 'meal_detail_screen.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late DateTime _currentWeekStart;
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  List<DayPlanEntity> _weekPlans = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex = now.weekday - 1;
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<UserProvider>(context, listen: false);
    _weekPlans = await provider.getWeeklyPlans(_currentWeekStart);
    setState(() => _isLoading = false);
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadWeek();
  }

  void _prevWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeek();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Weekly Plan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildWeekHeader(),
          _buildDaySelector(),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDayDetail(provider),
          ),
          _buildBottomActions(provider),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final endDate = _currentWeekStart.add(const Duration(days: 6));
    final format = DateFormat('MMM d');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevWeek,
          ),
          Text(
            '${format.format(_currentWeekStart)} - ${format.format(endDate)}',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          final date = _currentWeekStart.add(Duration(days: index));
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index],
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayDetail(UserProvider provider) {
    if (_weekPlans.isEmpty) return const Center(child: Text('No plan found.'));
    
    final dayPlan = _weekPlans[_selectedDayIndex];
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (dayPlan.breakfastId != null)
           _buildMealSlot(provider, 'Breakfast', dayPlan.breakfastId!, MealType.breakfast, dayPlan.breakfastLocked, dayPlan),
        if (dayPlan.lunchId != null)
           _buildMealSlot(provider, 'Lunch', dayPlan.lunchId!, MealType.lunch, dayPlan.lunchLocked, dayPlan),
        if (dayPlan.dinnerId != null)
           _buildMealSlot(provider, 'Dinner', dayPlan.dinnerId!, MealType.dinner, dayPlan.dinnerLocked, dayPlan),
      ],
    );
  }

  Widget _buildMealSlot(UserProvider provider, String title, String mealId, MealType type, bool isLocked, DayPlanEntity dayPlan) {
    final meal = provider.resolveMealById(mealId);
    if (meal == null) return const SizedBox.shrink();

    final color = _getMealColor(type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isLocked ? Icons.lock : Icons.lock_open, size: 20),
                      color: isLocked ? Theme.of(context).colorScheme.primary : Colors.grey,
                      onPressed: () => _toggleLock(dayPlan, type),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, size: 22),
                      color: color,
                      onPressed: isLocked ? null : () => _swapMeal(dayPlan, type, meal.id),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getMealIcon(type), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${meal.calories} kcal • ${meal.prepTimeMinutes} min',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  void _toggleLock(DayPlanEntity plan, MealType type) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    switch (type) {
      case MealType.breakfast: plan.breakfastLocked = !plan.breakfastLocked; break;
      case MealType.lunch: plan.lunchLocked = !plan.lunchLocked; break;
      case MealType.dinner: plan.dinnerLocked = !plan.dinnerLocked; break;
      default: break;
    }
    await provider.updateDayPlan(plan);
    setState(() {});
  }

  void _swapMeal(DayPlanEntity plan, MealType type, String currentMealId) async {
    showMealPickerSheet(
      context,
      currentMealId,
      mealType: type,
      popRouteOnSelect: false,
      onMealSelected: (newMealId) async {
         final provider = Provider.of<UserProvider>(context, listen: false);
         switch (type) {
           case MealType.breakfast: plan.breakfastId = newMealId; break;
           case MealType.lunch: plan.lunchId = newMealId; break;
           case MealType.dinner: plan.dinnerId = newMealId; break;
           default: break;
         }
         await provider.updateDayPlan(plan);
         _loadWeek();
      },
    );
  }

  Widget _buildBottomActions(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await provider.regenerateUnlockedSlots(_currentWeekStart);
                  await _loadWeek();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Regenerate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showBudgetPlanDialog(provider),
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                label: Text('Budget Planner', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetPlanDialog(UserProvider provider) {
    final budgetController = TextEditingController(text: '1800');
    final caloriesController = TextEditingController(text: provider.calorieTarget.toInt().toString());
    bool vegetarianOnly = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Budget Planner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate a 7-day cost-aware Bangladeshi meal plan optimized for value and nutrition per BDT.',
                      style: GoogleFonts.outfit(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weekly Budget (BDT)',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Daily Calorie Target (kcal)',
                        suffixText: ' kcal',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text('Vegetarian Only', style: GoogleFonts.outfit(fontSize: 15)),
                      value: vegetarianOnly,
                      onChanged: (val) => setState(() => vegetarianOnly = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final budget = double.tryParse(budgetController.text) ?? 1800.0;
                    final calories = double.tryParse(caloriesController.text) ?? provider.calorieTarget;
                    
                    Navigator.pop(context); // Close input dialog
                    
                    setState(() => _isLoading = true);
                    try {
                      final notes = await provider.generateWeeklyBudgetPlan(
                        weeklyBudget: budget,
                        dailyCalorieTarget: calories,
                        vegetarianOnly: vegetarianOnly,
                        weekStart: _currentWeekStart,
                      );
                      await _loadWeek();
                      if (!context.mounted) return;
                      _showOptimizerNotesDialog(notes);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Generation failed: $e')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Generate', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOptimizerNotesDialog(List<String> notes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text('Plan Optimization', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: notes.isEmpty ? 1 : notes.length,
              itemBuilder: (context, index) {
                if (notes.isEmpty) {
                  return Text(
                    'Plan successfully generated within budget and calories!',
                    style: GoogleFonts.outfit(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 20, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          notes[index],
                          style: GoogleFonts.outfit(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Done', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast: return Icons.wb_sunny_rounded;
      case MealType.lunch: return Icons.fastfood_rounded;
      case MealType.dinner: return Icons.nightlight_round;
      case MealType.snack: return Icons.apple_rounded;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.breakfast: return Colors.orange;
      case MealType.lunch: return Colors.green;
      case MealType.dinner: return Colors.indigo;
      case MealType.snack: return Colors.teal;
    }
  }
}
