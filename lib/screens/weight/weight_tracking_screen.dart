import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/weight_entry.dart';
import '../../providers/app_provider.dart';

/// Kilo Takip Ekranı
/// Kilo geçmişi, grafik ve yeni kilo girişi
class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final weightEntries = provider.weightEntries;
        final currentWeight = provider.userProfile?.weightKg ?? 0;
        final latestWeight = weightEntries.isNotEmpty
            ? weightEntries.last.weightKg
            : currentWeight;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kilo Takibi'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Güncel kilo kartı
                _buildCurrentWeightCard(context, latestWeight, provider),
                const SizedBox(height: 24),

                // Grafik
                if (weightEntries.length >= 2) ...[
                  Text(
                    'Kilo Grafiği',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildWeightChart(context, weightEntries),
                  const SizedBox(height: 24),
                ],

                // Geçmiş listesi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kilo Geçmişi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (weightEntries.isNotEmpty)
                      Text(
                        '${weightEntries.length} kayıt',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (weightEntries.isEmpty)
                  _buildEmptyState(context)
                else
                  _buildWeightHistory(context, weightEntries, provider),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddWeightDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Kilo Ekle'),
          ),
        );
      },
    );
  }

  Widget _buildCurrentWeightCard(
      BuildContext context, double weight, AppProvider provider) {
    final profile = provider.userProfile;
    final startWeight = profile?.weightKg ?? weight;
    final difference = weight - startWeight;
    final isLoss = difference < 0;
    final isGain = difference > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Güncel Kilonuz',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                weight.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  ' kg',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          if (difference != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLoss ? Icons.trending_down : Icons.trending_up,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isGain ? '+' : ''}${difference.toStringAsFixed(1)} kg başlangıçtan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeightStat('Başlangıç', '${startWeight.toStringAsFixed(1)} kg'),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildWeightStat('Hedef', _getGoalText(profile?.goalType)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getGoalText(String? goalType) {
    switch (goalType) {
      case 'kilo_ver':
        return 'Kilo Vermek';
      case 'kilo_al':
        return 'Kilo Almak';
      default:
        return 'Korumak';
    }
  }

  Widget _buildWeightChart(BuildContext context, List<WeightEntry> entries) {
    final recentEntries = entries.length > 30
        ? entries.sublist(entries.length - 30)
        : entries;

    final minWeight = recentEntries
        .map((e) => e.weightKg)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = recentEntries
        .map((e) => e.weightKg)
        .reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.2;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (recentEntries.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentEntries.length) {
                    return const SizedBox();
                  }
                  final date = recentEntries[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: ((maxWeight - minWeight + padding * 2) / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (recentEntries.length - 1).toDouble(),
          minY: minWeight - padding,
          maxY: maxWeight + padding,
          lineBarsData: [
            LineChartBarData(
              spots: recentEntries.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.weightKg);
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final entry = recentEntries[touchedSpot.spotIndex];
                  return LineTooltipItem(
                    '${entry.weightKg.toStringAsFixed(1)} kg\n${DateFormat('dd MMM', 'tr_TR').format(entry.date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz kilo kaydı yok',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlerlemenizi takip etmek için\nkilonuzu kaydedin',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistory(
      BuildContext context, List<WeightEntry> entries, AppProvider provider) {
    // En yeniden eskiye sırala
    final sortedEntries = entries.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final prevEntry = index < sortedEntries.length - 1
            ? sortedEntries[index + 1]
            : null;
        final diff = prevEntry != null
            ? entry.weightKg - prevEntry.weightKg
            : 0.0;

        return Dismissible(
          key: Key(entry.id),
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
          onDismissed: (_) => provider.deleteWeightEntry(entry.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Tarih
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy', 'tr_TR').format(entry.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE', 'tr_TR').format(entry.date),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Değişim
                if (diff != 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: diff < 0
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          diff < 0 ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                          color:
                              diff < 0 ? AppTheme.successColor : AppTheme.errorColor,
                          size: 16,
                        ),
                        Text(
                          diff.abs().toStringAsFixed(1),
                          style: TextStyle(
                            color: diff < 0
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Kilo
                Text(
                  '${entry.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddWeightDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(
      text: provider.userProfile?.weightKg.toStringAsFixed(1) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
                'Yeni Kilo Girişi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Bugünkü kilonuzu girin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Kilo (kg)',
                  hintText: 'örn: 72.5',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final weight = double.tryParse(controller.text);
                    if (weight != null && weight > 0 && weight < 500) {
                      await provider.addWeightEntry(weight);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kilo kaydedildi'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
