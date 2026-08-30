import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 56, color: AppColors.textDim),
              const SizedBox(height: 16),
              const Text('Page not found', style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                message ?? 'This page doesn\'t exist or was removed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),
              PrimaryButton(title: 'Back to marketplace', onPressed: () => popOrGo(context, '/home')),
            ],
          ),
        ),
      ),
    );
  }
}
