import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/professions.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class ProfessionScreen extends StatefulWidget {
  const ProfessionScreen({super.key});

  @override
  State<ProfessionScreen> createState() => _ProfessionScreenState();
}

class _ProfessionScreenState extends State<ProfessionScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('STEP 3 OF 4', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Your profession', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('What service do you offer? This shows on your profile and listings.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: professionOptions.length,
              itemBuilder: (_, i) {
                final opt = professionOptions[i];
                final selected = _selected == opt.apiValue;
                return InkWell(
                  onTap: () => setState(() => _selected = opt.apiValue),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          PrimaryButton(
            title: 'Continue →',
            onPressed: _selected == null
                ? null
                : () {
                    context.read<AppState>().setOnboardingProfession(_selected!);
                    context.go('/onboarding/city');
                  },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
