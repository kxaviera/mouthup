import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScreenWrapper extends StatelessWidget {
  const ScreenWrapper({
    super.key,
    required this.child,
    this.padding = true,
    this.bottomSafe = true,
    this.scrollable = false,
  });

  final Widget child;
  final bool padding;
  final bool bottomSafe;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    Widget body = child;

    if (padding) {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: body,
      );
    }

    if (scrollable) {
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: bottomSafe,
        child: body,
      ),
    );
  }
}
