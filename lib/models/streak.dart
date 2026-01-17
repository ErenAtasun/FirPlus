/// Streak model for tracking consecutive successful days
class Streak {
  final int currentStreak;
  final int longestStreak;
  final int cheatDaysEarned;
  final int cheatDaysUsed;
  final DateTime? lastSuccessDate;

  Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.cheatDaysEarned = 0,
    this.cheatDaysUsed = 0,
    this.lastSuccessDate,
  });

  /// Calculate available cheat days
  int get availableCheatDays => cheatDaysEarned - cheatDaysUsed;

  /// Check if user can use a cheat day
  bool get canUseCheatDay => availableCheatDays > 0;

  /// Copy with method for immutable updates
  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    int? cheatDaysEarned,
    int? cheatDaysUsed,
    DateTime? lastSuccessDate,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      cheatDaysEarned: cheatDaysEarned ?? this.cheatDaysEarned,
      cheatDaysUsed: cheatDaysUsed ?? this.cheatDaysUsed,
      lastSuccessDate: lastSuccessDate ?? this.lastSuccessDate,
    );
  }

  /// Increment streak (called when a day is successful)
  Streak incrementStreak() {
    final newStreak = currentStreak + 1;
    final newCheatDays = newStreak > 0 && newStreak % 14 == 0
        ? cheatDaysEarned + 1
        : cheatDaysEarned;

    return copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      cheatDaysEarned: newCheatDays,
      lastSuccessDate: DateTime.now(),
    );
  }

  /// Reset streak (called when a day fails without cheat day)
  Streak resetStreak() {
    return copyWith(
      currentStreak: 0,
      lastSuccessDate: null,
    );
  }

  /// Use a cheat day
  Streak useCheatDay() {
    if (!canUseCheatDay) return this;
    return copyWith(
      cheatDaysUsed: cheatDaysUsed + 1,
      lastSuccessDate: DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'cheatDaysEarned': cheatDaysEarned,
      'cheatDaysUsed': cheatDaysUsed,
      'lastSuccessDate': lastSuccessDate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      cheatDaysEarned: json['cheatDaysEarned'] as int? ?? 0,
      cheatDaysUsed: json['cheatDaysUsed'] as int? ?? 0,
      lastSuccessDate: json['lastSuccessDate'] != null
          ? DateTime.parse(json['lastSuccessDate'] as String)
          : null,
    );
  }
}
