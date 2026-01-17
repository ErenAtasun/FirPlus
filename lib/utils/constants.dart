/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'DietTracker';
  static const String appVersion = '1.0.0';

  // Calorie Tolerance (±10% of target)
  static const double calorieTolerancePercent = 0.10;

  // Streak Settings
  static const int daysForCheatReward = 14;
  static const int maxCheatDayExcessPercent =
      50; // Max 50% over target for cheat day

  // Default Values
  static const double defaultHeight = 170.0;
  static const double defaultWeight = 70.0;
  static const int defaultAge = 25;
  static const int defaultActivityLevel = 2;
  static const String defaultGoal = 'maintain';
  static const String defaultGender = 'male';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
}

/// Meal type enum helper
class MealTypes {
  static const String breakfast = 'breakfast';
  static const String lunch = 'lunch';
  static const String dinner = 'dinner';
  static const String snack = 'snack';

  static const List<String> all = [breakfast, lunch, dinner, snack];

  static String getDisplayName(String type) {
    switch (type) {
      case breakfast:
        return 'Kahvaltı';
      case lunch:
        return 'Öğle Yemeği';
      case dinner:
        return 'Akşam Yemeği';
      case snack:
        return 'Atıştırmalık';
      default:
        return type;
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case breakfast:
        return '🌅';
      case lunch:
        return '☀️';
      case dinner:
        return '🌙';
      case snack:
        return '🍎';
      default:
        return '🍽️';
    }
  }
}

/// Goal type helper
class GoalTypes {
  static const String lose = 'lose';
  static const String maintain = 'maintain';
  static const String gain = 'gain';

  static String getDisplayName(String goal) {
    switch (goal) {
      case lose:
        return 'Kilo Vermek';
      case maintain:
        return 'Kiloyu Korumak';
      case gain:
        return 'Kilo Almak';
      default:
        return goal;
    }
  }

  static String getDescription(String goal) {
    switch (goal) {
      case lose:
        return 'Günlük -500 kalori açığı';
      case maintain:
        return 'Mevcut kalorinizi koruyun';
      case gain:
        return 'Günlük +500 kalori fazlası';
      default:
        return '';
    }
  }
}
