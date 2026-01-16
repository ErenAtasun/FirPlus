import 'package:hive/hive.dart';

part 'meal_entry.g.dart';

/// Yemek girişi modeli
/// Her öğün için yemek adı, kalori ve makro değerlerini tutar
@HiveType(typeId: 2)
class MealEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String dailyLogId; // İlişkili günlük kaydın ID'si

  @HiveField(2)
  String mealType; // 'kahvalti', 'ogle', 'aksam', 'ara'

  @HiveField(3)
  String name; // Yemek adı

  @HiveField(4)
  int calories; // Kalori değeri

  @HiveField(5)
  double? protein; // Protein (gram) - opsiyonel

  @HiveField(6)
  double? carbs; // Karbonhidrat (gram) - opsiyonel

  @HiveField(7)
  double? fat; // Yağ (gram) - opsiyonel

  @HiveField(8)
  double? quantity; // Miktar/porsiyon - opsiyonel

  @HiveField(9)
  String? unit; // Birim (gram, porsiyon, adet vb.) - opsiyonel

  @HiveField(10)
  String? note; // Not - opsiyonel

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  MealEntry({
    required this.id,
    required this.dailyLogId,
    required this.mealType,
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.quantity,
    this.unit,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Makro değerleri var mı?
  bool get hasMacros => protein != null || carbs != null || fat != null;

  /// Toplam makro değeri (gram)
  double get totalMacros => (protein ?? 0) + (carbs ?? 0) + (fat ?? 0);

  /// Öğün türünü Türkçe olarak getir
  String get mealTypeLabel {
    switch (mealType) {
      case 'kahvalti':
        return 'Kahvaltı';
      case 'ogle':
        return 'Öğle Yemeği';
      case 'aksam':
        return 'Akşam Yemeği';
      case 'ara':
        return 'Ara Öğün';
      default:
        return mealType;
    }
  }

  /// Kopyasını oluştur
  MealEntry copyWith({
    String? id,
    String? dailyLogId,
    String? mealType,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? quantity,
    String? unit,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      dailyLogId: dailyLogId ?? this.dailyLogId,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Map'e dönüştür (JSON için)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dailyLogId': dailyLogId,
      'mealType': mealType,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'quantity': quantity,
      'unit': unit,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Map'ten oluştur
  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as String,
      dailyLogId: map['dailyLogId'] as String,
      mealType: map['mealType'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int,
      protein: map['protein'] as double?,
      carbs: map['carbs'] as double?,
      fat: map['fat'] as double?,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'MealEntry(name: $name, calories: $calories, mealType: $mealType)';
  }
}
