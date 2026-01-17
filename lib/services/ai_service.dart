import 'dart:convert';
import 'package:flutter/foundation.dart';

/// AI Service for food photo analysis and voice recognition
/// This service can be configured to use OpenAI, Google Cloud Vision, or simulate responses
class AIService {
  static const bool _useSimulation =
      true; // Set to false when API keys are configured

  // TODO: Add your API keys here
  // static const String _openAIKey = 'YOUR_OPENAI_API_KEY';
  // static const String _googleVisionKey = 'YOUR_GOOGLE_VISION_API_KEY';

  /// Analyze a food photo and return detected foods with calorie estimates
  /// Returns a list of detected food items with their estimated calories
  static Future<List<FoodAnalysisResult>> analyzePhoto(String imagePath) async {
    if (_useSimulation) {
      return _simulatePhotoAnalysis();
    }

    // TODO: Implement actual API call to OpenAI Vision or Google Cloud Vision
    // Example with OpenAI:
    // final response = await http.post(
    //   Uri.parse('https://api.openai.com/v1/chat/completions'),
    //   headers: {
    //     'Authorization': 'Bearer $_openAIKey',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'model': 'gpt-4-vision-preview',
    //     'messages': [
    //       {
    //         'role': 'user',
    //         'content': [
    //           {'type': 'text', 'text': 'Analyze this food image...'},
    //           {'type': 'image_url', 'image_url': {'url': base64Image}},
    //         ],
    //       },
    //     ],
    //   }),
    // );

    return _simulatePhotoAnalysis();
  }

  /// Simulate photo analysis for demo purposes
  static Future<List<FoodAnalysisResult>> _simulatePhotoAnalysis() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Return simulated results - in production, this would come from AI analysis
    return [
      FoodAnalysisResult(
        name: 'Pilav',
        calories: 200,
        confidence: 0.92,
        portion: '1 porsiyon',
      ),
      FoodAnalysisResult(
        name: 'Izgara Tavuk',
        calories: 250,
        confidence: 0.88,
        portion: '150g',
      ),
      FoodAnalysisResult(
        name: 'Salata',
        calories: 80,
        confidence: 0.85,
        portion: '1 kase',
      ),
    ];
  }

  /// Parse voice input to extract meal information
  /// Returns structured meal data from natural language input
  static Future<VoiceMealResult?> parseVoiceInput(String text) async {
    if (_useSimulation) {
      return _simulateVoiceParsing(text);
    }

    // TODO: Implement actual NLP processing with OpenAI or similar
    return _simulateVoiceParsing(text);
  }

  /// Simulate voice parsing for demo purposes
  static Future<VoiceMealResult?> _simulateVoiceParsing(String text) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final lowerText = text.toLowerCase();

    // Simple keyword-based parsing for demo
    final mealKeywords = {
      'kahvaltı': 'breakfast',
      'öğle': 'lunch',
      'akşam': 'dinner',
      'atıştırmalık': 'snack',
    };

    String mealType = 'lunch';
    for (final entry in mealKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        mealType = entry.value;
        break;
      }
    }

    // Extract common food items
    final foods = <FoodAnalysisResult>[];
    final foodDatabase = {
      'pilav': FoodAnalysisResult(
          name: 'Pilav',
          calories: 200,
          confidence: 0.95,
          portion: '1 porsiyon'),
      'tavuk': FoodAnalysisResult(
          name: 'Tavuk',
          calories: 250,
          confidence: 0.95,
          portion: '1 porsiyon'),
      'salata': FoodAnalysisResult(
          name: 'Salata', calories: 80, confidence: 0.95, portion: '1 kase'),
      'çorba': FoodAnalysisResult(
          name: 'Çorba', calories: 150, confidence: 0.95, portion: '1 kase'),
      'ekmek': FoodAnalysisResult(
          name: 'Ekmek', calories: 80, confidence: 0.95, portion: '1 dilim'),
      'ayran': FoodAnalysisResult(
          name: 'Ayran', calories: 60, confidence: 0.95, portion: '1 bardak'),
      'döner': FoodAnalysisResult(
          name: 'Döner',
          calories: 450,
          confidence: 0.95,
          portion: '1 porsiyon'),
      'makarna': FoodAnalysisResult(
          name: 'Makarna',
          calories: 300,
          confidence: 0.95,
          portion: '1 porsiyon'),
      'köfte': FoodAnalysisResult(
          name: 'Köfte', calories: 350, confidence: 0.95, portion: '4 adet'),
      'mercimek': FoodAnalysisResult(
          name: 'Mercimek Çorbası',
          calories: 180,
          confidence: 0.95,
          portion: '1 kase'),
      'kahve': FoodAnalysisResult(
          name: 'Kahve', calories: 5, confidence: 0.95, portion: '1 fincan'),
      'çay': FoodAnalysisResult(
          name: 'Çay', calories: 2, confidence: 0.95, portion: '1 bardak'),
      'elma': FoodAnalysisResult(
          name: 'Elma', calories: 52, confidence: 0.95, portion: '1 adet'),
      'muz': FoodAnalysisResult(
          name: 'Muz', calories: 89, confidence: 0.95, portion: '1 adet'),
      'yumurta': FoodAnalysisResult(
          name: 'Yumurta', calories: 78, confidence: 0.95, portion: '1 adet'),
      'süt': FoodAnalysisResult(
          name: 'Süt', calories: 150, confidence: 0.95, portion: '1 bardak'),
      'peynir': FoodAnalysisResult(
          name: 'Beyaz Peynir',
          calories: 100,
          confidence: 0.95,
          portion: '50g'),
    };

    for (final entry in foodDatabase.entries) {
      if (lowerText.contains(entry.key)) {
        foods.add(entry.value);
      }
    }

    if (foods.isEmpty) {
      return null;
    }

    return VoiceMealResult(
      mealType: mealType,
      foods: foods,
      originalText: text,
    );
  }

  /// Get common food suggestions based on partial input
  static List<FoodSuggestion> getSuggestions(String query) {
    final lowerQuery = query.toLowerCase();

    final allFoods = [
      FoodSuggestion(name: 'Pilav', calories: 200, icon: '🍚'),
      FoodSuggestion(name: 'Tavuk Göğsü', calories: 165, icon: '🍗'),
      FoodSuggestion(name: 'Izgara Tavuk', calories: 250, icon: '🍗'),
      FoodSuggestion(name: 'Salata', calories: 80, icon: '🥗'),
      FoodSuggestion(name: 'Mercimek Çorbası', calories: 180, icon: '🍲'),
      FoodSuggestion(name: 'Domates Çorbası', calories: 120, icon: '🍲'),
      FoodSuggestion(name: 'Ekmek', calories: 80, icon: '🍞'),
      FoodSuggestion(name: 'Makarna', calories: 300, icon: '🍝'),
      FoodSuggestion(name: 'Köfte', calories: 350, icon: '🍖'),
      FoodSuggestion(name: 'Döner', calories: 450, icon: '🌯'),
      FoodSuggestion(name: 'Lahmacun', calories: 280, icon: '🫓'),
      FoodSuggestion(name: 'Pizza', calories: 350, icon: '🍕'),
      FoodSuggestion(name: 'Hamburger', calories: 500, icon: '🍔'),
      FoodSuggestion(name: 'Yumurta', calories: 78, icon: '🥚'),
      FoodSuggestion(name: 'Omlet', calories: 180, icon: '🍳'),
      FoodSuggestion(name: 'Kahvaltı Tabağı', calories: 450, icon: '🍳'),
      FoodSuggestion(name: 'Beyaz Peynir', calories: 100, icon: '🧀'),
      FoodSuggestion(name: 'Kaşar Peyniri', calories: 120, icon: '🧀'),
      FoodSuggestion(name: 'Süt', calories: 150, icon: '🥛'),
      FoodSuggestion(name: 'Ayran', calories: 60, icon: '🥛'),
      FoodSuggestion(name: 'Kahve', calories: 5, icon: '☕'),
      FoodSuggestion(name: 'Türk Kahvesi', calories: 15, icon: '☕'),
      FoodSuggestion(name: 'Latte', calories: 150, icon: '☕'),
      FoodSuggestion(name: 'Çay', calories: 2, icon: '🍵'),
      FoodSuggestion(name: 'Elma', calories: 52, icon: '🍎'),
      FoodSuggestion(name: 'Muz', calories: 89, icon: '🍌'),
      FoodSuggestion(name: 'Portakal', calories: 47, icon: '🍊'),
      FoodSuggestion(name: 'Çikolata', calories: 230, icon: '🍫'),
      FoodSuggestion(name: 'Bisküvi', calories: 120, icon: '🍪'),
      FoodSuggestion(name: 'Dondurma', calories: 200, icon: '🍨'),
    ];

    if (lowerQuery.isEmpty) {
      return allFoods.take(10).toList();
    }

    return allFoods
        .where((f) => f.name.toLowerCase().contains(lowerQuery))
        .take(10)
        .toList();
  }
}

/// Result from AI food photo analysis
class FoodAnalysisResult {
  final String name;
  final int calories;
  final double confidence; // 0.0 to 1.0
  final String portion;

  FoodAnalysisResult({
    required this.name,
    required this.calories,
    required this.confidence,
    required this.portion,
  });

  int get confidencePercent => (confidence * 100).round();
}

/// Result from voice meal parsing
class VoiceMealResult {
  final String mealType;
  final List<FoodAnalysisResult> foods;
  final String originalText;

  VoiceMealResult({
    required this.mealType,
    required this.foods,
    required this.originalText,
  });

  int get totalCalories => foods.fold(0, (sum, f) => sum + f.calories);
}

/// Food suggestion for autocomplete
class FoodSuggestion {
  final String name;
  final int calories;
  final String icon;

  FoodSuggestion({
    required this.name,
    required this.calories,
    required this.icon,
  });
}
