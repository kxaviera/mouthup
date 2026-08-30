import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/user_profile_nav.dart';
import 'user_avatar.dart';

class StoriesStrip extends StatelessWidget {
  const StoriesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final usernames = app.storyUsernames;

    if (usernames.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: usernames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final username = usernames[i];
          final isSelf = app.isSelf(username);
          final profile = app.socialProfile(username);

          return GestureDetector(
            onTap: isSelf ? null : () => openUserProfile(context, app, username),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  UserAvatar(
                    name: username,
                    imageUrl: profile?.avatarUrl,
                    verified: profile?.verified ?? false,
                    radius: 28,
                    showStoryRing: !isSelf,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSelf ? 'Your story' : username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelf ? AppColors.text : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: isSelf ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
