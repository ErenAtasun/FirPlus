/// Uygulama sabitleri
class AppConstants {
  // Uygulama adı
  static const String appName = 'Kalori Takip';
  static const String appVersion = '1.0.0';

  // Aktivite seviyeleri ve katsayıları
  static const Map<String, double> activityMultipliers = {
    'sedanter': 1.2, // Hareketsiz (masabaşı iş)
    'hafif_aktif': 1.375, // Hafif egzersiz (haftada 1-3 gün)
    'orta_aktif': 1.55, // Orta düzey egzersiz (haftada 3-5 gün)
    'aktif': 1.725, // Yoğun egzersiz (haftada 6-7 gün)
    'cok_aktif': 1.9, // Çok yoğun egzersiz (günde 2 kez veya fiziksel iş)
  };

  // Aktivite seviyeleri Türkçe açıklamaları
  static const Map<String, String> activityLabels = {
    'sedanter': 'Hareketsiz (Masabaşı)',
    'hafif_aktif': 'Hafif Aktif (Haftada 1-3 gün)',
    'orta_aktif': 'Orta Aktif (Haftada 3-5 gün)',
    'aktif': 'Aktif (Haftada 6-7 gün)',
    'cok_aktif': 'Çok Aktif (Günde 2 kez)',
  };

  // Hedef türleri
  static const Map<String, String> goalLabels = {
    'kilo_ver': 'Kilo Vermek',
    'koru': 'Kiloyu Korumak',
    'kilo_al': 'Kilo Almak',
  };

  // Hedef türlerine göre kalori ayarları
  static const Map<String, int> goalCalorieAdjustments = {
    'kilo_ver': -500, // TDEE'den 500 kcal düş
    'koru': 0, // TDEE'yi koru
    'kilo_al': 350, // TDEE'ye 350 kcal ekle
  };

  // Öğün türleri
  static const Map<String, String> mealTypeLabels = {
    'kahvalti': 'Kahvaltı',
    'ogle': 'Öğle Yemeği',
    'aksam': 'Akşam Yemeği',
    'ara': 'Ara Öğün',
  };

  // Öğün ikonları (Material Icons)
  static const Map<String, int> mealTypeIcons = {
    'kahvalti': 0xe25a, // free_breakfast
    'ogle': 0xe56c, // lunch_dining
    'aksam': 0xe534, // dinner_dining
    'ara': 0xea60, // cookie
  };

  // Cinsiyet
  static const Map<String, String> genderLabels = {
    'erkek': 'Erkek',
    'kadin': 'Kadın',
  };

  // Minimum güvenli kalori değerleri
  static const int minCalorieMale = 1500;
  static const int minCalorieFemale = 1200;

  // Maksimum kalori değeri
  static const int maxCalorie = 5000;

  // Haftalık hedefler (kg/hafta)
  static const List<double> weeklyGoalOptions = [0.25, 0.5, 0.75, 1.0];

  // Boy sınırları (cm)
  static const double minHeight = 100.0;
  static const double maxHeight = 250.0;

  // Kilo sınırları (kg)
  static const double minWeight = 30.0;
  static const double maxWeight = 300.0;

  // Yaş sınırları
  static const int minAge = 12;
  static const int maxAge = 100;

  // Hive box isimleri
  static const String userProfileBox = 'user_profile_box';
  static const String dailyLogBox = 'daily_log_box';
  static const String mealEntryBox = 'meal_entry_box';
  static const String weightEntryBox = 'weight_entry_box';
  static const String settingsBox = 'settings_box';

  // SharedPreferences anahtarları
  static const String keyProfileCompleted = 'profile_completed';
  static const String keyDarkMode = 'dark_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyNotificationTime = 'notification_time';

  // Animasyon süreleri
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Gün durumları
  static const String statusGreen = 'GREEN'; // Hedef altında
  static const String statusRed = 'RED'; // Hedef aşıldı
  static const String statusEmpty = 'EMPTY'; // Veri yok
}
