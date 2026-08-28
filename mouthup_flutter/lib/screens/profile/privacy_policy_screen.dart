import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/screen_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      '1. What we collect',
      'We store your email (for login), permanent username, posts, comments, and direct messages. We do not require your real name, phone number, or photo.',
    ),
    (
      '2. Anonymous by design',
      'Your username cannot be changed. Other users see your username and pixel avatar only — not your email or wallet.',
    ),
    (
      '3. How we use data',
      'Data is used to operate the app: show your posts, deliver messages, enforce community rules, and send optional notifications about replies and DMs.',
    ),
    (
      '4. What we do not do',
      'We do not sell your personal data. We do not show ads based on your private messages. We do not publicly display your email.',
    ),
    (
      '5. Content moderation',
      'Posts and messages may be scanned automatically for prohibited content (e.g. pornographic material). Reported content may be reviewed by moderators.',
    ),
    (
      '6. Your controls',
      'You can block users, delete your posts and comments, save posts privately, and delete your account at any time from Profile.',
    ),
    (
      '7. Data retention',
      'When you delete your account, your data is removed from our active systems. Some backups may persist briefly for security purposes.',
    ),
    (
      '8. Contact',
      'For privacy questions, contact support@mouthup.app (demo address — replace when live).',
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
                  const Text('Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
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
