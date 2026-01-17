import 'meal.dart';

/// Daily record model for storing a day's meals and status
class DailyRecord {
  final String id;
  final DateTime date;
  final List<Meal> meals;
  final bool usedCheatDay;

  DailyRecord({
    required this.id,
    required this.date,
    required this.meals,
    this.usedCheatDay = false,
  });

  /// Calculate total calories for the day
  int get totalCalories {
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  /// Get day status based on target calories
  String getStatus(double targetCalories) {
    if (usedCheatDay) return 'cheat';
    if (meals.isEmpty) return 'empty';
    if (totalCalories <= targetCalories) return 'success';
    return 'exceeded';
  }

  /// Copy with method for immutable updates
  DailyRecord copyWith({
    String? id,
    DateTime? date,
    List<Meal>? meals,
    bool? usedCheatDay,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      usedCheatDay: usedCheatDay ?? this.usedCheatDay,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'usedCheatDay': usedCheatDay,
    };
  }

  /// Create from JSON
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((m) => Meal.fromJson(m as Map<String, dynamic>))
          .toList(),
      usedCheatDay: json['usedCheatDay'] as bool? ?? false,
    );
  }

  /// Create a new empty record for a date
  factory DailyRecord.empty(DateTime date) {
    return DailyRecord(
      id: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      date: DateTime(date.year, date.month, date.day),
      meals: [],
    );
  }
}
