import 'package:flutter_test/flutter_test.dart';
import 'package:smart_diet_assistant/models/user_model.dart';
import 'package:smart_diet_assistant/models/macro_targets.dart';
import 'package:smart_diet_assistant/services/health_service.dart';

void main() {
  group('Weight Management BMI Calculations', () {
    test('calculateBMI returns correct BMI', () {
      final bmi = HealthService.calculateBMI(70.0, 175.0);
      expect(bmi, closeTo(22.86, 0.01));
    });

    test('getBMICategory handles all classes correctly', () {
      expect(HealthService.getBMICategory(17.0), 'Underweight');
      expect(HealthService.getBMICategory(22.0), 'Normal Weight');
      expect(HealthService.getBMICategory(27.0), 'Overweight');
      expect(HealthService.getBMICategory(32.0), 'Obesity');
    });

    test('isHighBmi detects high BMI', () {
      expect(HealthService.isHighBmi(70.0, 175.0), false); // BMI ~22.8
      expect(HealthService.isHighBmi(90.0, 175.0), true);  // BMI ~29.4
    });
  });

  group('Calorie deficit and clamping logic', () {
    test('calculateCalorieTarget returns TDEE for normal BMI', () {
      final user = UserModel(
        name: 'Normal User',
        age: 30,
        gender: 'Male',
        heightCm: 175.0,
        weightKg: 70.0, // BMI ~22.86
      );

      final bmr = HealthService.calculateBMR(user);
      final tdee = HealthService.calculateTDEE(bmr);
      final target = HealthService.calculateCalorieTarget(user);

      expect(target, tdee);
    });

    test('calculateCalorieTarget applies deficit for high BMI user', () {
      final user = UserModel(
        name: 'Overweight User',
        age: 30,
        gender: 'Male',
        heightCm: 175.0,
        weightKg: 90.0, // BMI ~29.38
        weightManagementEnabled: true,
        weightDeficitCal: 500.0,
      );

      final bmr = HealthService.calculateBMR(user);
      final tdee = HealthService.calculateTDEE(bmr);
      final target = HealthService.calculateCalorieTarget(user);

      expect(target, tdee - 500.0);
    });

    test('calculateCalorieTarget clamps to safe minimum for males (1500 kcal)', () {
      // Create user whose TDEE is ~1925, deficit is 500, target would be ~1425 (clamped to 1500)
      final user = UserModel(
        name: 'Overweight Male',
        age: 60,
        gender: 'Male',
        heightCm: 150.0,
        weightKg: 60.0, // BMI ~26.6
        weightManagementEnabled: true,
        weightDeficitCal: 500.0,
      );

      final target = HealthService.calculateCalorieTarget(user);
      expect(target, 1500.0);
    });

    test('calculateCalorieTarget clamps to safe minimum for females (1200 kcal)', () {
      // Create user whose TDEE is ~1494, deficit is 500, target would be ~994 (clamped to 1200)
      final user = UserModel(
        name: 'Overweight Female',
        age: 60,
        gender: 'Female',
        heightCm: 140.0,
        weightKg: 55.0, // BMI ~28.0
        weightManagementEnabled: true,
        weightDeficitCal: 500.0,
      );

      final target = HealthService.calculateCalorieTarget(user);
      expect(target, 1200.0);
    });

    test('calculateCalorieTarget returns TDEE if TDEE is already below safe minimum', () {
      // Create male user with low BMR/TDEE (~1247 kcal)
      final user = UserModel(
        name: 'Low TDEE Male',
        age: 80,
        gender: 'Male',
        heightCm: 120.0,
        weightKg: 45.0,
        weightManagementEnabled: true,
        weightDeficitCal: 500.0,
      );

      final bmr = HealthService.calculateBMR(user);
      final tdee = HealthService.calculateTDEE(bmr);
      final target = HealthService.calculateCalorieTarget(user);

      expect(target, tdee);
    });

    test('calculateCalorieTarget skips deficit if weightManagementEnabled is false', () {
      final user = UserModel(
        name: 'Opt-out User',
        age: 30,
        gender: 'Male',
        heightCm: 175.0,
        weightKg: 90.0, // BMI ~29.38
        weightManagementEnabled: false,
        weightDeficitCal: 500.0,
      );

      final bmr = HealthService.calculateBMR(user);
      final tdee = HealthService.calculateTDEE(bmr);
      final target = HealthService.calculateCalorieTarget(user);

      expect(target, tdee);
    });
  });

  group('Weight Management Macro Targets', () {
    test('MacroTargets.weightManagement uses 35/35/30 ratio', () {
      final macros = MacroTargets.weightManagement(2000.0);

      // Protein: 35% of 2000 = 700 kcal / 4 = 175g
      expect(macros.proteinGrams, 175.0);

      // Carbs: 35% of 2000 = 700 kcal / 4 = 175g
      expect(macros.carbsGrams, 175.0);

      // Fat: 30% of 2000 = 600 kcal / 9 = 66.67g
      expect(macros.fatGrams, closeTo(66.67, 0.01));
    });
  });
}
