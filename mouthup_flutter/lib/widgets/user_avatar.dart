import 'package:flutter/material.dart';
import '../utils/avatar_generator.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 20,
  });

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _PixelAvatarPainter(name: name),
        size: Size.square(radius * 2),
      ),
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
