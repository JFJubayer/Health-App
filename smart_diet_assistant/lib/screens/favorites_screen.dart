import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_model.dart';
import '../services/persistence_service.dart';
import '../services/diet_service.dart';
import 'meal_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _searchQuery = '';
  List<MealModel> _favoriteMeals = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    // Load seeded favorites: Quinoa Chickpea Bowl, Oatmeal & Almonds, Egg Spinach Scramble
    final allTemplates = PersistenceService.getAllTemplates();
    final favoritedNames = ['Quinoa Chickpea Bowl', 'Oatmeal & Almonds', 'Egg Spinach Scramble', 'Chicken Salad & Yogurt'];
    
    final meals = allTemplates
        .where((t) => favoritedNames.contains(t.name))
        .map(DietService.resolveMealModel)
        .toList();

    setState(() {
      _favoriteMeals = meals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredFavorites = _favoriteMeals.where((meal) {
      return meal.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Favorites', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search favorites...',
                hintStyle: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredFavorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No favorites found',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save meals to your favorites list to see them here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final meal = filteredFavorites[index];
                      return _buildFavoriteCard(context, meal).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.05);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, MealModel meal) {
    final theme = Theme.of(context);
    final color = _getMealColor(meal.type);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'fav_meal_icon_${meal.id}',
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_getMealIcon(meal.type), color: color, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal.calories} kcal • ${meal.prepTimeMinutes} mins prep',
                    style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.star_rounded, color: Colors.orange),
              onPressed: () {
                setState(() {
                  _favoriteMeals.removeWhere((m) => m.id == meal.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${meal.name}" from favorites.', style: GoogleFonts.outfit()),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
