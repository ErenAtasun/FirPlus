/// User model for storing user profile and calorie targets
class User {
  final String id;
  final String name;
  final String gender; // 'male' | 'female'
  final int age;
  final double height; // cm
  final double weight; // kg
  final int activityLevel; // 1-5 (sedentary to very active)
  final String goal; // 'lose' | 'maintain' | 'gain'
  final double targetCalories;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
    required this.targetCalories,
    required this.createdAt,
  });

  /// Copy with method for immutable updates
  User copyWith({
    String? id,
    String? name,
    String? gender,
    int? age,
    double? height,
    double? weight,
    int? activityLevel,
    String? goal,
    double? targetCalories,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      targetCalories: targetCalories ?? this.targetCalories,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'goal': goal,
      'targetCalories': targetCalories,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      gender: json['gender'] as String,
      age: json['age'] as int,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      activityLevel: json['activityLevel'] as int,
      goal: json['goal'] as String,
      targetCalories: (json['targetCalories'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
