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

  MealModel get meal => widget.meal;

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isMainPlan, resolvedMeal),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNutritionalInfo(context, resolvedMeal),
                  const SizedBox(height: 32),
                  _buildIngredientList(context, resolvedMeal),
                  const SizedBox(height: 32),
                  _buildConditionAdvisories(context, resolvedMeal),
                  const SizedBox(height: 32),
                  _buildInstructions(context, resolvedMeal),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                if (resolvedMeal.isConsumed) {
                  provider.toggleMealConsumed(resolvedMeal.id);
                  if (context.mounted) Navigator.pop(context);
                } else {
                  // Automatically add recipe to today's dashboard menu if not already present
                  if (!isAlreadyInPlan) {
                    provider.addCustomMeal(resolvedMeal);
                  }

                  // Mark consumed first with default rating
                  await provider.toggleMealConsumedWithFeedback(
                    resolvedMeal.id,
                    satisfaction: 4.0,
                  );
                  if (!context.mounted) return;

                  // Show small prompt asking if user wants to rate
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
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
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
              icon: Icon(
                resolvedMeal.isConsumed ? Icons.undo : Icons.check_circle_outline,
              ),
              label: Text(
                resolvedMeal.isConsumed ? 'Mark as Pending' : 'Mark as Consumed',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: resolvedMeal.isConsumed
                    ? Colors.grey[800]
                    : Theme.of(context).colorScheme.primary,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            if (!resolvedMeal.isConsumed) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
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
                },
                child: Text(
                  'Skip this meal',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isMainPlan, MealModel meal) {
    final color = _getMealColor(meal.type);

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: color,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (isMainPlan)
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            tooltip: 'Replace Meal',
            onPressed: () => showMealPickerSheet(
              context,
              meal.id,
              popRouteOnSelect: true,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
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
                    )
            else if (meal.category != null && _getCategoryIconPath(meal.category).isNotEmpty)
              Container(
                color: color.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.35,
                  child: SvgPicture.asset(
                    _getCategoryIconPath(meal.category),
                    width: 140,
                    height: 140,
                    colorFilter: ColorFilter.mode(
                      color,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'meal_icon_${meal.id}',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getMealIcon(meal.type), color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                Hero(
                  tag: 'meal_name_${meal.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        meal.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${meal.calories} Calories Total',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${meal.prepTimeMinutes} min prep',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionalInfo(BuildContext context, MealModel meal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMacroItem('Protein', meal.protein, 'g', Colors.orange),
            _buildMacroItem('Carbs', meal.carbs, 'g', Colors.blue),
            _buildMacroItem('Fat', meal.fat, 'g', Colors.purple),
          ],
        ),
        if (meal.sodiumMg != null || meal.glycemicImpact != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
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
          ),
        ],
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMacroItem(String label, double val, String unit, Color color) {
    return Column(
      children: [
        Text(
          '${val.toInt()}$unit',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildIngredientList(BuildContext context, MealModel meal) {
    final hasComponents = meal.components.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasComponents ? 'Meal Components' : 'Ingredients',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (hasComponents)
          ...meal.components.map((comp) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comp['name'],
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${comp['weight'].toInt()}g',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meal.ingredients
                .map((ing) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ing,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildInstructions(BuildContext context, MealModel meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Structured Preparation',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (meal.recipeSteps.isNotEmpty)
          ...meal.recipeSteps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getMealColor(meal.type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: _getMealColor(meal.type),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        else
          Text(
            meal.instructions,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
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

  Widget _buildConditionAdvisories(BuildContext context, MealModel meal) {
    if (meal.diabetesFlag == null &&
        meal.hypertensionFlag == null &&
        meal.pcosFlag == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Condition Planning Guide',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'ℹ️ Information derived from recipe ingredients. This is a planning aid and not formal medical advice.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _buildConditionCard(
          context,
          'Diabetes',
          meal.diabetesFlag,
          meal.diabetesNote,
          Icons.biotech_rounded,
        ),
        const SizedBox(height: 12),
        _buildConditionCard(
          context,
          'Hypertension',
          meal.hypertensionFlag,
          meal.hypertensionNote,
          Icons.favorite_rounded,
        ),
        const SizedBox(height: 12),
        _buildConditionCard(
          context,
          'PCOS',
          meal.pcosFlag,
          meal.pcosNote,
          Icons.spa_rounded,
        ),
      ],
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1);
  }

  Widget _buildConditionCard(
    BuildContext context,
    String condition,
    String? flag,
    String? note,
    IconData icon,
  ) {
    if (flag == null) return const SizedBox.shrink();

    final color = _getConditionFlagColor(flag);
    final label = _getConditionFlagLabel(flag);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      condition,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
