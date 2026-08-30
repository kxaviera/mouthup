import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../constants/app_brand.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _rules = [
    (Icons.storefront_outlined, 'Buy, sell, rent, swap, or give away locally'),
    (Icons.handyman_outlined, 'Find or offer services — plumbers, tutors, chefs & more'),
    (Icons.location_on_outlined, 'Discover listings and people near you'),
    (Icons.chat_bubble_outline, 'Chat directly from any post'),
    (Icons.favorite_outline, 'Follow profiles, like posts, and join the conversation'),
    (Icons.block, 'No illegal content, scams, or harassment'),
    (Icons.description_outlined, 'By continuing you agree to our Terms & Conditions'),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Almost done!', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Welcome to ${AppBrand.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text(
            'Your local marketplace and community — list items, find services, connect nearby.',
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
            title: 'Start exploring',
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
