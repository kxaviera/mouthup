import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final _city = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    if (app.onboardingCity != null) _city.text = app.onboardingCity!;
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _city.text.trim().length >= 2;

    return ScreenWrapper(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('STEP 4 OF 4', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Your city', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('See nearby listings and connect with people in your area.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 32),
          TextField(
            controller: _city,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Mumbai, Delhi, Bangalore',
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            title: 'Continue →',
            onPressed: canContinue
                ? () {
                    context.read<AppState>().setOnboardingCity(_city.text.trim());
                    context.go('/onboarding/welcome');
                  }
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
