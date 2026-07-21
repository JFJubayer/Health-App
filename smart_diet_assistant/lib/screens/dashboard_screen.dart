import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';

import 'weekly_plan_screen.dart';
import 'meal_detail_screen.dart';
import '../widgets/segmented_calorie_arc.dart';
import '../widgets/water_tracker_widget.dart';
import '../services/export_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalTarget = userProvider.calorieTarget > 0 ? userProvider.calorieTarget : 2000.0;
    final consumed = userProvider.totalConsumedCalories.toDouble();
    final loggedMeals = userProvider.mealPlan; // Using actual logged meals

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Dashboard',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyPlanScreen())),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF79E74),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: 'Export PDF Report',
              icon: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.onSurface),
              onPressed: () {
                if (userProvider.user != null) {
                  ExportService.exportToPdf(userProvider.user!, userProvider.mealPlan);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110), // Leave space for floating bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedCalorieArc(
              consumed: consumed,
              target: totalTarget,
              burned: userProvider.burnedCalories.toDouble(),
              proteinConsumed: userProvider.totalConsumedProtein,
              proteinTarget: userProvider.proteinTarget,
              carbsConsumed: userProvider.totalConsumedCarbs,
              carbsTarget: userProvider.carbsTarget,
              fatConsumed: userProvider.totalConsumedFat,
              fatTarget: userProvider.fatTarget,
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 16),

            // 7 Day Streak Counter
            _buildStreakCounter(context, userProvider, isDark)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 24),


            // Today's Meals Section
            if (loggedMeals.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loggedMeals.length,
                itemBuilder: (context, index) {
                  final meal = loggedMeals[index];
                  return _buildMealLogCard(context, userProvider, meal, totalTarget)
                      .animate()
                      .fadeIn(delay: (300 + index * 100).ms)
                      .slideY(begin: 0.1);
                },
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No meals logged today yet',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // const SizedBox(height: 16),
            const Divider(height: 32),
            const SizedBox(height: 8),

            // Supplementary Utilities (Water & Fasting) gracefully nested below
            Text(
              'Water Intake',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const WaterTrackerWidget().animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            // const FastingTimerWidget().animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildMealLogCard(BuildContext context, UserProvider provider, MealModel meal, double totalTarget) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular crop food image
            Hero(
              tag: 'meal_img_${meal.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  color: _getMealColor(meal.type).withValues(alpha: 0.1),
                  child: meal.imageUrl != null
                      ? (meal.imageUrl!.startsWith('assets/')
                          ? Image.asset(
                              meal.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              meal.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(_getMealIcon(meal.type), color: _getMealColor(meal.type)),
                            ))
                      : Icon(_getMealIcon(meal.type), color: _getMealColor(meal.type), size: 24),
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // Main contents column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title/Calories vs Status indicator
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Calories
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                            '${meal.calories} kcal',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF79E74),
                            ),
                          ),
                          
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Consumed / Pending status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: meal.isConsumed
                              ? Colors.green.withValues(alpha: 0.12)
                              : const Color(0xFFF79E74).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meal.isConsumed
                                  ? Icons.check_circle_rounded
                                  : Icons.schedule_rounded,
                              size: 14,
                              color: meal.isConsumed
                                  ? Colors.green
                                  : const Color(0xFFF79E74),
                            ),
                            const SizedBox(width: 4),
                            // Text(
                            //   meal.isConsumed ? 'Eaten' : 'Pending',
                            //   style: GoogleFonts.outfit(
                            //     fontSize: 11,
                            //     fontWeight: FontWeight.w700,
                            //     color: meal.isConsumed
                            //         ? Colors.green
                            //         : const Color.fromARGB(255, 244, 159, 84),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bottom row: Macro indicators (Protein, Carbs, Fat)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroItem('Protein', '${meal.protein.toInt()}g'),
                      _buildMacroItem('Carbs', '${meal.carbs.toInt()}g'),
                      _buildMacroItem('Fat', '${meal.fat.toInt()}g'),

                      // Chevron arrow hint for tap
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3E3F43),
          ),
        ),
      ],
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

  Widget _buildStreakCounter(BuildContext context, UserProvider userProvider, bool isDark) {
    final streak = userProvider.gamification.currentStreak;
    final longestStreak = userProvider.gamification.longestStreak;

    // Generate rolling last 7 days ending with today.
    final today = DateTime.now();
    final lastActive = userProvider.gamification.lastActiveDate ?? today;

    // Normalizing a date to clear time components for exact day difference calculations.
    DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    final normalizedLastActive = normalize(lastActive);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEBE5DF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFF79E74),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$streak Day${streak == 1 ? "" : "s"} Streak',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF3E3F43),
                    ),
                  ),
                ],
              ),
              Text(
                'Personal Best: $longestStreak days',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : const Color(0xFF7E7E82),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = today.subtract(Duration(days: 6 - index));
              final normalizedDay = normalize(day);
              
              final diff = normalizedLastActive.difference(normalizedDay).inDays;
              final isActive = normalizedDay.isBefore(normalizedLastActive) || normalizedDay.isAtSameMomentAs(normalizedLastActive)
                  ? (diff < streak && diff >= 0)
                  : false;
              
              final isToday = normalizedDay.isAtSameMomentAs(normalize(today));
              final weekdayLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];

              return Column(
                children: [
                  Text(
                    weekdayLetter,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? (isDark ? const Color(0xFFF79E74) : const Color(0xFF3E3F43))
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFF79E74)
                          : (isDark ? Colors.black26 : Colors.white60),
                      shape: BoxShape.circle,
                      border: isToday && !isActive
                          ? Border.all(
                              color: const Color(0xFFF79E74).withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              day.day.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}