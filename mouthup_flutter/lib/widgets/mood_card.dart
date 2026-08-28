import 'package:flutter/material.dart';
import '../constants/moods.dart';
import '../theme/app_theme.dart';

class MoodCard extends StatelessWidget {
  const MoodCard({
    super.key,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? mood.color.withValues(alpha: 0.13) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? mood.color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              mood.labelHi,
              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(mood.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
