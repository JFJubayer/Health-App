import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/user_provider.dart';

Future<void> showMealPickerSheet(
  BuildContext context,
  String mealId, {
  bool popRouteOnSelect = false,
  void Function(String newMealId)? onMealSelected,
}) async {
  final provider = Provider.of<UserProvider>(context, listen: false);
  final alternatives = await provider.getMealAlternativesFor(mealId);

  if (!context.mounted) return;

  if (alternatives.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No alternative meals available.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(sheetContext).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a Replacement',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick one of these top matches for your plan',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...alternatives.map(
              (meal) => _MealOptionCard(
                meal: meal,
                onTap: () {
                  if (onMealSelected != null) {
                    onMealSelected(meal.id);
                  } else {
                    provider.replaceMeal(
                      mealId,
                      selectedTemplateId: meal.id,
                    );
                  }
                  Navigator.pop(sheetContext);
                  if (popRouteOnSelect && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
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
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.calories} kcal · ${meal.prepTimeMinutes} min',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
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
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
