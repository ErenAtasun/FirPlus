import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/daily_record.dart';
import '../models/streak.dart';
import '../models/meal.dart';
import '../services/database_service.dart';
import '../services/calorie_service.dart';
import '../utils/constants.dart';

/// Main app provider for global state management
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  User? _user;
  Streak _streak = Streak();
  List<DailyRecord> _records = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  // Getters
  User? get user => _user;
  Streak get streak => _streak;
  List<DailyRecord> get records => _records;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _user != null;

  /// Get today's record
  DailyRecord? get todayRecord {
    final today = DateTime.now();
    return getRecordForDate(today);
  }

  /// Get record for selected date
  DailyRecord? get selectedDayRecord => getRecordForDate(_selectedDate);

  /// Initialize the provider
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _db.init();
    _loadData();

    _isLoading = false;
    notifyListeners();
  }

  /// Load all data from database
  void _loadData() {
    _user = _db.getUser();
    _streak = _db.getStreak();
    _records = _db.getRecords();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // ==================== User Operations ====================

  /// Create user profile (during onboarding)
  Future<void> createUser({
    required String name,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required int activityLevel,
    required String goal,
  }) async {
    final targetCalories = CalorieService.getTargetCalories(
      gender: gender,
      weight: weight,
      height: height,
      age: age,
      activityLevel: activityLevel,
      goal: goal,
    );

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goal: goal,
      targetCalories: targetCalories,
      createdAt: DateTime.now(),
    );

    await _db.saveUser(user);
    _user = user;
    notifyListeners();
  }

  /// Update user profile
  Future<void> updateUser(User updatedUser) async {
    await _db.saveUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  // ==================== Meal Operations ====================

  /// Add meal to a specific date
  Future<void> addMeal({
    required String name,
    required int calories,
    required String mealType,
    String? photoPath,
    bool isAiEstimated = false,
    DateTime? date,
  }) async {
    final targetDate = date ?? _selectedDate;

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      calories: calories,
      mealType: mealType,
      timestamp: DateTime.now(),
      photoPath: photoPath,
      isAiEstimated: isAiEstimated,
    );

    final updatedRecord = await _db.addMealToDate(targetDate, meal);
    _updateRecordInList(updatedRecord);

    // Check streak after adding meal
    await _checkAndUpdateStreak(targetDate);

    notifyListeners();
  }

  /// Delete meal
  Future<void> deleteMeal(DateTime date, String mealId) async {
    final updatedRecord = await _db.deleteMealFromDate(date, mealId);
    if (updatedRecord != null) {
      _updateRecordInList(updatedRecord);
      notifyListeners();
    }
  }

  /// Update record in local list
  void _updateRecordInList(DailyRecord record) {
    final dateOnly =
        DateTime(record.date.year, record.date.month, record.date.day);
    final existingIndex = _records.indexWhere(
      (r) => DateTime(r.date.year, r.date.month, r.date.day) == dateOnly,
    );

    if (existingIndex >= 0) {
      _records[existingIndex] = record;
    } else {
      _records.add(record);
    }
  }

  // ==================== Record Operations ====================

  /// Get record for a specific date
  DailyRecord? getRecordForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    try {
      return _records.firstWhere(
        (r) => DateTime(r.date.year, r.date.month, r.date.day) == dateOnly,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get day status for calendar coloring
  String getDayStatus(DateTime date) {
    if (_user == null) return 'empty';

    final record = getRecordForDate(date);
    if (record == null) return 'empty';

    return record.getStatus(_user!.targetCalories);
  }

  /// Get remaining calories for today
  int get remainingCalories {
    if (_user == null) return 0;
    final record = todayRecord;
    final consumed = record?.totalCalories ?? 0;
    return (_user!.targetCalories - consumed).round();
  }

  /// Get consumed calories for today
  int get consumedCalories {
    final record = todayRecord;
    return record?.totalCalories ?? 0;
  }

  // ==================== Streak Operations ====================

  /// Check and update streak based on day performance
  Future<void> _checkAndUpdateStreak(DateTime date) async {
    if (_user == null) return;

    final record = getRecordForDate(date);
    if (record == null) return;

    final status = record.getStatus(_user!.targetCalories);

    if (status == 'success' || status == 'cheat') {
      // Check if this is a consecutive day
      final yesterday = date.subtract(const Duration(days: 1));
      final lastSuccess = _streak.lastSuccessDate;

      if (lastSuccess == null ||
          DateTime(lastSuccess.year, lastSuccess.month, lastSuccess.day) ==
              DateTime(yesterday.year, yesterday.month, yesterday.day)) {
        _streak = _streak.incrementStreak();
      }
    }

    await _db.saveStreak(_streak);
  }

  /// Use cheat day for a specific date
  Future<bool> useCheatDay(DateTime date) async {
    if (!_streak.canUseCheatDay) return false;

    var record = getRecordForDate(date);
    if (record == null) {
      record = DailyRecord.empty(date);
    }

    final updatedRecord = record.copyWith(usedCheatDay: true);
    await _db.saveRecord(updatedRecord);
    _updateRecordInList(updatedRecord);

    _streak = _streak.useCheatDay();
    await _db.saveStreak(_streak);

    notifyListeners();
    return true;
  }

  // ==================== Utility Operations ====================

  /// Reset all data
  Future<void> resetAll() async {
    await _db.clearAll();
    _user = null;
    _streak = Streak();
    _records = [];
    notifyListeners();
  }
}
