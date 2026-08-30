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

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshFeed(listingType: context.read<AppState>().feedListingFilter);
    });
  }

  List<MouthUpPost> _filteredPosts(AppState app) {
    var list = app.currentFeedPosts;
    final typeFilter = app.feedListingFilter;
    if (typeFilter != null) {
      list = list.where((p) => p.listingType == typeFilter).toList();
    }
    return list;
  }

  Widget _postTile(MouthUpPost post, AppState app, int index, int total) {
    final profile = app.socialProfile(post.author);
    return PostTile(
      post: post,
      authorAvatarUrl: profile?.avatarUrl,
      authorVerified: post.authorIsVerified || (profile?.verified ?? false),
      showDivider: index < total - 1,
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
      onLike: () => app.toggleLikePost(post.id),
      onChat: post.author == app.nickname
          ? null
          : () => openDirectChat(context, app, post.author, postId: post.id),
      onAuthorTap: () => openUserProfile(context, app, post.author),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final posts = _filteredPosts(app);

    return ScreenWrapper(
      padding: false,
      bottomSafe: false,
      child: Column(
        children: [
          _topBar(app),
          _locationBar(app, posts.length),
          _feedTabs(app),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await app.refreshFeed(listingType: app.feedListingFilter);
              },
              child: posts.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              app.loading ? 'Loading feed…' : _emptyMessage(app),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: posts.length,
                      itemBuilder: (_, i) => _postTile(posts[i], app, i, posts.length),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessage(AppState app) {
    return app.feedTab == FeedTab.following
        ? 'Follow people to see their listings here.'
        : 'No nearby listings.';
  }

  Widget _topBar(AppState app) {
    final unread = app.unreadNotificationCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const MouthUpWordmark(height: 28),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              backgroundColor: AppColors.primary,
              textColor: AppColors.onPrimary,
              child: const Icon(Icons.notifications_outlined, color: AppColors.text, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationBar(AppState app, int count) {
    final city = app.userCity ?? 'Your area';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            '$city · $count listings',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _feedTabs(AppState app) {
    Widget tab(FeedTab tab, String label) {
      final active = app.feedTab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => app.setFeedTab(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? AppColors.text : AppColors.textDim,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          tab(FeedTab.nearby, 'Nearby'),
          tab(FeedTab.following, 'Following'),
        ],
      ),
    );
  }
}
