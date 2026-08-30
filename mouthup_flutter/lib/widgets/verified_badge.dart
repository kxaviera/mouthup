import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});

  final double size;

  static const color = Color(0xFF1D9BF0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(Icons.check, size: size * 0.62, color: Colors.white),
    );
  }
}

/// Prominent verified label for profile header.
class VerifiedProfileChip extends StatelessWidget {
  const VerifiedProfileChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VerifiedBadge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: VerifiedBadge.color.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VerifiedBadge(size: 14),
          SizedBox(width: 6),
          Text(
            'Verified',
            style: TextStyle(color: VerifiedBadge.color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class UsernameWithBadge extends StatelessWidget {
  const UsernameWithBadge({
    super.key,
    required this.username,
    this.verified = false,
    this.style,
    this.badgeSize = 16,
  });

  final String username;
  final bool verified;
  final TextStyle? style;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            username,
            overflow: TextOverflow.ellipsis,
            style: style ?? const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
          ),
        ),
        if (verified) ...[
          const SizedBox(width: 4),
          VerifiedBadge(size: badgeSize),
        ],
      ],
    );
  }
}
