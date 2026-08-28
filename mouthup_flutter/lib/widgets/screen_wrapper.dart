import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScreenWrapper extends StatelessWidget {
  const ScreenWrapper({
    super.key,
    required this.child,
    this.padding = true,
    this.bottomSafe = true,
  });

  final Widget child;
  final bool padding;
  final bool bottomSafe;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Material(
        color: AppColors.bg,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            bottom: bottomSafe,
            child: Padding(
              padding: padding ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
