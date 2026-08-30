import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_generator.dart';
import 'verified_badge.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.imageUrl,
    this.verified = false,
    this.showStoryRing = false,
    this.onTap,
  });

  final String name;
  final double radius;
  final String? imageUrl;
  final bool verified;
  final bool showStoryRing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2 + (showStoryRing ? 6 : 0),
        height: radius * 2 + (showStoryRing ? 6 : 0),
        padding: showStoryRing ? const EdgeInsets.all(3) : null,
        decoration: showStoryRing
            ? BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: showStoryRing ? AppColors.bg : Colors.white.withValues(alpha: 0.08),
                  width: showStoryRing ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PixelAvatar(name: name),
                    )
                  : _PixelAvatar(name: name),
            ),
            if (verified)
              Positioned(
                right: -2,
                bottom: -2,
                child: VerifiedBadge(size: radius * 0.45),
              ),
          ],
        ),
      ),
    );

    return avatar;
  }
}

class _PixelAvatar extends StatelessWidget {
  const _PixelAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelAvatarPainter(name: name),
      size: Size.infinite,
    );
  }
}

class _PixelAvatarPainter extends CustomPainter {
  _PixelAvatarPainter({required this.name});

  final String name;

  @override
  void paint(Canvas canvas, Size size) {
    final mask = AvatarGenerator.pixelMask(name);
    final bg = AvatarGenerator.backgroundColor(name);
    final primary = AvatarGenerator.pixelColor(name);
    final accent = AvatarGenerator.accentColor(name);

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    final grid = mask.length;
    final cell = size.width / grid;
    final gap = cell * 0.08;

    for (var y = 0; y < grid; y++) {
      for (var x = 0; x < grid; x++) {
        if (!mask[y][x]) continue;
        final useAccent = (x + y) % 3 == 0;
        final paint = Paint()..color = useAccent ? accent : primary;
        final rect = Rect.fromLTWH(
          x * cell + gap / 2,
          y * cell + gap / 2,
          cell - gap,
          cell - gap,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(gap.clamp(0.5, 2))),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelAvatarPainter oldDelegate) => oldDelegate.name != name;
}
