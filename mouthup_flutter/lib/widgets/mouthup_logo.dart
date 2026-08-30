import 'package:flutter/material.dart';
import '../constants/app_brand.dart';
import '../theme/app_theme.dart';

/// Full ISZI logo: icon mark + wordmark (splash, login, signup).
class IsziFullLogo extends StatelessWidget {
  const IsziFullLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IsziIcon(size: size * 0.72),
        SizedBox(height: size * 0.16),
        IsziWordmark(height: size * 0.34),
      ],
    );
  }
}

/// Icon-only mark — app icon, favicons, compact slots.
class IsziIcon extends StatelessWidget {
  const IsziIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IsziIconPainter(borderRadius: radius),
      ),
    );
  }
}

class _IsziIconPainter extends CustomPainter {
  _IsziIconPainter({required this.borderRadius});

  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(borderRadius));
    canvas.drawRRect(rrect, Paint()..color = AppColors.bgCard);
    canvas.drawRRect(rrect, Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.018);

    final cx = size.width / 2;
    final barW = size.width * 0.11;
    final barH = size.height * 0.42;
    final barTop = size.height * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, barTop + barH / 2), width: barW, height: barH),
        Radius.circular(barW / 2),
      ),
      Paint()..color = AppColors.text,
    );

    final dotR = size.width * 0.055;
    canvas.drawCircle(Offset(cx, size.height * 0.72), dotR, Paint()..color = AppColors.text);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ISZI wordmark typography.
class IsziWordmark extends StatelessWidget {
  const IsziWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppBrand.name,
      style: TextStyle(
        color: AppColors.text,
        fontSize: height,
        fontWeight: FontWeight.w900,
        letterSpacing: height * 0.22,
        height: 1,
      ),
    );
  }
}

// Legacy aliases — keep existing imports working.
class MouthUpLogo extends StatelessWidget {
  const MouthUpLogo({
    super.key,
    this.size = 80,
    this.showWordmark = true,
    this.iconOnly = false,
  });

  final double size;
  final bool showWordmark;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (iconOnly || !showWordmark) return IsziIcon(size: size);
    return IsziFullLogo(size: size);
  }
}

class MouthUpWordmark extends StatelessWidget {
  const MouthUpWordmark({super.key, this.height = 28});
  final double height;
  @override
  Widget build(BuildContext context) => IsziWordmark(height: height);
}

class MouthUpIcon extends StatelessWidget {
  const MouthUpIcon({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => IsziIcon(size: size);
}

@Deprecated('Use IsziIcon')
typedef IsziMark = IsziIcon;
