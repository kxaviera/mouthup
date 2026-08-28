import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mouthup_logo.dart';
import '../../widgets/screen_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    final app = context.read<AppState>();
    await app.initialize();
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      context.go('/login');
    } else if (!app.emailVerified) {
      context.go('/verify-email');
    } else if (app.onboardingDone) {
      context.go('/home');
    } else {
      context.go('/onboarding/nickname');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MouthUpLogo(size: 100, iconOnly: true),
                    SizedBox(height: 16),
                    const Text(
                      'Share • Connect',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
