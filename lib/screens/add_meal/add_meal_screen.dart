import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/meal_entry.dart';
import '../../providers/app_provider.dart';

/// Yemek ekleme ekranı - Basitleştirilmiş versiyon
class AddMealScreen extends StatefulWidget {
  final String? initialMealType;
  final MealEntry? editingMeal;

  const AddMealScreen({
    super.key,
    this.initialMealType,
    this.editingMeal,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _noteController;

  late String _selectedMealType;
  bool _showMacros = false;
  bool _isSaving = false;

  bool get isEditing => widget.editingMeal != null;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _noteController = TextEditingController();
    
    _selectedMealType = widget.initialMealType ?? widget.editingMeal?.mealType ?? 'kahvalti';

    if (isEditing && widget.editingMeal != null) {
      final meal = widget.editingMeal!;
      _nameController.text = meal.name;
      _caloriesController.text = meal.calories.toString();
      if (meal.protein != null) _proteinController.text = meal.protein!.round().toString();
      if (meal.carbs != null) _carbsController.text = meal.carbs!.round().toString();
      if (meal.fat != null) _fatController.text = meal.fat!.round().toString();
      if (meal.note != null) _noteController.text = meal.note!;
      _showMacros = meal.hasMacros;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppProvider>();
      
      final calories = int.tryParse(_caloriesController.text) ?? 0;
      final protein = _proteinController.text.isNotEmpty ? double.tryParse(_proteinController.text) : null;
      final carbs = _carbsController.text.isNotEmpty ? double.tryParse(_carbsController.text) : null;
      final fat = _fatController.text.isNotEmpty ? double.tryParse(_fatController.text) : null;
      final note = _noteController.text.isEmpty ? null : _noteController.text.trim();

      if (isEditing && widget.editingMeal != null) {
        final updatedMeal = widget.editingMeal!.copyWith(
          mealType: _selectedMealType,
          name: _nameController.text.trim(),
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          note: note,
          updatedAt: DateTime.now(),
        );
        await provider.updateMeal(updatedMeal);
      } else {
        await provider.addMeal(
          mealType: _selectedMealType,
          name: _nameController.text.trim(),
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          note: note,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Yemek güncellendi' : 'Yemek eklendi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Yemeği Düzenle' : 'Yemek Ekle'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Öğün seçimi
            const Text('Öğün Seçin', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.mealTypeLabels.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedMealType == entry.key,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMealType = entry.key);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Yemek adı
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Yemek Adı *',
                hintText: 'örn: Tavuk Sote',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Yemek adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kalori
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Kalori (kcal) *',
                hintText: 'örn: 350',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kalori gerekli';
                }
                final cal = int.tryParse(value);
                if (cal == null || cal <= 0) {
                  return 'Geçerli bir değer girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Makro toggle
            SwitchListTile(
              title: const Text('Makro değerleri ekle'),
              value: _showMacros,
              onChanged: (value) => setState(() => _showMacros = value),
            ),

            // Makrolar
            if (_showMacros) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Karb (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Yağ (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Not
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                hintText: 'örn: Zeytinyağlı',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Hızlı öneriler
            const Text('Hızlı Öneriler', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('Kahve', 5),
                _quickChip('Çay', 2),
                _quickChip('Yumurta', 78),
                _quickChip('Ekmek', 80),
                _quickChip('Elma', 95),
                _quickChip('Muz', 105),
              ],
            ),
            const SizedBox(height: 32),

            // Kaydet butonu
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String name, int cal) {
    return ActionChip(
      label: Text('$name ($cal kcal)'),
      onPressed: () {
        _nameController.text = name;
        _caloriesController.text = cal.toString();
      },
    );
  }

  void _confirmDelete() {
    if (widget.editingMeal == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yemeği Sil'),
        content: Text('${widget.editingMeal!.name} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<AppProvider>();
              await provider.deleteMeal(widget.editingMeal!.id);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yemek silindi'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
