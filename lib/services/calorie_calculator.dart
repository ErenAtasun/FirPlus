import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';

/// Kalori hesaplama servisi
/// BMR, TDEE ve günlük kalori hedefi hesaplamaları yapar
class CalorieCalculatorService {
  /// BMR (Bazal Metabolizma) hesapla - Mifflin St Jeor formülü
  /// Erkek: BMR = 10 × kilo + 6.25 × boy - 5 × yaş + 5
  /// Kadın: BMR = 10 × kilo + 6.25 × boy - 5 × yaş - 161
  static double calculateBMR({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    double bmr;
    if (gender == 'erkek') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
    return bmr;
  }

  /// TDEE (Günlük toplam enerji harcaması) hesapla
  /// TDEE = BMR × Aktivite Katsayısı
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier = AppConstants.activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  /// Hedef kalori hesapla
  /// Hedefe göre TDEE'den kalori ekle veya çıkar
  static int calculateTargetCalories({
    required double tdee,
    required String goalType,
    required String gender,
  }) {
    int adjustment = AppConstants.goalCalorieAdjustments[goalType] ?? 0;
    int targetCalories = (tdee + adjustment).round();

    // Güvenlik sınırı kontrolü
    int minCalorie = gender == 'erkek'
        ? AppConstants.minCalorieMale
        : AppConstants.minCalorieFemale;

    int maxCalorie = AppConstants.maxCalorie;

    return targetCalories.clamp(minCalorie, maxCalorie);
  }

  /// Profil bilgilerinden kalori hedefi hesapla (tek fonksiyon)
  static int calculateFromProfile(UserProfile profile) {
    double bmr = calculateBMR(
      gender: profile.gender,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
    );

    double tdee = calculateTDEE(
      bmr: bmr,
      activityLevel: profile.activityLevel,
    );

    return calculateTargetCalories(
      tdee: tdee,
      goalType: profile.goalType,
      gender: profile.gender,
    );
  }

  /// Profil wizard için kalori hesapla (ayrı parametreler ile)
  static CalorieCalculationResult calculateCalories({
    required String gender,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goalType,
  }) {
    // Yaş hesapla
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    // BMR hesapla
    double bmr = calculateBMR(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );

    // TDEE hesapla
    double tdee = calculateTDEE(
      bmr: bmr,
      activityLevel: activityLevel,
    );

    // Hedef kalori hesapla
    int targetCalories = calculateTargetCalories(
      tdee: tdee,
      goalType: goalType,
      gender: gender,
    );

    // Güvenlik uyarısı kontrolü
    int minCalorie =
        gender == 'erkek' ? AppConstants.minCalorieMale : AppConstants.minCalorieFemale;
    bool showWarning = targetCalories <= minCalorie;

    return CalorieCalculationResult(
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCalories,
      showLowCalorieWarning: showWarning,
      age: age,
    );
  }

  /// Makro hedefleri hesapla (opsiyonel)
  /// Protein: 1.6-2.2 g/kg
  /// Yağ: 0.8-1.0 g/kg
  /// Karbonhidrat: Kalan kalori
  static MacroTargets calculateMacros({
    required double weightKg,
    required int targetCalories,
    required String goalType,
  }) {
    // Protein hesapla (hedefe göre)
    double proteinPerKg;
    if (goalType == 'kilo_ver') {
      proteinPerKg = 2.0; // Kilo verirken daha fazla protein
    } else if (goalType == 'kilo_al') {
      proteinPerKg = 1.8;
    } else {
      proteinPerKg = 1.6;
    }
    double proteinGrams = weightKg * proteinPerKg;
    int proteinCalories = (proteinGrams * 4).round(); // 1g protein = 4 kcal

    // Yağ hesapla
    double fatPerKg = 0.9;
    double fatGrams = weightKg * fatPerKg;
    int fatCalories = (fatGrams * 9).round(); // 1g yağ = 9 kcal

    // Kalan kaloriyi karbonhidrata ver
    int remainingCalories = targetCalories - proteinCalories - fatCalories;
    double carbsGrams = remainingCalories / 4; // 1g karb = 4 kcal
    if (carbsGrams < 0) carbsGrams = 50; // Minimum karbonhidrat

    return MacroTargets(
      proteinGrams: proteinGrams.round().toDouble(),
      carbsGrams: carbsGrams.round().toDouble(),
      fatGrams: fatGrams.round().toDouble(),
    );
  }
}

/// Kalori hesaplama sonucu
class CalorieCalculationResult {
  final double bmr;
  final double tdee;
  final int targetCalories;
  final bool showLowCalorieWarning;
  final int age;

  CalorieCalculationResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.showLowCalorieWarning,
    required this.age,
  });

  @override
  String toString() {
    return 'BMR: ${bmr.round()}, TDEE: ${tdee.round()}, Hedef: $targetCalories kcal';
  }
}

/// Makro hedefleri
class MacroTargets {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  MacroTargets({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  int get proteinCalories => (proteinGrams * 4).round();
  int get carbsCalories => (carbsGrams * 4).round();
  int get fatCalories => (fatGrams * 9).round();
  int get totalCalories => proteinCalories + carbsCalories + fatCalories;

  @override
  String toString() {
    return 'Protein: ${proteinGrams.round()}g, Karb: ${carbsGrams.round()}g, Yağ: ${fatGrams.round()}g';
  }
}
