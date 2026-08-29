import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/post_translate.dart';

/// Tap to translate post text (helps with regional / bot news in other languages).
class PostTranslateLink extends StatelessWidget {
  const PostTranslateLink({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () async {
            final ok = await openPostTranslation(content);
            if (!context.mounted || ok) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open translator')),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.primary,
          ),
          icon: const Icon(Icons.translate, size: 15),
          label: const Text('Translate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
