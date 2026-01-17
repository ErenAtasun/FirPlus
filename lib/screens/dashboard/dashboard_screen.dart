import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/app_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/calorie_progress_ring.dart';
import '../../widgets/streak_flame_widget.dart';
import '../../widgets/meal_card.dart';
import '../meal/add_meal_screen.dart';

/// Main dashboard screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        if (user == null) return const SizedBox();

        final selectedRecord = provider.selectedDayRecord;
        final meals = selectedRecord?.meals ?? [];
        final totalCalories = selectedRecord?.totalCalories ?? 0;
        final targetCalories = user.targetCalories.round();

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  title: Row(
                    children: [
                      const Text('🔥'),
                      const SizedBox(width: 8),
                      Text(
                        'DietTracker',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  actions: [
                    StreakFlameWidget(streak: provider.streak.currentStreak),
                    const SizedBox(width: 16),
                  ],
                ),

                // Calorie Progress
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: CalorieProgressRing(
                            consumed: totalCalories,
                            target: targetCalories,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatCard(
                                'Hedef',
                                '$targetCalories kcal',
                                AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                'Tüketilen',
                                '$totalCalories kcal',
                                AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                'Kalan',
                                '${targetCalories - totalCalories} kcal',
                                totalCalories <= targetCalories
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cheat Day Badge
                if (provider.streak.availableCheatDays > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kaçamak Hakkınız: ${provider.streak.availableCheatDays}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  Text(
                                    '14 gün başarılı tamamladığınızda kazanırsınız',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Calendar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(provider.selectedDate, day),
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() => _calendarFormat = format);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          provider.setSelectedDate(selectedDay);
                          setState(() => _focusedDay = focusedDay);
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle:
                              const TextStyle(color: AppColors.textPrimary),
                          weekendTextStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          outsideTextStyle:
                              const TextStyle(color: AppColors.textTertiary),
                          selectedDecoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          formatButtonDecoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: AppColors.primary,
                          ),
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.textPrimary,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildDayCell(context, day, provider);
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Selected Day Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(provider.selectedDate),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${meals.length} öğün',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                // Meals List
                if (meals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz öğün eklenmedi',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aşağıdaki + butonuna tıklayarak\nöğün ekleyebilirsiniz',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final meal = meals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MealCard(
                              meal: meal,
                              onDelete: () {
                                provider.deleteMeal(
                                  provider.selectedDate,
                                  meal.id,
                                );
                              },
                            ),
                          );
                        },
                        childCount: meals.length,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddMealScreen(date: provider.selectedDate),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Öğün Ekle'),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
      BuildContext context, DateTime day, AppProvider provider) {
    final status = provider.getDayStatus(day);
    Color backgroundColor;
    Color textColor = AppColors.textPrimary;

    switch (status) {
      case 'success':
        backgroundColor = AppColors.daySuccess;
        textColor = Colors.white;
        break;
      case 'exceeded':
        backgroundColor = AppColors.dayExceeded;
        textColor = Colors.white;
        break;
      case 'cheat':
        backgroundColor = AppColors.dayCheat;
        textColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: status != 'empty' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Bugün';
    } else if (dateOnly == yesterday) {
      return 'Dün';
    } else {
      final months = [
        '',
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık'
      ];
      return '${date.day} ${months[date.month]}';
    }
  }
}
