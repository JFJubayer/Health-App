import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';
import '../services/persistence_service.dart';
import '../services/diet_service.dart';
import 'meal_detail_screen.dart';

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

  // Custom Quinoa Veggie Bowl Meal Model to match featured card
  late final MealModel _quinoaVeggieBowl;

  @override
  void initState() {
    super.initState();
    _quinoaVeggieBowl = MealModel(
      id: 'quinoa_veggie_bowl_featured',
      name: 'Quinoa Veggie Bowl',
      calories: 750,
      type: MealType.lunch,
      protein: 22.0,
      carbs: 88.0,
      fat: 26.0,
      prepTimeMinutes: 45,
      imageUrl: 'assets/images/quinoa_veggie_bowl.png',
      ingredients: [
        'Cooked Quinoa',
        'Sliced Avocado',
        'Cherry Tomatoes',
        'Cucumber Slices',
        'Red Cabbage',
        'Fresh Salad Leaves',
        'Chickpeas',
        'Lemon Dressing'
      ],
      instructions: '1. Prepare quinoa.\n2. Slice vegetables and avocado.\n3. Arrange in a bowl and top with chickpeas.\n4. Dress with lemon juice.',
      recipeSteps: [
        'Boil 1 cup of quinoa in 2 cups of water for 15 minutes, then fluff with a fork.',
        'Slice cherry tomatoes, cucumber, red cabbage, and fresh avocado.',
        'Place salad greens at the base of the bowl, then partition quinoa, chickpeas, and sliced vegetables side by side.',
        'Drizzle fresh lemon juice and olive oil dressing over the ingredients. Enjoy!'
      ],
    );
  }

  List<MealModel> _getFilteredTemplates() {
    final allTemplates = PersistenceService.getAllTemplates();
    final mealModels = allTemplates.map(DietService.resolveMealModel).toList();

    return mealModels.where((meal) {
      // 1. Search Query Filter
      final matchesSearch = meal.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      // 2. Category Tag Filter
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Vegan') {
        return meal.ingredients.any((ing) => ing.toLowerCase().contains('tofu') || ing.toLowerCase().contains('spinach') || ing.toLowerCase().contains('oats')) ||
            meal.name.toLowerCase().contains('veggie') || meal.name.toLowerCase().contains('salad');
      }
      if (_selectedCategory == 'Protein') {
        return meal.protein >= 15.0 || meal.name.toLowerCase().contains('chicken') || meal.name.toLowerCase().contains('beef') || meal.name.toLowerCase().contains('egg') || meal.name.toLowerCase().contains('fish');
      }
      if (_selectedCategory == 'Snacks') {
        return meal.type == MealType.snack;
      }
      return true;
    }).toList();
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
              // Search input + notification header
              Row(
                children: [
                  // Text(
                  //   'Recipes',
                  //   style: GoogleFonts.outfit(
                  //     fontSize: 22,
                  //     fontWeight: FontWeight.bold,
                  //     color: theme.colorScheme.onSurface,
                  //   ),
                  // ),
                  
                  const SizedBox(width: 12),
                ],
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
                    final meal = filteredRecipes[index];
                    return _buildRecipeListCard(context, userProvider, meal)
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

  // High Fidelity Redesign of Featured Card
  Widget _buildFeaturedRecipeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title, Star, and Cook time row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _quinoaVeggieBowl.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${_quinoaVeggieBowl.prepTimeMinutes} min',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.star_rounded, color: Color(0xFFF79E74), size: 28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"Quinoa Veggie Bowl" is already saved!', style: GoogleFonts.outfit()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Large Round Crop Photo of Bowl
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MealDetailScreen(meal: _quinoaVeggieBowl)),
              );
            },
            child: Center(
              child: Hero(
                tag: 'meal_img_quinoa_veggie_bowl_featured',
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(85),
                    child: Image.asset(
                      _quinoaVeggieBowl.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Difficulty Indicators and Calories row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Difficulty Easy + 5 Blocks (4 filled, 1 grey)
              Row(
                children: [
                  Text(
                    'Easy',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Segmented Blocks
                  Row(
                    children: List.generate(5, (i) {
                      return Container(
                        width: 14,
                        height: 6,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: i < 4 ? const Color(0xFFF79E74) : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // Calories
              Text(
                '${_quinoaVeggieBowl.calories} kcal',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildRecipeListCard(BuildContext context, UserProvider provider, MealModel meal) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
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
                    '${meal.calories} kcal • ${meal.prepTimeMinutes} min',
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
                provider.addCustomMeal(meal);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${meal.name}" to your plan!', style: GoogleFonts.outfit()),
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
}
