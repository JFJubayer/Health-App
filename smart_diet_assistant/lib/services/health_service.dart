import '../models/user_model.dart';

class HealthService {
  /// Calculates BMR using the Mifflin-St Jeor Equation
  static double calculateBMR(UserModel user) {
    double bmr;
    if (user.gender == 'Male') {
      bmr = (10 * user.weightKg) + (6.25 * user.heightCm) - (5 * user.age) + 5;
    } else {
      bmr = (10 * user.weightKg) + (6.25 * user.heightCm) - (5 * user.age) - 161;
    }
    return bmr;
  }

  /// Calculates TDEE based on moderate activity level
  static double calculateTDEE(double bmr) {
    return bmr * 1.55;
  }

  /// Calculates Body Mass Index (BMI)
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm == 0) return 0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Returns BMI category based on WHO standards
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi >= 18.5 && bmi < 25) return 'Normal Weight';
    if (bmi >= 25 && bmi < 30) return 'Overweight';
    return 'Obesity';
  }
}
