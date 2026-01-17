import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Widget to display streak flame with animation
class StreakFlameWidget extends StatelessWidget {
  final int streak;

  const StreakFlameWidget({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: streak > 0
            ? const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: streak == 0 ? AppColors.surfaceLight : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            streak > 0 ? '🔥' : '💤',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            '$streak',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: streak > 0 ? Colors.white : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
