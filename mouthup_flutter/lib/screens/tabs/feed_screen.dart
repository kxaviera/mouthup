import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../utils/user_profile_nav.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../widgets/mouthup_logo.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _activeHashtag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshFeed(hashtag: _activeHashtag);
    });
  }

  List<MouthUpPost> _posts(AppState app) {
    var list = [...app.posts];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _selectHashtag(String? tag) {
    final next = tag == _activeHashtag ? null : tag;
    setState(() => _activeHashtag = next);
    context.read<AppState>().refreshFeed(hashtag: next);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final posts = _posts(app);
    final trending = app.trendingHashtags;

    return ScreenWrapper(
      padding: false,
      bottomSafe: false,
      child: Column(
        children: [
          _topBar(context, app),
          if (trending.isNotEmpty) _trendingBar(trending),
          if (_activeHashtag != null) _activeTagBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => app.refreshFeed(hashtag: _activeHashtag),
              child: posts.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              app.loading
                                  ? 'Loading feed…'
                                  : app.lastError != null
                                      ? 'Could not load feed.\nPull down to retry.'
                                      : _activeHashtag != null
                                          ? 'No posts for $_activeHashtag'
                                          : 'No posts yet — be the first!',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: posts.length,
                      itemBuilder: (_, i) {
                        final post = posts[i];
                        return PostTile(
                          post: post,
                          showDivider: i < posts.length - 1,
                          onTap: () => context.push('/post/${post.id}'),
                          onSave: () async {
                            final wasSaved = post.userSaved;
                            await app.toggleSavePost(post.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Post saved')),
                            );
                          },
                          onComment: () => context.push('/post/${post.id}'),
                          onShare: () => sharePost(context, post),
                          onHashtagTap: _selectHashtag,
                          onAuthorTap: () => openUserProfile(context, app, post.author),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendingBar(List<String> tags) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trending', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tag = tags[i];
                final active = _activeHashtag == tag;
                return GestureDetector(
                  onTap: () => _selectHashtag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primarySoft : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: active ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: active ? AppColors.primary : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _activeTagBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bgElevated,
      child: Row(
        children: [
          Text('Showing $_activeHashtag', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: () => _selectHashtag(null),
            child: const Text('Clear', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, AppState app) {
    final unread = app.unreadNotificationCount;
    final chatBadge = app.unreadDmCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const MouthUpWordmark(height: 32),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.push('/chats'),
                icon: const Icon(Icons.mail_outline, color: AppColors.textMuted),
                tooltip: 'Messages',
              ),
              if (chatBadge > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_none, color: AppColors.textMuted),
              ),
              if (unread > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserAvatar(name: app.nickname, radius: 18),
            ),
          ),
        ],
      ),
    );
  }
}
