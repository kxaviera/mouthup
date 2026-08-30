import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/screen_wrapper.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    (
      '1. Acceptance',
      'By using MouthUp you agree to these terms. MouthUp is a local marketplace and community platform for buying, selling, renting, swapping, and offering services.',
    ),
    (
      '2. Public profiles',
      'Your username is your public identity on MouthUp. It is assigned once and cannot be changed. Be honest in listings and respectful in messages.',
    ),
    (
      '3. Listings & transactions',
      'Sellers and service providers are responsible for the accuracy of their listings. MouthUp facilitates discovery and messaging — we are not a party to transactions between users.',
    ),
    (
      '4. Acceptable content',
      'Do not post illegal items, scams, counterfeit goods, or sexually explicit content. Report suspicious listings or harassment using in-app tools.',
    ),
    (
      '5. Conduct',
      'Do not harass, threaten, spam, or impersonate others. Block users you do not wish to interact with. MouthUp is not professional legal, medical, or financial advice.',
    ),
    (
      '6. Your content',
      'You retain ownership of what you post. By posting, you grant MouthUp a license to display your content within the app. You are responsible for what you share.',
    ),
    (
      '7. Account & data',
      'You may delete your account at any time from Profile. Deletion removes your data from this device session. We may update these terms; continued use means acceptance.',
    ),
    (
      '8. Disclaimer',
      'MouthUp is provided "as is" without warranties. We are not liable for user-generated content, listings, or interactions between users.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(onPressed: () => popOrGo(context, '/profile'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Text('Terms & Conditions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: _sections.length,
                separatorBuilder: (_, i) => const SizedBox(height: 20),
                itemBuilder: (_, i) {
                  final (title, body) = _sections[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
