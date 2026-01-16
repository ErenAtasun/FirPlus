import 'package:hive/hive.dart';

part 'weight_entry.g.dart';

/// Kilo girişi modeli
/// Kullanıcının kilo geçmişini tutar
@HiveType(typeId: 3)
class WeightEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double weightKg;

  @HiveField(3)
  String? note;

  @HiveField(4)
  DateTime createdAt;

  WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.note,
    required this.createdAt,
  });

  /// Tarih anahtarı
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  WeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    String? note,
    DateTime? createdAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WeightEntry(date: $dateKey, weight: $weightKg kg)';
  }
}
