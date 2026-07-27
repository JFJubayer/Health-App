import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/meal_model.dart';
import '../providers/user_provider.dart';
import '../widgets/meal_picker_sheet.dart';
import '../widgets/meal_rating_sheet.dart';

class MealDetailScreen extends StatefulWidget {
  final MealModel meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  int _selectedTabIndex = 0; // 0 for Ingredients, 1 for Instructions

  MealModel get meal => widget.meal;

  // Helper to parse title and Bangla subtitle from meal.name
  (String, String?) _parseMealName(String fullName) {
    final regExp = RegExp(r'^(.*?)\s*\((.*?)\)$');
    final match = regExp.firstMatch(fullName);
    if (match != null) {
      final title = match.group(1)?.trim() ?? fullName;
      final subtitle = match.group(2)?.trim();
      return (title, subtitle);
    }
    return (fullName, null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    // Resolve the meal dynamically from today's plan if it exists, otherwise fallback to template
    final resolvedMeal = provider.mealPlan.firstWhere(
      (m) => m.id == widget.meal.id,
      orElse: () => widget.meal,
    );

    final isMainPlan = provider.isMainPlanMeal(resolvedMeal.id);
    final isAlreadyInPlan = provider.mealPlan.any((m) => m.id == resolvedMeal.id);
    final (titleText, subtitleText) = _parseMealName(resolvedMeal.name);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Palette tailored to match the mockup:
    final scaffoldBg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFAF7F2);
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final primaryOrange = const Color(0xFFF58A6A); // Warm coral peach accent
    final cardPeachBg = isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFFAF0E6);
    final iconCircleBg = isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF3E1D3);
    final tabBgColor = isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFF9EDE3);
    final chipBgColor = isDark ? theme.colorScheme.surfaceContainerLow : const Color(0xFFFAF2EC);
    final chipBorderColor = isDark ? theme.colorScheme.outlineVariant : const Color(0xFFEFE4D9);
    final textDark = isDark ? theme.colorScheme.onSurface : const Color(0xFF2D2621);
    final textMuted = isDark ? theme.colorScheme.onSurfaceVariant : const Color(0xFF7A7067);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Image Header
                _buildImageHeader(context, isMainPlan, resolvedMeal),

                // 2. Main Card Content Sheet overlapping header
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Bangla Subtitle
                        Text(
                          titleText,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            height: 1.15,
                          ),
                        ),
                        if (subtitleText != null && subtitleText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitleText,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Mark as Consumed Action Button
                        _buildActionButton(
                          context,
                          provider,
                          resolvedMeal,
                          isAlreadyInPlan,
                          primaryOrange,
                        ),
                        const SizedBox(height: 28),

                        // Nutrition Section
                        Text(
                          'Nutrition',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildNutritionGrid(resolvedMeal, cardPeachBg, iconCircleBg, textDark, primaryOrange),
                        
                        if (resolvedMeal.sodiumMg != null || resolvedMeal.glycemicImpact != null) ...[
                          const SizedBox(height: 16),
                          _buildExtraNutrientsRow(context, resolvedMeal),
                        ],
                        const SizedBox(height: 28),

                        // Segmented Control Tab Switcher (Ingredients / Instructions)
                        _buildTabSwitcher(tabBgColor, primaryOrange, textDark),
                        const SizedBox(height: 24),

                        // Tab Content
                        if (_selectedTabIndex == 0)
                          _buildIngredientsContent(context, resolvedMeal, textDark)
                        else
                          _buildInstructionsContent(context, resolvedMeal, textDark, primaryOrange),

                        const SizedBox(height: 28),

                        // Health Condition Section
                        _buildHealthConditionSection(context, resolvedMeal, chipBgColor, chipBorderColor, textDark),
                        const SizedBox(height: 24),

                        // Skip Meal Button at bottom
                        if (!resolvedMeal.isConsumed)
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _handleSkipMeal(context, provider, resolvedMeal),
                              icon: Icon(Icons.do_not_disturb_on_outlined, size: 18, color: textMuted),
                              label: Text(
                                'Skip this meal',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Back & Swap Buttons Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
                if (isMainPlan)
                  _buildCircleIconButton(
                    icon: Icons.swap_horiz_rounded,
                    tooltip: 'Replace Meal',
                    onPressed: () => showMealPickerSheet(
                      context,
                      meal.id,
                      mealType: meal.type,
                      popRouteOnSelect: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context, bool isMainPlan, MealModel meal) {
    final color = _getMealColor(meal.type);

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (meal.imageUrl != null)
            meal.imageUrl!.startsWith('assets/')
                ? Image.asset(
                    meal.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.network(
                    meal.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _buildFallbackHeader(color, meal),
                  )
          else if (meal.category != null && _getCategoryIconPath(meal.category).isNotEmpty)
            Container(
              color: color.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.3,
                child: SvgPicture.asset(
                  _getCategoryIconPath(meal.category),
                  width: 140,
                  height: 140,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
            )
          else
            _buildFallbackHeader(color, meal),

          // Subtle gradient overlay for back button contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHeader(Color color, MealModel meal) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Icon(_getMealIcon(meal.type), color: Colors.white.withValues(alpha: 0.8), size: 80),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    UserProvider provider,
    MealModel resolvedMeal,
    bool isAlreadyInPlan,
    Color primaryOrange,
  ) {
    final isConsumed = resolvedMeal.isConsumed;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () async {
          if (isConsumed) {
            provider.toggleMealConsumed(resolvedMeal.id);
            if (context.mounted) Navigator.pop(context);
          } else {
            if (!isAlreadyInPlan) {
              provider.addCustomMeal(resolvedMeal);
            }

            await provider.toggleMealConsumedWithFeedback(
              resolvedMeal.id,
              satisfaction: 4.0,
            );
            if (!context.mounted) return;

            final wantsToRate = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final dlgTheme = Theme.of(ctx);
                return AlertDialog(
                  backgroundColor: dlgTheme.scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Meal Logged!',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dlgTheme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Would you like to rate this meal?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: dlgTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Skip', style: GoogleFonts.outfit(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Rate Now',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: dlgTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            if (wantsToRate == true && context.mounted) {
              final rating = await showMealRatingSheet(context, resolvedMeal);
              if (rating != null && context.mounted) {
                await provider.toggleMealConsumedWithFeedback(
                  resolvedMeal.id,
                  satisfaction: rating,
                );
              }
            }

            if (context.mounted) Navigator.pop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isConsumed ? const Color(0xFF4A4440) : primaryOrange,
          foregroundColor: Colors.white,
          elevation: isConsumed ? 0 : 2,
          shadowColor: primaryOrange.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                isConsumed ? Icons.undo : Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isConsumed ? 'Mark as Pending' : 'Mark as Consumed',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Future<void> _handleSkipMeal(
    BuildContext context,
    UserProvider provider,
    MealModel resolvedMeal,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Skip this meal?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will log the meal as skipped and adjust your preferences.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Skip',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await provider.skipMeal(resolvedMeal.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildNutritionGrid(
    MealModel meal,
    Color cardBg,
    Color iconCircleBg,
    Color textDark,
    Color primaryOrange,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                icon: Icons.local_fire_department_outlined,
                value: '${meal.calories} Kcal',
                cardBg: cardBg,
                iconCircleBg: iconCircleBg,
                textDark: textDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard(
                icon: Icons.egg_outlined,
                value: '${meal.protein.toInt()}g proteins',
                cardBg: cardBg,
                iconCircleBg: iconCircleBg,
                textDark: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                icon: Icons.grain_rounded,
                value: '${meal.carbs.toInt()}g carbs',
                cardBg: cardBg,
                iconCircleBg: iconCircleBg,
                textDark: textDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard(
                icon: Icons.local_pizza_outlined,
                value: '${meal.fat.toInt()}g fats',
                cardBg: cardBg,
                iconCircleBg: iconCircleBg,
                textDark: textDark,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildNutritionCard({
    required IconData icon,
    required String value,
    required Color cardBg,
    required Color iconCircleBg,
    required Color textDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconCircleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6E5644)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraNutrientsRow(BuildContext context, MealModel meal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (meal.sodiumMg != null)
          _buildExtraNutrientItem(
            context,
            Icons.info_outline,
            'Sodium',
            '${meal.sodiumMg!.toStringAsFixed(0)} mg',
            Colors.blueGrey,
          ),
        if (meal.glycemicImpact != null)
          _buildExtraNutrientItem(
            context,
            Icons.speed_rounded,
            'Glycemic Impact',
            meal.glycemicImpact!.toUpperCase(),
            _getGlycemicColor(meal.glycemicImpact!),
          ),
      ],
    );
  }

  Widget _buildTabSwitcher(Color tabBgColor, Color primaryOrange, Color textDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tabBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Ingredients',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0 ? Colors.white : textDark,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Instructions',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1 ? Colors.white : textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsContent(BuildContext context, MealModel meal, Color textDark) {
    final hasComponents = meal.components.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasComponents ? 'Meal Components' : 'Ingredients',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 14),
        if (hasComponents)
          ...meal.components.map((comp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comp['name'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                      ),
                    ),
                    Text(
                      '${comp['weight']?.toInt() ?? 0}g',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF58A6A),
                      ),
                    ),
                  ],
                ),
              ))
        else
          ...meal.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ing,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textDark,
                    height: 1.4,
                  ),
                ),
              )),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildInstructionsContent(
    BuildContext context,
    MealModel meal,
    Color textDark,
    Color primaryOrange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 14),
        if (meal.recipeSteps.isNotEmpty)
          ...meal.recipeSteps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: primaryOrange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          entry.value,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: textDark,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        else
          Text(
            meal.instructions.isNotEmpty ? meal.instructions : 'No specific preparation steps listed.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: textDark,
              height: 1.45,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildHealthConditionSection(
    BuildContext context,
    MealModel meal,
    Color chipBgColor,
    Color chipBorderColor,
    Color textDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Condition',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildConditionChip(
              context,
              label: 'Diabetes',
              icon: Icons.water_drop_outlined,
              flag: meal.diabetesFlag,
              note: meal.diabetesNote,
              chipBgColor: chipBgColor,
              chipBorderColor: chipBorderColor,
              textDark: textDark,
            ),
            _buildConditionChip(
              context,
              label: 'Hypertension',
              icon: Icons.favorite_border_rounded,
              flag: meal.hypertensionFlag,
              note: meal.hypertensionNote,
              chipBgColor: chipBgColor,
              chipBorderColor: chipBorderColor,
              textDark: textDark,
            ),
            _buildConditionChip(
              context,
              label: 'PCOS',
              icon: Icons.female_rounded,
              flag: meal.pcosFlag,
              note: meal.pcosNote,
              chipBgColor: chipBgColor,
              chipBorderColor: chipBorderColor,
              textDark: textDark,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildConditionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? flag,
    String? note,
    required Color chipBgColor,
    required Color chipBorderColor,
    required Color textDark,
  }) {
    final flagColor = flag != null ? _getConditionFlagColor(flag) : Colors.grey;

    return InkWell(
      onTap: note != null && note.isNotEmpty
          ? () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: flagColor),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (flag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: flagColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getConditionFlagLabel(flag),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: flagColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        note,
                        style: GoogleFonts.outfit(fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipBorderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: flag != null ? flagColor : textDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny_rounded;
      case MealType.lunch:
        return Icons.fastfood_rounded;
      case MealType.dinner:
        return Icons.nightlight_round;
      case MealType.snack:
        return Icons.apple_rounded;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.dinner:
        return Colors.indigo;
      case MealType.snack:
        return Colors.teal;
    }
  }

  String _getCategoryIconPath(String? categoryStr) {
    if (categoryStr == null) return '';
    const String iconBase = 'assets/icons';
    switch (categoryStr) {
      case 'riceBased':
        return '$iconBase/rice_based.svg';
      case 'bhorta':
        return '$iconBase/bhorta.svg';
      case 'dal':
        return '$iconBase/dal.svg';
      case 'fishCurry':
        return '$iconBase/fish_curry.svg';
      case 'meatCurry':
        return '$iconBase/meat_curry.svg';
      case 'eggDish':
        return '$iconBase/egg_dish.svg';
      case 'vegetableCurry':
        return '$iconBase/vegetable_curry.svg';
      case 'shak':
        return '$iconBase/shak.svg';
      case 'snack':
        return '$iconBase/snack.svg';
      case 'breakfast':
        return '$iconBase/breakfast.svg';
      case 'sweet':
        return '$iconBase/sweet.svg';
      case 'soupStew':
        return '$iconBase/soup_stew.svg';
      default:
        return '';
    }
  }

  Widget _buildExtraNutrientItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGlycemicColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getConditionFlagColor(String flag) {
    switch (flag.toLowerCase()) {
      case 'favorable':
        return Colors.green;
      case 'neutral':
        return Colors.grey;
      case 'usecaution':
      case 'use_caution':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getConditionFlagLabel(String flag) {
    switch (flag.toLowerCase()) {
      case 'favorable':
        return 'FAVORABLE';
      case 'neutral':
        return 'NEUTRAL';
      case 'usecaution':
      case 'use_caution':
        return 'USE CAUTION';
      default:
        return flag.toUpperCase();
    }
  }
}
