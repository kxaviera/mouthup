import 'package:flutter/material.dart';
import '../constants/moods.dart';
import '../theme/app_theme.dart';

class MoodPickerRow extends StatelessWidget {
  const MoodPickerRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MoodId? selected;
  final ValueChanged<MoodId?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling?',
          style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Optional — helps us show a feed that supports your mood.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in moods)
              _MoodChip(
                mood: mood,
                selected: selected == mood.id,
                onTap: () => onSelected(selected == mood.id ? null : mood.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              mood.label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
