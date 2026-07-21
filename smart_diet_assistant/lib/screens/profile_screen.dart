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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    final bmi = HealthService.calculateBMI(user.weightKg, user.heightCm);
    final bmiCategory = HealthService.getBMICategory(bmi);
    final prefs = PersistenceService.getPreferences(MealFeedbackService.userId);
    final favoriteCount = prefs?.favoriteMealIds.length ?? 0;
    final badgeCount = userProvider.gamification.badges.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
        child: Column(
          children: [
            _buildHeader(context, user).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 28),

            // Minimalist Container for Menu List
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- SECTION 1: Health & Performance ---
                  _buildMenuItem(
                    context: context,
                    icon: Icons.insights_outlined,
                    title: 'Metabolic & Calorie Insights',
                    value: '${userProvider.calorieTarget.toInt()} kcal',
                    onTap: () => _showMetabolicInsightsModal(context, userProvider),
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.monitor_weight_outlined,
                    title: 'BMI & Body Health',
                    value: '${bmi.toStringAsFixed(1)} • $bmiCategory',
                    onTap: () => _showBmiInfoModal(context),
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.favorite_border_rounded,
                    title: 'Favorite Meals',
                    value: '$favoriteCount saved',
                    onTap: () => _showFavoritesModal(context),
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Achievements & Badges',
                    value: '$badgeCount unlocked',
                    onTap: () => _showBadgesModal(context, userProvider),
                  ),

                  // Section Divider Line
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1.5,
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),

                  // --- SECTION 2: Preferences & Settings ---
                  _buildMenuItem(
                    context: context,
                    icon: Icons.water_drop_outlined,
                    title: 'Daily Water Goal',
                    value: '${userProvider.waterGoal} ml',
                    onTap: () => showWaterGoalSheet(context),
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Hydration Reminders',
                    trailing: Switch(
                      value: userProvider.hydrationRemindersEnabled,
                      onChanged: userProvider.setHydrationRemindersEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.storefront_outlined,
                    title: 'Bazaar Ingredient Prices',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BazaarPricesScreen(),
                        ),
                      );
                    },
                  ),
                  if (HealthService.isHighBmi(user.weightKg, user.heightCm)) ...[
                    _buildDivider(context),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.tune_outlined,
                      title: 'Weight Loss Plan',
                      value: user.weightManagementEnabled
                          ? '-${user.weightDeficitCal.toInt()} kcal'
                          : 'Disabled',
                      onTap: () => _showDeficitAdjustmentDialog(context, userProvider),
                    ),
                  ],
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleTheme(),
                      activeThumbColor: Colors.white,
                      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),

                  // Section Divider Line
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1.5,
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),

                  // --- SECTION 3: Account & System ---
                  _buildMenuItem(
                    context: context,
                    icon: Icons.send_outlined,
                    title: 'Send Test Notification',
                    onTap: () => NotificationService.showTestNotification(),
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.edit_outlined,
                    title: 'Edit Personal Details',
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
                  ),
                  _buildDivider(context),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Reset Profile & Goals',
                    titleColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onTap: () => _showResetConfirmationDialog(context, userProvider),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 3),
              ),
              child: Icon(
                user.gender == 'Male' ? Icons.face_rounded : Icons.face_3_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            InkWell(
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'User Profile',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${user.age} yrs  •  ${user.weightKg.toStringAsFixed(1)} kg  •  ${user.heightCm.toInt()} cm  •  ${user.gender}',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        icon,
        color: effectiveIconColor,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? theme.colorScheme.onSurface,
        ),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null) ...[
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
    );
  }

  void _showMetabolicInsightsModal(BuildContext context, UserProvider provider) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Metabolic & Calorie Insights',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMetabolicGrid(context, provider),
                const SizedBox(height: 20),
                Text(
                  '7-Day Calorie Intake',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: CalorieGraphWidget(userProvider: provider),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFavoritesModal(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = PersistenceService.getPreferences(MealFeedbackService.userId);
    final favoriteIds = prefs?.favoriteMealIds ?? [];
    final ratings = prefs?.mealRatings ?? {};
    final templates = PersistenceService.getAllTemplates();
    final templateMap = {for (var t in templates) t.id: t};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorite Meals',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (favoriteIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Rate meals 4.5+ when you consume them to auto-favorite.',
                      style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: favoriteIds.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final id = favoriteIds[index];
                      final template = templateMap[id];
                      if (template == null) return const SizedBox.shrink();
                      final meal = DietService.resolveMealModel(template);
                      final rating = ratings[id];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.favorite, color: theme.colorScheme.primary, size: 20),
                        ),
                        title: Text(meal.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Text('${meal.calories} kcal', style: GoogleFonts.outfit(fontSize: 13)),
                        trailing: rating != null
                            ? Chip(
                                backgroundColor: theme.colorScheme.surface,
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
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgesModal(BuildContext context, UserProvider provider) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements & Badges',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBadgesSection(context, provider),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showResetConfirmationDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Reset Profile & Goals?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to reset your profile and goals? This action cannot be undone.',
            style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                userProvider.clearUser();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const InputScreen()),
                  (route) => false,
                );
              },
              child: Text('Reset', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
          padding: const EdgeInsets.only(left: 4, bottom: 12, right: 4),
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

  Widget _buildBadgesSection(BuildContext context, UserProvider provider) {
    final gamification = provider.gamification;
    
    return GlassCard(
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

  void _showBmiInfoModal(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    final bmi = HealthService.calculateBMI(user.weightKg, user.heightCm);
    final category = HealthService.getBMICategory(bmi);

    Color getCategoryColor(String cat) {
      if (cat == 'Underweight') return Colors.blue;
      if (cat == 'Normal Weight') return Colors.green;
      if (cat == 'Overweight') return Colors.orange;
      return Colors.red;
    }

    final color = getCategoryColor(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Body Mass Index (BMI)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
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
                          'Your status:',
                          style: GoogleFonts.outfit(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('BMI Reference Scale', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBmiLegendRow(context, 'Underweight', '< 18.5', Colors.blue),
              _buildBmiLegendRow(context, 'Normal Weight', '18.5 - 24.9', Colors.green),
              _buildBmiLegendRow(context, 'Overweight', '25.0 - 29.9', Colors.orange),
              _buildBmiLegendRow(context, 'Obesity', '≥ 30.0', Colors.red),
              const SizedBox(height: 24),
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
              const SizedBox(width: 14),
              Text(category, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          Text(range, style: GoogleFonts.outfit(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
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

