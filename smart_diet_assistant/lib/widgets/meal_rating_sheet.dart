import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

Future<double?> showMealRatingSheet(BuildContext context, MealModel meal) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MealRatingSheet(meal: meal),
  );
}

class _MealRatingSheet extends StatefulWidget {
  final MealModel meal;

  const _MealRatingSheet({super.key, required this.meal});

  @override
  State<_MealRatingSheet> createState() => _MealRatingSheetState();
}

class _MealRatingSheetState extends State<_MealRatingSheet> {
  double _rating = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0).copyWith(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            'How was ${widget.meal.name}?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Rate your meal to improve your future recommendations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Text(
            _rating.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              trackHeight: 8.0,
            ),
            child: Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 40, // 0.1 increments
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _rating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Submit Rating',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, duration: 400.ms),
        ],
      ),
    );
  }
}
