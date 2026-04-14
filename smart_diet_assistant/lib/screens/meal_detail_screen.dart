import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_model.dart';
import '../providers/user_provider.dart';

class MealDetailScreen extends StatelessWidget {
  final MealModel meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildNutritionalInfo(context),
                   const SizedBox(height: 32),
                   _buildIngredientList(context),
                   const SizedBox(height: 32),
                   _buildInstructions(context),
                   const SizedBox(height: 100), // Space for fab
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          onPressed: () {
            provider.toggleMealConsumed(meal.id);
            Navigator.pop(context);
          },
          icon: Icon(meal.isConsumed ? Icons.undo : Icons.check_circle_outline),
          label: Text(
            meal.isConsumed ? 'Mark as Pending' : 'Mark as Consumed',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: meal.isConsumed ? Colors.grey[800] : const Color(0xFF059669),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    Color color = _getMealColor(meal.type);
    
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
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
          tooltip: 'Replace Meal',
          onPressed: () {
             Provider.of<UserProvider>(context, listen: false).replaceMeal(meal.id);
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Meal replaced with a healthy alternative!')),
             );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            if (meal.imageUrl != null)
              Image.network(
                meal.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withOpacity(0.8)],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
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
                      color: Colors.white.withOpacity(0.2),
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
                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionalInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroItem('Protein', meal.protein, 'g', Colors.orange),
        _buildMacroItem('Carbs', meal.carbs, 'g', Colors.blue),
        _buildMacroItem('Fat', meal.fat, 'g', Colors.purple),
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

  Widget _buildIngredientList(BuildContext context) {
    bool hasComponents = meal.components.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hasComponents ? 'Meal Components' : 'Ingredients', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (hasComponents)
          ...meal.components.map((comp) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(comp['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                Text('${comp['weight'].toInt()}g', style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList()
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meal.ingredients.map((ing) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(ing, style: GoogleFonts.outfit(color: const Color(0xFF374151))),
            )).toList(),
          ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Structured Preparation', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    color: _getMealColor(meal.type).withOpacity(0.1),
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
                    style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF4B5563), height: 1.5),
                  ),
                ),
              ],
            ),
          ))
        else
          Text(
            meal.instructions,
            style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF4B5563), height: 1.5),
          ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast: return Icons.wb_sunny_rounded;
      case MealType.lunch: return Icons.fastfood_rounded;
      case MealType.dinner: return Icons.nightlight_round;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.breakfast: return Colors.orange;
      case MealType.lunch: return Colors.green;
      case MealType.dinner: return Colors.indigo;
    }
  }
}
