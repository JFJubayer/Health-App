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
import '../widgets/glass_card.dart';
import 'bazaar_prices_screen.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: Column(
          children: [
            _buildHeader(context, user).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            
            // Personal Info 2×2 Grid Card
            _buildPersonalInfoCard(context, user).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            _buildBmiSection(context, user).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            _buildMetabolicGrid(context, userProvider).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: CalorieGraphWidget(userProvider: userProvider),
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            _buildFavoritesSection(context).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            _buildBadgesSection(context, userProvider).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            _buildPreferencesSection(context, userProvider, themeProvider).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
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
            ).animate().fadeIn(delay: 650.ms),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 110,
                height: 110,
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
                  size: 55,
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
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome Back!',
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        Text(
          'Your go to place for health tracking.',
          style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final valueColor = theme.colorScheme.onSurface;
    // final dividerColor = isDark
    //     ? Colors.white.withValues(alpha: 0.08)
    //     : const Color(0xFFE0DAD5);

    Widget buildCell(String label, String value) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Age | Weight
          IntrinsicHeight(
            child: Row(
              children: [
                buildCell('Age', '${user.age}'),
                buildCell('Weight', '${user.weightKg.toStringAsFixed(1)} kg'),
              ],
            ),
          ),
          // Divider(height: 1, thickness: 1, color: dividerColor),
          // Bottom row: Height | Gender
          IntrinsicHeight(
            child: Row(
              children: [
                buildCell('Height', '${user.heightCm.toInt()} cm'),
                buildCell('Gender', user.gender),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(BuildContext context, IconData icon, String title, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicGrid(BuildContext context, UserProvider provider) {
    final theme = Theme.of(context);
    final isWeightLoss = provider.isWeightManagementActive;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metabolic Plan',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isWeightLoss)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Weight Loss Active (-${provider.user!.weightDeficitCal.toInt()} kcal)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    context,
                    Icons.track_changes_rounded,
                    'Daily Calorie Target',
                    '${provider.calorieTarget.toInt()} kcal',
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    context,
                    Icons.local_fire_department_outlined,
                    'Calorie Tier',
                    provider.calorieTier,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    context,
                    Icons.speed_outlined,
                    'BMR (Base)',
                    '${provider.bmr.toInt()} kcal',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    context,
                    Icons.directions_run_outlined,
                    'TDEE (Maintenance)',
                    '${provider.tdee.toInt()} kcal',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    final prefs = PersistenceService.getPreferences(MealFeedbackService.userId);
    final favoriteIds = prefs?.favoriteMealIds ?? [];
    final ratings = prefs?.mealRatings ?? {};

    final templates = PersistenceService.getAllTemplates();
    final templateMap = {for (var t in templates) t.id: t};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, right: 8),
          child: Text(
            'Favorite Meals',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (favoriteIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Rate meals 4.5+ when you consume them to auto-favorite.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
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
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(meal.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${meal.calories} kcal',
                      style: GoogleFonts.outfit(fontSize: 13),
                    ),
                    trailing: rating != null
                        ? Chip(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context, UserProvider provider) {
    final gamification = provider.gamification;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Achievements',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildBadgeIcon(context, 'Consistency King', Icons.local_fire_department, Colors.orange, gamification.badges.contains('Consistency King')),
              _buildBadgeIcon(context, 'Hydration Hero', Icons.water_drop, Colors.blue, gamification.badges.contains('Hydration Hero')),
              _buildBadgeIcon(context, 'Nutrition Master', Icons.restaurant, Colors.green, gamification.badges.contains('Nutrition Master')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeIcon(BuildContext context, String title, IconData icon, Color color, bool isUnlocked) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? color.withValues(alpha: 0.6) : Colors.transparent,
              width: 2,
            ),
            boxShadow: isUnlocked ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Icon(
            icon,
            size: 32,
            color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
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

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Body Mass Index (BMI)',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
                onPressed: () => _showBmiInfoModal(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    bmi.toStringAsFixed(1),
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 24),
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
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBmiInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BMI Categories', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildBmiLegendRow(context, 'Underweight', '< 18.5', Colors.blue),
              _buildBmiLegendRow(context, 'Normal Weight', '18.5 - 24.9', Colors.green),
              _buildBmiLegendRow(context, 'Overweight', '25.0 - 29.9', Colors.orange),
              _buildBmiLegendRow(context, 'Obesity', '≥ 30.0', Colors.red),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Got it', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Text(category, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          Text(range, style: GoogleFonts.outfit(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, UserProvider userProvider, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Preferences',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 22),
                ),
                title: Text('Hydration Reminders', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text('Actionable alerts', style: GoogleFonts.outfit(fontSize: 13)),
                trailing: Switch(
                  value: userProvider.hydrationRemindersEnabled,
                  onChanged: userProvider.setHydrationRemindersEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop_outlined, color: Colors.cyan, size: 22),
                ),
                title: Text('Daily Water Goal', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text('${userProvider.waterGoal} ml', style: GoogleFonts.outfit(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showWaterGoalSheet(context),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store_mall_directory_outlined, color: Colors.green, size: 22),
                ),
                title: Text('Bazaar Prices', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text('Edit ingredient costs (BDT)', style: GoogleFonts.outfit(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BazaarPricesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                title: Text('Dark Mode', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text(themeProvider.isDarkMode ? 'Enabled' : 'Disabled', style: GoogleFonts.outfit(fontSize: 13)),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              if (HealthService.isHighBmi(userProvider.user!.weightKg, userProvider.user!.heightCm)) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.scale_rounded, color: Colors.orange, size: 22),
                  ),
                  title: Text('Weight Loss Plan', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                  subtitle: Text(userProvider.user!.weightManagementEnabled ? 'Active deficit' : 'Disabled (Maintenance)', style: GoogleFonts.outfit(fontSize: 13)),
                  trailing: Switch(
                    value: userProvider.user!.weightManagementEnabled,
                    onChanged: (val) {
                      final updatedUser = userProvider.user!.copyWith(weightManagementEnabled: val);
                      userProvider.updateUserProfile(updatedUser);
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                if (userProvider.user!.weightManagementEnabled)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.trending_down_rounded, color: Colors.red, size: 22),
                    ),
                    title: Text('Calorie Deficit', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text('-${userProvider.user!.weightDeficitCal.toInt()} kcal/day', style: GoogleFonts.outfit(fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showDeficitAdjustmentDialog(context, userProvider);
                    },
                  ),
              ],
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton.icon(
                  onPressed: () => NotificationService.showTestNotification(),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Test Notification'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeficitAdjustmentDialog(BuildContext context, UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        double tempDeficit = provider.user!.weightDeficitCal;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text('Adjust Calorie Deficit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the daily calorie deficit for weight loss.',
                    style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [250.0, 500.0, 750.0].map((deficit) {
                      final isSelected = tempDeficit == deficit;
                      return ChoiceChip(
                        label: Text('-${deficit.toInt()} kcal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => tempDeficit = deficit);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final updatedUser = provider.user!.copyWith(weightDeficitCal: tempDeficit);
                    provider.updateUserProfile(updatedUser);
                    Navigator.pop(context);
                  },
                  child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
