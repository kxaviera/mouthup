import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_brand.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  static const _rules = [
    (Icons.visibility_off_outlined, 'Fully anonymous — unique username, no real name required'),
    (Icons.groups_outlined, 'Everyone is equal — no follower counts, no likes, no view counts'),
    (Icons.eco_outlined, '100% organic feed — chronological posts, no secret algorithm or ranking games'),
    (Icons.spa_outlined, 'No pressure — post without chasing numbers or competing for attention'),
    (Icons.chat_bubble_outline, 'Share anything — news, politics, opinions, entertainment'),
    (Icons.mail_outline, 'Direct messages only — no group chat'),
    (Icons.block, 'No pornographic content'),
    (Icons.favorite_outline, 'Peer support — not medical or legal advice'),
    (Icons.description_outlined, 'By continuing you agree to our Terms & Conditions'),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('STEP 2 OF 2', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Safe space rules', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text(
            '${AppBrand.name} is calm, equal, and judgment-free — no influencer headache.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final (icon, text) = _rules[i];
                final isTerms = i == _rules.length - 1;
                return InkWell(
                  onTap: isTerms ? () => context.push('/profile/terms') : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.bgElevated,
                          child: Icon(icon, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: isTerms ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isTerms) const Icon(Icons.chevron_right, color: AppColors.textDim, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            title: 'Got it — go to feed',
            onPressed: () async {
              final error = await context.read<AppState>().completeOnboarding();
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              context.go('/home');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
