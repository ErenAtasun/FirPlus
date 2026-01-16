import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_theme.dart';

/// Kalori ilerleme kartı
/// Dairesel progress göstergesi ile hedef/alınan/kalan kaloriyi gösterir
class CalorieProgressCard extends StatelessWidget {
  final int targetCalories;
  final int consumedCalories;
  final int remainingCalories;

  const CalorieProgressCard({
    super.key,
    required this.targetCalories,
    required this.consumedCalories,
    required this.remainingCalories,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetCalories > 0
        ? (consumedCalories / targetCalories).clamp(0.0, 1.5)
        : 0.0;
    final isOverLimit = consumedCalories > targetCalories;
    final progressColor = isOverLimit ? AppTheme.errorColor : AppTheme.successColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 16,
                    backgroundColor: Colors.grey.shade100,
                    color: Colors.grey.shade100,
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 200,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: _CircularProgressPainter(
                          progress: value,
                          progressColor: progressColor,
                          strokeWidth: 16,
                        ),
                      );
                    },
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOverLimit ? '+${consumedCalories - targetCalories}' : '$remainingCalories',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isOverLimit ? AppTheme.errorColor : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      isOverLimit ? 'Fazla' : 'Kalan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                label: 'Alınan',
                value: consumedCalories,
                icon: Icons.restaurant,
                color: progressColor,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade200,
              ),
              _buildStatItem(
                context,
                label: 'Hedef',
                value: targetCalories,
                icon: Icons.flag,
                color: AppTheme.secondaryColor,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade200,
              ),
              _buildStatItem(
                context,
                label: 'Kalan',
                value: remainingCalories.abs(),
                icon: isOverLimit ? Icons.warning : Icons.check_circle,
                color: isOverLimit ? AppTheme.errorColor : AppTheme.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Custom circular progress painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Create gradient
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        progressColor.withOpacity(0.6),
        progressColor,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
  }
}
