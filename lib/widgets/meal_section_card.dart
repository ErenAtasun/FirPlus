import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/meal_entry.dart';

/// Öğün bölümü kartı
/// Bir öğün türündeki yemekleri listeler
class MealSectionCard extends StatelessWidget {
  final String mealType;
  final List<MealEntry> meals;
  final int totalCalories;
  final VoidCallback onAddPressed;
  final Function(MealEntry) onMealTap;
  final Function(String) onMealDelete;

  const MealSectionCard({
    super.key,
    required this.mealType,
    required this.meals,
    required this.totalCalories,
    required this.onAddPressed,
    required this.onMealTap,
    required this.onMealDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mealLabel = AppConstants.mealTypeLabels[mealType] ?? mealType;
    final mealIcon = _getMealIcon(mealType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getMealColor(mealType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              mealIcon,
              color: _getMealColor(mealType),
              size: 24,
            ),
          ),
          title: Text(
            mealLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            meals.isEmpty
                ? 'Henüz yemek eklenmedi'
                : '${meals.length} yemek • $totalCalories kcal',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalCalories > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCalories',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                onPressed: onAddPressed,
              ),
            ],
          ),
          children: [
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: onAddPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'Yemek ekle',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...meals.map((meal) => _buildMealItem(context, meal)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, MealEntry meal) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppTheme.errorColor),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Yemeği Sil'),
            content: Text('${meal.name} silinsin mi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onMealDelete(meal.id),
      child: InkWell(
        onTap: () => onMealTap(meal),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    if (meal.note != null && meal.note!.isNotEmpty)
                      Text(
                        meal.note!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.calories} kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (meal.hasMacros)
                    Text(
                      'P:${meal.protein?.round() ?? 0} K:${meal.carbs?.round() ?? 0} Y:${meal.fat?.round() ?? 0}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'kahvalti':
        return Icons.free_breakfast;
      case 'ogle':
        return Icons.lunch_dining;
      case 'aksam':
        return Icons.dinner_dining;
      case 'ara':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'kahvalti':
        return Colors.orange;
      case 'ogle':
        return Colors.green;
      case 'aksam':
        return Colors.indigo;
      case 'ara':
        return Colors.pink;
      default:
        return AppTheme.primaryColor;
    }
  }
}
