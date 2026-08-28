import 'package:flutter/material.dart';
import '../constants/moods.dart';
import '../theme/app_theme.dart';

class PulseBar extends StatelessWidget {
  const PulseBar({
    super.key,
    required this.moodId,
    required this.percent,
    this.highlight = false,
  });

  final MoodId moodId;
  final int percent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final mood = moodById(moodId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mood.labelHi,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                        color: highlight ? AppColors.text : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 12,
                        color: highlight ? mood.color : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.bgElevated,
                    color: mood.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
