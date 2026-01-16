import 'package:google_generative_ai/google_generative_ai.dart';

/// Yemek besin değeri analizi sonucu
class FoodNutritionResult {
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String portion;
  final String? note;
  final bool isSuccessful;
  final String? errorMessage;

  FoodNutritionResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portion,
    this.note,
    this.isSuccessful = true,
    this.errorMessage,
  });

  factory FoodNutritionResult.error(String message) {
    return FoodNutritionResult(
      foodName: '',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      portion: '',
      isSuccessful: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    return 'FoodNutritionResult(foodName: $foodName, calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }
}

/// Yapay zeka ile yemek analizi servisi
/// Gemini API kullanarak yemek besin değerlerini tahmin eder
class AIFoodAnalysisService {
  static AIFoodAnalysisService? _instance;
  static AIFoodAnalysisService get instance => _instance ??= AIFoodAnalysisService._();

  AIFoodAnalysisService._();

  GenerativeModel? _model;
  String? _apiKey;

  /// API anahtarını ayarla
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// API anahtarı ayarlanmış mı?
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Yemek besin değerlerini analiz et
  Future<FoodNutritionResult> analyzeFoodNutrition(String foodDescription) async {
    if (!isConfigured) {
      return FoodNutritionResult.error('API anahtarı ayarlanmamış. Ayarlar\'dan API anahtarınızı girin.');
    }

    if (foodDescription.trim().isEmpty) {
      return FoodNutritionResult.error('Lütfen bir yemek adı girin.');
    }

    try {
      final prompt = '''
Sen bir beslenme uzmanısın. Aşağıdaki Türk yemeği veya besin için tahmini besin değerlerini JSON formatında ver.

Yemek/Besin: "$foodDescription"

SADECE aşağıdaki JSON formatında yanıt ver, başka hiçbir şey yazma:
{
  "foodName": "düzeltilmiş yemek adı",
  "portion": "standart porsiyon miktarı (örn: 1 porsiyon, 100g, 1 adet)",
  "calories": kalori_sayisi_tam_sayi,
  "protein": protein_gram_ondalik,
  "carbs": karbonhidrat_gram_ondalik,
  "fat": yag_gram_ondalik,
  "note": "varsa kısa not veya null"
}

Kurallar:
- Türk mutfağına uygun porsiyon boyutları kullan
- Değerler gerçekçi ve günlük ortalama değerlere yakın olsun
- calories tam sayı olmalı
- protein, carbs, fat ondalıklı sayı olmalı (örn: 12.5)
- Bilinmeyen yemekler için en yakın tahmini yap
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return FoodNutritionResult.error('Yapay zeka yanıt vermedi. Lütfen tekrar deneyin.');
      }

      // JSON'u parse et
      return _parseResponse(responseText, foodDescription);
    } catch (e) {
      if (e.toString().contains('API_KEY')) {
        return FoodNutritionResult.error('Geçersiz API anahtarı. Lütfen doğru anahtarı girin.');
      }
      return FoodNutritionResult.error('Analiz hatası: ${e.toString().substring(0, 100)}');
    }
  }

  /// API yanıtını parse et
  FoodNutritionResult _parseResponse(String responseText, String originalFood) {
    try {
      // JSON bloğunu bul
      String jsonStr = responseText;
      
      // Markdown code block varsa çıkar
      if (responseText.contains('```json')) {
        final start = responseText.indexOf('```json') + 7;
        final end = responseText.indexOf('```', start);
        jsonStr = responseText.substring(start, end).trim();
      } else if (responseText.contains('```')) {
        final start = responseText.indexOf('```') + 3;
        final end = responseText.indexOf('```', start);
        jsonStr = responseText.substring(start, end).trim();
      }

      // { ile başlayıp } ile biten kısmı al
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0) {
        return FoodNutritionResult.error('Yapay zeka yanıtı işlenemedi.');
      }
      jsonStr = jsonStr.substring(jsonStart, jsonEnd);

      // Manuel parse (dart:convert kullanmadan basit yaklaşım)
      final foodName = _extractString(jsonStr, 'foodName') ?? originalFood;
      final portion = _extractString(jsonStr, 'portion') ?? '1 porsiyon';
      final calories = _extractInt(jsonStr, 'calories') ?? 0;
      final protein = _extractDouble(jsonStr, 'protein') ?? 0;
      final carbs = _extractDouble(jsonStr, 'carbs') ?? 0;
      final fat = _extractDouble(jsonStr, 'fat') ?? 0;
      final note = _extractString(jsonStr, 'note');

      if (calories == 0) {
        return FoodNutritionResult.error('Besin değerleri hesaplanamadı.');
      }

      return FoodNutritionResult(
        foodName: foodName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        portion: portion,
        note: note,
      );
    } catch (e) {
      return FoodNutritionResult.error('Yanıt işlenirken hata: $e');
    }
  }

  String? _extractString(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    if (match != null) {
      final value = match.group(1);
      if (value == 'null' || value == null || value.isEmpty) return null;
      return value;
    }
    return null;
  }

  int? _extractInt(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*(\\d+)');
    final match = pattern.firstMatch(json);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  double? _extractDouble(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*([\\d.]+)');
    final match = pattern.firstMatch(json);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}
