import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../models/meal_entry.dart';
import '../models/weight_entry.dart';
import '../services/database_service.dart';
import '../services/calorie_calculator.dart';

/// Ana uygulama state provider'ı
/// Tüm uygulama durumunu yönetir
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  // Durumlar
  UserProfile? _userProfile;
  DailyLog? _todayLog;
  List<MealEntry> _todayMeals = [];
  List<WeightEntry> _weightEntries = [];
  bool _isLoading = true;
  String? _error;

  // Getter'lar
  UserProfile? get userProfile => _userProfile;
  DailyLog? get todayLog => _todayLog;
  List<MealEntry> get todayMeals => _todayMeals;
  List<WeightEntry> get weightEntries => _weightEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _userProfile != null;

  // Türetilmiş değerler
  int get targetCalories => _userProfile?.targetCalories ?? 2000;
  int get consumedCalories => _todayLog?.totalCalories ?? 0;
  int get remainingCalories => targetCalories - consumedCalories;
  double get progressPercentage => _todayLog?.progressPercentage ?? 0;
  String get todayStatus => _todayLog?.status ?? 'EMPTY';

  /// Provider'ı başlat
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.initialize();
      _userProfile = _db.getUserProfile();
      _weightEntries = _db.getWeightEntries();

      if (_userProfile != null) {
        await _loadTodayData();
      }

      _error = null;
    } catch (e) {
      _error = 'Veritabanı yüklenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Bugünün verilerini yükle
  Future<void> _loadTodayData() async {
    if (_userProfile == null) return;

    _todayLog = await _db.getOrCreateTodayLog(_userProfile!.targetCalories);
    _todayMeals = _db.getMealEntries(_todayLog!.id);
    notifyListeners();
  }

  // ==================== PROFILE ====================

  /// Profil oluştur/güncelle
  Future<void> saveProfile({
    required String gender,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goalType,
    required double weeklyGoal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Kalori hedefini hesapla
      final result = CalorieCalculatorService.calculateCalories(
        gender: gender,
        birthDate: birthDate,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: activityLevel,
        goalType: goalType,
      );

      final now = DateTime.now();
      final profile = UserProfile(
        id: _userProfile?.id ?? _uuid.v4(),
        gender: gender,
        birthDate: birthDate,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: activityLevel,
        goalType: goalType,
        weeklyGoal: weeklyGoal,
        targetCalories: result.targetCalories,
        createdAt: _userProfile?.createdAt ?? now,
        updatedAt: now,
      );

      await _db.saveUserProfile(profile);
      _userProfile = profile;

      await _loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Profil kaydedilirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Profil güncelle
  Future<void> updateProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Kalori hedefini yeniden hesapla
      final newCalories = CalorieCalculatorService.calculateFromProfile(profile);
      final updatedProfile = profile.copyWith(
        targetCalories: newCalories,
        updatedAt: DateTime.now(),
      );

      await _db.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;

      await _loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Profil güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== MEALS ====================

  /// Yemek ekle
  Future<void> addMeal({
    required String mealType,
    required String name,
    required int calories,
    double? protein,
    double? carbs,
    double? fat,
    double? quantity,
    String? unit,
    String? note,
  }) async {
    if (_todayLog == null) return;

    try {
      final now = DateTime.now();
      final entry = MealEntry(
        id: _uuid.v4(),
        dailyLogId: _todayLog!.id,
        mealType: mealType,
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        quantity: quantity,
        unit: unit,
        note: note,
        createdAt: now,
        updatedAt: now,
      );

      await _db.addMealEntry(entry);
      await _loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Yemek eklenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  /// Yemek güncelle
  Future<void> updateMeal(MealEntry entry) async {
    try {
      final oldEntry = _todayMeals.firstWhere((m) => m.id == entry.id);
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());

      await _db.updateMealEntry(updatedEntry, oldEntry.calories);
      await _loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Yemek güncellenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  /// Yemek sil
  Future<void> deleteMeal(String entryId) async {
    try {
      await _db.deleteMealEntry(entryId);
      await _loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Yemek silinirken hata oluştu: $e';
      notifyListeners();
    }
  }

  /// Öğün türüne göre yemekleri getir
  List<MealEntry> getMealsByType(String mealType) {
    return _todayMeals.where((m) => m.mealType == mealType).toList();
  }

  /// Öğün türüne göre toplam kalori
  int getCaloriesByMealType(String mealType) {
    return getMealsByType(mealType).fold(0, (sum, m) => sum + m.calories);
  }

  // ==================== WEIGHT TRACKING ====================

  /// Kilo girişi ekle
  Future<void> addWeightEntry(double weightKg, {String? note}) async {
    try {
      final now = DateTime.now();
      final entry = WeightEntry(
        id: _uuid.v4(),
        date: DateTime(now.year, now.month, now.day),
        weightKg: weightKg,
        note: note,
        createdAt: now,
      );

      await _db.addWeightEntry(entry);
      _weightEntries = _db.getWeightEntries();

      // Profildeki kiloyu da güncelle
      if (_userProfile != null) {
        final updatedProfile = _userProfile!.copyWith(
          weightKg: weightKg,
          updatedAt: now,
        );
        // Kalori hedefini yeniden hesapla
        final newCalories = CalorieCalculatorService.calculateFromProfile(updatedProfile);
        final finalProfile = updatedProfile.copyWith(targetCalories: newCalories);
        await _db.updateUserProfile(finalProfile);
        _userProfile = finalProfile;
      }

      notifyListeners();
      _error = null;
    } catch (e) {
      _error = 'Kilo kaydedilirken hata oluştu: $e';
      notifyListeners();
    }
  }

  /// Kilo girişi sil
  Future<void> deleteWeightEntry(String entryId) async {
    try {
      await _db.deleteWeightEntry(entryId);
      _weightEntries = _db.getWeightEntries();
      notifyListeners();
      _error = null;
    } catch (e) {
      _error = 'Kilo silinirken hata oluştu: $e';
      notifyListeners();
    }
  }

  /// Son kilo girişini getir
  WeightEntry? get latestWeightEntry {
    if (_weightEntries.isEmpty) return null;
    return _weightEntries.last;
  }

  // ==================== CALENDAR & STATS ====================

  /// Belirli bir tarihin günlük kaydını getir
  DailyLog? getDailyLog(DateTime date) {
    return _db.getDailyLog(date);
  }

  /// Ay için günlük kayıtları getir
  List<DailyLog> getMonthLogs(int year, int month) {
    return _db.getMonthLogs(year, month);
  }

  /// Haftalık istatistikleri getir
  Map<String, dynamic> getWeeklyStats() {
    return _db.getWeeklyStats();
  }

  /// Belirli bir tarih için yemekleri getir
  List<MealEntry> getMealsForDate(DateTime date) {
    final log = _db.getDailyLog(date);
    if (log == null) return [];
    return _db.getMealEntries(log.id);
  }

  // ==================== HELPERS ====================

  /// Hatayı temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Verileri yenile
  Future<void> refresh() async {
    await _loadTodayData();
    _weightEntries = _db.getWeightEntries();
  }
}
