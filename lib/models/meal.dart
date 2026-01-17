/// Meal model for storing individual meal entries
class Meal {
  final String id;
  final String name;
  final int calories;
  final String? photoPath;
  final String mealType; // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final DateTime timestamp;
  final bool isAiEstimated;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    this.photoPath,
    required this.mealType,
    required this.timestamp,
    this.isAiEstimated = false,
  });

  /// Copy with method for immutable updates
  Meal copyWith({
    String? id,
    String? name,
    int? calories,
    String? photoPath,
    String? mealType,
    DateTime? timestamp,
    bool? isAiEstimated,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      photoPath: photoPath ?? this.photoPath,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      isAiEstimated: isAiEstimated ?? this.isAiEstimated,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'photoPath': photoPath,
      'mealType': mealType,
      'timestamp': timestamp.toIso8601String(),
      'isAiEstimated': isAiEstimated,
    };
  }

  /// Create from JSON
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      photoPath: json['photoPath'] as String?,
      mealType: json['mealType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isAiEstimated: json['isAiEstimated'] as bool? ?? false,
    );
  }

  /// Get meal type display name in Turkish
  String get mealTypeDisplay {
    switch (mealType) {
      case 'breakfast':
        return 'Kahvaltı';
      case 'lunch':
        return 'Öğle Yemeği';
      case 'dinner':
        return 'Akşam Yemeği';
      case 'snack':
        return 'Atıştırmalık';
      default:
        return mealType;
    }
  }

  /// Get meal type icon
  String get mealTypeIcon {
    switch (mealType) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }
}
