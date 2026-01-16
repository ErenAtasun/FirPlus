import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/calorie_progress_card.dart';
import '../../widgets/meal_section_card.dart';

/// Ana sayfa (Dashboard)
/// Günlük kalori özeti, öğünler ve hızlı erişim
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    title: Text(
                      'Merhaba! 👋',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/calendar');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/settings');
                        },
                      ),
                    ],
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Tarih gösterimi
                        _buildDateHeader(context),
                        const SizedBox(height: 20),

                        // Kalori progress kartı
                        CalorieProgressCard(
                          targetCalories: provider.targetCalories,
                          consumedCalories: provider.consumedCalories,
                          remainingCalories: provider.remainingCalories,
                        ),
                        const SizedBox(height: 24),

                        // Öğünler başlığı
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bugünün Öğünleri',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _showAddMealBottomSheet(context);
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Ekle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Öğün kartları
                        ...['kahvalti', 'ogle', 'aksam', 'ara'].map((mealType) {
                          final meals = provider.getMealsByType(mealType);
                          final totalCalories = provider.getCaloriesByMealType(mealType);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MealSectionCard(
                              mealType: mealType,
                              meals: meals,
                              totalCalories: totalCalories,
                              onAddPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/add-meal',
                                  arguments: {'mealType': mealType},
                                );
                              },
                              onMealTap: (meal) {
                                Navigator.of(context).pushNamed(
                                  '/add-meal',
                                  arguments: {'meal': meal},
                                );
                              },
                              onMealDelete: (mealId) {
                                _confirmDeleteMeal(context, provider, mealId);
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: 80), // FAB için boşluk
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _showAddMealBottomSheet(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Yemek Ekle'),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final monthNames = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    return Text(
      '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
    );
  }

  void _showAddMealBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Öğün Seçin',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...AppConstants.mealTypeLabels.entries.map((entry) {
              return ListTile(
                leading: Icon(
                  _getMealIcon(entry.key),
                  color: AppTheme.primaryColor,
                ),
                title: Text(entry.value),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(
                    '/add-meal',
                    arguments: {'mealType': entry.key},
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
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

  void _confirmDeleteMeal(BuildContext context, AppProvider provider, String mealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yemeği Sil'),
        content: const Text('Bu yemeği silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMeal(mealId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
