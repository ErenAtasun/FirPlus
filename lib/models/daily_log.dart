import 'package:hive/hive.dart';
import 'meal_entry.dart';

part 'daily_log.g.dart';

/// Günlük kayıt modeli
/// Her gün için kalori hedefi, toplam alınan kalori ve durum bilgisini tutar
@HiveType(typeId: 1)
class DailyLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date; // Sadece yıl-ay-gün olarak kullanılacak

  @HiveField(2)
  int targetCalories; // O gün için hedef kalori (profil değişse bile sabit kalır)

  @HiveField(3)
  int totalCalories; // Toplam alınan kalori (cache)

  @HiveField(4)
  String status; // 'GREEN', 'RED', 'EMPTY'

  @HiveField(5)
  List<String> mealEntryIds; // İlişkili yemek girişlerinin ID'leri

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  // Yemek girişleri (runtime'da doldurulur, Hive'a kaydedilmez)
  List<MealEntry>? meals;

  DailyLog({
    required this.id,
    required this.date,
    required this.targetCalories,
    this.totalCalories = 0,
    this.status = 'EMPTY',
    List<String>? mealEntryIds,
    required this.createdAt,
    required this.updatedAt,
    this.meals,
  }) : mealEntryIds = mealEntryIds ?? [];

  /// Sadece tarih kısmını al (saat bilgisi olmadan)
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Kalan kalori
  int get remainingCalories => targetCalories - totalCalories;

  /// Hedef yüzdesi
  double get progressPercentage {
    if (targetCalories == 0) return 0;
    return (totalCalories / targetCalories * 100).clamp(0, 200);
  }

  /// Hedef aşım miktarı
  int get excessCalories {
    if (totalCalories > targetCalories) {
      return totalCalories - targetCalories;
    }
    return 0;
  }

  /// Durumu güncelle
  void updateStatus() {
    if (totalCalories == 0 && mealEntryIds.isEmpty) {
      status = 'EMPTY';
    } else if (totalCalories > targetCalories) {
      status = 'RED';
    } else {
      status = 'GREEN';
    }
    updatedAt = DateTime.now();
  }

  /// Toplam kaloriyi yemek girişlerinden hesapla
  void calculateTotalCalories(List<MealEntry> entries) {
    totalCalories = entries.fold(0, (sum, entry) => sum + entry.calories);
    updateStatus();
  }

  /// Kopyasını oluştur
  DailyLog copyWith({
    String? id,
    DateTime? date,
    int? targetCalories,
    int? totalCalories,
    String? status,
    List<String>? mealEntryIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MealEntry>? meals,
  }) {
    return DailyLog(
      id: id ?? this.id,
      date: date ?? this.date,
      targetCalories: targetCalories ?? this.targetCalories,
      totalCalories: totalCalories ?? this.totalCalories,
      status: status ?? this.status,
      mealEntryIds: mealEntryIds ?? List<String>.from(this.mealEntryIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      meals: meals ?? this.meals,
    );
  }

  @override
  String toString() {
    return 'DailyLog(date: $dateKey, target: $targetCalories, total: $totalCalories, status: $status)';
  }
}
