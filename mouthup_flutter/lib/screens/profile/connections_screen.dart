import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../utils/user_profile_nav.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({
    super.key,
    required this.username,
    required this.showFollowers,
  });

  final String username;
  final bool showFollowers;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final title = showFollowers ? 'Followers' : 'Following';
    final users = showFollowers ? app.followerUsersFor(username) : app.followingUsersFor(username);
    final total = showFollowers
        ? (app.isSelf(username) ? app.followerCount : app.socialProfile(username)?.followerCount ?? users.length)
        : (app.isSelf(username) ? app.followingCount : app.socialProfile(username)?.followingCount ?? users.length);

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
                  onPressed: () => popOrGo(context, app.isSelf(username) ? '/profile' : '/user/$username'),
                  icon: const Icon(Icons.arrow_back, color: AppColors.text),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                      Text('@$username · $total total', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Text(
                      showFollowers ? 'No followers yet' : 'Not following anyone yet',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final name = users[i];
                      final profile = app.socialProfile(name);
                      return InkWell(
                        onTap: () => openUserProfile(context, app, name),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              UserAvatar(name: name, imageUrl: profile?.avatarUrl, verified: profile?.verified ?? false, radius: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: UsernameWithBadge(
                                  username: name,
                                  verified: profile?.verified ?? false,
                                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              if (!app.isSelf(name) && !showFollowers)
                                TextButton(
                                  onPressed: () => app.toggleFollow(name),
                                  child: Text(app.isFollowing(name) ? 'Following' : 'Follow'),
                                )
                              else
                                const Icon(Icons.chevron_right, color: AppColors.textDim, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
