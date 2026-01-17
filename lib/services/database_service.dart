import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/daily_record.dart';
import '../models/streak.dart';
import '../models/meal.dart';

/// Service for handling local data storage using SharedPreferences
class DatabaseService {
  static const String _userKey = 'user_data';
  static const String _recordsKey = 'daily_records';
  static const String _streakKey = 'streak_data';

  SharedPreferences? _prefs;

  /// Initialize the database service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('DatabaseService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== User Operations ====================

  /// Save user data
  Future<void> saveUser(User user) async {
    final jsonString = jsonEncode(user.toJson());
    await prefs.setString(_userKey, jsonString);
  }

  /// Get user data
  User? getUser() {
    final jsonString = prefs.getString(_userKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Check if user exists
  bool hasUser() {
    return prefs.containsKey(_userKey);
  }

  /// Delete user data
  Future<void> deleteUser() async {
    await prefs.remove(_userKey);
  }

  // ==================== Daily Records Operations ====================

  /// Save all daily records
  Future<void> saveRecords(List<DailyRecord> records) async {
    final jsonList = records.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_recordsKey, jsonString);
  }

  /// Get all daily records
  List<DailyRecord> getRecords() {
    final jsonString = prefs.getString(_recordsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => DailyRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get record for a specific date
  DailyRecord? getRecordForDate(DateTime date) {
    final records = getRecords();
    final dateOnly = DateTime(date.year, date.month, date.day);

    try {
      return records.firstWhere(
        (r) => DateTime(r.date.year, r.date.month, r.date.day) == dateOnly,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save or update a single record
  Future<void> saveRecord(DailyRecord record) async {
    final records = getRecords();
    final dateOnly =
        DateTime(record.date.year, record.date.month, record.date.day);

    final existingIndex = records.indexWhere(
      (r) => DateTime(r.date.year, r.date.month, r.date.day) == dateOnly,
    );

    if (existingIndex >= 0) {
      records[existingIndex] = record;
    } else {
      records.add(record);
    }

    await saveRecords(records);
  }

  /// Add meal to a specific date
  Future<DailyRecord> addMealToDate(DateTime date, Meal meal) async {
    var record = getRecordForDate(date);

    if (record == null) {
      record = DailyRecord.empty(date);
    }

    final updatedMeals = [...record.meals, meal];
    final updatedRecord = record.copyWith(meals: updatedMeals);

    await saveRecord(updatedRecord);
    return updatedRecord;
  }

  /// Delete meal from a date
  Future<DailyRecord?> deleteMealFromDate(DateTime date, String mealId) async {
    var record = getRecordForDate(date);
    if (record == null) return null;

    final updatedMeals = record.meals.where((m) => m.id != mealId).toList();
    final updatedRecord = record.copyWith(meals: updatedMeals);

    await saveRecord(updatedRecord);
    return updatedRecord;
  }

  // ==================== Streak Operations ====================

  /// Save streak data
  Future<void> saveStreak(Streak streak) async {
    final jsonString = jsonEncode(streak.toJson());
    await prefs.setString(_streakKey, jsonString);
  }

  /// Get streak data
  Streak getStreak() {
    final jsonString = prefs.getString(_streakKey);
    if (jsonString == null) return Streak();

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Streak.fromJson(json);
    } catch (e) {
      return Streak();
    }
  }

  // ==================== Utility Operations ====================

  /// Clear all data
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
