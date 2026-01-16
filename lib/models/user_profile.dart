import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// Kullanıcı profili modeli
/// BMR ve TDEE hesaplamaları için gerekli tüm bilgileri içerir
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String gender; // 'erkek' veya 'kadin'

  @HiveField(2)
  DateTime birthDate;

  @HiveField(3)
  double heightCm; // Boy (cm)

  @HiveField(4)
  double weightKg; // Kilo (kg)

  @HiveField(5)
  String activityLevel; // 'sedanter', 'hafif_aktif', 'orta_aktif', 'aktif', 'cok_aktif'

  @HiveField(6)
  String goalType; // 'kilo_ver', 'koru', 'kilo_al'

  @HiveField(7)
  double weeklyGoal; // Haftalık hedef (kg)

  @HiveField(8)
  int targetCalories; // Hesaplanan günlük kalori hedefi

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalType,
    required this.weeklyGoal,
    required this.targetCalories,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Yaşı hesapla
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Profil kopyasını oluştur
  UserProfile copyWith({
    String? id,
    String? gender,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goalType,
    double? weeklyGoal,
    int? targetCalories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      targetCalories: targetCalories ?? this.targetCalories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, gender: $gender, age: $age, height: $heightCm cm, weight: $weightKg kg, targetCalories: $targetCalories)';
  }
}
