import 'package:flutter/material.dart';

/// MouthUp brand logo — icon and/or wordmark from assets.
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

  static const iconAsset = 'assets/images/mouthup_icon.png';
  static const wordmarkAsset = 'assets/images/mouthup_wordmark.png';
  static const wordmarkDarkAsset = 'assets/images/mouthup_wordmark_dark.png';

  @override
  Widget build(BuildContext context) {
    final icon = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(iconAsset, width: size, height: size, fit: BoxFit.cover),
    );

    if (iconOnly || !showWordmark) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: size * 0.16),
        Image.asset(
          wordmarkDarkAsset,
          height: size * 0.34,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

/// Compact wordmark for app bars on dark backgrounds.
class MouthUpWordmark extends StatelessWidget {
  const MouthUpWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      MouthUpLogo.wordmarkDarkAsset,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

/// App icon only — for compact headers or signup.
class MouthUpIcon extends StatelessWidget {
  const MouthUpIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return MouthUpLogo(size: size, iconOnly: true);
  }
}
