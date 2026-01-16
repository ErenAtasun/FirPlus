import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../models/meal_entry.dart';
import '../models/weight_entry.dart';
import '../core/constants/app_constants.dart';

/// Veritabanı servisi
/// Hive ile tüm CRUD işlemlerini yönetir
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  late Box<UserProfile> _userProfileBox;
  late Box<DailyLog> _dailyLogBox;
  late Box<MealEntry> _mealEntryBox;
  late Box<WeightEntry> _weightEntryBox;

  bool _isInitialized = false;

  /// Veritabanını başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web'de main.dart'ta zaten başlatıldı, diğer platformlarda burada başlat
    if (!kIsWeb) {
      await Hive.initFlutter();
    }

    // Adapter'ları kaydet
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailyLogAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WeightEntryAdapter());
    }

    // Box'ları aç
    _userProfileBox = await Hive.openBox<UserProfile>(AppConstants.userProfileBox);
    _dailyLogBox = await Hive.openBox<DailyLog>(AppConstants.dailyLogBox);
    _mealEntryBox = await Hive.openBox<MealEntry>(AppConstants.mealEntryBox);
    _weightEntryBox = await Hive.openBox<WeightEntry>(AppConstants.weightEntryBox);

    _isInitialized = true;
  }

  // ==================== USER PROFILE ====================

  /// Kullanıcı profili var mı?
  bool hasUserProfile() {
    return _userProfileBox.isNotEmpty;
  }

  /// Kullanıcı profilini getir
  UserProfile? getUserProfile() {
    if (_userProfileBox.isEmpty) return null;
    return _userProfileBox.values.first;
  }

  /// Kullanıcı profilini kaydet
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userProfileBox.clear();
    await _userProfileBox.put(profile.id, profile);
  }

  /// Kullanıcı profilini güncelle
  Future<void> updateUserProfile(UserProfile profile) async {
    await _userProfileBox.put(profile.id, profile);
  }

  // ==================== DAILY LOG ====================

  /// Belirli bir tarihin günlük kaydını getir
  DailyLog? getDailyLog(DateTime date) {
    final dateKey = _getDateKey(date);
    try {
      return _dailyLogBox.values.firstWhere(
        (log) => log.dateKey == dateKey,
      );
    } catch (e) {
      return null;
    }
  }

  /// Bugünün günlük kaydını getir (yoksa oluştur)
  Future<DailyLog> getOrCreateTodayLog(int targetCalories) async {
    final today = DateTime.now();
    DailyLog? log = getDailyLog(today);

    if (log == null) {
      log = DailyLog(
        id: _generateId(),
        date: DateTime(today.year, today.month, today.day),
        targetCalories: targetCalories,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dailyLogBox.put(log.id, log);
    }

    return log;
  }

  /// Günlük kaydı kaydet
  Future<void> saveDailyLog(DailyLog log) async {
    await _dailyLogBox.put(log.id, log);
  }

  /// Tarih aralığındaki günlük kayıtları getir
  List<DailyLog> getDailyLogs({DateTime? startDate, DateTime? endDate}) {
    var logs = _dailyLogBox.values.toList();

    if (startDate != null) {
      logs = logs.where((log) => !log.date.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      logs = logs.where((log) => !log.date.isAfter(endDate)).toList();
    }

    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  /// Ay için günlük kayıtları getir
  List<DailyLog> getMonthLogs(int year, int month) {
    return _dailyLogBox.values.where((log) {
      return log.date.year == year && log.date.month == month;
    }).toList();
  }

  // ==================== MEAL ENTRY ====================

  /// Yemek girişi ekle
  Future<MealEntry> addMealEntry(MealEntry entry) async {
    await _mealEntryBox.put(entry.id, entry);

    // Günlük kaydı güncelle
    DailyLog? log = getDailyLog(
      DateTime.parse(entry.dailyLogId.split('_').take(3).join('-')),
    );
    if (log == null) {
      // dailyLogId'den tarihi çıkar
      final parts = entry.dailyLogId.split('_');
      if (parts.length >= 3) {
        final profile = getUserProfile();
        if (profile != null) {
          log = await getOrCreateTodayLog(profile.targetCalories);
        }
      }
    }

    if (log != null) {
      log.mealEntryIds.add(entry.id);
      log.totalCalories += entry.calories;
      log.updateStatus();
      await saveDailyLog(log);
    }

    return entry;
  }

  /// Günlük kayda ait yemek girişlerini getir
  List<MealEntry> getMealEntries(String dailyLogId) {
    return _mealEntryBox.values
        .where((entry) => entry.dailyLogId == dailyLogId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Yemek girişini güncelle
  Future<void> updateMealEntry(MealEntry entry, int oldCalories) async {
    await _mealEntryBox.put(entry.id, entry);

    // Günlük kaydı güncelle
    DailyLog? log;
    try {
      log = _dailyLogBox.values.firstWhere(
        (l) => l.mealEntryIds.contains(entry.id),
      );
    } catch (e) {
      log = null;
    }

    if (log != null) {
      log.totalCalories = log.totalCalories - oldCalories + entry.calories;
      log.updateStatus();
      await saveDailyLog(log);
    }
  }

  /// Yemek girişini sil
  Future<void> deleteMealEntry(String entryId) async {
    final entry = _mealEntryBox.get(entryId);
    if (entry == null) return;

    // Günlük kayıttan çıkar
    DailyLog? log;
    try {
      log = _dailyLogBox.values.firstWhere(
        (l) => l.mealEntryIds.contains(entryId),
      );
    } catch (e) {
      log = null;
    }

    if (log != null) {
      log.mealEntryIds.remove(entryId);
      log.totalCalories -= entry.calories;
      log.updateStatus();
      await saveDailyLog(log);
    }

    await _mealEntryBox.delete(entryId);
  }

  /// Öğün türüne göre yemek girişlerini getir
  List<MealEntry> getMealEntriesByType(String dailyLogId, String mealType) {
    return getMealEntries(dailyLogId)
        .where((entry) => entry.mealType == mealType)
        .toList();
  }

  // ==================== WEIGHT ENTRY ====================

  /// Kilo girişi ekle
  Future<WeightEntry> addWeightEntry(WeightEntry entry) async {
    await _weightEntryBox.put(entry.id, entry);
    return entry;
  }

  /// Tüm kilo girişlerini getir (tarihe göre sıralı)
  List<WeightEntry> getWeightEntries() {
    final entries = _weightEntryBox.values.toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  /// Son N kilo girişini getir
  List<WeightEntry> getRecentWeightEntries(int count) {
    final entries = getWeightEntries();
    if (entries.length <= count) return entries;
    return entries.sublist(entries.length - count);
  }

  /// Son kilo girişini getir
  WeightEntry? getLatestWeightEntry() {
    final entries = getWeightEntries();
    if (entries.isEmpty) return null;
    return entries.last;
  }

  /// Kilo girişini sil
  Future<void> deleteWeightEntry(String entryId) async {
    await _weightEntryBox.delete(entryId);
  }

  /// Kilo girişini güncelle
  Future<void> updateWeightEntry(WeightEntry entry) async {
    await _weightEntryBox.put(entry.id, entry);
  }

  // ==================== STATISTICS ====================

  /// Haftalık istatistikleri getir
  Map<String, dynamic> getWeeklyStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final logs = getDailyLogs(
      startDate: weekStart,
      endDate: now,
    );

    if (logs.isEmpty) {
      return {
        'averageCalories': 0,
        'totalCalories': 0,
        'daysLogged': 0,
        'greenDays': 0,
        'redDays': 0,
      };
    }

    int totalCalories = 0;
    int greenDays = 0;
    int redDays = 0;

    for (var log in logs) {
      totalCalories += log.totalCalories;
      if (log.status == 'GREEN') greenDays++;
      if (log.status == 'RED') redDays++;
    }

    return {
      'averageCalories': (totalCalories / logs.length).round(),
      'totalCalories': totalCalories,
      'daysLogged': logs.length,
      'greenDays': greenDays,
      'redDays': redDays,
    };
  }

  // ==================== HELPERS ====================

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Tüm verileri temizle (debug için)
  Future<void> clearAllData() async {
    await _userProfileBox.clear();
    await _dailyLogBox.clear();
    await _mealEntryBox.clear();
    await _weightEntryBox.clear();
  }
}
