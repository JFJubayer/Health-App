import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/user_provider.dart';

Future<void> showMealPickerSheet(
  BuildContext context,
  String mealId, {
  MealType? mealType,
  bool popRouteOnSelect = false,
  void Function(String newMealId)? onMealSelected,
}) async {
  final provider = Provider.of<UserProvider>(context, listen: false);
  final alternatives = await provider.getMealAlternativesFor(mealId, mealType: mealType);

  if (!context.mounted) return;

  if (alternatives.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No alternative meals available for this slot.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _MealPickerSheetContent(
            alternatives: alternatives,
            mealId: mealId,
            popRouteOnSelect: popRouteOnSelect,
            onMealSelected: onMealSelected,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _MealPickerSheetContent extends StatefulWidget {
  final List<MealModel> alternatives;
  final String mealId;
  final bool popRouteOnSelect;
  final void Function(String newMealId)? onMealSelected;
  final ScrollController scrollController;

  const _MealPickerSheetContent({
    required this.alternatives,
    required this.mealId,
    required this.popRouteOnSelect,
    required this.onMealSelected,
    required this.scrollController,
  });

  @override
  State<_MealPickerSheetContent> createState() => _MealPickerSheetContentState();
}

class _MealPickerSheetContentState extends State<_MealPickerSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<UserProvider>(context, listen: false);

    final filteredMeals = widget.alternatives.where((meal) {
      if (_searchQuery.isEmpty) return true;
      final nameLower = meal.name.toLowerCase();
      final tagLower = (meal.tags ?? []).join(' ').toLowerCase();
      final ingLower = meal.ingredients.join(' ').toLowerCase();
      return nameLower.contains(_searchQuery) ||
          tagLower.contains(_searchQuery) ||
          ingLower.contains(_searchQuery);
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Replacement',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${filteredMeals.length} dishes available to swap',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search dishes or ingredients...',
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: colorScheme.onSurfaceVariant),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meals List
          Expanded(
            child: filteredMeals.isNotEmpty
                ? ListView.builder(
                    controller: widget.scrollController,
                    itemCount: filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = filteredMeals[index];
                      return _MealOptionCard(
                        meal: meal,
                        onTap: () {
                          if (widget.onMealSelected != null) {
                            widget.onMealSelected!(meal.id);
                          } else {
                            provider.replaceMeal(
                              widget.mealId,
                              selectedTemplateId: meal.id,
                            );
                          }
                          Navigator.pop(context);
                          if (widget.popRouteOnSelect && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No matching dishes found',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MealOptionCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onTap;

  const _MealOptionCard({
    required this.meal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food icon / avatar indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.calories} kcal · ${meal.prepTimeMinutes} min',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P ${meal.protein.toStringAsFixed(0)}g · C ${meal.carbs.toStringAsFixed(0)}g · F ${meal.fat.toStringAsFixed(0)}g',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (meal.instructions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meal.instructions.split('\n').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.swap_horiz_rounded, color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
