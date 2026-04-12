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
}
