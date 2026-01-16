import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/daily_log.dart';
import '../../models/meal_entry.dart';
import '../../providers/app_provider.dart';

/// Takvim ekranı
/// Aylık görünümde günleri yeşil/kırmızı/gri olarak gösterir
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<String, DailyLog> _monthLogs = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadMonthLogs();
  }

  void _loadMonthLogs() {
    final provider = context.read<AppProvider>();
    final logs = provider.getMonthLogs(_focusedDay.year, _focusedDay.month);
    _monthLogs = {for (var log in logs) log.dateKey: log};
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takvim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _loadMonthLogs();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Takvim
          _buildCalendar(),

          // Seçili gün detayı
          Expanded(
            child: _buildSelectedDayDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadMonthLogs();
          setState(() {});
        },
        locale: 'tr_TR',
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left),
          rightChevronIcon: const Icon(Icons.chevron_right),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.grey.shade600),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, false, isToday: true);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, true);
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected, {bool isToday = false}) {
    final dateKey = _getDateKey(day);
    final log = _monthLogs[dateKey];
    final status = log?.status ?? 'EMPTY';

    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    if (isSelected) {
      backgroundColor = AppTheme.primaryColor;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = AppTheme.primaryColor.withOpacity(0.2);
      textColor = AppTheme.primaryColor;
      borderColor = AppTheme.primaryColor;
    } else {
      textColor = Colors.black87;
      switch (status) {
        case 'GREEN':
          backgroundColor = AppTheme.successColor.withOpacity(0.2);
          break;
        case 'RED':
          backgroundColor = AppTheme.errorColor.withOpacity(0.2);
          break;
        default:
          backgroundColor = Colors.transparent;
      }
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // Kalori rozeti
            if (log != null && log.totalCalories > 0 && !isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: status == 'GREEN'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == 'GREEN'
                      ? '✓'
                      : '+${log.totalCalories - log.targetCalories}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    if (_selectedDay == null) {
      return const Center(child: Text('Bir gün seçin'));
    }

    final provider = context.read<AppProvider>();
    final log = provider.getDailyLog(_selectedDay!);
    final meals = log != null ? provider.getMealsForDate(_selectedDay!) : <MealEntry>[];

    final dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final monthNames = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final dateStr =
        '${dayNames[_selectedDay!.weekday - 1]}, ${_selectedDay!.day} ${monthNames[_selectedDay!.month - 1]}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (log != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: log.status == 'GREEN'
                        ? AppTheme.successColor.withOpacity(0.1)
                        : log.status == 'RED'
                            ? AppTheme.errorColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    log.status == 'GREEN'
                        ? 'Hedefte ✓'
                        : log.status == 'RED'
                            ? '+${log.excessCalories} kcal'
                            : 'Veri yok',
                    style: TextStyle(
                      color: log.status == 'GREEN'
                          ? AppTheme.successColor
                          : log.status == 'RED'
                              ? AppTheme.errorColor
                              : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Kalori özeti
          if (log != null)
            Text(
              '${log.totalCalories} / ${log.targetCalories} kcal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),

          const SizedBox(height: 16),

          // Yemek listesi
          Expanded(
            child: meals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Bu gün için kayıt yok',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            _getMealIcon(meal.mealType),
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(meal.name),
                        subtitle: Text(meal.mealTypeLabel),
                        trailing: Text(
                          '${meal.calories} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
}
