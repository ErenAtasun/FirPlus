import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

/// Screen for adding meals with AI-powered options
class AddMealScreen extends StatefulWidget {
  final DateTime date;

  const AddMealScreen({super.key, required this.date});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _selectedMealType = MealTypes.lunch;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _isListening = false;

  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();

  // AI Analysis results
  List<FoodAnalysisResult>? _photoAnalysisResults;
  VoiceMealResult? _voiceResult;
  String _voiceText = '';

  // Food suggestions
  List<FoodSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _suggestions = AIService.getSuggestions('');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AppProvider>().addMeal(
            name: _nameController.text.trim(),
            calories: int.parse(_caloriesController.text.trim()),
            mealType: _selectedMealType,
            date: widget.date,
            isAiEstimated:
                _photoAnalysisResults != null || _voiceResult != null,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Öğün eklendi! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMultipleMeals(List<FoodAnalysisResult> foods) async {
    setState(() => _isLoading = true);

    try {
      for (final food in foods) {
        await context.read<AppProvider>().addMeal(
              name: food.name,
              calories: food.calories,
              mealType: _selectedMealType,
              date: widget.date,
              isAiEstimated: true,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foods.length} öğün eklendi! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndAnalyzePhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isAnalyzing = true;
        _photoAnalysisResults = null;
      });

      // Analyze with AI
      final results = await AIService.analyzePhoto(image.path);

      setState(() {
        _isAnalyzing = false;
        _photoAnalysisResults = results;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf analizi başarısız: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startVoiceInput() {
    setState(() {
      _isListening = true;
      _voiceText = '';
      _voiceResult = null;
    });

    // Simulate voice listening for demo
    // In production, use speech_to_text package
    _showVoiceInputDialog();
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VoiceInputDialog(
        onResult: (text) async {
          Navigator.of(context).pop();
          if (text.isNotEmpty) {
            setState(() {
              _voiceText = text;
              _isListening = false;
            });

            final result = await AIService.parseVoiceInput(text);
            setState(() {
              _voiceResult = result;
            });
          } else {
            setState(() => _isListening = false);
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() => _isListening = false);
        },
      ),
    );
  }

  void _onFoodNameChanged(String value) {
    setState(() {
      _suggestions = AIService.getSuggestions(value);
    });
  }

  void _selectSuggestion(FoodSuggestion suggestion) {
    _nameController.text = suggestion.name;
    _caloriesController.text = suggestion.calories.toString();
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğün Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Manuel'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Fotoğraf'),
            Tab(icon: Icon(Icons.mic), text: 'Sesli'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualTab(),
          _buildPhotoTab(),
          _buildVoiceTab(),
        ],
      ),
      bottomNavigationBar: _tabController.index == 0
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Öğün Ekle'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildManualTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quick Add Buttons
          Text(
            'Hızlı Ekle',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAddButton('🍞 Ekmek', 80),
                _buildQuickAddButton('🍚 Pilav', 200),
                _buildQuickAddButton('🍗 Tavuk', 250),
                _buildQuickAddButton('🥗 Salata', 100),
                _buildQuickAddButton('🍎 Elma', 52),
                _buildQuickAddButton('🥛 Süt', 150),
                _buildQuickAddButton('☕ Kahve', 5),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Meal Type Selection
          Text(
            'Öğün Tipi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildMealTypeSelector(),
          const SizedBox(height: 32),

          // Food Name
          Text(
            'Yemek Adı',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Örn: Izgara tavuk',
              prefixIcon: Icon(Icons.restaurant),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: _onFoodNameChanged,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen yemek adı girin';
              }
              return null;
            },
          ),

          // Suggestions
          if (_suggestions.isNotEmpty && _nameController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _suggestions
                    .take(5)
                    .map((s) => ListTile(
                          leading: Text(s.icon,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(s.name),
                          trailing: Text('${s.calories} kcal',
                              style: TextStyle(color: AppColors.textSecondary)),
                          onTap: () => _selectSuggestion(s),
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Calories
          Text(
            'Kalori',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              hintText: 'Örn: 350',
              prefixIcon: Icon(Icons.local_fire_department),
              suffixText: 'kcal',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen kalori miktarı girin';
              }
              final calories = int.tryParse(value.trim());
              if (calories == null || calories <= 0) {
                return 'Geçerli bir kalori değeri girin';
              }
              if (calories > 5000) {
                return 'Kalori değeri çok yüksek';
              }
              return null;
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo capture buttons
          Row(
            children: [
              Expanded(
                child: _buildPhotoButton(
                  icon: Icons.camera_alt,
                  label: 'Fotoğraf Çek',
                  onTap: () => _pickAndAnalyzePhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPhotoButton(
                  icon: Icons.photo_library,
                  label: 'Galeriden Seç',
                  onTap: () => _pickAndAnalyzePhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Meal Type Selection
          Text(
            'Öğün Tipi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildMealTypeSelector(),
          const SizedBox(height: 24),

          // Analysis status
          if (_isAnalyzing)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Fotoğraf analiz ediliyor...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI yemekleri tanımlıyor',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Analysis results
          if (_photoAnalysisResults != null) ...[
            _buildAIResultsSection(_photoAnalysisResults!),
          ],

          // Info card
          if (!_isAnalyzing && _photoAnalysisResults == null)
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'AI ile Yemek Tanıma',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yemeğinizin fotoğrafını çekin veya galeriden seçin. Yapay zeka yemekleri tanıyıp kalori tahmininde bulunacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice input button
          Center(
            child: GestureDetector(
              onTap: _isListening ? null : _startVoiceInput,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: _isListening
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        )
                      : AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening ? AppColors.error : AppColors.primary)
                              .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _isListening ? 'Dinleniyor...' : 'Konuşmak için dokunun',
              style: TextStyle(
                color: _isListening ? AppColors.error : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Meal Type Selection
          Text(
            'Öğün Tipi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildMealTypeSelector(),
          const SizedBox(height: 24),

          // Voice text display
          if (_voiceText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote,
                          color: AppColors.textTertiary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Algılanan metin:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _voiceText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Voice analysis results
          if (_voiceResult != null) ...[
            _buildAIResultsSection(_voiceResult!.foods),
          ],

          // Example phrases
          if (_voiceText.isEmpty && _voiceResult == null)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Örnek Cümleler',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExamplePhrase('Öğle yemeğinde pilav ve tavuk yedim'),
                  _buildExamplePhrase('Kahvaltıda 2 yumurta ve peynir yedim'),
                  _buildExamplePhrase('Akşam döner ve ayran içtim'),
                  _buildExamplePhrase('Atıştırmalık olarak bir elma yedim'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIResultsSection(List<FoodAnalysisResult> results) {
    final totalCalories = results.fold(0, (sum, f) => sum + f.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tespit Edilen Yemekler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$totalCalories kcal',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...results.map((food) => _buildAIFoodCard(food)),

        const SizedBox(height: 20),

        // Add all button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _saveMultipleMeals(results),
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Tümünü Ekle ($totalCalories kcal)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Disclaimer
        Text(
          '* AI tahminleri yaklaşık değerlerdir. Gerekirse düzenleyebilirsiniz.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAIFoodCard(FoodAnalysisResult food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      food.portion,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${food.confidencePercent}% güven',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${food.calories}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Row(
      children: MealTypes.all.map((type) {
        final isSelected = _selectedMealType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMealType = type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    MealTypes.getIcon(type),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MealTypes.getDisplayName(type),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickAddButton(String label, int calories) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () {
          final parts = label.split(' ');
          final name = parts.sublist(1).join(' ');
          _nameController.text = name;
          _caloriesController.text = calories.toString();
          setState(() => _suggestions = []);
        },
        backgroundColor: AppColors.surfaceLight,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildExamplePhrase(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: AppColors.textTertiary, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '"$text"',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice input dialog for simulating speech recognition
class _VoiceInputDialog extends StatefulWidget {
  final Function(String) onResult;
  final VoidCallback onCancel;

  const _VoiceInputDialog({
    required this.onResult,
    required this.onCancel,
  });

  @override
  State<_VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<_VoiceInputDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          const Text('Sesli Giriş'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Yediğiniz yemeği yazın veya söyleyin:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Örn: Öğle yemeğinde pilav ve tavuk yedim',
              hintStyle: TextStyle(color: AppColors.textTertiary),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => widget.onResult(_textController.text),
          child: const Text('Analiz Et'),
        ),
      ],
    );
  }
}
