import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null || userProvider.mealPlan.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meals')),
        body: const Center(child: Text('No meal plan available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate New Plan',
            onPressed: () {
              userProvider.regenerateMeals();
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: userProvider.mealPlan.length,
        itemBuilder: (context, index) {
          final meal = userProvider.mealPlan[index];
          return _buildMealDetailCard(meal);
        },
      ),
    );
  }

  Widget _buildMealDetailCard(MealModel meal) {
    IconData icon;
    Color color;

    if (meal.type == MealType.breakfast) {
      icon = Icons.free_breakfast;
      color = Colors.orange;
    } else if (meal.type == MealType.lunch) {
      icon = Icons.lunch_dining;
      color = Colors.green;
    } else {
      icon = Icons.dinner_dining;
      color = Colors.purple;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  meal.type.name.toUpperCase(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${meal.calories} kcal',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              meal.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'A perfectly balanced meal using local ingredients carefully selected for your ${meal.type.name}.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Provider.of<UserProvider>(context, listen: false).replaceMeal(meal);
                  },
                  icon: Icon(Icons.swap_horiz, color: color),
                  label: Text('Swap', style: TextStyle(color: color)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
