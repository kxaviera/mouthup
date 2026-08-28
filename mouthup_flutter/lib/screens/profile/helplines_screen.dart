import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_wrapper.dart';

class HelplinesScreen extends StatelessWidget {
  const HelplinesScreen({super.key});

  static const _lines = [
    ('Find A Helpline', 'findahelpline.com', 'Worldwide crisis lines by country (IASP)'),
    ('Befrienders Worldwide', 'befrienders.org', 'Emotional support in 30+ countries'),
    ('Crisis Text Line', 'Text HOME to 741741', 'US & UK — free 24/7 text support'),
    ('Samaritans', '116 123', 'UK & Ireland — free, confidential'),
    ('988 Lifeline', '988', 'US — suicide & crisis lifeline'),
    ('Emergency', 'Local emergency number', 'Call your country\'s emergency services'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/profile');
      },
      child: ScreenWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.go('/profile'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                const Text('Crisis support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Free, confidential help — available worldwide', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ..._lines.map((line) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.bgElevated,
                    child: Icon(Icons.call_outlined, color: AppColors.primary, size: 20),
                  ),
                  title: Text(line.$1, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  subtitle: Text('${line.$3}\n${line.$2}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.textDim, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: line.$2));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${line.$2} copied')));
                    },
                  ),
                ),
              );
            }),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'If you or someone else is in immediate danger, contact your local emergency number right away.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
