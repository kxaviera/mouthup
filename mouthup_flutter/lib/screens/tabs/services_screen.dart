import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_wrapper.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      padding: false,
      bottomSafe: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.handyman_outlined, size: 48, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Coming soon',
                      style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'We\'re launching buy & sell first.\nLocal services — plumbers, chefs, nurses & more — will be back soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
