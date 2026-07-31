import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/user_provider.dart';

Future<MealType?> showMealSlotPickerSheet({
  required BuildContext context,
  required MealModel meal,
  List<MealType>? availableTypes,
}) async {
  final provider = Provider.of<UserProvider>(context, listen: false);

  final List<MealType> options = (availableTypes != null && availableTypes.isNotEmpty)
      ? availableTypes
      : [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack];

  final theme = Theme.of(context);

  return await showModalBottomSheet<MealType>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: theme.scaffoldBackgroundColor,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              'Add to Daily Plan',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select meal time for "${meal.name}"',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Simple Meal Slot Options
            ...MealType.values.map((type) {
              final isRecommended = options.contains(type);
              return _buildSimpleSlotOptionTile(
                context: sheetContext,
                type: type,
                isRecommended: isRecommended,
                showBadge: options.length < 4 && isRecommended,
                onTap: () {
                  provider.addMealToPlan(meal, type);
                  Navigator.pop(sheetContext, type);

                  final slotName = _getMealTypeName(type);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added "${meal.name}" as $slotName to your plan!',
                        style: GoogleFonts.outfit(),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

Widget _buildSimpleSlotOptionTile({
  required BuildContext context,
  required MealType type,
  required bool isRecommended,
  required bool showBadge,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final label = _getMealTypeName(type);
  final primaryColor = theme.colorScheme.primary;

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: isDark ? theme.colorScheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isRecommended
            ? primaryColor.withValues(alpha: 0.5)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        width: isRecommended ? 1.5 : 1,
      ),
    ),
    child: ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Option',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          Icon(Icons.add_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
        ],
      ),
    ),
  );
}

String _getMealTypeName(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'Breakfast';
    case MealType.lunch:
      return 'Lunch';
    case MealType.dinner:
      return 'Dinner';
    case MealType.snack:
      return 'Snack';
  }
}
