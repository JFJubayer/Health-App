import 'package:flutter_test/flutter_test.dart';

import 'package:smart_diet_assistant/models/meal_model.dart';

void main() {
  test('MealModel persists prepTimeMinutes in map', () {
    final meal = MealModel(
      id: 'test_1',
      name: 'Test Meal',
      calories: 400,
      type: MealType.lunch,
      prepTimeMinutes: 25,
    );

    final restored = MealModel.fromMap(meal.toMap());
    expect(restored.prepTimeMinutes, 25);
  });
}
