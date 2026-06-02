import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import 'input_screen.dart';
import '../services/notification_service.dart';
import '../services/health_service.dart';
import '../services/persistence_service.dart';
import '../services/diet_service.dart';
import '../services/meal_feedback_service.dart';
import '../widgets/water_goal_dialog.dart';
import '../widgets/calorie_graph_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      user.gender == 'Male' ? Icons.face_rounded : Icons.face_3_rounded,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InputScreen(
                            initialUser: user,
                            isEditMode: true,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Welcome Back!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            Text(
              'Your health summary is updated daily',
              style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileTile(context, Icons.cake, 'Age', '${user.age} years', Colors.orange),
                  _buildProfileTile(context, Icons.monitor_weight, 'Weight', '${user.weightKg.toStringAsFixed(1)} kg', Colors.green),
                  _buildProfileTile(context, Icons.height, 'Height', '${user.heightCm.toInt()} cm', Colors.blue),
                  _buildProfileTile(context, Icons.person_outline, 'Gender', user.gender, Colors.purple),
                  if (user.conditions.isNotEmpty)
                    _buildProfileTile(context, Icons.medical_information, 'Conditions', user.conditions.join(', '), Colors.red, isLast: true),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),
            _buildMetabolicSection(context, userProvider)
                .animate()
                .fadeIn(delay: 225.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 24),
            CalorieGraphWidget(userProvider: userProvider)
                .animate()
                .fadeIn(delay: 235.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 24),
            _buildFavoritesSection(context)
                .animate()
                .fadeIn(delay: 240.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 24),
            _buildBadgesSection(context, userProvider).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),
            _buildBmiSection(context, user).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
                    child: Text(
                      'Preferences',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 20),
                    ),
                    title: Text('Smart Hydration Reminders', style: GoogleFonts.outfit(fontSize: 15)),
                    subtitle: Text('Actionable alerts during the day', style: GoogleFonts.outfit(fontSize: 12)),
                    trailing: Switch(
                      value: userProvider.hydrationRemindersEnabled,
                      onChanged: userProvider.setHydrationRemindersEnabled,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.water_drop_outlined,
                        color: Colors.cyan,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Daily Water Goal',
                      style: GoogleFonts.outfit(fontSize: 15),
                    ),
                    subtitle: Text(
                      '${userProvider.waterGoal} ml',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showWaterGoalDialog(context),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    title: Text('Dark Mode', style: GoogleFonts.outfit(fontSize: 15)),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (val) {
                        themeProvider.toggleTheme();
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => NotificationService.showTestNotification(),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Test Notification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                userProvider.clearUser();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const InputScreen()),
                  (route) => false,
                );
              },
              child: const Text('Reset Profile & Goals'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String value, Color color, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: GoogleFonts.outfit(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          trailing: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.05)),
          ),
      ],
    );
  }

  Widget _buildMetabolicSection(BuildContext context, UserProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
            child: Text(
              'Metabolic Plan',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildProfileTile(
            context,
            Icons.local_fire_department_outlined,
            'Calorie tier',
            provider.calorieTier,
            Theme.of(context).colorScheme.primary,
          ),
          _buildProfileTile(
            context,
            Icons.speed_outlined,
            'BMR',
            '${provider.bmr.toInt()} kcal/day',
            Colors.orange,
          ),
          _buildProfileTile(
            context,
            Icons.directions_run_outlined,
            'TDEE',
            '${provider.tdee.toInt()} kcal/day',
            Colors.green,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    final prefs = PersistenceService.getPreferences(MealFeedbackService.userId);
    final favoriteIds = prefs?.favoriteMealIds ?? [];
    final ratings = prefs?.mealRatings ?? {};

    final templates = PersistenceService.getAllTemplates();
    final templateMap = {for (var t in templates) t.id: t};

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8, right: 20),
            child: Text(
              'Favorite Meals',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (favoriteIds.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Rate meals 4.5+ when you consume them to auto-favorite.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...favoriteIds.map((id) {
              final template = templateMap[id];
              if (template == null) return const SizedBox.shrink();
              final meal = DietService.resolveMealModel(template);
              final rating = ratings[id];
              return ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(meal.name, style: GoogleFonts.outfit(fontSize: 15)),
                subtitle: Text(
                  '${meal.calories} kcal',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                trailing: rating != null
                    ? Chip(
                        label: Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, UserProvider provider) {
    final gamification = provider.gamification;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
            child: Text(
              'Achievements',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildBadgeIcon(context, 'Consistency King', Icons.local_fire_department, Colors.orange, gamification.badges.contains('Consistency King')),
              _buildBadgeIcon(context, 'Hydration Hero', Icons.water_drop, Colors.blue, gamification.badges.contains('Hydration Hero')),
              _buildBadgeIcon(context, 'Nutrition Master', Icons.restaurant, Colors.green, gamification.badges.contains('Nutrition Master')),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(BuildContext context, String title, IconData icon, Color color, bool isUnlocked) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? color.withValues(alpha: 0.5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            color: isUnlocked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBmiSection(BuildContext context, UserModel user) {
    final bmi = HealthService.calculateBMI(user.weightKg, user.heightCm);
    final category = HealthService.getBMICategory(bmi);
    
    Color getCategoryColor(String cat) {
      if (cat == 'Underweight') return Colors.blue;
      if (cat == 'Normal Weight') return Colors.green;
      if (cat == 'Overweight') return Colors.orange;
      return Colors.red;
    }
    
    final color = getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Body Mass Index (BMI)',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  onPressed: () => _showBmiInfoModal(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      bmi.toStringAsFixed(1),
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your BMI indicates you are',
                        style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showBmiInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BMI Categories', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBmiLegendRow(context, 'Underweight', '< 18.5', Colors.blue),
              _buildBmiLegendRow(context, 'Normal Weight', '18.5 - 24.9', Colors.green),
              _buildBmiLegendRow(context, 'Overweight', '25.0 - 29.9', Colors.orange),
              _buildBmiLegendRow(context, 'Obesity', '≥ 30.0', Colors.red),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Got it', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBmiLegendRow(BuildContext context, String category, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(category, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          Text(range, style: GoogleFonts.outfit(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

