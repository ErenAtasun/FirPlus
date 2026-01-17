import '../models/user.dart';

/// Service for calculating BMR and TDEE using Mifflin-St Jeor formula
class CalorieService {
  /// Activity level multipliers
  static const Map<int, double> activityMultipliers = {
    1: 1.2, // Sedentary (little or no exercise)
    2: 1.375, // Lightly active (light exercise 1-3 days/week)
    3: 1.55, // Moderately active (moderate exercise 3-5 days/week)
    4: 1.725, // Very active (hard exercise 6-7 days/week)
    5: 1.9, // Extra active (very hard exercise, physical job)
  };

  /// Calculate BMR using Mifflin-St Jeor formula
  /// Male: BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
  /// Female: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161
  static double calculateBMR({
    required String gender,
    required double weight,
    required double height,
    required int age,
  }) {
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);

    if (gender == 'male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    return bmr;
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  static double calculateTDEE({
    required double bmr,
    required int activityLevel,
  }) {
    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  /// Calculate target calories based on goal
  /// Lose: TDEE - 500 calories
  /// Maintain: TDEE
  /// Gain: TDEE + 500 calories
  static double calculateTargetCalories({
    required double tdee,
    required String goal,
  }) {
    switch (goal) {
      case 'lose':
        return tdee - 500;
      case 'gain':
        return tdee + 500;
      case 'maintain':
      default:
        return tdee;
    }
  }

  /// Calculate all values and return target calories
  static double getTargetCalories({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required int activityLevel,
    required String goal,
  }) {
    final bmr = calculateBMR(
      gender: gender,
      weight: weight,
      height: height,
      age: age,
    );

    final tdee = calculateTDEE(
      bmr: bmr,
      activityLevel: activityLevel,
    );

    return calculateTargetCalories(
      tdee: tdee,
      goal: goal,
    );
  }

  /// Get activity level description in Turkish
  static String getActivityLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Hareketsiz (Masa başı iş, egzersiz yok)';
      case 2:
        return 'Az Hareketli (Hafif egzersiz, haftada 1-3 gün)';
      case 3:
        return 'Orta Hareketli (Orta düzey egzersiz, haftada 3-5 gün)';
      case 4:
        return 'Çok Hareketli (Yoğun egzersiz, haftada 6-7 gün)';
      case 5:
        return 'Ekstra Aktif (Çok yoğun egzersiz veya fiziksel iş)';
      default:
        return 'Bilinmiyor';
    }
  }

  /// Get goal description in Turkish
  static String getGoalDescription(String goal) {
    switch (goal) {
      case 'lose':
        return 'Kilo Vermek';
      case 'maintain':
        return 'Kiloyu Korumak';
      case 'gain':
        return 'Kilo Almak';
      default:
        return goal;
    }
  }
}
