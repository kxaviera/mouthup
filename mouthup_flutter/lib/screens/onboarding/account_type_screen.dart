import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/account_types.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  AccountTypeId? _selected;

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('STEP 2 OF 4', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('How will you use MouthUp?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Pick what fits you — you can browse, sell, or offer services locally.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: accountTypeOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = accountTypeOptions[i];
                final selected = _selected == opt.id;
                return InkWell(
                  onTap: () => setState(() => _selected = opt.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Text(opt.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(opt.label, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(opt.subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
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
                    context.read<AppState>().setOnboardingAccountType(_selected!);
                    if (_selected == AccountTypeId.serviceProvider) {
                      context.go('/onboarding/profession');
                    } else {
                      context.go('/onboarding/city');
                    }
                  },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
