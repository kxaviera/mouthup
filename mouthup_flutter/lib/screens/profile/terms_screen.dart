import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/screen_wrapper.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    (
      '1. Acceptance',
      'By using MouthUp you agree to these terms. MouthUp is an anonymous social platform for sharing thoughts and connecting through direct messages.',
    ),
    (
      '2. Equal space — no popularity game',
      'MouthUp does not show follower counts, like counts, or view counts on posts. Everyone is treated the same in the feed. There is no pressure to chase big numbers or compete for attention.',
    ),
    (
      '3. Organic feed',
      'Your feed is chronological and transparent. We do not use hidden engagement algorithms to boost or bury posts. What you see is based on time and what you follow — not secret ranking systems.',
    ),
    (
      '4. Anonymous use',
      'Your username is assigned once and cannot be changed. Do not attempt to identify other users or share personal information that could deanonymize yourself or others.',
    ),
    (
      '5. Acceptable content',
      'You may share opinions, politics, news, entertainment, and everyday posts freely. Pornographic and sexually explicit content is prohibited and will be removed.',
    ),
    (
      '6. Regional & translated content',
      'Some automated news posts may appear in other languages. Use the Translate option on any post to read it in your language.',
    ),
    (
      '7. Conduct',
      'Do not harass, threaten, spam, or impersonate others. Block users you do not wish to interact with. MouthUp is peer support — not professional medical or legal advice.',
    ),
    (
      '8. Your content',
      'You retain ownership of what you post. By posting, you grant MouthUp a license to display your content within the app. You are responsible for what you share.',
    ),
    (
      '9. Account & data',
      'You may delete your account at any time from Profile. Deletion removes your data from this device session. We may update these terms; continued use means acceptance.',
    ),
    (
      '10. Disclaimer',
      'MouthUp is provided "as is" without warranties. We are not liable for user-generated content or interactions between users.',
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
