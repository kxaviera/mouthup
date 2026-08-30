import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/screen_wrapper.dart';

class FeedSettingsScreen extends StatelessWidget {
  const FeedSettingsScreen({super.key});

  static const _shields = [
    ('politics', 'Hide politics & debates', '#politics #government'),
    ('news', 'Hide heavy news', '#news #breaking #world'),
    ('crime', 'Hide crime stories', '#crime'),
    ('negative_moods', 'Hide sad / angry posts from others', 'When others share low moods'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return ScreenWrapper(
      padding: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => popOrGo(context, '/profile'),
                  icon: const Icon(Icons.arrow_back, color: AppColors.text),
                ),
                const Text(
                  'Feed settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comfort feed',
                        style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Shows uplifting posts first — sports, music, travel, good vibes. Transparent, not a secret algorithm.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Comfort mode', style: TextStyle(color: AppColors.text, fontSize: 14)),
                        subtitle: Text(
                          app.comfortFeedEnabled ? 'On — supporting your mood' : 'Off — all posts',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                        ),
                        value: app.comfortFeedEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => app.setComfortFeedEnabled(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Topic shields',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hide topics you don\'t want in your feed. You control this — nothing is hidden silently.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final (id, title, subtitle) in _shields)
                  SwitchListTile(
                    title: Text(title, style: const TextStyle(color: AppColors.text, fontSize: 14)),
                    subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                    value: app.topicShields.contains(id),
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => app.toggleTopicShield(id, v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
