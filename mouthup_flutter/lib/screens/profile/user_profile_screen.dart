import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../utils/user_profile_nav.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.isSelf(username)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/profile');
      });
      return const SizedBox.shrink();
    }

    if (!app.canViewProfile(username)) {
      return ScreenWrapper(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
            const Expanded(
              child: Center(child: Text('This profile is unavailable', style: TextStyle(color: AppColors.textMuted))),
            ),
          ],
        ),
      );
    }

    final userPosts = app.postsByUser(username);
    final canMessage = app.canDm(username);

    return PopScope(
      canPop: true,
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  Expanded(
                    child: Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(name: username, radius: 36),
                  const SizedBox(height: 14),
                  Text(username, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${userPosts.length} post${userPosts.length == 1 ? '' : 's'} · Anonymous',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  if (canMessage) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => openDirectChat(context, app, username),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: userPosts.isEmpty
                  ? const Center(child: Text('No posts yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: userPosts.length,
                      itemBuilder: (_, i) {
                        final post = userPosts[i];
                        return PostTile(
                          post: post,
                          showDivider: i < userPosts.length - 1,
                          onTap: () => context.push('/post/${post.id}'),
                          onSave: () {
                            final wasSaved = post.userSaved;
                            app.toggleSavePost(post.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Post saved')),
                            );
                          },
                          onComment: () => context.push('/post/${post.id}'),
                          onShare: () => sharePost(context, post),
                          onAuthorTap: () => openUserProfile(context, app, post.author),
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
