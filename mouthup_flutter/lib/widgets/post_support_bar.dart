import 'package:flutter/material.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

class PostSupportBar extends StatelessWidget {
  const PostSupportBar({
    super.key,
    required this.post,
    required this.onReact,
  });

  final MouthUpPost post;
  final Future<void> Function(SupportReactionType type) onReact;

  static const _options = [
    (SupportReactionType.hug, '🫂', 'Hug'),
    (SupportReactionType.strength, '💪', 'Strength'),
    (SupportReactionType.same, '🌟', 'Same here'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (type, emoji, label) in _options) ...[
          _SupportChip(
            emoji: emoji,
            label: label,
            selected: post.userSupportReaction == type,
            onTap: () => onReact(type),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
