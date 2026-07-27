import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';
import '../services/persistence_service.dart';
import '../services/diet_service.dart';
import '../widgets/meal_slot_picker_sheet.dart';
import 'meal_detail_screen.dart';

class DeduplicatedMeal {
  final MealModel primaryMeal;
  final List<MealType> availableTypes;

  DeduplicatedMeal({
    required this.primaryMeal,
    required this.availableTypes,
  });
}

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Category list items matching the 3D icons styling with system emojis
  final List<Map<String, String>> _categories = [
    {'name': 'All', 'emoji': '🍲'},
    {'name': 'Vegan', 'emoji': '🥗'},
    {'name': 'Protein', 'emoji': '🥛'},
    {'name': 'Snacks', 'emoji': '🍟'},
  ];

  @override
  void initState() {
    super.initState();
  }

  List<DeduplicatedMeal> _getFilteredTemplates() {
    final allTemplates = PersistenceService.getAllTemplates();
    final mealModels = allTemplates.map(DietService.resolveMealModel).toList();

    // Group meals by normalized name to deduplicate
    final Map<String, List<MealModel>> grouped = {};
    for (final meal in mealModels) {
      if (meal.calories <= 0) continue;
      final key = meal.name.trim().toLowerCase();
      grouped.putIfAbsent(key, () => []).add(meal);
    }

    final List<DeduplicatedMeal> dedupList = [];
    for (final group in grouped.values) {
      if (group.isEmpty) continue;
      final primary = group.first;
      final Set<MealType> typesSet = group.map((m) => m.type).toSet();

      // Check search filter
      final matchesSearch = primary.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) continue;

      // Check category filter
      if (_selectedCategory == 'Vegan') {
        final isVegan = primary.ingredients.any((ing) =>
                ing.toLowerCase().contains('tofu') ||
                ing.toLowerCase().contains('spinach') ||
                ing.toLowerCase().contains('oats')) ||
            primary.name.toLowerCase().contains('veggie') ||
            primary.name.toLowerCase().contains('salad');
        if (!isVegan) continue;
      } else if (_selectedCategory == 'Protein') {
        final isProtein = primary.protein >= 15.0 ||
            primary.name.toLowerCase().contains('chicken') ||
            primary.name.toLowerCase().contains('beef') ||
            primary.name.toLowerCase().contains('egg') ||
            primary.name.toLowerCase().contains('fish');
        if (!isProtein) continue;
      } else if (_selectedCategory == 'Snacks') {
        if (!typesSet.contains(MealType.snack)) continue;
      }

      dedupList.add(DeduplicatedMeal(
        primaryMeal: primary,
        availableTypes: typesSet.toList(),
      ));
    }

    return dedupList;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredRecipes = _getFilteredTemplates();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110), // Safe spacing for navigation bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Heading
              Text(
                'Meals',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 24),

              // Categories Row
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['name']!;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFF79E74) 
                              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              cat['emoji']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat['name']!,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected 
                                    ? Colors.white 
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Trending Recipes Header
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 6),
                ],
              ),

              const SizedBox(height: 12),

              if (filteredRecipes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No matching recipes found',
                      style: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final dedupMeal = filteredRecipes[index];
                    return _buildRecipeListCard(context, userProvider, dedupMeal)
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideY(begin: 0.05);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeListCard(
      BuildContext context, UserProvider provider, DeduplicatedMeal dedupMeal) {
    final theme = Theme.of(context);
    final meal = dedupMeal.primaryMeal;
    final typesText = dedupMeal.availableTypes.map((t) {
      switch (t) {
        case MealType.breakfast:
          return 'Breakfast';
        case MealType.lunch:
          return 'Lunch';
        case MealType.dinner:
          return 'Dinner';
        case MealType.snack:
          return 'Snack';
      }
    }).join(' • ');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailScreen(
              meal: meal,
              availableTypes: dedupMeal.availableTypes,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Circular image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 55,
                height: 55,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: meal.imageUrl != null
                    ? (meal.imageUrl!.startsWith('assets/')
                        ? Image.asset(meal.imageUrl!, fit: BoxFit.cover)
                        : Image.network(
                            meal.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(_getMealIcon(meal.type), color: theme.colorScheme.primary),
                          ))
                    : Icon(_getMealIcon(meal.type), color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal.calories} kcal • ${meal.prepTimeMinutes} min • $typesText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Log/Add button
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
              onPressed: () {
                showMealSlotPickerSheet(
                  context: context,
                  meal: meal,
                  availableTypes: dedupMeal.availableTypes,
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
}
